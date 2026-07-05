import "server-only";

import { z } from "zod";
import type {
  AiActionRequest,
  AiEvidence,
  AiExecution,
  AiRecommendation,
  AiRiskLevel,
  DatabaseState,
} from "@/lib/types";
import type { AiRuntimeContext } from "@/lib/ai/context";
import { executionStatus, highestRisk } from "@/lib/ai/action-engine";
import { detectIntent, planForIntent } from "@/lib/ai/planner";
import {
  analyzeCancellation,
  dispatchRecommendation,
  findBestJob,
  fraudSignals,
  marketplaceMetrics,
} from "@/lib/ai/tools";
import { taskExecutiveSystemPrompt } from "@/lib/ai/prompts";
import { activeAiProvider } from "@/lib/integrations/api-center";

const riskSchema = z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]);
const entityTypeSchema = z.enum([
  "customer",
  "provider",
  "job",
  "payment",
  "complaint",
  "wallet",
  "service",
  "system",
]);
const actionTypeSchema = z.enum([
  "navigate",
  "openJob",
  "openProvider",
  "refundJob",
  "adjustWallet",
  "createComplaint",
  "assignProvider",
  "changeJobStatus",
  "setProviderDecision",
  "createPromo",
  "createNotification",
]);
const primitivePayloadSchema = z.union([
  z.string(),
  z.number(),
  z.boolean(),
  z.null(),
]);
const geminiActionSchema = z.object({
  type: actionTypeSchema,
  label: z.string().min(1),
  risk: riskSchema,
  requiresConfirmation: z.boolean(),
  payload: z.record(z.string(), primitivePayloadSchema.optional()).default({}),
});
const geminiEvidenceSchema = z.object({
  label: z.string().min(1),
  entityType: entityTypeSchema,
  entityId: z.string().optional(),
  value: z.string().min(1),
});
const geminiRecommendationSchema = z.object({
  title: z.string().min(1),
  body: z.string().min(1),
  risk: riskSchema,
  action: geminiActionSchema.optional(),
});
const geminiExecutionSchema = z.object({
  answer: z.string().min(1),
  risk: riskSchema.default("LOW"),
  evidence: z.array(geminiEvidenceSchema).default([]),
  recommendations: z.array(geminiRecommendationSchema).default([]),
  resolvedEntityType: z.string().optional(),
  resolvedEntityId: z.string().optional(),
});

const responseJsonSchema = {
  type: "object",
  properties: {
    answer: {
      type: "string",
      description:
        "Concise operational answer based only on the supplied Firestore snapshot.",
    },
    risk: { type: "string", enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"] },
    evidence: {
      type: "array",
      items: {
        type: "object",
        properties: {
          label: { type: "string" },
          entityType: {
            type: "string",
            enum: [
              "customer",
              "provider",
              "job",
              "payment",
              "complaint",
              "wallet",
              "service",
              "system",
            ],
          },
          entityId: { type: "string" },
          value: { type: "string" },
        },
        required: ["label", "entityType", "value"],
      },
    },
    recommendations: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          body: { type: "string" },
          risk: {
            type: "string",
            enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
          },
          action: {
            type: "object",
            properties: {
              type: {
                type: "string",
                enum: [
                  "navigate",
                  "openJob",
                  "openProvider",
                  "refundJob",
                  "adjustWallet",
                  "createComplaint",
                  "assignProvider",
                  "changeJobStatus",
                  "setProviderDecision",
                  "createPromo",
                  "createNotification",
                ],
              },
              label: { type: "string" },
              risk: {
                type: "string",
                enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
              },
              requiresConfirmation: { type: "boolean" },
              payload: {
                type: "object",
                additionalProperties: {
                  anyOf: [
                    { type: "string" },
                    { type: "number" },
                    { type: "boolean" },
                    { type: "null" },
                  ],
                },
              },
            },
            required: ["type", "label", "risk", "requiresConfirmation"],
          },
        },
        required: ["title", "body", "risk"],
      },
    },
    resolvedEntityType: { type: "string" },
    resolvedEntityId: { type: "string" },
  },
  required: ["answer", "risk", "evidence", "recommendations"],
} as const;

const id = (prefix: string) =>
  `${prefix}-${Date.now().toString(36)}-${Math.random().toString(16).slice(2, 7)}`;
const clip = (value: unknown, max = 500) =>
  String(value ?? "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, max);

const sensitiveActions = new Set<AiActionRequest["type"]>([
  "refundJob",
  "adjustWallet",
  "createComplaint",
  "assignProvider",
  "changeJobStatus",
  "setProviderDecision",
  "createPromo",
  "createNotification",
]);

const requiredPayload: Partial<Record<AiActionRequest["type"], string[]>> = {
  openJob: ["jobId"],
  openProvider: ["providerId"],
  refundJob: ["jobId"],
  adjustWallet: ["customerId", "amount"],
  assignProvider: ["jobId", "providerId"],
  changeJobStatus: ["jobId", "status"],
  setProviderDecision: ["providerId", "decision"],
};

function geminiModel(configModel?: string) {
  return configModel || process.env.GEMINI_MODEL?.trim() || "gemini-3.5-flash";
}

function openAiModel(configModel?: string) {
  return configModel || process.env.OPENAI_MODEL?.trim() || "gpt-4.1-mini";
}

function compactState(state: DatabaseState) {
  const metrics = marketplaceMetrics(state);
  const activeJobs = state.jobs.filter(
    (job) => !["Completed", "Cancelled", "Refunded"].includes(job.status),
  );
  const delayedJobs = activeJobs.filter((job) => job.status === "Delayed");
  const openComplaints = state.complaints.filter(
    (complaint) => complaint.status !== "Closed",
  );
  const paidTransactions = state.transactions.filter(
    (transaction) => transaction.status === "Completed",
  );
  const providerRatings = state.providers
    .filter((provider) => provider.rating > 0)
    .map((provider) => provider.rating);
  const averageProviderRating = providerRatings.length
    ? providerRatings.reduce((sum, rating) => sum + rating, 0) /
      providerRatings.length
    : 0;

  return {
    generatedAt: new Date().toISOString(),
    metrics: {
      bookings: metrics.bookings,
      activeJobs: metrics.active,
      delayedJobs: delayedJobs.length,
      cancelledJobs: metrics.cancelled,
      cancellationRate: Number((metrics.cancellationRate * 100).toFixed(1)),
      revenue: metrics.revenue,
      emergencyJobs: metrics.emergency,
      unassignedJobs: metrics.unassigned,
      onlineProviders: metrics.onlineProviders,
      averageResponseMinutes: Number(metrics.avgResponseMinutes.toFixed(1)),
      averageProviderRating: Number(averageProviderRating.toFixed(2)),
      openComplaints: openComplaints.length,
    },
    jobs: state.jobs
      .slice()
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .slice(0, 30)
      .map((job) => ({
        id: job.id,
        customerId: job.customerId,
        customer: job.customer,
        providerId: job.providerId,
        service: job.service,
        area: job.area,
        city: job.city,
        status: job.status,
        priority: job.priority,
        amount: job.amount,
        paymentStatus: job.paymentStatus,
        paymentMethod: job.paymentMethod,
        offerCount: job.offers?.length ?? 0,
        mediaCount: job.media?.length ?? 0,
        chatMessages: job.messages?.length ?? 0,
        calls: job.calls?.length ?? 0,
        cancellation: job.cancellation
          ? {
              cancelledBy: job.cancellation.cancelledBy,
              stage: job.cancellation.stage,
              reason: job.cancellation.reason,
              refundStatus: job.cancellation.refundStatus,
              followUpStatus: job.cancellation.followUpStatus,
            }
          : null,
        createdAt: job.createdAt,
        scheduled: job.scheduled,
      })),
    providers: state.providers
      .slice()
      .sort((a, b) => a.status.localeCompare(b.status) || b.rating - a.rating)
      .slice(0, 40)
      .map((provider) => ({
        id: provider.id,
        providerId: provider.providerId,
        name: provider.name,
        phone: provider.phone,
        email: provider.email,
        trade: provider.trade,
        rating: provider.rating,
        acceptanceRate: provider.acceptanceRate,
        jobs: provider.jobs,
        earnings: provider.earnings,
        status: provider.status,
        verified: provider.verified,
        available: provider.available,
        areas: provider.areas,
        cities: provider.cities,
        documentStatuses: provider.documents?.map((document) => ({
          type: document.type,
          status: document.status,
          expiryDate: document.expiryDate ?? null,
        })),
        openComplaints: state.complaints.filter(
          (complaint) =>
            complaint.providerId === provider.id && complaint.status !== "Closed",
        ).length,
      })),
    customers: state.customers
      .slice()
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .slice(0, 30)
      .map((customer) => ({
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        status: customer.status,
        walletBalance: customer.walletBalance,
        bookings: customer.bookings,
        totalSpend: customer.totalSpend,
        rating: customer.rating,
        risk: customer.risk,
        complaints: state.complaints.filter(
          (complaint) => complaint.customerId === customer.id,
        ).length,
      })),
    payments: {
      totals: {
        transactions: state.transactions.length,
        completedAmount: paidTransactions.reduce(
          (sum, transaction) => sum + Number(transaction.amount ?? 0),
          0,
        ),
        pendingPayouts: state.payouts.filter((payout) => payout.status === "Pending")
          .length,
        instapayPending: state.instapayReviews.filter(
          (review) => review.status === "Pending",
        ).length,
      },
      recentTransactions: state.transactions
        .slice()
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
        .slice(0, 30)
        .map((transaction) => ({
          id: transaction.id,
          type: transaction.type,
          party: transaction.party,
          ownerId: transaction.ownerId,
          amount: transaction.amount,
          status: transaction.status,
          method: transaction.method,
          reference: transaction.reference,
          jobId: transaction.jobId,
          createdAt: transaction.createdAt,
        })),
    },
    complaints: openComplaints.slice(0, 30).map((complaint) => ({
      id: complaint.id,
      title: complaint.title,
      severity: complaint.severity,
      status: complaint.status,
      customerId: complaint.customerId,
      providerId: complaint.providerId,
      jobId: complaint.jobId,
      ownerId: complaint.ownerId,
      createdAt: complaint.createdAt,
      description: clip(complaint.description, 240),
    })),
    ratings: {
      providerAverage: Number(averageProviderRating.toFixed(2)),
      providerLowRated: state.providers
        .filter((provider) => provider.rating < 4.2)
        .map((provider) => ({
          id: provider.id,
          providerId: provider.providerId,
          name: provider.name,
          rating: provider.rating,
        }))
        .slice(0, 10),
      customerAverage: state.customers.length
        ? Number(
            (
              state.customers.reduce((sum, customer) => sum + customer.rating, 0) /
              state.customers.length
            ).toFixed(2),
          )
        : 0,
    },
    liveLocations: state.locations.slice(0, 50).map((location) => ({
      providerId: location.providerId,
      status: location.status,
      updatedAt: location.updatedAt,
      lat: location.lat,
      lng: location.lng,
    })),
    conversations: {
      count: state.conversations.length,
      recent: state.conversations
        .slice()
        .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
        .slice(0, 12)
        .map((conversation) => ({
          id: conversation.id,
          subject: conversation.subject,
          priority: conversation.priority,
          status: conversation.status,
          customerId: conversation.customerId,
          providerId: conversation.providerId,
          messages: conversation.messages?.length ?? 0,
          updatedAt: conversation.updatedAt,
        })),
    },
  };
}

function safeComputedSignals(state: DatabaseState, prompt: string) {
  const intent = detectIntent(prompt);
  const targetJob =
    intent === "dispatch" || intent === "cancellation" || intent === "customerRecovery"
      ? findBestJob(state, prompt) ??
        state.jobs.find((job) => job.cancellation || !job.providerId)
      : undefined;
  return {
    intent,
    marketplace: marketplaceMetrics(state),
    dispatch: dispatchRecommendation(state, targetJob),
    cancellation: targetJob?.cancellation ? analyzeCancellation(targetJob) : null,
    fraud: fraudSignals(state),
    candidateActions: [
      ...dispatchRecommendation(state, targetJob).recommendations,
      ...(targetJob?.cancellation ? analyzeCancellation(targetJob).recommendations : []),
      ...fraudSignals(state).recommendations,
    ].slice(0, 8),
  };
}

function extractText(value: unknown): string {
  if (!value || typeof value !== "object") return "";
  const record = value as Record<string, unknown>;
  if (typeof record.output_text === "string") return record.output_text;
  if (typeof record.outputText === "string") return record.outputText;
  if (typeof record.text === "string") return record.text;
  const parts: string[] = [];
  const visit = (item: unknown, depth = 0) => {
    if (depth > 6 || !item) return;
    if (typeof item === "string") return;
    if (Array.isArray(item)) {
      item.forEach((child) => visit(child, depth + 1));
      return;
    }
    if (typeof item !== "object") return;
    const object = item as Record<string, unknown>;
    if (typeof object.text === "string") parts.push(object.text);
    for (const [key, child] of Object.entries(object)) {
      if (key !== "thought" && key !== "metadata") visit(child, depth + 1);
    }
  };
  visit(value);
  return parts.join("\n").trim();
}

function parseJson(text: string) {
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?/i, "")
    .replace(/```$/i, "")
    .trim();
  return JSON.parse(cleaned);
}

function needsRequiredPayload(action: AiActionRequest) {
  const required = requiredPayload[action.type] ?? [];
  return required.every((key) => action.payload[key] !== undefined && action.payload[key] !== "");
}

function sanitizeAction(action?: z.infer<typeof geminiActionSchema>): AiActionRequest | undefined {
  if (!action) return undefined;
  const next: AiActionRequest = {
    type: action.type,
    label: clip(action.label, 80) || action.type,
    risk: action.risk,
    requiresConfirmation: sensitiveActions.has(action.type)
      ? true
      : action.requiresConfirmation,
    payload: Object.fromEntries(
      Object.entries(action.payload ?? {}).filter(([, value]) => value !== undefined),
    ) as AiActionRequest["payload"],
  };
  if (!needsRequiredPayload(next)) return undefined;
  return next;
}

function sanitizeEvidence(input: z.infer<typeof geminiEvidenceSchema>[]): AiEvidence[] {
  return input.slice(0, 10).map((item) => ({
    id: id("EV"),
    label: clip(item.label, 90),
    entityType: item.entityType,
    entityId: item.entityId ? clip(item.entityId, 120) : undefined,
    value: clip(item.value, 260),
  }));
}

function sanitizeRecommendations(
  input: z.infer<typeof geminiRecommendationSchema>[],
): AiRecommendation[] {
  return input.slice(0, 8).map((item) => ({
    id: id("REC"),
    title: clip(item.title, 100),
    body: clip(item.body, 360),
    risk: item.risk,
    action: sanitizeAction(item.action),
  }));
}

export async function runGeminiAiExecution(
  context: AiRuntimeContext,
  prompt: string,
): Promise<Partial<AiExecution> & { geminiInteractionId?: string }> {
  if (context.actor.isDemoUser) {
    const intent = detectIntent(prompt);
    const plan = planForIntent(intent);
    return {
      prompt,
      normalizedPrompt: prompt.trim().toLowerCase(),
      actorId: context.actor.id,
      actorName: context.actor.name,
      actorRole: context.actor.role,
      page: context.page.page,
      status: "Completed",
      risk: "LOW",
      answer:
        "Demo AI response: this simulated analysis uses only isolated demo workspace data and does not call OpenAI or Gemini.",
      plan,
      toolCalls: [
        {
          id: id("TOOL"),
          name: "demoAiProvider",
          status: "executed",
          risk: "LOW" as AiRiskLevel,
          summary: "Returned mock AI response for demo mode without using real API credentials.",
        },
      ],
      evidence: [],
      recommendations: [],
      context: {
        currentEntityType: context.page.currentEntityType,
        currentEntityId: context.page.currentEntityId,
      },
    };
  }
  const providerConfig = await activeAiProvider();
  const provider =
    "record" in providerConfig && providerConfig.record
      ? providerConfig.record.provider
      : "provider" in providerConfig
        ? providerConfig.provider
        : "disabled";
  const key = providerConfig.credentials.apiKey?.trim();
  if (provider === "disabled") throw new Error("AI is disabled.");
  if (!key) throw new Error("AI is not configured.");
  const compact = compactState(context.state);
  const computedSignals = safeComputedSignals(context.state, prompt);
  const model =
    provider === "openai"
      ? openAiModel("record" in providerConfig && providerConfig.record ? providerConfig.record.defaultModel : providerConfig.defaultModel)
      : geminiModel("record" in providerConfig && providerConfig.record ? providerConfig.record.defaultModel : providerConfig.defaultModel);
  const body = {
    model,
    system_instruction: [
      taskExecutiveSystemPrompt,
      "You are connected to live Firebase data supplied by the server.",
      "Do not invent records, IDs, phone numbers, amounts, or facts that are not in the snapshot.",
      "Analyze jobs, providers, customers, payments, complaints, conversations, ratings, and live locations.",
      "Detect suspicious activity and operational risk patterns with clear explanations.",
      "Suggest actions only when the supplied data supports them.",
      "Normal admins must never silently execute changes. Every state-changing action must set requiresConfirmation=true.",
      "Return only valid JSON matching the requested schema. No markdown.",
    ].join("\n"),
    input: JSON.stringify({
      admin: {
        id: context.actor.id,
        name: context.actor.name,
        role: context.actor.role,
        permissions: context.actor.permissions ?? [],
      },
      page: context.page,
      prompt,
      firestoreSnapshot: compact,
      computedSignals,
      allowedActions: [
        "navigate",
        "openJob",
        "openProvider",
        "refundJob",
        "adjustWallet",
        "createComplaint",
        "assignProvider",
        "changeJobStatus",
        "setProviderDecision",
        "createPromo",
        "createNotification",
      ],
      outputRules: {
        evidenceLimit: 10,
        recommendationLimit: 8,
        actionPayloads:
          "Use only IDs present in firestoreSnapshot. If unsure, omit the action.",
      },
    }),
    generation_config: {
      temperature: 0.2,
      thinking_level: "low",
    },
    response_format: {
      type: "text",
      mime_type: "application/json",
      schema: responseJsonSchema,
    },
  };

  const response =
    provider === "openai"
      ? await fetch("https://api.openai.com/v1/chat/completions", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: `Bearer ${key}`,
          },
          body: JSON.stringify({
            model,
            response_format: { type: "json_object" },
            messages: [
              { role: "system", content: body.system_instruction },
              { role: "user", content: body.input },
            ],
            temperature: 0.2,
          }),
        })
      : await fetch("https://generativelanguage.googleapis.com/v1beta/interactions", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-goog-api-key": key,
          },
          body: JSON.stringify(body),
        });
  const raw = (await response.json().catch(() => ({}))) as Record<string, unknown>;
  if (!response.ok) {
    const message =
      (raw.error as { message?: string } | undefined)?.message ??
      `${provider} API request failed with HTTP ${response.status}`;
    throw new Error(message);
  }

  const text =
    provider === "openai"
      ? String(
          (((raw.choices as Array<{ message?: { content?: string } }> | undefined)?.[0]?.message?.content) ?? ""),
        )
      : extractText(raw);
  if (!text) throw new Error(`${provider} returned an empty response.`);
  const parsed = geminiExecutionSchema.parse(parseJson(text));
  const recommendations = sanitizeRecommendations(parsed.recommendations);
  const evidence = sanitizeEvidence(parsed.evidence);
  const risk = highestRisk([
    ...recommendations,
    { id: "model-risk", title: "Model risk", body: "", risk: parsed.risk },
  ]);
  const intent = detectIntent(prompt);
  const plan = planForIntent(intent);

  return {
    prompt,
    normalizedPrompt: prompt.trim().toLowerCase(),
    actorId: context.actor.id,
    actorName: context.actor.name,
    actorRole: context.actor.role,
    page: context.page.page,
    status: executionStatus(risk),
    risk,
    answer: parsed.answer,
    plan,
    toolCalls: [
      {
        id: id("TOOL"),
        name: "firebaseSnapshot",
        status: "executed",
        risk: "LOW" as AiRiskLevel,
        summary: `Read ${context.state.jobs.length} jobs, ${context.state.providers.length} providers, ${context.state.customers.length} customers, ${context.state.transactions.length} transactions, and ${context.state.complaints.length} complaints from Firestore.`,
      },
      {
        id: id("TOOL"),
        name: "riskPatternScan",
        status: "executed",
        risk: "MEDIUM" as AiRiskLevel,
        summary: `Computed marketplace metrics, cancellation signals, dispatch eligibility, provider ratings, and payment/refund exposure before sending the compact snapshot to Gemini.`,
      },
      {
        id: id("TOOL"),
        name: `${provider}Analysis`,
        status: "executed",
        risk,
        summary: `${provider === "openai" ? "OpenAI" : "Gemini"} model ${model} generated the operational analysis server-side.`,
      },
    ],
    evidence,
    recommendations,
    context: {
      currentEntityType: context.page.currentEntityType,
      currentEntityId: context.page.currentEntityId,
      resolvedEntityType: parsed.resolvedEntityType,
      resolvedEntityId: parsed.resolvedEntityId,
    },
    geminiInteractionId:
      typeof raw.id === "string"
        ? raw.id
        : typeof raw.name === "string"
          ? raw.name
          : undefined,
  };
}
