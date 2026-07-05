import type { AdminUser } from "@/lib/types";
import { isSuperAdminRole } from "@/lib/permissions";

export type DashboardCustomClaims = {
  roleId: string;
  tenantId: string;
  isSuperAdmin: boolean;
};

export function smallDashboardClaims(input: {
  roleId?: string | null;
  role?: string | null;
  tenantId?: string | null;
}): DashboardCustomClaims {
  const roleId = String(input.roleId || "support");
  const claims = {
    roleId,
    tenantId: String(input.tenantId || "task"),
    isSuperAdmin:
      roleId === "super-admin" ||
      roleId === "super_admin" ||
      isSuperAdminRole(input.role),
  };
  const serialized = JSON.stringify(claims);
  if (serialized.length >= 1000)
    throw new Error("Dashboard custom claims exceed Firebase limit.");
  return claims;
}

export function roleClaimsFromAdmin(admin: Pick<AdminUser, "role" | "roleId"> & { tenantId?: string }) {
  return smallDashboardClaims({
    role: admin.role,
    roleId: admin.roleId,
    tenantId: admin.tenantId,
  });
}
