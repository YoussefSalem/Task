"use client";

import { useAuth } from "@/components/auth-provider";
import { useAdminData } from "@/components/admin-data-provider";
import type { Permission } from "@/lib/types";
import { expandPermissions, hasPermission } from "@/lib/permissions";
import { isDemoExpired, isDemoRestrictedPermission } from "@/lib/demo-mode";

export function usePermissions() {
  const { user } = useAuth();
  const { db } = useAdminData();
  const rolePermissions =
    db.roles.find((role) => role.id === user?.roleId)?.permissions ??
    user?.permissions ??
    [];
  const permissions = Array.from(expandPermissions(rolePermissions));
  return {
    permissions,
    can(permission: Permission) {
      if (user?.isDemoUser && (isDemoExpired(user) || isDemoRestrictedPermission(permission)))
        return false;
      if (user?.roleId === "super-admin" || user?.roleId === "super_admin")
        return true;
      return hasPermission(user?.role, rolePermissions, permission);
    },
  };
}
