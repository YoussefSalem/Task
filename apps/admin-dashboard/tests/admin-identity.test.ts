import { test } from "node:test";
import assert from "node:assert/strict";
import { resolveAdminIdentity } from "../lib/firebase/admin-identity";

test("denies access when no admins/{uid} doc exists", () => {
  const result = resolveAdminIdentity(false, null);
  assert.equal(result.allowed, false);
});

test("allows a clean admin identity with no Customer App user doc", () => {
  const result = resolveAdminIdentity(true, null);
  assert.equal(result.allowed, true);
});

test("allows a uid whose Customer App role is itself admin", () => {
  const result = resolveAdminIdentity(true, "admin");
  assert.equal(result.allowed, true);
});

test("REFUSES admin access when the same uid is a real Customer App customer (the RBAC compatibility fix)", () => {
  const result = resolveAdminIdentity(true, "customer");
  assert.equal(result.allowed, false);
  assert.match(result.reason ?? "", /customer/);
});

test("REFUSES admin access when the same uid is a real Customer App technician", () => {
  const result = resolveAdminIdentity(true, "technician");
  assert.equal(result.allowed, false);
  assert.match(result.reason ?? "", /technician/);
});
