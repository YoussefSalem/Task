"use client";

import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, Search, X } from "lucide-react";
import type { Provider } from "@/lib/types";
import { useAdminData } from "@/components/admin-data-provider";
import { providerMatchesQuery } from "@/lib/provider-search";
import { isProviderEligible, verificationSummary } from "@/lib/provider-verification";
import { cn } from "@/lib/utils";

export function ProviderResultCard({ provider, active, onClick }: { provider: Provider; active?: boolean; onClick: () => void }) {
  const summary = verificationSummary(provider);
  return (
    <button onClick={onClick} className={cn("w-full rounded-2xl border p-4 text-left transition hover:border-indigo-400/40 hover:bg-white/[.04]", active ? "border-indigo-400/60 bg-indigo-500/[.08]" : "border-white/[.08] bg-white/[.025]")}>
      <div className="flex gap-3">
        <div className="grid h-11 w-11 shrink-0 place-items-center overflow-hidden rounded-xl bg-gradient-to-br from-indigo-500 to-violet-700 text-xs font-semibold text-white">
          {provider.photo ? <span aria-label={`${provider.name} photo`} className="h-full w-full bg-cover bg-center" style={{ backgroundImage: `url(${provider.photo})` }} /> : provider.initials}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm font-semibold">{provider.name}</span>
            <span className="rounded-md bg-indigo-500/10 px-2 py-0.5 font-mono text-[9px] text-indigo-300">{provider.providerId}</span>
            <span className={cn("h-2 w-2 rounded-full", provider.available ? "bg-emerald-400 shadow-[0_0_8px_#34d399]" : "bg-zinc-600")} />
          </div>
          <div className="mt-1 truncate text-[10px] text-zinc-500">{provider.phone} · {provider.email}</div>
          <div className="mt-3 grid grid-cols-3 gap-2 text-[10px] sm:grid-cols-6">
            <Metric label="Rating" value={`${provider.rating || "—"} ★`} />
            <Metric label="Jobs" value={provider.jobs} />
            <Metric label="Acceptance" value={`${provider.acceptanceRate}%`} />
            <Metric label="Presence" value={provider.available ? "Online" : "Offline"} />
            <Metric label="Availability" value={provider.available && provider.status === "Active" ? "Available" : provider.status} />
            <Metric label="Distance" value="Realtime ready" />
          </div>
          <div className="mt-3 flex items-center justify-between text-[10px]">
            <span className={summary.eligible ? "text-emerald-400" : summary.rejected.length ? "text-red-400" : "text-amber-400"}>
              {summary.eligible && <CheckCircle2 className="mr-1 inline h-3 w-3" />}{summary.eligible ? "Verified" : summary.rejected.length ? "Rejected" : `${summary.percentage}% verified`}
            </span>
            <span className="text-zinc-600">Last active {provider.lastActive}</span>
          </div>
        </div>
      </div>
    </button>
  );
}

function Metric({ label, value }: { label: string; value: string | number }) {
  return <div><div className="text-zinc-600">{label}</div><div className="mt-0.5 truncate text-zinc-300">{value}</div></div>;
}

export function ProviderSearchPicker({ open, close, onSelect, allowIneligible = false, title = "Find and assign provider" }: { open: boolean; close: () => void; onSelect: (provider: Provider, override: boolean) => void; allowIneligible?: boolean; title?: string }) {
  const { db } = useAdminData();
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(0);
  const [showIneligible, setShowIneligible] = useState(false);
  const results = useMemo(() => db.providers.filter((provider) => providerMatchesQuery(provider, query, db.services)).filter((provider) => showIneligible || isProviderEligible(provider)).slice(0, 20), [db.providers, db.services, query, showIneligible]);
  useEffect(() => setActive(0), [query, showIneligible]);
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-[110] flex items-start justify-center overflow-y-auto bg-black/70 p-4 pt-[7vh] backdrop-blur-md" onMouseDown={close}>
      <div className="w-full max-w-3xl rounded-3xl border border-white/[.1] bg-[#111114] shadow-2xl" onMouseDown={(event) => event.stopPropagation()}>
        <div className="flex items-center justify-between border-b border-white/[.07] p-5"><div><h3 className="text-sm font-semibold">{title}</h3><p className="mt-1 text-[10px] text-zinc-500">Search by permanent ID, name, phone, email, national ID, trade, service, city or area.</p></div><button onClick={close} className="icon-btn"><X className="h-4 w-4" /></button></div>
        <div className="p-5">
          <div className="flex items-center gap-3 rounded-xl border border-white/[.09] bg-white/[.03] px-3"><Search className="h-4 w-4 text-zinc-500" /><input autoFocus value={query} onChange={(e) => setQuery(e.target.value)} onKeyDown={(e) => { if (e.key === "ArrowDown") { e.preventDefault(); setActive((i) => Math.min(i + 1, results.length - 1)); } if (e.key === "ArrowUp") { e.preventDefault(); setActive((i) => Math.max(i - 1, 0)); } if (e.key === "Enter" && results[active]) onSelect(results[active], !isProviderEligible(results[active])); if (e.key === "Escape") close(); }} placeholder="Search provider ID, phone, name, email, service, skill, area, city, rating or status" className="h-12 flex-1 bg-transparent text-sm outline-none" /></div>
          {allowIneligible && <label className="mt-3 flex cursor-pointer items-center gap-2 text-[10px] text-amber-400"><input type="checkbox" checked={showIneligible} onChange={(e) => setShowIneligible(e.target.checked)} /> Super Admin override: include unverified or blocked providers</label>}
          <div className="mt-4 max-h-[58vh] space-y-2 overflow-y-auto pr-1">{results.length ? results.map((provider, index) => <ProviderResultCard key={provider.id} provider={provider} active={index === active} onClick={() => onSelect(provider, !isProviderEligible(provider))} />) : <div className="rounded-2xl border border-dashed border-white/[.1] py-14 text-center text-xs text-zinc-500">No providers match this search.</div>}</div>
        </div>
      </div>
    </div>
  );
}
