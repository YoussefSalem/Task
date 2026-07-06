import { z } from "zod";
import { firebaseAdminDb } from "@/lib/firebase/admin";
import {
  firebaseApiError,
  requireFirebaseAdmin,
} from "@/lib/firebase/server-auth";
import { buildAiContext } from "@/lib/ai/context";
import { runGeminiAiExecution } from "@/lib/ai/gemini";
import { memoryFromExecution } from "@/lib/ai/memory";
import { hasPermission } from "@/lib/permissions";
import { isCollectionAllowedForAi, redactDocForAi } from "@/lib/ai/context-redaction";
import type {
  AiExecution,
  AiMemory,
  AiReport,
  AdminUser,
  DatabaseState,
} from "@/lib/types";

export const runtime = "nodejs";

const requestSchema = z.object({
  prompt: z.string().trim().min(2).max(4000),
  page: z
    .object({
      page: z.string().optional(),
      currentEntityType: z.string().optional(),
      currentEntityId: z.string().optional(),
    })
    .optional(),
});

const collections = {
  aiExecutions: "aiExecutions",
  aiMemories: "aiMemories",
  aiReports: "aiReports",
  customers: "customers",
  providers: "providers",
  jobs: "orders",
  categories: "categories",
  services: "services",
  banners: "banners",
  conversations: "conversations",
  verificationRequirements: "verificationRequirements",
  wallets: "wallets",
  transactions: "transactions",
  complaints: "complaints",
  reviews: "reviews",
  admins: "admins",
  invitations: "adminInvites",
  roles: "roles",
  promos: "promos",
  notifications: "notifications",
  payouts: "payouts",
  auditLogs: "auditLogs",
  locations: "providerLocations",
  instapayReviews: "instapayReviews",
} as const;

const emptyDatabase: DatabaseState = {
  aiExecutions: [],
  aiMemories: [],
  aiReports: [],
  customers: [],
  providers: [],
  jobs: [],
  categories: [],
  services: [],
  banners: [],
  conversations: [],
  verificationRequirements: [],
  wallets: [],
  transactions: [],
  complaints: [],
  reviews: [],
  admins: [],
  invitations: [],
  roles: [],
  promos: [],
  notifications: [],
  payouts: [],
  auditLogs: [],
  locations: [],
  instapayReviews: [],
  sequences: { provider: 0 },
  issuedProviderIds: [],
};

type ArrayStateKey = Exclude<
  keyof DatabaseState,
  "sequences" | "issuedProviderIds"
>;
const environmentScopedCollections = new Set<ArrayStateKey>([
  "aiExecutions",
  "aiMemories",
  "aiReports",
  "customers",
  "providers",
  "jobs",
  "categories",
  "services",
  "banners",
  "conversations",
  "wallets",
  "transactions",
  "complaints",
  "reviews",
  "promos",
  "notifications",
  "auditLogs",
  "payouts",
  "locations",
  "instapayReviews",
]);
const environmentForActor = (actor: AdminUser) =>
  actor.isDemoUser ? "demo" : "production";

function normalizeFirestore(value: unknown): unknown {
  if (!value || typeof value !== "object") return value;
  if (
    "toDate" in value &&
    typeof (value as { toDate?: unknown }).toDate === "function"
  ) {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }
  if (Array.isArray(value)) return value.map((item) => normalizeFirestore(item));
  return Object.fromEntries(
    Object.entries(value).map(([key, item]) => [key, normalizeFirestore(item)]),
  );
}

function clean<T>(value: T): T {
  return JSON.parse(
    JSON.stringify(value, (_key, item) => (item === undefined ? null : item)),
  ) as T;
}

/**
 * Cap on documents per collection sent into AI context. This is a "minimal
 * context" limit, not a UI display limit (contrast with the dashboard's own
 * limit(1000) reads) - the AI route previously pulled up to 1000 docs from
 * every one of ~23 collections into every single prompt, unfiltered and
 * unredacted, sent whole to a third-party LLM.
 */
const AI_CONTEXT_DOC_LIMIT = 150;

async function readState(actor: AdminUser): Promise<DatabaseState> {
  const state = structuredClone(emptyDatabase);
  const environment = environmentForActor(actor);
  await Promise.all(
    (Object.entries(collections) as Array<[ArrayStateKey, string]>).map(
      async ([key, name]) => {
        // Collections that must never reach a third-party LLM (admin role
        // assignments, wallet balances) are skipped entirely and stay as the
        // empty arrays already in `emptyDatabase`. Collections the actor
        // lacks view permission for are likewise skipped - a support-role
        // admin's AI query gets a narrower context than a Super Admin's.
        if (!isCollectionAllowedForAi(key, actor)) return;
        const ref = firebaseAdminDb.collection(name);
        const snapshot = environmentScopedCollections.has(key)
          ? await ref.where("environment", "==", environment).limit(AI_CONTEXT_DOC_LIMIT).get()
          : await ref.limit(AI_CONTEXT_DOC_LIMIT).get();
        (state[key] as unknown[]) = snapshot.docs.map((doc) =>
          redactDocForAi({
            id: doc.id,
            ...(normalizeFirestore(doc.data()) as Record<string, unknown>),
          }),
        );
      },
    ),
  );
  state.sequences.provider = state.providers.length;
  state.issuedProviderIds = state.providers.map((provider) => provider.providerId);
  return state;
}

async function saveExecution(input: Partial<AiExecution>, actor: AdminUser) {
  const now = new Date().toISOString();
  const ref = firebaseAdminDb.collection("aiExecutions").doc();
  const execution: AiExecution = clean({
    id: ref.id,
    prompt: input.prompt ?? "",
    normalizedPrompt: input.normalizedPrompt ?? "",
    actorId: input.actorId ?? "",
    actorName: input.actorName ?? "",
    actorRole: input.actorRole ?? "Support",
    page: input.page ?? "Unknown",
    status: input.status ?? "Completed",
    risk: input.risk ?? "LOW",
    answer: input.answer ?? "",
    plan: input.plan ?? [],
    toolCalls: input.toolCalls ?? [],
    evidence: input.evidence ?? [],
    recommendations: input.recommendations ?? [],
    context: input.context ?? {},
    createdAt: now,
    updatedAt: now,
    environment: environmentForActor(actor),
    isDemoData: Boolean(actor.isDemoUser),
  });
  await ref.set(execution);
  return execution;
}

async function saveMemory(execution: AiExecution, actor: AdminUser) {
  const memory = memoryFromExecution(execution);
  if (!memory) return null;
  const ref = memory.id
    ? firebaseAdminDb.collection("aiMemories").doc(memory.id)
    : firebaseAdminDb.collection("aiMemories").doc();
  const now = new Date().toISOString();
  const saved: AiMemory = clean({
    id: ref.id,
    actorId: execution.actorId,
    scope: memory.scope ?? "admin",
    key: memory.key ?? "context",
    value: memory.value ?? "",
    recordType: memory.recordType,
    recordId: memory.recordId,
    createdAt: memory.createdAt ?? now,
    updatedAt: now,
    environment: environmentForActor(actor),
    isDemoData: Boolean(actor.isDemoUser),
  });
  await ref.set(saved, { merge: true });
  return saved;
}

async function saveReport(execution: AiExecution, actor: AdminUser) {
  if (!/brief|report|summary|executive/i.test(execution.prompt)) return null;
  const ref = firebaseAdminDb.collection("aiReports").doc();
  const report: AiReport = clean({
    id: ref.id,
    type: "executive-brief",
    title: "Task AI Executive Brief",
    summary: execution.answer,
    metrics: Object.fromEntries(
      execution.evidence.map((item) => [item.label, item.value]),
    ),
    recommendations: execution.recommendations,
    generatedAt: new Date().toISOString(),
    generatedBy: actor.name,
    environment: environmentForActor(actor),
    isDemoData: Boolean(actor.isDemoUser),
  });
  await ref.set(report);
  return report;
}

async function auditAiRun(
  actor: AdminUser,
  execution: AiExecution,
  geminiInteractionId?: string,
) {
  await firebaseAdminDb.collection("auditLogs").add(
    clean({
      actorId: actor.id,
      actorName: actor.name,
      action: "ai.gemini_execution_created",
      entityType: "aiExecution",
      entityId: execution.id,
      detail: `Gemini AI execution created for "${execution.prompt}".${geminiInteractionId ? ` Gemini interaction: ${geminiInteractionId}.` : ""}`,
      environment: environmentForActor(actor),
      isDemoData: Boolean(actor.isDemoUser),
      createdAt: new Date().toISOString(),
      ipAddress: "Firebase Auth",
      device: "Task Admin server",
    }),
  );
}

export async function POST(request: Request) {
  try {
    const actor = (await requireFirebaseAdmin(request)) as AdminUser;
    const parsed = requestSchema.parse(await request.json());
    if (
      parsed.page?.page === "Technician Performance" &&
      !hasPermission(actor.role, actor.permissions, "technicians.performance.aiSummary")
    ) {
      throw new Response("Forbidden", { status: 403, statusText: "Forbidden" });
    }
    const state = await readState(actor);
    const context = buildAiContext({
      actor,
      state,
      page: parsed.page,
    });
    const generated = await runGeminiAiExecution(context, parsed.prompt);
    const { geminiInteractionId, ...executionInput } = generated;
    const execution = await saveExecution(executionInput, actor);
    const [memory, report] = await Promise.all([
      saveMemory(execution, actor),
      saveReport(execution, actor),
      auditAiRun(actor, execution, geminiInteractionId),
    ]);
    return Response.json({ execution, memory, report });
  } catch (error) {
    return firebaseApiError(error);
  }
}
