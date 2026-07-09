import { test } from "node:test";
import assert from "node:assert/strict";
import { hasPermission, allPermissions } from "../lib/permissions";

test("complaints.reopen is a real leaf permission distinct from complaints.resolve", () => {
  assert.ok(allPermissions.includes("complaints.reopen"));
  assert.ok(allPermissions.includes("complaints.resolve"));
  assert.notEqual(
    allPermissions.includes("complaints.reopen"),
    false,
  );
});

test("a role granted only complaints.resolve does not get complaints.reopen for free", () => {
  assert.equal(
    hasPermission("staff", ["complaints.resolve"], "complaints.reopen"),
    false,
  );
});

test("a role granted complaints.reopen has it directly", () => {
  assert.equal(
    hasPermission("staff", ["complaints.reopen"], "complaints.reopen"),
    true,
  );
});

test("technicians.complaints.reopen alias now implies complaints.reopen (not complaints.resolve)", () => {
  assert.equal(
    hasPermission("staff", ["technicians.complaints.reopen"], "complaints.reopen"),
    true,
  );
});

test("complaints.view and complaints.resolve already existed and still resolve", () => {
  assert.equal(hasPermission("staff", ["complaints.view"], "complaints.view"), true);
  assert.equal(hasPermission("staff", ["complaints.resolve"], "complaints.resolve"), true);
});

test("notifications.view already existed and still resolves", () => {
  assert.equal(hasPermission("staff", ["notifications.view"], "notifications.view"), true);
});

test("chat.view is a legacy-alias shorthand for support.liveChat.view, not a new module", () => {
  assert.equal(allPermissions.includes("chat.view" as never), false);
  assert.equal(
    hasPermission("staff", ["support.liveChat.view"], "chat.view"),
    true,
  );
});

test("a role with neither chat.view's alias target nor trust/support permissions is denied", () => {
  assert.equal(hasPermission("staff", [], "chat.view"), false);
});

test("a super admin role bypasses all of the above checks", () => {
  assert.equal(hasPermission("super_admin", [], "complaints.reopen"), true);
  assert.equal(hasPermission("super_admin", [], "chat.view"), true);
});
