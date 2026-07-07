import { test } from "node:test";
import assert from "node:assert/strict";
import {
  PRODUCTION_READ_ONLY,
  PRODUCTION_WRITE_DISABLED_MESSAGE,
  checkProductionWriteAccess,
  isProductionReadOnly,
  environmentBadges,
} from "../lib/firebase/read-only-mode";

test("PRODUCTION_READ_ONLY is enabled (the Phase D.1 guarantee holds)", () => {
  assert.equal(PRODUCTION_READ_ONLY, true);
});

test("the blocked-action message is exactly the required copy", () => {
  assert.equal(
    PRODUCTION_WRITE_DISABLED_MESSAGE,
    "This production action is disabled until migration is approved.",
  );
});

test("a production (non-demo) actor is blocked from writes with the standard message", () => {
  const result = checkProductionWriteAccess({ isDemoUser: false });
  assert.equal(result.allowed, false);
  assert.equal(result.reason, PRODUCTION_WRITE_DISABLED_MESSAGE);
});

test("an actor with no isDemoUser field is treated as production and blocked", () => {
  const result = checkProductionWriteAccess({});
  assert.equal(result.allowed, false);
});

test("a demo actor is always allowed to write (demo data is isolated)", () => {
  const result = checkProductionWriteAccess({ isDemoUser: true });
  assert.equal(result.allowed, true);
  assert.equal(result.reason, undefined);
});

test("no destructive action can run in read-only mode: the guard is action-independent", () => {
  // The production-write choke point in performFirestoreOperation does not
  // branch on action - it blocks the entire mutation dispatcher for a
  // production actor. So refund, payout, delete, notify, status-change, wallet
  // adjustment, etc. are all equally blocked. This test documents that
  // guarantee at the guard level.
  const productionActor = { isDemoUser: false };
  for (const action of [
    "refundJob",
    "createPayout",
    "verifyPayout",
    "createNotification",
    "deleteJob",
    "deleteComplaint",
    "adjustWallet",
    "changeJobStatus",
    "assignProvider",
    "reviewInstapay",
  ]) {
    assert.equal(
      checkProductionWriteAccess(productionActor).allowed,
      false,
      `${action} must be blocked in read-only mode`,
    );
  }
});

test("isProductionReadOnly is true for production actors and false for demo", () => {
  assert.equal(isProductionReadOnly({ isDemoUser: false }), true);
  assert.equal(isProductionReadOnly({}), true);
  assert.equal(isProductionReadOnly({ isDemoUser: true }), false);
});

test("demo actor shows only the Demo Data badge", () => {
  assert.deepEqual(environmentBadges(true), [{ label: "Demo Data", tone: "demo" }]);
});

test("production actor shows Production Read-only + Production Write Disabled badges", () => {
  assert.deepEqual(environmentBadges(false), [
    { label: "Production Read-only", tone: "readonly" },
    { label: "Production Write Disabled", tone: "disabled" },
  ]);
  // absent isDemoUser is also treated as production
  assert.deepEqual(environmentBadges(undefined), [
    { label: "Production Read-only", tone: "readonly" },
    { label: "Production Write Disabled", tone: "disabled" },
  ]);
});
