"use client";

import type { Complaint } from "@/lib/types";

/**
 * Read-only detail drawer for one complaint: description, current status,
 * evidence (attachments placeholder), internal notes, and the audit-log
 * history trail (assignment/status-change/note events). History is only
 * populated for native/demo complaints - bridged real complaints have no
 * history subcollection today (see lib/firebase/repository.ts's complaint
 * write actions), so the section renders an honest empty state for those.
 */
export function ComplaintDetailDrawer({
  complaint,
  onClose,
}: {
  complaint: Complaint | null;
  onClose: () => void;
}) {
  if (!complaint) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/60">
      <div className="h-full w-full max-w-md overflow-y-auto bg-zinc-950 p-5 text-zinc-200 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h2 className="text-sm font-semibold">{complaint.title}</h2>
            <p className="text-[10px] text-zinc-500">{complaint.id}</p>
          </div>
          <button onClick={onClose} className="text-xs text-zinc-500 hover:text-zinc-300">
            Close
          </button>
        </div>

        <dl className="mb-5 grid grid-cols-2 gap-3 text-[11px]">
          <div>
            <dt className="text-zinc-500">Status</dt>
            <dd className="mt-0.5 text-zinc-200">{complaint.status}</dd>
          </div>
          <div>
            <dt className="text-zinc-500">Severity</dt>
            <dd className="mt-0.5 text-zinc-200">{complaint.severity}</dd>
          </div>
          <div>
            <dt className="text-zinc-500">Owner</dt>
            <dd className="mt-0.5 text-zinc-200">{complaint.owner}</dd>
          </div>
          <div>
            <dt className="text-zinc-500">Filed</dt>
            <dd className="mt-0.5 text-zinc-200">{complaint.age} ago</dd>
          </div>
          <div>
            <dt className="text-zinc-500">Customer</dt>
            <dd className="mt-0.5 text-zinc-200">{complaint.customer}</dd>
          </div>
          <div>
            <dt className="text-zinc-500">Job</dt>
            <dd className="mt-0.5 text-zinc-200">{complaint.jobId ?? "—"}</dd>
          </div>
        </dl>

        <section className="mb-5">
          <h3 className="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-500">
            Description
          </h3>
          <p className="text-[11px] text-zinc-400">{complaint.description || "No description provided."}</p>
        </section>

        <section className="mb-5">
          <h3 className="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-500">
            Attachments / evidence
          </h3>
          {complaint.evidence.length === 0 && (
            <p className="text-[11px] text-zinc-600">No evidence uploaded yet.</p>
          )}
          <ul className="space-y-1">
            {complaint.evidence.map((url) => (
              <li key={url} className="truncate text-[11px] text-indigo-300">
                {url}
              </li>
            ))}
          </ul>
        </section>

        <section className="mb-5">
          <h3 className="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-500">
            Internal notes
          </h3>
          {complaint.notes.length === 0 && (
            <p className="text-[11px] text-zinc-600">No internal notes yet.</p>
          )}
          <ul className="space-y-1">
            {complaint.notes.map((note, index) => (
              <li key={index} className="rounded bg-white/[.03] p-2 text-[11px] text-zinc-300">
                {note}
              </li>
            ))}
          </ul>
        </section>

        <section>
          <h3 className="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-500">
            Timeline / audit log
          </h3>
          {(!complaint.history || complaint.history.length === 0) && (
            <p className="text-[11px] text-zinc-600">
              {complaint.environment === "production"
                ? "No history trail is recorded for real (bridged) complaints yet - only status is read from the real document."
                : "No history events recorded yet."}
            </p>
          )}
          <ol className="space-y-2 border-l border-white/10 pl-3">
            {(complaint.history ?? [])
              .slice()
              .reverse()
              .map((event, index) => (
                <li key={index} className="text-[11px]">
                  <p className="text-zinc-300">{event.action}</p>
                  <p className="text-zinc-600">{event.detail}</p>
                  <p className="text-[10px] text-zinc-700">{new Date(event.at).toLocaleString()}</p>
                </li>
              ))}
          </ol>
        </section>
      </div>
    </div>
  );
}
