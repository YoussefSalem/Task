/**
 * Seeds temporary E2E smoke-test data into the Firebase emulator suite
 * (never production - FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST
 * must be set before this runs, which makes the Admin SDK auto-connect to
 * the emulator without needing any real service-account credentials).
 *
 * Writes a JSON manifest to e2e/.manifest.json so the Playwright spec and
 * teardown script can reuse the exact ids/credentials created here.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { writeFileSync } from "node:fs";

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error(
      "Refusing to seed: FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST are not set. " +
        "This script must only ever run against the local emulator suite.",
    );
  }

  const app = initializeApp({ projectId: "demo-task" });
  const auth = getAuth(app);
  const db = getFirestore(app);

  const stamp = Date.now().toString(36);
  const adminEmail = `e2e-admin-${stamp}@example.test`;
  const customerEmail = `e2e-customer-${stamp}@example.test`;
  const password = "E2eSmokeTest!12345";

  const adminUser = await auth.createUser({ email: adminEmail, password, displayName: "E2E Smoke Admin" });
  // Pre-create the admins/{uid} profile doc directly (Admin SDK bypasses
  // Firestore rules) rather than relying on the session route's first-login
  // bootstrap path, so this account is unambiguously a real (non-demo) actor
  // with role "Super Admin" - lib/permissions.ts's isSuperAdminRole() then
  // bypasses the permission tree entirely, exactly like a genuine super
  // admin account, without needing an ADMIN_ALLOWED_EMAILS/roles-collection
  // setup that only matters for production bootstrapping.
  await db.collection("admins").doc(adminUser.uid).set({
    id: adminUser.uid,
    uid: adminUser.uid,
    email: adminEmail,
    name: "E2E Smoke Admin",
    role: "Super Admin",
    roleId: "super_admin",
    permissions: [],
    status: "Active",
    enabled: true,
    authDisabled: false,
    isDemoUser: false,
    lastSeen: "Never",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  // The Firestore rules' isAdmin() checks the REAL users/{uid}.role field
  // (backend/firestore.rules), which is a different concept from the
  // dashboard-native admins/{uid} doc above - both are required for a
  // dashboard "Super Admin" to actually pass the deployed complaints rule's
  // admin-only collectionGroup read.
  await db.collection("users").doc(adminUser.uid).set({
    role: "admin",
    name: "E2E Smoke Admin",
    email: adminEmail,
  });

  const customerUser = await auth.createUser({ email: customerEmail, password, displayName: "E2E Smoke Customer" });
  await db.collection("users").doc(customerUser.uid).set({
    role: "customer",
    name: "E2E Smoke Customer",
    email: customerEmail,
  });

  const jobId = `e2e-job-${stamp}`;
  await db.collection("jobs").doc(jobId).set({
    customer_id: customerUser.uid,
    status: "completed",
    category: "plumbing",
    created_at: new Date().toISOString(),
  });

  const complaintId = `e2e-complaint-${stamp}`;
  // Field shape must match packages/task_data/lib/src/complaints/firestore_complaint_repository.dart
  // exactly, since this is standing in for "customer creates a complaint" per
  // the smoke test's step 5 (direct-to-repository-shape write, done via the
  // Admin SDK rather than a live Customer App build for this automated run).
  await db
    .collection("jobs")
    .doc(jobId)
    .collection("complaints")
    .doc(complaintId)
    .set({
      job_id: jobId,
      raised_by: "customer",
      reporter_id: customerUser.uid,
      subject_id: null,
      category: "no_show",
      description: "E2E smoke test: technician never arrived.",
      status: "open",
      evidence: [],
      created_at: new Date().toISOString(),
    });

  const manifest = {
    adminEmail,
    adminUid: adminUser.uid,
    customerEmail,
    customerUid: customerUser.uid,
    password,
    jobId,
    complaintId,
  };
  writeFileSync(new URL("./.manifest.json", import.meta.url), JSON.stringify(manifest, null, 2));
  console.log("SEED_OK", JSON.stringify(manifest));
}

main().catch((error) => {
  console.error("SEED_FAILED", error);
  process.exit(1);
});
