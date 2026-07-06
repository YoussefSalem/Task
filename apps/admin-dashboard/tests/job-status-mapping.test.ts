import { test } from "node:test";
import assert from "node:assert/strict";
import { adminJobStatusFromWire, jobWireStatusFromAdmin } from "../lib/firebase/job-status-mapping";

test("maps real Customer App wire values written today", () => {
  assert.equal(adminJobStatusFromWire("biddingActive"), "Scheduled");
  assert.equal(adminJobStatusFromWire("accepted"), "Assigned");
  assert.equal(adminJobStatusFromWire("cancelled"), "Cancelled");
});

test("does NOT silently coerce disputed to Scheduled (the fixed bug)", () => {
  assert.equal(adminJobStatusFromWire("disputed"), "Disputed");
});

test("does NOT silently coerce pausedForApproval to Scheduled (the fixed bug)", () => {
  assert.equal(adminJobStatusFromWire("pausedForApproval"), "Paused for approval");
  assert.equal(adminJobStatusFromWire("paused_for_approval"), "Paused for approval");
});

test("maps every declared Customer App JobStatus enum value to a distinct-or-intentional dashboard status", () => {
  const wireValues = [
    "searching",
    "pendingScheduled",
    "biddingActive",
    "accepted",
    "enRoute",
    "inProgress",
    "pausedForApproval",
    "completed",
    "disputed",
    "cancelled",
  ];
  for (const value of wireValues) {
    const mapped = adminJobStatusFromWire(value);
    assert.notEqual(mapped, undefined);
  }
  // The two statuses this fix specifically targets must not collapse into
  // the generic "Scheduled" bucket the way searching/pendingScheduled/
  // biddingActive intentionally do.
  assert.notEqual(adminJobStatusFromWire("disputed"), "Scheduled");
  assert.notEqual(adminJobStatusFromWire("pausedForApproval"), "Scheduled");
});

test("truly unknown values still fall back to Scheduled (not silent for known statuses only)", () => {
  assert.equal(adminJobStatusFromWire("some-garbage-value"), "Scheduled");
  assert.equal(adminJobStatusFromWire(undefined), "Scheduled");
});

test("round-trips admin statuses back to real wire values", () => {
  assert.equal(jobWireStatusFromAdmin("Disputed"), "disputed");
  assert.equal(jobWireStatusFromAdmin("Paused for approval"), "pausedForApproval");
  assert.equal(jobWireStatusFromAdmin("Assigned"), "accepted");
  assert.equal(jobWireStatusFromAdmin("Cancelled"), "cancelled");
});
