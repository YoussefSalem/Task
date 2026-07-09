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

test("complaints.assign already existed as a real leaf permission", () => {
  assert.ok(allPermissions.includes("complaints.assign"));
});

test("complaints.internalNotes, complaints.timeline, complaints.attachments are new real leaves", () => {
  assert.ok(allPermissions.includes("complaints.internalNotes"));
  assert.ok(allPermissions.includes("complaints.timeline"));
  assert.ok(allPermissions.includes("complaints.attachments"));
  assert.equal(
    hasPermission("staff", ["complaints.internalNotes"], "complaints.internalNotes"),
    true,
  );
  assert.equal(
    hasPermission("staff", [], "complaints.internalNotes"),
    false,
  );
});

test("notifications.read is an alias for notifications.view", () => {
  assert.equal(allPermissions.includes("notifications.read" as never), false);
  assert.equal(
    hasPermission("staff", ["notifications.view"], "notifications.read"),
    true,
  );
});

test("notifications.manage implies the full notifications CRUD set", () => {
  assert.equal(
    hasPermission("staff", ["notifications.manage"], "notifications.view"),
    true,
  );
  assert.equal(
    hasPermission("staff", ["notifications.manage"], "notifications.create"),
    true,
  );
  assert.equal(
    hasPermission("staff", ["notifications.manage"], "notifications.delete"),
    true,
  );
});

test("chat.search is an alias for support.liveChat.view, same as chat.view", () => {
  assert.equal(allPermissions.includes("chat.search" as never), false);
  assert.equal(
    hasPermission("staff", ["support.liveChat.view"], "chat.search"),
    true,
  );
  assert.equal(hasPermission("staff", [], "chat.search"), false);
});

test("jobs.live.view / jobs.timeline.view are aliases onto real operations+jobs leaves", () => {
  assert.equal(hasPermission("staff", ["operations.liveJobs.view"], "jobs.live.view"), true);
  assert.equal(hasPermission("staff", ["jobs.view"], "jobs.live.view"), true);
  assert.equal(hasPermission("staff", ["operations.timeline.view"], "jobs.timeline.view"), true);
  assert.equal(hasPermission("staff", [], "jobs.live.view"), false);
});

test("jobs.status.update resolves onto jobs.edit", () => {
  assert.equal(hasPermission("staff", ["jobs.edit"], "jobs.status.update"), true);
  assert.equal(hasPermission("staff", ["jobs.view"], "jobs.status.update"), false);
});

test("customers.detail.view resolves onto customers.view", () => {
  assert.equal(hasPermission("staff", ["customers.view"], "customers.detail.view"), true);
  assert.equal(hasPermission("staff", [], "customers.detail.view"), false);
});

test("technicians.detail.view / technicians.location.view resolve onto real leaves", () => {
  assert.equal(hasPermission("staff", ["providers.view"], "technicians.detail.view"), true);
  assert.equal(hasPermission("staff", ["technicians.performance.view"], "technicians.detail.view"), true);
  assert.equal(hasPermission("staff", ["operations.map.view"], "technicians.location.view"), true);
  assert.equal(hasPermission("staff", ["providers.view"], "technicians.location.view"), true);
  assert.equal(hasPermission("staff", [], "technicians.location.view"), false);
});

test("the new job/customer/technician aliases are aliases, not standalone leaves", () => {
  for (const p of [
    "jobs.live.view",
    "jobs.timeline.view",
    "jobs.status.update",
    "customers.detail.view",
    "technicians.detail.view",
    "technicians.location.view",
  ]) {
    assert.equal(allPermissions.includes(p as never), false, `${p} should not be a real leaf`);
  }
});
