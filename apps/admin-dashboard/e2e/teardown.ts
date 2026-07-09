/**
 * Deletes the exact temp records seed.ts created (belt-and-suspenders -
 * stopping the emulator process already wipes all emulator data, since it's
 * in-memory only and never persisted or connected to production).
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { readFileSync } from "node:fs";

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error("Refusing to run teardown outside the emulator suite.");
  }
  const manifest = JSON.parse(readFileSync(new URL("./.manifest.json", import.meta.url), "utf8"));
  const app = initializeApp({ projectId: "demo-task" });
  const auth = getAuth(app);
  const db = getFirestore(app);

  await db.collection("jobs").doc(manifest.jobId).collection("complaints").doc(manifest.complaintId).delete();
  await db.collection("jobs").doc(manifest.jobId).delete();
  await db.collection("users").doc(manifest.customerUid).delete();
  await db.collection("users").doc(manifest.adminUid).delete();
  await db.collection("admins").doc(manifest.adminUid).delete();
  await auth.deleteUser(manifest.adminUid);
  await auth.deleteUser(manifest.customerUid);
  console.log("TEARDOWN_OK");
}

main().catch((error) => {
  console.error("TEARDOWN_FAILED", error);
  process.exit(1);
});
