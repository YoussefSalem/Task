import { hasPermission, isSuperAdminRole } from "@/lib/permissions";

export interface SystemResetActorLike {
  role?: string;
  roleId?: string;
  permissions?: string[];
  isDemoUser?: boolean;
}

export interface SystemResetCheckResult {
  allowed: boolean;
  reason?: string;
}

export function isSuperAdminActor(actor: SystemResetActorLike): boolean {
  return (
    isSuperAdminRole(actor.role) ||
    actor.roleId === "super-admin" ||
    actor.roleId === "super_admin" ||
    hasPermission(actor.role, actor.permissions, "system.reset")
  );
}

/**
 * Decides whether an actor may invoke the production system-reset route.
 *
 * system-reset ALWAYS targets `environment == "production"` data - there is
 * no demo-mode variant of it (demo data has its own reset path: POST
 * /api/firebase/demo/reset). A demo actor must NEVER be allowed through here,
 * even if they somehow carry a Super Admin role/roleId/permission (e.g. a
 * misconfigured demo tenant seeded with elevated access for a sales demo) -
 * demo status is checked and refused before the Super Admin check runs, so
 * no combination of role/roleId/permissions can bypass it.
 */
export function checkSystemResetAccess(actor: SystemResetActorLike): SystemResetCheckResult {
  if (actor.isDemoUser === true) {
    return {
      allowed: false,
      reason:
        "Demo accounts can never reset production data, regardless of role. " +
        "Use /api/firebase/demo/reset to reset the demo dataset instead.",
    };
  }
  if (!isSuperAdminActor(actor)) {
    return { allowed: false, reason: "Only Super Admin can reset the system." };
  }
  return { allowed: true };
}
