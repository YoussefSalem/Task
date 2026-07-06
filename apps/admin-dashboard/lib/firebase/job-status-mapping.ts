import type { JobStatus } from "@/lib/types";

/**
 * Explicit, bidirectional mapping between the Customer App's real `jobs.status`
 * wire values (Dart JobStatus enum name, e.g. "biddingActive", or its snake_case
 * wire form) and the dashboard's own JobStatus display union.
 *
 * The Customer App's real enum (packages/task_domain/lib/src/entities/enums.dart)
 * declares searching, pendingScheduled, biddingActive, accepted, enRoute,
 * inProgress, pausedForApproval, completed, disputed, cancelled. Only
 * biddingActive, accepted, and cancelled are actually written by the Customer
 * App today; the rest are reserved for the future Technician App. Every one of
 * them must map to a distinct, real dashboard status - none may be silently
 * coerced to "Scheduled", since that would hide a disputed or paused job from
 * an admin as if it were merely newly-scheduled.
 */
const WIRE_TO_ADMIN: Record<string, JobStatus> = {
  // Not yet written by any real client, but explicitly mapped so they never
  // fall through to a misleading default if the Technician App starts writing
  // them.
  searching: "Scheduled",
  pendingScheduled: "Scheduled",
  pending_scheduled: "Scheduled",
  Scheduled: "Scheduled",
  biddingActive: "Scheduled",
  bidding_active: "Scheduled",

  accepted: "Assigned",
  Assigned: "Assigned",

  enRoute: "En route",
  en_route: "En route",
  "En route": "En route",

  inProgress: "In progress",
  in_progress: "In progress",
  "In progress": "In progress",

  pausedForApproval: "Paused for approval",
  paused_for_approval: "Paused for approval",
  "Paused for approval": "Paused for approval",

  completed: "Completed",
  Completed: "Completed",

  cancelled: "Cancelled",
  Cancelled: "Cancelled",

  disputed: "Disputed",
  Disputed: "Disputed",

  refunded: "Refunded",
  Refunded: "Refunded",
};

const ADMIN_TO_WIRE: Record<JobStatus, string> = {
  Scheduled: "pendingScheduled",
  Assigned: "accepted",
  "En route": "enRoute",
  "In progress": "inProgress",
  Delayed: "inProgress",
  Completed: "completed",
  Cancelled: "cancelled",
  Refunded: "refunded",
  Disputed: "disputed",
  "Paused for approval": "pausedForApproval",
};

/**
 * Maps a raw Firestore `jobs.status` wire value to the dashboard's JobStatus.
 * Unknown/unrecognized values are surfaced as a console warning rather than
 * silently coerced, so a future enum addition on the Customer App side is
 * noticed instead of hidden. Falls back to "Scheduled" only for truly unknown
 * values (e.g. malformed data), never for the two values this fix targets.
 */
export const adminJobStatusFromWire = (value: unknown): JobStatus => {
  const normalized = String(value ?? "").trim();
  const mapped = WIRE_TO_ADMIN[normalized];
  if (mapped) return mapped;
  if (normalized) {
    console.warn(
      `[Task Admin] Unrecognized job status wire value "${normalized}" - defaulting display to "Scheduled". ` +
        "This status is not in job-status-mapping.ts's WIRE_TO_ADMIN table and should be added explicitly.",
    );
  }
  return "Scheduled";
};

/** Maps a dashboard JobStatus back to the Customer App's real wire value. */
export const jobWireStatusFromAdmin = (status: JobStatus): string =>
  ADMIN_TO_WIRE[status] ?? "pendingScheduled";
