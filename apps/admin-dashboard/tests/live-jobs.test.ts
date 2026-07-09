import { test } from "node:test";
import assert from "node:assert/strict";
import { deriveLiveJobsBoard } from "../lib/firebase/live-jobs";
import type { Job } from "../lib/types";

const NOW = "2026-07-09T12:00:00.000Z";

function job(over: Partial<Job>): Job {
  return {
    id: "j1",
    customerId: "c1",
    serviceId: "s1",
    customer: "Cust",
    customerInitials: "C",
    service: "AC",
    provider: "Unassigned",
    area: "",
    address: "",
    scheduled: "",
    amount: 100,
    status: "Scheduled",
    paymentStatus: "Pending",
    paymentMethod: "Card",
    notes: [],
    timeline: [],
    createdAt: NOW,
    ...over,
  } as Job;
}

test("active bucket includes in-flight statuses, excludes terminal", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "a", status: "In progress" }),
      job({ id: "b", status: "Assigned" }),
      job({ id: "c", status: "Completed" }),
      job({ id: "d", status: "Cancelled" }),
    ],
    NOW,
  );
  assert.deepEqual(board.active.map((j) => j.id).sort(), ["a", "b"]);
});

test("emergency bucket keys off bookingType or priority, only while active", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "e1", bookingType: "Emergency", status: "En route" }),
      job({ id: "e2", priority: "Emergency", status: "In progress" }),
      job({ id: "e3", bookingType: "Emergency", status: "Completed" }),
      job({ id: "n1", status: "In progress" }),
    ],
    NOW,
  );
  assert.deepEqual(board.emergency.map((j) => j.id).sort(), ["e1", "e2"]);
});

test("enRoute / inProgress / delayed buckets match status exactly", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "r", status: "En route" }),
      job({ id: "p", status: "In progress" }),
      job({ id: "x", status: "Delayed" }),
    ],
    NOW,
  );
  assert.deepEqual(board.enRoute.map((j) => j.id), ["r"]);
  assert.deepEqual(board.inProgress.map((j) => j.id), ["p"]);
  assert.deepEqual(board.delayed.map((j) => j.id), ["x"]);
});

test("arrived is intentionally always empty (no distinct real state)", () => {
  const board = deriveLiveJobsBoard([job({ status: "In progress" })], NOW);
  assert.deepEqual(board.arrived, []);
});

test("completedToday only counts Completed jobs created on the same UTC day", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "today", status: "Completed", createdAt: "2026-07-09T09:00:00.000Z" }),
      job({ id: "yesterday", status: "Completed", createdAt: "2026-07-08T23:00:00.000Z" }),
    ],
    NOW,
  );
  assert.deepEqual(board.completedToday.map((j) => j.id), ["today"]);
});

test("problem bucket includes Cancelled/Disputed/Refunded", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "c", status: "Cancelled" }),
      job({ id: "d", status: "Disputed" }),
      job({ id: "r", status: "Refunded" }),
      job({ id: "ok", status: "In progress" }),
    ],
    NOW,
  );
  assert.deepEqual(board.problem.map((j) => j.id).sort(), ["c", "d", "r"]);
});

test("mapReady requires an assigned technician AND an on-the-move status", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "m1", providerId: "t1", status: "En route" }),
      job({ id: "m2", providerId: "t2", status: "In progress" }),
      job({ id: "no-provider", status: "En route" }),
      job({ id: "wrong-status", providerId: "t3", status: "Assigned" }),
    ],
    NOW,
  );
  assert.deepEqual(board.mapReady.map((j) => j.id).sort(), ["m1", "m2"]);
});

test("SLA warning fires for an emergency stalled past the threshold", () => {
  const board = deriveLiveJobsBoard(
    [job({ id: "slow", bookingType: "Emergency", status: "Assigned", createdAt: "2026-07-09T11:00:00.000Z" })],
    NOW,
    { emergencySlaMinutes: 30 },
  );
  const warn = board.slaWarnings.find((w) => w.jobId === "slow");
  assert.ok(warn);
  assert.equal(warn?.reason, "emergency-stalled");
});

test("SLA warning fires for an explicitly Delayed job and an overdue scheduled job", () => {
  const board = deriveLiveJobsBoard(
    [
      job({ id: "late", status: "Delayed" }),
      job({ id: "overdue", status: "Scheduled", scheduledAt: "2026-07-09T10:00:00.000Z" }),
    ],
    NOW,
  );
  assert.ok(board.slaWarnings.some((w) => w.jobId === "late" && w.reason === "delayed-status"));
  assert.ok(board.slaWarnings.some((w) => w.jobId === "overdue" && w.reason === "scheduled-overdue"));
});

test("counts mirror the bucket sizes", () => {
  const board = deriveLiveJobsBoard([job({ status: "In progress" }), job({ status: "Delayed" })], NOW);
  assert.equal(board.counts.inProgress, 1);
  assert.equal(board.counts.delayed, 1);
  assert.equal(board.counts.active, 2);
});
