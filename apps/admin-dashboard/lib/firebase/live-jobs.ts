import type { Job, JobStatus } from "@/lib/types";

/**
 * Pure, dependency-free derivation of the Live Operations board from the real
 * jobs already loaded into the dashboard (subscribeDashboard bridges the real
 * `jobs` collection for production actors - see entity-routing.ts). This does
 * NOT read Firestore itself; it buckets the in-memory Job[] so the same data
 * powers the board and is trivially unit-testable.
 *
 * Honesty notes about the real status vocabulary
 * (packages/task_data/lib/src/mappers/enum_codecs.dart JobStatusCodec):
 * - The technician-writable wire states are en_route / in_progress / completed.
 *   There is NO distinct "arrived" wire state, so `arrived` is intentionally
 *   left empty here rather than fabricated - a genuine arrived signal needs a
 *   new status the Customer/Technician App does not write yet.
 * - "completed today" is approximated by createdAt: the dashboard Job model
 *   does not surface a separate completion timestamp today, so this bucket is
 *   best-effort (same-UTC-day as `nowIso`), not a guarantee. Wiring a real
 *   completed_at through mapJobDoc is a follow-up, noted rather than faked.
 */
export interface LiveJobsBoard {
  active: Job[];
  delayed: Job[];
  emergency: Job[];
  enRoute: Job[];
  arrived: Job[];
  inProgress: Job[];
  completedToday: Job[];
  problem: Job[];
  /** Jobs that have an assigned technician and a live status - map candidates. */
  mapReady: Job[];
  /** Derived SLA warnings (emergency stalled, or explicitly Delayed). */
  slaWarnings: SlaWarning[];
  counts: Record<string, number>;
}

export interface SlaWarning {
  jobId: string;
  reason: "emergency-stalled" | "delayed-status" | "scheduled-overdue";
  detail: string;
}

const ACTIVE_STATUSES: JobStatus[] = [
  "Assigned",
  "En route",
  "In progress",
  "Delayed",
  "Paused for approval",
];
const PROBLEM_STATUSES: JobStatus[] = ["Cancelled", "Disputed", "Refunded"];

const isEmergency = (job: Job) =>
  job.bookingType === "Emergency" || job.priority === "Emergency";

const sameUtcDay = (a: string, b: string) => {
  if (!a || !b) return false;
  return a.slice(0, 10) === b.slice(0, 10);
};

/** Minutes an emergency job may sit not-yet-in-progress before it's an SLA breach. */
const EMERGENCY_SLA_MINUTES = 30;

export function deriveLiveJobsBoard(
  jobs: Job[],
  nowIso: string,
  opts: { emergencySlaMinutes?: number } = {},
): LiveJobsBoard {
  const slaMinutes = opts.emergencySlaMinutes ?? EMERGENCY_SLA_MINUTES;
  const nowMs = Date.parse(nowIso);

  const active = jobs.filter((j) => ACTIVE_STATUSES.includes(j.status));
  const delayed = jobs.filter((j) => j.status === "Delayed");
  const emergency = jobs.filter((j) => isEmergency(j) && ACTIVE_STATUSES.includes(j.status));
  const enRoute = jobs.filter((j) => j.status === "En route");
  const arrived: Job[] = []; // no distinct real "arrived" state - see module doc
  const inProgress = jobs.filter((j) => j.status === "In progress");
  const completedToday = jobs.filter(
    (j) => j.status === "Completed" && sameUtcDay(String(j.createdAt ?? ""), nowIso),
  );
  const problem = jobs.filter((j) => PROBLEM_STATUSES.includes(j.status));
  const mapReady = jobs.filter(
    (j) => Boolean(j.providerId) && ["En route", "In progress"].includes(j.status),
  );

  const slaWarnings: SlaWarning[] = [];
  for (const job of jobs) {
    if (job.status === "Delayed") {
      slaWarnings.push({
        jobId: job.id,
        reason: "delayed-status",
        detail: `${job.service} is marked Delayed.`,
      });
      continue;
    }
    if (isEmergency(job) && ["Assigned", "En route"].includes(job.status)) {
      const created = Date.parse(String(job.createdAt ?? ""));
      if (Number.isFinite(created) && Number.isFinite(nowMs)) {
        const ageMin = (nowMs - created) / 60000;
        if (ageMin >= slaMinutes) {
          slaWarnings.push({
            jobId: job.id,
            reason: "emergency-stalled",
            detail: `Emergency job not in progress after ${Math.round(ageMin)} min.`,
          });
        }
      }
    }
    if (
      job.status === "Scheduled" &&
      job.scheduledAt &&
      Number.isFinite(Date.parse(job.scheduledAt)) &&
      Number.isFinite(nowMs) &&
      Date.parse(job.scheduledAt) < nowMs
    ) {
      slaWarnings.push({
        jobId: job.id,
        reason: "scheduled-overdue",
        detail: `Scheduled job is past its start time and still unassigned.`,
      });
    }
  }

  return {
    active,
    delayed,
    emergency,
    enRoute,
    arrived,
    inProgress,
    completedToday,
    problem,
    mapReady,
    slaWarnings,
    counts: {
      active: active.length,
      delayed: delayed.length,
      emergency: emergency.length,
      enRoute: enRoute.length,
      arrived: arrived.length,
      inProgress: inProgress.length,
      completedToday: completedToday.length,
      problem: problem.length,
      mapReady: mapReady.length,
      slaWarnings: slaWarnings.length,
    },
  };
}
