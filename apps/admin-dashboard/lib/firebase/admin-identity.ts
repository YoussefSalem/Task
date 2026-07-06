/**
 * RBAC compatibility helper (Phase C, item 6 of the safe-code-alignment plan).
 *
 * The dashboard's Firestore rules and its `admins/{uid}` + `roles/{roleId}`
 * model have no counterpart in the Customer App's real schema, where every
 * account (customer, technician, or admin) is just a `users/{uid}` document
 * distinguished by a `role` string field. If the two Firebase projects are
 * ever unified (task-admin-eg becoming the one shared project), dashboard
 * admins and Customer App customers/technicians would share one Firebase Auth
 * user pool.
 *
 * This module does NOT change Firestore rules (that is explicitly deferred -
 * see docs/required-firestore-rule-changes.md) and does not decide which Auth
 * pool strategy is chosen. It only adds a defense-in-depth, code-level check:
 * a uid is never treated as a dashboard admin if it also carries a real
 * Customer App `users/{uid}` document with role `customer` or `technician` -
 * even if an `admins/{uid}` document also exists for it (e.g. from a bug, a
 * stale migration script, or a compromised/mistaken account).
 */

export type CustomerAppRole = "customer" | "technician" | "admin";

export interface AdminIdentityCheckResult {
  allowed: boolean;
  reason?: string;
}

/**
 * Pure decision function - no Firestore access. Callers look up the two
 * documents themselves (server-side, via the Admin SDK) and pass in only
 * what's needed to decide.
 */
export function resolveAdminIdentity(
  adminDocExists: boolean,
  customerAppUserRole: CustomerAppRole | null,
): AdminIdentityCheckResult {
  if (!adminDocExists) {
    return {
      allowed: false,
      reason: "No admins/{uid} document exists for this Firebase Auth user.",
    };
  }
  if (customerAppUserRole === "customer" || customerAppUserRole === "technician") {
    return {
      allowed: false,
      reason:
        `This uid also has a real Customer App users/{uid} document with role "${customerAppUserRole}". ` +
        "Refusing to treat it as an admin identity so a customer/technician account can never gain admin access, " +
        "even if an admins/{uid} document also exists for it.",
    };
  }
  return { allowed: true };
}
