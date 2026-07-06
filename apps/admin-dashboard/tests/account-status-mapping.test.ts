import { test } from "node:test";
import assert from "node:assert/strict";
import { adminStatusFromUser } from "../lib/firebase/account-status-mapping";

test("disabled:true always wins, regardless of status", () => {
  assert.equal(adminStatusFromUser({ disabled: true, status: "anything" }), "Disabled");
});

test("absent/empty status defaults to Active (preserves today's behavior for ordinary customers)", () => {
  assert.equal(adminStatusFromUser({}), "Active");
  assert.equal(adminStatusFromUser({ status: "" }), "Active");
  assert.equal(adminStatusFromUser({ status: "   " }), "Active");
});

test("known statuses map as before", () => {
  assert.equal(adminStatusFromUser({ status: "suspended" }), "Suspended");
  assert.equal(adminStatusFromUser({ status: "rejected" }), "Suspended");
  assert.equal(adminStatusFromUser({ status: "banned" }), "Banned");
  assert.equal(adminStatusFromUser({ status: "blacklisted" }), "Banned");
  assert.equal(adminStatusFromUser({ status: "blocked" }), "Banned");
  assert.equal(adminStatusFromUser({ status: "pending" }), "Pending");
  assert.equal(adminStatusFromUser({ status: "applied" }), "Pending");
  assert.equal(adminStatusFromUser({ status: "under_review" }), "Pending");
});

test("a present but unrecognized status NEVER defaults to Active (the fixed bug)", () => {
  assert.equal(adminStatusFromUser({ status: "some-future-status" }), "Pending");
  assert.equal(adminStatusFromUser({ status: "garbage" }), "Pending");
  assert.notEqual(adminStatusFromUser({ status: "some-future-status" }), "Active");
});

test("is case-insensitive", () => {
  assert.equal(adminStatusFromUser({ status: "SUSPENDED" }), "Suspended");
  assert.equal(adminStatusFromUser({ status: "Banned" }), "Banned");
});
