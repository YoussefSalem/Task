/**
 * Decides how (and whether) a dashboard-authored notification can safely be
 * fanned out to the Customer App's real per-user feed at
 * `users/{uid}/notifications`, without ever attempting an unbounded,
 * client-side broadcast write against every customer/technician in the app.
 *
 * Bounded audiences (a specific user, or an admin-selected set of users) are
 * safe to fan out directly from this client code - the write count is capped
 * by what the admin actually selected. Unbounded broadcast audiences ("All
 * customers" / "All providers" / "Segment") are NOT fanned out here: doing so
 * from client code would mean a single admin action could trigger writes
 * against the entire customer or provider base with no batching, pagination,
 * or rate limiting - exactly the kind of operation the audit report
 * recommended moving to a Cloud Function instead. Until that Cloud Function
 * exists, broadcast sends explicitly refuse to run in production rather than
 * silently doing nothing (today's behavior) or attempting a risky unbounded
 * write.
 */

export type NotificationAudience =
  | "All customers"
  | "All providers"
  | "Segment"
  | "Individual";

export interface FanoutPlan {
  /** Real Firebase Auth uids to fan out a users/{uid}/notifications write to. */
  targetUserIds: string[];
}

export class BroadcastFanoutNotImplementedError extends Error {
  constructor(audience: NotificationAudience) {
    super(
      `Sending a "${audience}" notification to real Customer App users is not implemented yet. ` +
        "This requires a Cloud Function to fan out safely at scale (see docs/required-firestore-rule-changes.md). " +
        "Pass a bounded targetUserId/targetUserIds instead (an admin-selected set of recipients), or wait for the Cloud Function.",
    );
    this.name = "BroadcastFanoutNotImplementedError";
  }
}

/**
 * Upper bound on how many users a single client-side action may fan out to.
 * This is a safety cap, not a real system limit - it exists so an
 * accidentally-huge admin selection can't turn into an unbounded write burst
 * indistinguishable from a true broadcast.
 */
export const MAX_BOUNDED_FANOUT_RECIPIENTS = 500;

/**
 * Resolves which real users/{uid}/notifications docs (if any) a dashboard
 * notification action should also write to.
 *
 * The safety signal is whether the CALLER supplied bounded recipient ids, not
 * the audience label alone (the label is just UI copy) - a "targetUserIds"
 * list bounds the write count regardless of what the audience is called. Only
 * when NO recipient ids are supplied at all does this fall back to treating
 * the request as an attempted unbounded broadcast, which throws.
 */
export function resolveNotificationFanout(
  audience: NotificationAudience,
  targetUserId?: string,
  targetUserIds?: string[],
): FanoutPlan {
  const ids = new Set<string>();
  if (targetUserId) ids.add(targetUserId);
  for (const id of targetUserIds ?? []) if (id) ids.add(id);

  if (ids.size === 0) {
    throw new BroadcastFanoutNotImplementedError(audience);
  }
  if (ids.size > MAX_BOUNDED_FANOUT_RECIPIENTS) {
    throw new Error(
      `Refusing to fan out to ${ids.size} recipients in one action (cap is ${MAX_BOUNDED_FANOUT_RECIPIENTS}). ` +
        "Split into smaller batches or wait for the Cloud Function-based broadcast path.",
    );
  }
  return { targetUserIds: [...ids] };
}

/** The Customer App's real users/{uid}/notifications document shape. */
export interface RealNotificationDoc {
  type: "message" | "offer" | "hired" | "job_status";
  title: string;
  body: string;
  read: false;
  created_at: unknown;
}

/**
 * Builds the real notification document to write into a Customer App user's
 * feed. Dashboard-originated notifications don't map to a specific
 * message/offer/hired event, so they use the generic "job_status" wire type -
 * the closest real, already-accepted NotificationType value for a
 * system/informational message.
 */
export function buildRealNotificationDoc(
  title: string,
  body: string,
  serverTimestamp: unknown,
): RealNotificationDoc {
  return {
    type: "job_status",
    title,
    body,
    read: false,
    created_at: serverTimestamp,
  };
}
