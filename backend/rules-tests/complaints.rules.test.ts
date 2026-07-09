import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";
import { setDoc, doc, getDoc, getDocs, collectionGroup, query, updateDoc } from "firebase/firestore";

// Verifies backend/firestore.rules' new jobs/{jobId}/complaints rule and the
// admin-only collectionGroup("complaints") rule
// (docs/superpowers/specs/2026-07-09-complaints-firestore-rule.md).
// Run against the Firestore emulator only - never against production.

let testEnv: RulesTestEnvironment;

const CUSTOMER_UID = "customer-1";
const OTHER_CUSTOMER_UID = "customer-2";
const TECHNICIAN_UID = "technician-1";
const OTHER_TECHNICIAN_UID = "technician-2";
const ADMIN_UID = "admin-1";
const JOB_ID = "job-1";

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-task",
    firestore: {
      rules: readFileSync("../firestore.rules", "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users", CUSTOMER_UID), { role: "customer" });
    await setDoc(doc(db, "users", OTHER_CUSTOMER_UID), { role: "customer" });
    await setDoc(doc(db, "users", TECHNICIAN_UID), { role: "technician" });
    await setDoc(doc(db, "users", OTHER_TECHNICIAN_UID), { role: "technician" });
    await setDoc(doc(db, "users", ADMIN_UID), { role: "admin" });
    await setDoc(doc(db, "jobs", JOB_ID), {
      customer_id: CUSTOMER_UID,
      status: "completed",
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

test("customer can create a complaint on their own job as the reporter", async () => {
  const db = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  await assertSucceeds(
    setDoc(doc(db, "jobs", JOB_ID, "complaints", "c1"), {
      job_id: JOB_ID,
      raised_by: "customer",
      reporter_id: CUSTOMER_UID,
      subject_id: TECHNICIAN_UID,
      category: "no_show",
      description: "Never showed up",
      status: "open",
      evidence: [],
      created_at: new Date().toISOString(),
    }),
  );
});

test("a different customer cannot create a complaint claiming to be someone else's reporter", async () => {
  const db = testEnv.authenticatedContext(OTHER_CUSTOMER_UID).firestore();
  await assertFails(
    setDoc(doc(db, "jobs", JOB_ID, "complaints", "c2"), {
      job_id: JOB_ID,
      raised_by: "customer",
      reporter_id: CUSTOMER_UID, // impersonation attempt
      subject_id: TECHNICIAN_UID,
      category: "no_show",
      description: "spoofed",
      status: "open",
      evidence: [],
      created_at: new Date().toISOString(),
    }),
  );
});

test("cannot create a complaint with a non-open status", async () => {
  const db = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  await assertFails(
    setDoc(doc(db, "jobs", JOB_ID, "complaints", "c3"), {
      job_id: JOB_ID,
      raised_by: "customer",
      reporter_id: CUSTOMER_UID,
      subject_id: TECHNICIAN_UID,
      category: "no_show",
      description: "pre-resolved sneak",
      status: "resolved",
      evidence: [],
      created_at: new Date().toISOString(),
    }),
  );
});

test("cannot create a complaint under a mismatched job_id field", async () => {
  const db = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  await assertFails(
    setDoc(doc(db, "jobs", JOB_ID, "complaints", "c4"), {
      job_id: "some-other-job",
      raised_by: "customer",
      reporter_id: CUSTOMER_UID,
      subject_id: TECHNICIAN_UID,
      category: "no_show",
      description: "mismatched job id",
      status: "open",
      evidence: [],
      created_at: new Date().toISOString(),
    }),
  );
});

test("the reporter can read their own complaint", async () => {
  const db = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  await assertSucceeds(getDoc(doc(db, "jobs", JOB_ID, "complaints", "c1")));
});

test("the named subject (technician) can read the complaint against them", async () => {
  const db = testEnv.authenticatedContext(TECHNICIAN_UID).firestore();
  await assertSucceeds(getDoc(doc(db, "jobs", JOB_ID, "complaints", "c1")));
});

test("an unrelated technician cannot read someone else's complaint", async () => {
  const db = testEnv.authenticatedContext(OTHER_TECHNICIAN_UID).firestore();
  await assertFails(getDoc(doc(db, "jobs", JOB_ID, "complaints", "c1")));
});

test("an unrelated customer cannot read someone else's complaint", async () => {
  const db = testEnv.authenticatedContext(OTHER_CUSTOMER_UID).firestore();
  await assertFails(getDoc(doc(db, "jobs", JOB_ID, "complaints", "c1")));
});

test("the reporter cannot update their own complaint (e.g. cannot self-resolve)", async () => {
  const db = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  await assertFails(
    updateDoc(doc(db, "jobs", JOB_ID, "complaints", "c1"), { status: "resolved" }),
  );
});

test("admin can read any complaint directly", async () => {
  const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
  await assertSucceeds(getDoc(doc(db, "jobs", JOB_ID, "complaints", "c1")));
});

test("admin can update a complaint's status", async () => {
  const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
  await assertSucceeds(
    updateDoc(doc(db, "jobs", JOB_ID, "complaints", "c1"), { status: "investigating" }),
  );
});

test("admin collectionGroup('complaints') read works", async () => {
  const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
  const snapshot = await assertSucceeds(getDocs(query(collectionGroup(db, "complaints"))));
  assert.ok(snapshot.size >= 1);
});

test("a non-admin customer's collectionGroup('complaints') read is denied", async () => {
  const db = testEnv.authenticatedContext(CUSTOMER_UID).firestore();
  await assertFails(getDocs(query(collectionGroup(db, "complaints"))));
});

test("a signed-out request cannot read or create complaints", async () => {
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, "jobs", JOB_ID, "complaints", "c1")));
  await assertFails(
    setDoc(doc(db, "jobs", JOB_ID, "complaints", "c5"), {
      job_id: JOB_ID,
      raised_by: "customer",
      reporter_id: "anonymous",
      subject_id: TECHNICIAN_UID,
      category: "no_show",
      description: "anon",
      status: "open",
      evidence: [],
      created_at: new Date().toISOString(),
    }),
  );
});
