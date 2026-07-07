/**
 * Phase D.1 — production read-only integration.
 *
 * The Admin Dashboard can now READ real production data through the adapter
 * layer (see subscribeDashboard / resolveReadSource in repository.ts), but
 * every WRITE that would touch real production data is disabled until the
 * migration is explicitly approved. This is a single, deliberate global
 * switch so a later phase (D.2+) can enable production writes in exactly one
 * place after review.
 *
 * Demo actors are unaffected: their writes only ever touch the isolated,
 * environment=="demo" collections, so they remain fully functional.
 */

/**
 * While true, no production (non-demo) write may proceed. Flip to false ONLY
 * as an explicit, reviewed step when production writes are approved.
 */
export const PRODUCTION_READ_ONLY = true;

/** Exact message shown to the user for any blocked production action. */
export const PRODUCTION_WRITE_DISABLED_MESSAGE =
  "This production action is disabled until migration is approved.";

export interface WriteAccessResult {
  allowed: boolean;
  reason?: string;
}

/**
 * Decides whether an actor may perform a data-mutating action.
 *
 * - Demo actors: always allowed (their writes are isolated to demo data).
 * - Production (non-demo) actors: blocked while PRODUCTION_READ_ONLY, with the
 *   standard user-facing message. When the flag is later turned off, they are
 *   allowed (subject to the normal per-action permission checks elsewhere).
 */
export function checkProductionWriteAccess(actor: {
  isDemoUser?: boolean;
}): WriteAccessResult {
  if (actor.isDemoUser === true) return { allowed: true };
  if (PRODUCTION_READ_ONLY) {
    return { allowed: false, reason: PRODUCTION_WRITE_DISABLED_MESSAGE };
  }
  return { allowed: true };
}

/** True when the actor is operating against real production data read-only. */
export function isProductionReadOnly(actor: { isDemoUser?: boolean }): boolean {
  return actor.isDemoUser !== true && PRODUCTION_READ_ONLY;
}

export type EnvironmentBadgeTone = "demo" | "readonly" | "disabled";
export interface EnvironmentBadge {
  label: string;
  tone: EnvironmentBadgeTone;
}

/**
 * The badges the dashboard shell should show for the current actor:
 * - demo actor -> "Demo Data"
 * - production actor while read-only -> "Production Read-only" + "Production
 *   Write Disabled"
 * Pure so the badge logic is unit-testable without rendering React.
 */
export function environmentBadges(isDemoUser: boolean | undefined): EnvironmentBadge[] {
  if (isDemoUser === true) {
    return [{ label: "Demo Data", tone: "demo" }];
  }
  if (PRODUCTION_READ_ONLY) {
    return [
      { label: "Production Read-only", tone: "readonly" },
      { label: "Production Write Disabled", tone: "disabled" },
    ];
  }
  return [];
}
