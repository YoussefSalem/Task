import { z } from "zod";
import { firebaseAdminDb, firebaseAdminStorage } from "@/lib/firebase/admin";
import {
  firebaseApiError,
  requireFirebaseAdmin,
} from "@/lib/firebase/server-auth";
import { requestId, serverLog } from "@/lib/server/logger";
import { checkSystemResetAccess } from "@/lib/firebase/system-reset-guard";

export const runtime = "nodejs";

const RESET_PHRASE = "RESET TASK";
const PRODUCTION_ENVIRONMENT = "production";

const resetModules = {
  customers: {
    label: "Customers",
    collections: ["customers"],
    linkedCollectionsById: [
      "customerProfiles",
      "customerPrivate",
      "customerSettings",
      "customerDevices",
    ],
  },
  providers: {
    label: "Providers",
    collections: ["providers", "providerLocations", "providerDocuments"],
    linkedCollectionsById: [
      "providerProfiles",
      "providerPrivate",
      "providerSettings",
      "providerDevices",
      "providerAvailability",
    ],
  },
  jobs: {
    label: "Jobs",
    collections: ["orders"],
  },
  quotations: {
    label: "Quotations",
    collections: ["quotations", "quotes", "offers"],
  },
  payments: {
    label: "Payments",
    collections: ["payments", "payouts", "instapayReviews"],
  },
  walletTransactions: {
    label: "Wallet Transactions",
    collections: ["transactions", "wallets"],
  },
  reviews: {
    label: "Reviews",
    collections: ["reviews", "ratings"],
  },
  notifications: {
    label: "Notifications",
    collections: ["notifications"],
  },
  reports: {
    label: "Reports",
    collections: ["aiReports", "aiExecutions", "aiMemories", "reports"],
  },
  analytics: {
    label: "Analytics",
    collections: ["analytics", "analyticsEvents", "metrics"],
  },
  uploadedFiles: {
    label: "Uploaded files",
    collections: [],
  },
} as const;

type ResetModule = keyof typeof resetModules;
type ResetCounts = Record<
  ResetModule,
  { label: string; count: number; collections: Record<string, number> }
>;

const moduleSchema = z.enum(
  Object.keys(resetModules) as [ResetModule, ...ResetModule[]],
);

const schema = z.discriminatedUnion("action", [
  z.object({ action: z.literal("counts") }),
  z.object({
    action: z.literal("reset-module"),
    module: moduleSchema,
    confirmation: z.literal(RESET_PHRASE),
    secondConfirmation: z.literal(true),
  }),
]);

/**
 * This route ALWAYS targets `environment == "production"` data (see
 * getProductionDocs/countProductionCollection below) - there is no demo-mode
 * variant of system-reset. Demo data has its own reset path: POST
 * /api/firebase/demo/reset. See lib/firebase/system-reset-guard.ts for the
 * actual (unit-tested) access decision - a demo actor is refused here
 * regardless of role/roleId/permissions.
 */
function requireSystemResetActor(actor: unknown) {
  const check = checkSystemResetAccess(
    (actor ?? {}) as Parameters<typeof checkSystemResetAccess>[0],
  );
  if (!check.allowed) {
    throw new Response(check.reason, {
      status: 403,
      statusText: check.reason,
    });
  }
}

async function getProductionDocs(collectionName: string) {
  const snapshot = await firebaseAdminDb
    .collection(collectionName)
    .where("environment", "==", PRODUCTION_ENVIRONMENT)
    .get();
  return snapshot.docs;
}

async function countProductionCollection(collectionName: string) {
  const snapshot = await firebaseAdminDb
    .collection(collectionName)
    .where("environment", "==", PRODUCTION_ENVIRONMENT)
    .count()
    .get();
  return snapshot.data().count;
}

function collectStoragePaths(value: unknown, output: Set<string>) {
  if (!value) return;
  if (Array.isArray(value)) {
    value.forEach((item) => collectStoragePaths(item, output));
    return;
  }
  if (typeof value !== "object") return;
  for (const [key, item] of Object.entries(value as Record<string, unknown>)) {
    if (
      ["storagePath", "storageKey", "path"].includes(key) &&
      typeof item === "string" &&
      item &&
      !item.startsWith("http")
    ) {
      output.add(item);
    } else {
      collectStoragePaths(item, output);
    }
  }
}

async function collectProductionStoragePaths() {
  const paths = new Set<string>();
  await Promise.all(
    Object.values(resetModules)
      .flatMap((module) => module.collections)
      .filter(Boolean)
      .map(async (collectionName) => {
        const docs = await getProductionDocs(collectionName);
        docs.forEach((doc) => collectStoragePaths(doc.data(), paths));
      }),
  );
  return paths;
}

async function countModule(module: ResetModule) {
  if (module === "uploadedFiles") {
    const files = await collectProductionStoragePaths();
    return {
      label: resetModules[module].label,
      count: files.size,
      collections: { storage: files.size },
    };
  }

  const definition = resetModules[module];
  const counts: Record<string, number> = {};
  await Promise.all(
    definition.collections.map(async (collectionName) => {
      counts[collectionName] = await countProductionCollection(collectionName);
    }),
  );
  const count = Object.values(counts).reduce((sum, value) => sum + value, 0);
  return { label: definition.label, count, collections: counts };
}

async function countAllModules() {
  const entries = await Promise.all(
    (Object.keys(resetModules) as ResetModule[]).map(async (module) => [
      module,
      await countModule(module),
    ]),
  );
  return Object.fromEntries(entries) as ResetCounts;
}

async function deleteDocuments(
  docs: FirebaseFirestore.QueryDocumentSnapshot[],
) {
  if (!docs.length) return 0;
  const writer = firebaseAdminDb.bulkWriter();
  docs.forEach((doc) => writer.delete(doc.ref));
  await writer.close();
  return docs.length;
}

async function deleteLinkedDocumentsById(
  ids: string[],
  collectionNames: readonly string[] = [],
) {
  if (!ids.length || !collectionNames.length) return 0;
  const writer = firebaseAdminDb.bulkWriter();
  let count = 0;
  collectionNames.forEach((collectionName) => {
    ids.forEach((id) => {
      writer.delete(firebaseAdminDb.collection(collectionName).doc(id));
      count += 1;
    });
  });
  await writer.close();
  return count;
}

async function resetModule(module: ResetModule) {
  if (module === "uploadedFiles") {
    const paths = await collectProductionStoragePaths();
    const bucket = firebaseAdminStorage.bucket();
    let deleted = 0;
    const errors: string[] = [];
    for (const path of paths) {
      try {
        await bucket.file(path).delete({ ignoreNotFound: true });
        deleted += 1;
      } catch (error) {
        errors.push(
          `${path}: ${error instanceof Error ? error.message : "delete failed"}`,
        );
      }
    }
    if (errors.length)
      throw new Error(`Some uploaded files could not be deleted: ${errors.join("; ")}`);
    return {
      module,
      label: resetModules[module].label,
      deleted,
      collections: { storage: deleted },
    };
  }

  const definition = resetModules[module];
  const deletedCollections: Record<string, number> = {};
  let deleted = 0;

  for (const collectionName of definition.collections) {
    const docs = await getProductionDocs(collectionName);
    const ids = docs.map((doc) => doc.id);
    const collectionDeleted = await deleteDocuments(docs);
    deletedCollections[collectionName] = collectionDeleted;
    deleted += collectionDeleted;

    if (
      (module === "customers" || module === "providers") &&
      "linkedCollectionsById" in definition
    ) {
      const linkedDeleted = await deleteLinkedDocumentsById(
        ids,
        definition.linkedCollectionsById,
      );
      if (linkedDeleted) {
        deletedCollections[`${collectionName}:linkedProfiles`] =
          (deletedCollections[`${collectionName}:linkedProfiles`] ?? 0) +
          linkedDeleted;
        deleted += linkedDeleted;
      }
    }
  }

  return {
    module,
    label: definition.label,
    deleted,
    collections: deletedCollections,
  };
}

async function writeAudit(input: {
  actor: { id: string; name: string };
  module: ResetModule;
  before: Awaited<ReturnType<typeof countModule>>;
  result: Awaited<ReturnType<typeof resetModule>>;
}) {
  const now = new Date().toISOString();
  await firebaseAdminDb.collection("auditLogs").add({
    actorId: input.actor.id,
    actorName: input.actor.name,
    performedBy: input.actor.id,
    action: "system.reset",
    entityType: "system",
    entityId: input.module,
    detail: `System reset deleted ${input.result.deleted} production record(s) from ${input.result.label}.`,
    deletedCollections: input.result.collections,
    deletedRecordCounts: input.result.deleted,
    before: JSON.stringify(input.before),
    after: JSON.stringify(input.result),
    environment: PRODUCTION_ENVIRONMENT,
    isDemoData: false,
    timestamp: now,
    createdAt: now,
    ipAddress: "Firebase Auth",
    device: "Task Admin API",
  });
}

export async function POST(request: Request) {
  const id = requestId(request);
  try {
    const actor = await requireFirebaseAdmin(request);
    requireSystemResetActor(actor);
    const parsed = schema.parse(await request.json());

    if (parsed.action === "counts") {
      return Response.json({
        modules: await countAllModules(),
        confirmationPhrase: RESET_PHRASE,
      });
    }

    const before = await countModule(parsed.module);
    const result = await resetModule(parsed.module);
    await writeAudit({
      actor: { id: actor.id, name: actor.name },
      module: parsed.module,
      before,
      result,
    });
    serverLog("warn", "Production system reset module executed", {
      requestId: id,
      actorId: actor.id,
      module: parsed.module,
      deleted: result.deleted,
    });
    return Response.json({ ok: true, result });
  } catch (error) {
    return firebaseApiError(error, {
      requestId: id,
      route: "/api/firebase/system-reset",
    });
  }
}
