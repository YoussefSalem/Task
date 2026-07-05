import type { Permission } from "@/lib/types";

export const permissionActions = [
  { id: "view", label: "View" },
  { id: "create", label: "Create" },
  { id: "edit", label: "Edit" },
  { id: "delete", label: "Delete" },
  { id: "approve", label: "Approve" },
  { id: "reject", label: "Reject" },
  { id: "export", label: "Export" },
  { id: "assign", label: "Assign" },
  { id: "change_status", label: "Change Status" },
  { id: "sensitive", label: "View Sensitive Data" },
] as const;

export const permissionModules = [
  { id: "dashboard", label: "Dashboard", description: "Overview, KPIs, command center" },
  { id: "users", label: "Users", description: "Dashboard administrators" },
  { id: "customers", label: "Customers", description: "Customer accounts and history" },
  { id: "technicians", label: "Technicians", description: "Providers, workers, verification" },
  { id: "jobs", label: "Bookings / Jobs", description: "Requests, dispatch, offers, timelines" },
  { id: "services", label: "Categories / Services", description: "Catalog, prices, availability" },
  { id: "payments", label: "Payments", description: "Transactions, refunds, payouts, wallets" },
  { id: "reviews", label: "Reviews", description: "Ratings, reviews, quality signals" },
  { id: "notifications", label: "Notifications", description: "Push/email announcements" },
  { id: "support", label: "Support Tickets", description: "Support chats, complaints, cases" },
  { id: "reports", label: "Reports / Analytics", description: "Analytics, exports, reports" },
  { id: "settings", label: "Settings", description: "Company, branding, integrations" },
  { id: "roles", label: "Roles & Permissions", description: "Role and permission policies" },
  { id: "audit", label: "Audit Logs", description: "Administrative activity history" },
] as const;

export type PermissionModuleId = (typeof permissionModules)[number]["id"];
export type PermissionActionId = (typeof permissionActions)[number]["id"];
export type StructuredPermission = `${PermissionModuleId}.${PermissionActionId}`;

export const allPermissions = permissionModules.flatMap((module) =>
  permissionActions.map((action) => `${module.id}.${action.id}` as StructuredPermission),
);

export const viewOnlyPermissions = permissionModules.map(
  (module) => `${module.id}.view` as StructuredPermission,
);

export const fullAccessPermissions = [...allPermissions];

const legacyPermissionAliases: Record<string, StructuredPermission[]> = {
  "customers.read": ["customers.view"],
  "customers.write": ["customers.create", "customers.edit", "customers.delete", "customers.change_status"],
  "providers.read": ["technicians.view"],
  "providers.approve": ["technicians.approve", "technicians.reject", "technicians.view", "technicians.edit"],
  "providers.suspend": ["technicians.change_status"],
  "jobs.read": ["jobs.view"],
  "jobs.write": ["jobs.create", "jobs.edit", "jobs.assign", "jobs.change_status"],
  "services.manage": ["services.view", "services.create", "services.edit", "services.delete", "services.change_status"],
  "payments.read": ["payments.view"],
  "payments.manage": ["payments.view", "payments.create", "payments.edit", "payments.approve", "payments.reject", "payments.change_status", "payments.sensitive"],
  "trust.manage": ["support.view", "support.create", "support.edit", "support.assign", "support.change_status", "support.sensitive"],
  "promotions.manage": ["notifications.view", "notifications.create", "notifications.edit", "notifications.delete"],
  "notifications.send": ["notifications.create", "notifications.approve"],
  "admins.manage": ["users.view", "users.create", "users.edit", "users.delete", "users.change_status", "roles.view", "roles.create", "roles.edit", "roles.delete"],
  "audit.read": ["audit.view"],
};

export function expandPermissions(permissions: Permission[] = []) {
  const expanded = new Set<Permission>(permissions);
  for (const permission of permissions) {
    for (const alias of legacyPermissionAliases[permission] ?? []) expanded.add(alias);
  }
  return expanded;
}

export function hasPermission(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  permission: Permission,
) {
  if (roleName === "Super admin") return true;
  return expandPermissions(permissions).has(permission);
}

export function moduleViewPermission(moduleId: PermissionModuleId) {
  return `${moduleId}.view` as StructuredPermission;
}

export function normalizePermissionList(permissions: Permission[]) {
  const allowed = new Set(allPermissions);
  return Array.from(new Set(permissions)).filter((permission) =>
    allowed.has(permission as StructuredPermission),
  ) as StructuredPermission[];
}
