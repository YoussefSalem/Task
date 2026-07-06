import { test } from "node:test";
import assert from "node:assert/strict";
import { checkSystemResetAccess, isSuperAdminActor } from "../lib/firebase/system-reset-guard";

test("denies a demo actor even when they hold every super-admin signal (the fixed bug)", () => {
  const result = checkSystemResetAccess({
    isDemoUser: true,
    role: "Super Admin",
    roleId: "super-admin",
    permissions: ["system.reset"],
  });
  assert.equal(result.allowed, false);
  assert.match(result.reason ?? "", /[Dd]emo/);
});

test("denies a demo actor with roleId super_admin (alternate spelling)", () => {
  const result = checkSystemResetAccess({ isDemoUser: true, roleId: "super_admin" });
  assert.equal(result.allowed, false);
});

test("denies a non-demo actor who is not a super admin", () => {
  const result = checkSystemResetAccess({ isDemoUser: false, role: "Support", permissions: [] });
  assert.equal(result.allowed, false);
  assert.match(result.reason ?? "", /Super Admin/);
});

test("allows a real (non-demo) super admin via role name", () => {
  assert.equal(checkSystemResetAccess({ isDemoUser: false, role: "Super Admin" }).allowed, true);
});

test("allows a real (non-demo) super admin via roleId", () => {
  assert.equal(checkSystemResetAccess({ isDemoUser: false, roleId: "super-admin" }).allowed, true);
  assert.equal(checkSystemResetAccess({ isDemoUser: false, roleId: "super_admin" }).allowed, true);
});

test("system.reset is intentionally super-admin-only and fails closed even with an explicit grant (verifies existing permissions.ts behavior, not a regression)", () => {
  // hasPermission() treats "system.reset" as superAdminOnlyPermissions - a
  // non-super-admin role can never satisfy it, even if a role document
  // explicitly lists "system.reset" in its permissions array. This is
  // intentional fail-closed behavior in lib/permissions.ts, unrelated to the
  // demo-safety fix - documenting it here so it isn't mistaken for a bug.
  assert.equal(
    checkSystemResetAccess({ isDemoUser: false, role: "Support", permissions: ["system.reset"] }).allowed,
    false,
  );
});

test("treats isDemoUser undefined/absent as non-demo (matches existing AdminUser field optionality)", () => {
  assert.equal(checkSystemResetAccess({ role: "Super Admin" }).allowed, true);
});

test("isSuperAdminActor helper matches checkSystemResetAccess's super-admin branch", () => {
  assert.equal(isSuperAdminActor({ role: "Super Admin" }), true);
  assert.equal(isSuperAdminActor({ role: "Support" }), false);
});
