import type { EntityStatus } from "@/lib/types";

const SUSPENDED = new Set(["suspended", "rejected"]);
const BANNED = new Set(["banned", "blacklisted", "blocked"]);
const PENDING = new Set(["pending", "applied", "under_review"]);

/**
 * Maps a raw Firestore user/customer doc's `disabled`/`status` fields to the
 * dashboard's EntityStatus.
 *
 * An ABSENT status (the normal case for most real Customer App users, which
 * don't track this dimension at all unless the dashboard itself has written
 * one via suspend/ban) is treated as "Active" - no negative status recorded
 * means presumed fine, and this preserves today's behavior for the common
 * case so ordinary customers don't all start showing as under review.
 *
 * A NON-EMPTY but unrecognized status value - data was explicitly set to
 * something this function doesn't know how to interpret - is a genuinely
 * different case. It must NOT default to "Active" (the most permissive
 * state), since that would silently hide a real, possibly problematic,
 * account state from an admin. It falls back to "Pending" (an existing,
 * safe, neutral EntityStatus value - no new status was invented) so the
 * account surfaces for manual review instead of silently looking fine.
 */
export function adminStatusFromUser(data: Record<string, unknown>): EntityStatus {
  if (data.disabled === true) return "Disabled";
  const raw = String(data.status ?? "").trim();
  if (!raw) return "Active";
  const status = raw.toLowerCase();
  if (SUSPENDED.has(status)) return "Suspended";
  if (BANNED.has(status)) return "Banned";
  if (PENDING.has(status)) return "Pending";
  return "Pending";
}
