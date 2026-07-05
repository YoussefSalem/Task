"use client";
import { useState } from "react";
import {
  AlertTriangle,
  FileImage,
  MessageSquare,
  WalletCards,
  X,
} from "lucide-react";
import { useAdminData } from "@/components/admin-data-provider";
import { RequestControlCenter } from "@/components/request-control-center";
import type { Job } from "@/lib/types";

export function CustomerHistoryDrawer({
  customerId,
  close,
  notify,
}: {
  customerId: string;
  close: () => void;
  notify: (message: string) => void;
}) {
  const { db, actions } = useAdminData();
  const customer = db.customers.find((item) => item.id === customerId);
  const [request, setRequest] = useState<Job | null>(null);
  if (!customer) return null;
  const jobs = db.jobs.filter((item) => item.customerId === customer.id);
  const cancelled = jobs.filter(
    (item) => item.cancellation || item.status === "Cancelled",
  );
  const completed = jobs.filter((item) => item.status === "Completed");
  const pending = jobs.filter(
    (item) => !["Completed", "Cancelled", "Refunded"].includes(item.status),
  );
  const complaints = db.complaints.filter(
    (item) => item.customerId === customer.id,
  );
  const transactions = db.transactions.filter(
    (item) => item.ownerId === customer.id,
  );
  const wallet = db.wallets.find((item) => item.ownerId === customer.id);
  const media = jobs.flatMap((item) => item.media ?? []);
  const offers = jobs.flatMap((item) => item.offers ?? []);
  return (
    <>
      <div
        className="fixed inset-0 z-[90] bg-black/70 backdrop-blur-sm"
        onMouseDown={close}
      >
        <aside
          className="ml-auto h-full w-full max-w-4xl overflow-y-auto border-l border-white/[.08] bg-[#101013] p-5"
          onMouseDown={(e) => e.stopPropagation()}
        >
          <div className="flex items-start">
            <div className="flex-1">
              <h2 className="text-lg font-semibold">{customer.name}</h2>
              <p className="mt-1 text-[10px] text-zinc-500">
                {customer.id} · {customer.phone} · {customer.email}
              </p>
            </div>
            <button onClick={close} className="icon-btn">
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="mt-5 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
            {[
              ["All requests", jobs.length],
              ["Completed", completed.length],
              ["Cancelled", cancelled.length],
              ["Pending", pending.length],
              ["Offers received", offers.length],
              ["Complaints", complaints.length],
            ].map(([a, b]) => (
              <div key={a} className="rounded-xl border border-white/[.06] p-3">
                <div className="text-[9px] text-zinc-600">{a}</div>
                <div className="mt-1 text-lg font-semibold">{b}</div>
              </div>
            ))}
          </div>
          <section className="mt-5 rounded-2xl border border-white/[.07] p-4">
            <div className="flex items-center gap-2">
              <WalletCards className="h-4 w-4 text-indigo-400" />
              <h3 className="text-xs font-semibold">App wallet</h3>
              <span className="ml-auto text-lg font-semibold">
                EGP {wallet?.balance.toLocaleString() ?? 0}
              </span>
            </div>
            <div className="mt-3 grid gap-2 sm:grid-cols-4 text-[10px] text-zinc-500">
              <span>
                Total added: EGP{" "}
                {transactions
                  .filter((t) => t.type === "Wallet credit")
                  .reduce((n, t) => n + t.amount, 0)}
              </span>
              <span>
                Total spent: EGP{" "}
                {transactions
                  .filter((t) => t.type === "Wallet debit")
                  .reduce((n, t) => n + t.amount, 0)}
              </span>
              <span>
                Total refunded: EGP{" "}
                {transactions
                  .filter((t) => t.type === "Customer refund")
                  .reduce((n, t) => n + t.amount, 0)}
              </span>
              <span>Promo credit: EGP {wallet?.promoCredit ?? 0}</span>
            </div>
            <div className="mt-3 flex gap-2">
              <button
                onClick={() => {
                  actions.setWalletFrozen(
                    customer.id,
                    !wallet?.frozen,
                    "Customer history wallet control",
                  );
                  notify(wallet?.frozen ? "Wallet unfrozen" : "Wallet frozen");
                }}
                className="btn-secondary"
              >
                {wallet?.frozen ? "Unfreeze wallet" : "Freeze wallet"}
              </button>
            </div>
          </section>
          <section className="mt-5">
            <h3 className="mb-3 text-xs font-semibold">
              Complete request history
            </h3>
            <div className="space-y-2">
              {jobs.map((job) => (
                <button
                  key={job.id}
                  onClick={() => setRequest(job)}
                  className="flex w-full items-center gap-3 rounded-xl border border-white/[.06] p-3 text-left hover:bg-white/[.03]"
                >
                  <span className="flex-1">
                    <b className="text-xs">
                      {job.id} · {job.service}
                    </b>
                    <span className="mt-1 block text-[9px] text-zinc-600">
                      {job.status} · {job.area} · {job.offers?.length ?? 0}{" "}
                      offers · {job.media?.length ?? 0} media ·{" "}
                      {job.messages?.length ?? 0} messages
                    </span>
                  </span>
                  <span className="text-[10px] text-zinc-400">
                    EGP {job.amount}
                  </span>
                </button>
              ))}
            </div>
          </section>
          <div className="mt-5 grid gap-4 lg:grid-cols-2">
            <History
              title="Refunds & wallet transactions"
              icon={WalletCards}
              rows={transactions.map(
                (t) => `${t.id} · ${t.type} · EGP ${t.amount} · ${t.status}`,
              )}
            />
            <History
              title="Uploaded media"
              icon={FileImage}
              rows={media.map((m) => `${m.id} · ${m.fileName} · ${m.jobId}`)}
            />
            <History
              title="Complaints"
              icon={AlertTriangle}
              rows={complaints.map((c) => `${c.id} · ${c.title} · ${c.status}`)}
            />
            <History
              title="Support & follow-up"
              icon={MessageSquare}
              rows={[
                ...jobs.flatMap((j) => j.notes.map((n) => `${j.id} · ${n}`)),
                ...cancelled.flatMap(
                  (j) =>
                    j.cancellation?.followUpNotes.map(
                      (n) => `${j.id} · ${n}`,
                    ) ?? [],
                ),
              ]}
            />
          </div>
        </aside>
      </div>
      {request && (
        <RequestControlCenter
          job={request}
          close={() => setRequest(null)}
          notify={notify}
        />
      )}
    </>
  );
}
function History({
  title,
  icon: Icon,
  rows,
}: {
  title: string;
  icon: typeof WalletCards;
  rows: string[];
}) {
  return (
    <section className="rounded-2xl border border-white/[.07] p-4">
      <div className="flex items-center gap-2">
        <Icon className="h-4 w-4 text-indigo-400" />
        <h3 className="text-xs font-semibold">{title}</h3>
      </div>
      <div className="mt-3 space-y-2">
        {rows.length ? (
          rows.map((row, i) => (
            <div
              key={`${row}-${i}`}
              className="rounded-lg bg-white/[.025] p-2 text-[10px] text-zinc-500"
            >
              {row}
            </div>
          ))
        ) : (
          <div className="py-5 text-center text-[10px] text-zinc-700">
            No history
          </div>
        )}
      </div>
    </section>
  );
}
