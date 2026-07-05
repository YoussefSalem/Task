import { firebaseAdminDb } from "../lib/firebase/admin";

const environmentCollections = [
  "categories",
  "services",
  "banners",
  "customers",
  "providers",
  "providerLocations",
  "providerDocuments",
  "wallets",
  "orders",
  "quotations",
  "quotes",
  "offers",
  "payments",
  "transactions",
  "payouts",
  "complaints",
  "conversations",
  "promos",
  "notifications",
  "instapayReviews",
  "reviews",
  "ratings",
  "aiReports",
  "reports",
  "aiExecutions",
  "aiMemories",
  "analytics",
  "analyticsEvents",
  "metrics",
  "auditLogs",
] as const;

type Environment = "production" | "demo";

function inferEnvironment(data: FirebaseFirestore.DocumentData): Environment {
  if (data.environment === "demo" || data.isDemoData === true) return "demo";
  if (
    typeof data.action === "string" &&
    (data.action.startsWith("demo.") || data.action.includes(".demo"))
  )
    return "demo";
  return "production";
}

function shouldUpdate(
  data: FirebaseFirestore.DocumentData,
  environment: Environment,
) {
  return data.environment !== environment || data.isDemoData !== (environment === "demo");
}

async function commitChunk(
  writes: Array<(batch: FirebaseFirestore.WriteBatch) => void>,
) {
  for (let index = 0; index < writes.length; index += 450) {
    const batch = firebaseAdminDb.batch();
    writes.slice(index, index + 450).forEach((write) => write(batch));
    await batch.commit();
  }
}

async function migrate() {
  let scanned = 0;
  let updated = 0;

  for (const collectionName of environmentCollections) {
    const snapshot = await firebaseAdminDb.collection(collectionName).get();
    scanned += snapshot.size;

    const writes: Array<(batch: FirebaseFirestore.WriteBatch) => void> = [];
    snapshot.docs.forEach((item) => {
      const data = item.data();
      const environment = inferEnvironment(data);
      if (!shouldUpdate(data, environment)) return;
      updated += 1;
      writes.push((batch) =>
        batch.set(
          item.ref,
          {
            environment,
            isDemoData: environment === "demo",
          },
          { merge: true },
        ),
      );
    });

    await commitChunk(writes);
    console.log(
      `${collectionName}: scanned ${snapshot.size}, updated ${writes.length}`,
    );
  }

  console.log(
    `Environment migration complete. Scanned ${scanned} document(s), updated ${updated}.`,
  );
}

migrate().catch((error) => {
  console.error("Environment migration failed:", error);
  process.exitCode = 1;
});
