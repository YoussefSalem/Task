"use client";

import { useMemo } from "react";
import { useAdminData } from "@/components/admin-data-provider";
import { usePermissions } from "@/components/use-permissions";
import { deriveLiveJobsBoard, type LiveJobsBoard } from "@/lib/firebase/live-jobs";
import type { Job } from "@/lib/types";

/**
 * Live Operations board driven entirely by the centralized, unit-tested
 * deriveLiveJobsBoard helper (lib/firebase/live-jobs.ts) over the real `jobs`
 * already bridged into the dashboard by subscribeDashboard. No new Firestore
 * read and no duplicated bucketing logic - the same helper the tests cover.
 * Gated by jobs.live.view; read-only (no write controls here).
 */
const BUCKETS: { key: keyof LiveJobsBoard; label: string; tone: string }[] = [
  { key: "active", label: "Active now", tone: "text-indigo-300" },
  { key: "emergency", label: "Emergency", tone: "text-red-300" },
  { key: "enRoute", label: "Technician en route", tone: "text-cyan-300" },
  { key: "inProgress", label: "Work in progress", tone: "text-emerald-300" },
  { key: "delayed", label: "Delayed", tone: "text-amber-300" },
  { key: "completedToday", label: "Completed today", tone: "text-green-300" },
  { key: "problem", label: "Cancelled / problem", tone: "text-rose-300" },
  { key: "mapReady", label: "Map-ready (live)", tone: "text-sky-300" },
];

export function LiveJobsBoard({ openJob }: { openJob?: (job: Job) => void }) {
  const { db } = useAdminData();
  const { can } = usePermissions();
  const board = useMemo(
    () => deriveLiveJobsBoard(db.jobs, new Date().toISOString()),
    [db.jobs],
  );

  if (!can("jobs.live.view")) {
    return (
      <div className="panel p-4 text-xs text-zinc-500">
        You do not have the jobs.live.view permission required for the live operations board.
      </div>
    );
  }

  return (
    <div className="panel p-4">
      <div className="mb-3 flex items-center justify-between">
        <div>
          <h2 className="text-sm font-semibold">Live operations board</h2>
          <p className="text-[10px] text-zinc-500">
            Derived from live Firestore jobs · read-only
          </p>
        </div>
        {board.slaWarnings.length > 0 && (
          <span className="rounded-full border border-red-500/30 bg-red-500/10 px-2 py-0.5 text-[10px] text-red-300">
            {board.slaWarnings.length} SLA warning{board.slaWarnings.length === 1 ? "" : "s"}
          </span>
        )}
      </div>

      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        {BUCKETS.map((b) => (
          <div key={b.key} className="rounded-lg border border-white/[.06] bg-white/[.02] p-3">
            <p className={`text-lg font-semibold ${b.tone}`}>
              {(board[b.key] as Job[]).length}
            </p>
            <p className="text-[10px] text-zinc-500">{b.label}</p>
          </div>
        ))}
      </div>

      {board.slaWarnings.length > 0 && (
        <div className="mt-4">
          <p className="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-500">
            SLA warnings
          </p>
          <ul className="space-y-1">
            {board.slaWarnings.slice(0, 8).map((w) => {
              const job = db.jobs.find((j) => j.id === w.jobId);
              return (
                <li
                  key={`${w.jobId}-${w.reason}`}
                  className="flex items-center justify-between rounded bg-white/[.03] p-2 text-[11px]"
                >
                  <span className="text-zinc-300">{w.detail}</span>
                  {job && openJob && (
                    <button
                      onClick={() => openJob(job)}
                      className="text-[10px] text-indigo-300 hover:text-indigo-200"
                    >
                      Open {job.id}
                    </button>
                  )}
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
