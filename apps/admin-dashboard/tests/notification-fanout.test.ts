import { test } from "node:test";
import assert from "node:assert/strict";
import {
  resolveNotificationFanout,
  buildRealNotificationDoc,
  BroadcastFanoutNotImplementedError,
  MAX_BOUNDED_FANOUT_RECIPIENTS,
} from "../lib/firebase/notification-fanout";

test("Individual audience with a targetUserId fans out to exactly that user", () => {
  const plan = resolveNotificationFanout("Individual", "tech-123");
  assert.deepEqual(plan.targetUserIds, ["tech-123"]);
});

test("bounded targetUserIds fan out even for a broadcast-labeled audience (admin-selected set)", () => {
  const plan = resolveNotificationFanout("All providers", undefined, ["p1", "p2", "p3"]);
  assert.deepEqual(plan.targetUserIds.sort(), ["p1", "p2", "p3"]);
});

test("deduplicates targetUserId and targetUserIds overlap", () => {
  const plan = resolveNotificationFanout("Individual", "p1", ["p1", "p2"]);
  assert.deepEqual(plan.targetUserIds.sort(), ["p1", "p2"]);
});

test("throws BroadcastFanoutNotImplementedError when no recipients are given at all (the fixed bug: dashboard notifications never reached real users)", () => {
  assert.throws(
    () => resolveNotificationFanout("All customers"),
    BroadcastFanoutNotImplementedError,
  );
  assert.throws(() => resolveNotificationFanout("Segment"));
  assert.throws(() => resolveNotificationFanout("Individual"));
});

test("refuses to fan out beyond the safety cap even with bounded ids", () => {
  const tooMany = Array.from({ length: MAX_BOUNDED_FANOUT_RECIPIENTS + 1 }, (_, i) => `u${i}`);
  assert.throws(() => resolveNotificationFanout("All customers", undefined, tooMany));
});

test("builds a real Customer App notification doc shape", () => {
  const doc = buildRealNotificationDoc("Title", "Body", "TIMESTAMP");
  assert.equal(doc.type, "job_status");
  assert.equal(doc.title, "Title");
  assert.equal(doc.body, "Body");
  assert.equal(doc.read, false);
  assert.equal(doc.created_at, "TIMESTAMP");
});
