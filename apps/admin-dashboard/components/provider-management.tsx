"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import {
  ChevronLeft,
  ChevronRight,
  Download,
  FileCheck2,
  Filter,
  MapPin,
  Plus,
  Search,
  Star,
  Users,
  WalletCards,
  X,
} from "lucide-react";
import type {
  AuditLog,
  Complaint,
  Job,
  Provider,
  Service,
  Transaction,
} from "@/lib/types";
import { useAdminData } from "@/components/admin-data-provider";
import {
  ConfirmDialog,
  FormDialog,
  RowActions,
} from "@/components/functional-dialogs";
import { ProviderVerificationCenter } from "@/components/provider-verification-center";
import { ProviderResultCard } from "@/components/provider-search-picker";
import { SearchableSelect } from "@/components/searchable-select";
import { emptyProviderFilters, filterProviders } from "@/lib/provider-search";
import { verificationSummary } from "@/lib/provider-verification";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 8;

export function ProviderManagement({
  notify,
  openProviderId,
  onProviderOpened,
}: {
  notify: (message: string) => void;
  openProviderId?: string | null;
  onProviderOpened?: () => void;
}) {
  const { db, actions } = useAdminData();
  const [query, setQuery] = useState("");
  const [filters, setFilters] = useState(emptyProviderFilters);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [selected, setSelected] = useState<string[]>([]);
  const [page, setPage] = useState(1);
  const [view, setView] = useState<"table" | "cards">("table");
  const [profile, setProfile] = useState<Provider | null>(null);
  const [verification, setVerification] = useState<Provider | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [edit, setEdit] = useState<Provider | null>(null);
  const [deleting, setDeleting] = useState<Provider | null>(null);
  const [bulk, setBulk] = useState<"service" | "city" | "delete" | null>(null);
  useEffect(() => {
    if (!openProviderId) return;
    const provider = db.providers.find(
      (item) =>
        item.id === openProviderId || item.providerId === openProviderId,
    );
    if (provider) setProfile(provider);
    onProviderOpened?.();
  }, [db.providers, onProviderOpened, openProviderId]);
  const filtered = useMemo(
    () =>
      filterProviders(db.providers, query, filters, db.services, db.complaints),
    [db, filters, query],
  );
  const pages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const visible = filtered.slice(
    (Math.min(page, pages) - 1) * PAGE_SIZE,
    Math.min(page, pages) * PAGE_SIZE,
  );
  const cities = [
    ...new Set(db.providers.flatMap((provider) => provider.cities)),
  ].sort();
  const areas = [
    ...new Set(db.providers.flatMap((provider) => provider.areas)),
  ].sort();
  const updateFilter = (key: keyof typeof filters, value: string | boolean) => {
    setFilters((current) => ({ ...current, [key]: value }));
    setPage(1);
  };
  const toggle = (id: string) =>
    setSelected((current) =>
      current.includes(id)
        ? current.filter((item) => item !== id)
        : [...current, id],
    );
  const eachSelected = async (fn: (provider: Provider) => Promise<unknown>) => {
    await Promise.all(
      db.providers.filter((provider) => selected.includes(provider.id)).map(fn),
    );
    setSelected([]);
  };
  const bulkAction = async (action: string) => {
    if (!selected.length) return notify("Select at least one provider");
    if (action === "approve")
      await eachSelected((provider) =>
        verificationSummary(provider).eligible
          ? actions.setProviderDecision(provider.id, "approve")
          : Promise.resolve(),
      );
    if (action === "suspend")
      await eachSelected((provider) =>
        provider.status === "Disabled" || provider.disabled
          ? Promise.resolve()
          : actions.toggleProvider(provider.id),
      );
    if (action === "activate")
      await eachSelected((provider) =>
        provider.status === "Disabled" || provider.disabled
          ? actions.toggleProvider(provider.id)
          : actions.setProviderDecision(provider.id, "approve"),
      );
    if (action === "notify") {
      await actions.createNotification({
        title: `Provider account update · ${selected.length} recipients`,
        body: "Please review the latest update in your Task Provider app.",
        audience: "All providers",
        // Bounded to the admin's actual selection, not every provider in the
        // system - see notification-fanout.ts for why unbounded broadcast
        // audiences are refused against real data.
        targetUserIds: selected,
      });
      setSelected([]);
    }
    notify(`${action[0].toUpperCase()}${action.slice(1)} action completed`);
  };
  const exportProviders = () => {
    const rows = selected.length
      ? db.providers.filter((item) => selected.includes(item.id))
      : filtered;
    const csv = [
      "Provider ID,Name,Phone,Email,Status,Rating,Jobs,City,Areas",
      ...rows.map((p) =>
        [
          p.providerId,
          p.name,
          p.phone,
          p.email,
          p.status,
          p.rating,
          p.jobs,
          p.cities.join(";"),
          p.areas.join(";"),
        ]
          .map((v) => `"${String(v).replaceAll('"', '""')}"`)
          .join(","),
      ),
    ].join("\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "task-providers.csv";
    anchor.click();
    URL.revokeObjectURL(url);
    notify("Provider export downloaded");
  };
  return (
    <div className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Summary
          label="Total providers"
          value={db.providers.length}
          icon={Users}
        />
        <Summary
          label="Online now"
          value={db.providers.filter((p) => p.available).length}
          icon={MapPin}
          tone="emerald"
        />
        <Summary
          label="Pending verification"
          value={
            db.providers.filter((p) => !verificationSummary(p).eligible).length
          }
          icon={FileCheck2}
          tone="amber"
        />
        <Summary
          label="Monthly earnings"
          value={`EGP ${db.providers.reduce((sum, p) => sum + p.earnings, 0).toLocaleString()}`}
          icon={WalletCards}
          tone="indigo"
        />
      </div>
      <div className="panel overflow-hidden">
        <div className="border-b border-white/[.07] p-4">
          <div className="flex flex-col gap-3 xl:flex-row xl:items-center">
            <div className="flex min-w-0 flex-1 items-center gap-3 rounded-xl border border-white/[.09] bg-white/[.025] px-3">
              <Search className="h-4 w-4 text-zinc-500" />
              <input
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setPage(1);
                }}
                placeholder="Search ID, name, 0109, email, national ID, skill, service, area or city…"
                className="h-11 flex-1 bg-transparent text-xs outline-none"
              />
            </div>
            <button
              onClick={() => setFiltersOpen(!filtersOpen)}
              className={cn(
                "btn-secondary",
                filtersOpen && "border-indigo-400/40 text-indigo-300",
              )}
            >
              <Filter className="h-3.5 w-3.5" /> Filters
            </button>
            <button
              onClick={() => setView(view === "table" ? "cards" : "table")}
              className="btn-secondary"
            >
              {view === "table" ? "Result cards" : "Table view"}
            </button>
            <button onClick={exportProviders} className="btn-secondary">
              <Download className="h-3.5 w-3.5" /> Export
            </button>
            <button onClick={() => setCreateOpen(true)} className="btn-primary">
              <Plus className="h-3.5 w-3.5" /> Add provider
            </button>
          </div>
          {filtersOpen && (
            <div className="mt-4 grid gap-3 rounded-2xl border border-white/[.07] bg-black/10 p-4 sm:grid-cols-2 lg:grid-cols-4">
              <FilterSelect
                label="Presence"
                value={filters.presence}
                options={["All", "Online", "Offline", "Available", "Busy"]}
                onChange={(v) => updateFilter("presence", v)}
              />
              <FilterSelect
                label="Account"
                value={filters.account}
                options={[
                  "All",
                  "Active",
                  "Review",
                  "Rejected",
                  "Suspended",
                  "Disabled",
                  "Blocked",
                  "Banned",
                ]}
                onChange={(v) => updateFilter("account", v)}
              />
              <FilterSelect
                label="Verification"
                value={filters.verification}
                options={[
                  "All",
                  "Approved",
                  "Pending Verification",
                  "Rejected",
                ]}
                onChange={(v) => updateFilter("verification", v)}
              />
              <FilterSelect
                label="Minimum rating"
                value={filters.minRating}
                options={["0", "3", "4", "4.5", "4.8"]}
                onChange={(v) => updateFilter("minRating", v)}
              />
              <FilterSelect
                label="City"
                value={filters.city}
                options={["All", ...cities]}
                onChange={(v) => updateFilter("city", v)}
              />
              <FilterSelect
                label="Area"
                value={filters.area}
                options={["All", ...areas]}
                onChange={(v) => updateFilter("area", v)}
              />
              <FilterSelect
                label="Service"
                value={filters.service}
                options={["All", ...db.services.map((s) => s.id)]}
                labels={Object.fromEntries(
                  db.services.map((s) => [s.id, s.name]),
                )}
                onChange={(v) => updateFilter("service", v)}
              />
              <div className="flex flex-wrap items-end gap-3 pb-1">
                {(
                  [
                    ["hasComplaints", "Has complaints"],
                    ["expiredDocuments", "Expired docs"],
                    ["missingDocuments", "Missing docs"],
                  ] as const
                ).map(([key, label]) => (
                  <label
                    key={key}
                    className="flex items-center gap-2 text-[10px] text-zinc-400"
                  >
                    <input
                      type="checkbox"
                      checked={filters[key]}
                      onChange={(e) => updateFilter(key, e.target.checked)}
                    />
                    {label}
                  </label>
                ))}
              </div>
              <button
                onClick={() => setFilters(emptyProviderFilters)}
                className="text-left text-[10px] text-indigo-300"
              >
                Reset all filters
              </button>
            </div>
          )}
        </div>
        {selected.length > 0 && (
          <div className="flex flex-wrap items-center gap-2 border-b border-indigo-500/20 bg-indigo-500/[.06] px-4 py-3 text-[10px]">
            <strong className="mr-2 text-indigo-300">
              {selected.length} selected
            </strong>
            {[
              ["approve", "Approve"],
              ["suspend", "Suspend"],
              ["activate", "Activate"],
              ["notify", "Send notification"],
            ].map(([key, label]) => (
              <button
                key={key}
                onClick={() => bulkAction(key)}
                className="btn-secondary !h-8"
              >
                {label}
              </button>
            ))}
            <button
              onClick={() => setBulk("service")}
              className="btn-secondary !h-8"
            >
              Assign service
            </button>
            <button
              onClick={() => setBulk("city")}
              className="btn-secondary !h-8"
            >
              Assign city
            </button>
            <button onClick={exportProviders} className="btn-secondary !h-8">
              Export
            </button>
            <button
              onClick={() => setBulk("delete")}
              className="ml-auto rounded-lg px-3 py-2 text-red-400 hover:bg-red-500/10"
            >
              Delete · Super Admin
            </button>
          </div>
        )}
        {view === "cards" ? (
          <div className="grid gap-3 p-4 lg:grid-cols-2">
            {visible.map((provider) => (
              <ProviderResultCard
                key={provider.id}
                provider={provider}
                onClick={() => setProfile(provider)}
              />
            ))}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1050px]">
              <thead>
                <tr className="table-head">
                  <th>
                    <input
                      type="checkbox"
                      checked={
                        visible.length > 0 &&
                        visible.every((p) => selected.includes(p.id))
                      }
                      onChange={() =>
                        setSelected(
                          visible.every((p) => selected.includes(p.id))
                            ? selected.filter(
                                (id) => !visible.some((p) => p.id === id),
                              )
                            : [
                                ...new Set([
                                  ...selected,
                                  ...visible.map((p) => p.id),
                                ]),
                              ],
                        )
                      }
                    />
                  </th>
                  <th>Provider</th>
                  <th>Contact</th>
                  <th>Rating / jobs</th>
                  <th>Presence</th>
                  <th>Verification</th>
                  <th>Coverage</th>
                  <th>Last active</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {visible.map((p) => {
                  const summary = verificationSummary(p);
                  return (
                    <tr
                      key={p.id}
                      className="table-row cursor-pointer"
                      onDoubleClick={() => setProfile(p)}
                    >
                      <td>
                        <input
                          type="checkbox"
                          checked={selected.includes(p.id)}
                          onChange={() => toggle(p.id)}
                        />
                      </td>
                      <td onClick={() => setProfile(p)}>
                        <div className="font-medium">{p.name}</div>
                        <div className="mt-1 font-mono text-[9px] text-indigo-300">
                          {p.providerId}
                        </div>
                        <div className="text-[9px] text-zinc-600">
                          {p.trade}
                        </div>
                      </td>
                      <td>
                        <div>{p.phone}</div>
                        <div className="text-[9px] text-zinc-600">
                          {p.email}
                        </div>
                      </td>
                      <td>
                        <div className="flex items-center gap-1">
                          <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
                          {p.rating || "—"}
                        </div>
                        <div className="text-[9px] text-zinc-600">
                          {p.jobs} jobs · {p.acceptanceRate}% accepted
                        </div>
                      </td>
                      <td>
                        <span
                          className={
                            p.available ? "text-emerald-400" : "text-zinc-500"
                          }
                        >
                          ● {p.available ? "Online · Available" : "Offline"}
                        </span>
                      </td>
                      <td>
                        <button
                          onClick={() => setVerification(p)}
                          className={
                            summary.eligible
                              ? "text-emerald-400"
                              : summary.rejected.length
                                ? "text-red-400"
                                : "text-amber-400"
                          }
                        >
                          {summary.eligible
                            ? "Verified"
                            : summary.rejected.length
                              ? "Rejected"
                              : `${summary.percentage}% complete`}
                        </button>
                      </td>
                      <td>
                        {p.cities.join(", ")}
                        <div className="text-[9px] text-zinc-600">
                          {p.areas.join(", ")}
                        </div>
                      </td>
                      <td>{p.lastActive}</td>
                      <td>
                        <RowActions
                          label={`Actions for ${p.name}`}
                          actions={[
                            {
                              label: "Open complete profile",
                              onClick: () => setProfile(p),
                            },
                            {
                              label: "Documents & verification",
                              onClick: () => setVerification(p),
                            },
                            {
                              label: "Edit provider",
                              onClick: () => setEdit(p),
                            },
                            {
                              label: p.available
                                ? "Set unavailable"
                                : "Set available",
                              onClick: () =>
                                actions.updateProvider(p.id, {
                                  available: !p.available,
                                }),
                            },
                            {
                              label:
                                p.status === "Disabled" || p.disabled
                                  ? "Enable provider"
                                  : "Disable provider",
                              onClick: () => actions.toggleProvider(p.id),
                              separator: true,
                            },
                            {
                              label: "Ban",
                              onClick: () =>
                                actions.setProviderDecision(p.id, "ban"),
                              danger: true,
                            },
                            {
                              label: "Delete",
                              onClick: () => setDeleting(p),
                              danger: true,
                            },
                          ]}
                        />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {!visible.length && (
              <div className="py-16 text-center text-xs text-zinc-500">
                No providers match the current search and filters.
              </div>
            )}
          </div>
        )}
        <div className="flex items-center justify-between border-t border-white/[.07] px-4 py-3 text-[10px] text-zinc-500">
          <span>
            {filtered.length} results · page {Math.min(page, pages)} of {pages}
          </span>
          <div className="flex gap-2">
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              className="icon-btn disabled:opacity-30"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <button
              disabled={page >= pages}
              onClick={() => setPage((p) => Math.min(pages, p + 1))}
              className="icon-btn disabled:opacity-30"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Create provider"
        description="A permanent Provider ID is generated automatically and can never be changed or reused."
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "email", label: "Email", type: "email", required: true },
          {
            name: "phone",
            label: "Mobile number",
            type: "tel",
            required: true,
          },
          { name: "nationalIdNumber", label: "National ID", required: true },
          { name: "trade", label: "Primary skill / trade", required: true },
          { name: "city", label: "City", required: true },
          { name: "areas", label: "Areas (comma separated)", required: true },
        ]}
        submitLabel="Create provider"
        onSubmit={async (v) => {
          const item = await actions.createProvider({
            name: v.name,
            email: v.email,
            phone: v.phone,
            nationalIdNumber: v.nationalIdNumber,
            trade: v.trade,
            cities: [v.city],
            areas: v.areas
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
          });
          notify(`${item.providerId} created permanently`);
          setProfile(item);
        }}
      />
      <FormDialog
        open={!!edit}
        onClose={() => setEdit(null)}
        title="Edit provider"
        description={
          edit ? `Permanent ID ${edit.providerId} is immutable.` : ""
        }
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "phone", label: "Phone", required: true },
          { name: "email", label: "Email", type: "email", required: true },
          { name: "trade", label: "Skill", required: true },
          {
            name: "commission",
            label: "Commission %",
            type: "number",
            required: true,
            min: 0,
          },
          { name: "cities", label: "Cities", required: true },
          { name: "areas", label: "Areas", required: true },
        ]}
        initial={
          edit
            ? {
                name: edit.name,
                phone: edit.phone,
                email: edit.email,
                trade: edit.trade,
                commission: edit.commission,
                cities: edit.cities.join(", "),
                areas: edit.areas.join(", "),
              }
            : {}
        }
        onSubmit={(v) =>
          edit &&
          actions.updateProvider(edit.id, {
            name: v.name,
            phone: v.phone,
            email: v.email,
            trade: v.trade,
            commission: Number(v.commission),
            cities: v.cities
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
            areas: v.areas
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
          })
        }
      />
      <FormDialog
        open={bulk === "service"}
        onClose={() => setBulk(null)}
        title="Assign service to selected providers"
        fields={[
          {
            name: "serviceId",
            label: "Service",
            type: "select",
            required: true,
            options: db.services.map((s) => ({ label: s.name, value: s.id })),
          },
        ]}
        onSubmit={async (v) => {
          await eachSelected((p) =>
            actions.updateProvider(p.id, {
              serviceIds: [...new Set([...p.serviceIds, v.serviceId])],
            }),
          );
          notify("Service assigned");
        }}
      />
      <FormDialog
        open={bulk === "city"}
        onClose={() => setBulk(null)}
        title="Assign city to selected providers"
        fields={[{ name: "city", label: "City", required: true }]}
        onSubmit={async (v) => {
          await eachSelected((p) =>
            actions.updateProvider(p.id, {
              cities: [...new Set([...p.cities, v.city])],
            }),
          );
          notify("City assigned");
        }}
      />
      <ConfirmDialog
        open={bulk === "delete"}
        onClose={() => setBulk(null)}
        title="Delete selected providers?"
        description="Super Admin bulk deletion is audited. Permanent Provider IDs remain reserved and will never be reused."
        onConfirm={async () => {
          await eachSelected((p) => actions.deleteProvider(p.id));
          notify("Selected providers deleted from Firestore; IDs remain reserved");
        }}
      />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete provider?"
        description={`This removes the provider record. ${deleting?.providerId ?? "The ID"} remains permanently reserved.`}
        onConfirm={() => deleting && actions.deleteProvider(deleting.id)}
      />
      {profile && (
        <ProviderProfile
          providerId={profile.id}
          close={() => setProfile(null)}
          openVerification={(p) => setVerification(p)}
          notify={notify}
        />
      )}
      {verification && (
        <ProviderVerificationCenter
          providerId={verification.id}
          close={() => setVerification(null)}
          notify={notify}
        />
      )}
    </div>
  );
}

function Summary({
  label,
  value,
  icon: Icon,
  tone = "zinc",
}: {
  label: string;
  value: string | number;
  icon: typeof Users;
  tone?: string;
}) {
  return (
    <div className="panel p-4">
      <div className="flex items-center justify-between">
        <span className="text-[10px] text-zinc-500">{label}</span>
        <Icon
          className={cn(
            "h-4 w-4",
            tone === "emerald"
              ? "text-emerald-400"
              : tone === "amber"
                ? "text-amber-400"
                : tone === "indigo"
                  ? "text-indigo-400"
                  : "text-zinc-400",
          )}
        />
      </div>
      <div className="mt-3 text-xl font-semibold">{value}</div>
    </div>
  );
}
function FilterSelect({
  label,
  value,
  options,
  labels,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  labels?: Record<string, string>;
  onChange: (value: string) => void;
}) {
  return (
    <label className="block text-[9px] text-zinc-600">
      {label}
      <SearchableSelect
        className="mt-1 w-full"
        value={value}
        onChange={onChange}
        allowEmpty={false}
        options={options.map((option) => ({
          label: labels?.[option] ?? option,
          value: option,
        }))}
      />
    </label>
  );
}

const profileTabs = [
  "General",
  "Verification",
  "Documents",
  "Wallet",
  "Transactions",
  "Jobs",
  "Reviews",
  "Complaints",
  "Timeline",
  "Availability",
  "Areas & services",
  "Commission",
  "Bank / Instapay",
  "Performance",
  "Audit logs",
  "Notes",
];
function ProviderProfile({
  providerId,
  close,
  openVerification,
  notify,
}: {
  providerId: string;
  close: () => void;
  openVerification: (provider: Provider) => void;
  notify: (message: string) => void;
}) {
  const { db, actions } = useAdminData();
  const provider = db.providers.find((p) => p.id === providerId);
  const [tab, setTab] = useState("General");
  const [note, setNote] = useState("");
  if (!provider) return null;
  const summary = verificationSummary(provider);
  const jobs = db.jobs.filter(
    (j) =>
      j.providerId === provider.id ||
      j.offers?.some((offer) => offer.providerId === provider.id),
  );
  const complaints = db.complaints.filter((c) => c.providerId === provider.id);
  const transactions = db.transactions.filter(
    (t) => t.ownerId === provider.id || t.party === provider.name,
  );
  const audits = db.auditLogs.filter(
    (a) =>
      a.entityId === provider.id ||
      a.detail.includes(provider.name) ||
      a.detail.includes(provider.providerId),
  );
  const saveNote = () => {
    if (!note.trim()) return;
    actions.updateProvider(provider.id, {
      notes: [note.trim(), ...provider.notes],
    });
    setNote("");
    notify("Internal provider note saved");
  };
  return (
    <div className="fixed inset-0 z-[100] overflow-y-auto bg-black/75 backdrop-blur-md">
      <div className="ml-auto min-h-full w-full max-w-5xl border-l border-white/[.08] bg-[#101013] p-5 shadow-2xl">
        <div className="flex items-start gap-4 border-b border-white/[.07] pb-5">
          <div className="grid h-14 w-14 place-items-center rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-700 text-sm font-semibold">
            {provider.initials}
          </div>
          <div className="flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-lg font-semibold">{provider.name}</h2>
              <span className="rounded-md bg-indigo-500/10 px-2 py-1 font-mono text-[10px] text-indigo-300">
                {provider.providerId}
              </span>
              <span
                className={
                  summary.eligible
                    ? "text-xs text-emerald-400"
                    : "text-xs text-amber-400"
                }
              >
                {summary.eligible
                  ? "✓ Verified"
                  : `${summary.percentage}% verified`}
              </span>
            </div>
            <p className="mt-1 text-xs text-zinc-500">
              {provider.trade} · {provider.phone} · {provider.email}
            </p>
          </div>
          <button onClick={close} className="icon-btn">
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="mt-4 flex gap-2 overflow-x-auto pb-2">
          {profileTabs.map((item) => (
            <button
              key={item}
              onClick={() => setTab(item)}
              className={cn(
                "whitespace-nowrap rounded-lg px-3 py-2 text-[10px]",
                tab === item
                  ? "bg-indigo-500 text-white"
                  : "bg-white/[.035] text-zinc-500 hover:text-zinc-200",
              )}
            >
              {item}
            </button>
          ))}
        </div>
        <div className="mt-4 rounded-2xl border border-white/[.07] bg-white/[.02] p-5">
          <ProfileContent
            tab={tab}
            provider={provider}
            jobs={jobs}
            complaints={complaints}
            transactions={transactions}
            audits={audits}
            services={db.services}
            openVerification={() => openVerification(provider)}
            actions={actions}
          />
        </div>
        {tab === "Notes" && (
          <div className="mt-4 flex gap-2">
            <input
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Add an operational note…"
              className="input flex-1"
            />
            <button onClick={saveNote} className="btn-primary">
              Save note
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

type ProfileContentProps = {
  tab: string;
  provider: Provider;
  jobs: Job[];
  complaints: Complaint[];
  transactions: Transaction[];
  audits: AuditLog[];
  services: Service[];
  openVerification: () => void;
  actions: ReturnType<typeof useAdminData>["actions"];
};
function ProfileContent({
  tab,
  provider,
  jobs,
  complaints,
  transactions,
  audits,
  services,
  openVerification,
  actions,
}: ProfileContentProps) {
  const rows = <T,>(
    items: T[],
    render: (item: T, index: number) => ReactNode,
  ) =>
    items.length ? (
      <div className="space-y-2">{items.map(render)}</div>
    ) : (
      <Empty label={`No ${tab.toLowerCase()} recorded`} />
    );
  const allRequests = jobs;
  const providerOffers = allRequests.flatMap((job) =>
    (job.offers ?? []).filter((offer) => offer.providerId === provider.id),
  );
  if (tab === "General")
    return (
      <div className="grid gap-4 sm:grid-cols-3">
        {[
          ["Permanent Provider ID", provider.providerId],
          ["National ID", provider.nationalIdNumber],
          ["Status", provider.status],
          ["Phone", provider.phone],
          ["Email", provider.email],
          ["Created", new Date(provider.createdAt).toLocaleString()],
          [
            "Last login",
            provider.lastLogin
              ? new Date(provider.lastLogin).toLocaleString()
              : "Never",
          ],
          ["Last active", provider.lastActive],
          ["Primary skill", provider.trade],
        ].map(([a, b]) => (
          <Info key={a} label={a} value={b} />
        ))}
      </div>
    );
  if (tab === "Verification" || tab === "Documents")
    return (
      <div>
        <div className="mb-5 grid gap-3 sm:grid-cols-4">
          <Info
            label="Progress"
            value={`${verificationSummary(provider).percentage}%`}
          />
          <Info label="Stage" value={provider.verification.stage} />
          <Info
            label="Officer"
            value={provider.verification.officerName || "Unassigned"}
          />
          <Info label="Documents" value={provider.documents.length} />
        </div>
        <button onClick={openVerification} className="btn-primary">
          Open Documents & Verification Center
        </button>
      </div>
    );
  if (tab === "Wallet")
    return (
      <div className="grid gap-4 sm:grid-cols-3">
        <Info
          label="Available earnings"
          value={`EGP ${provider.earnings.toLocaleString()}`}
        />
        <Info
          label="Payout method"
          value={
            provider.bankInfo.instapay ||
            provider.bankInfo.iban ||
            "Not configured"
          }
        />
        <Info label="Commission" value={`${provider.commission}%`} />
      </div>
    );
  if (tab === "Transactions")
    return rows(transactions, (t) => (
      <Line
        key={t.id}
        title={`${t.type} · EGP ${t.amount}`}
        meta={`${t.id} · ${t.status} · ${new Date(t.createdAt).toLocaleString()}`}
      />
    ));
  if (tab === "Jobs")
    return rows(jobs, (j) => (
      <Line
        key={j.id}
        title={`${j.id} · ${j.service}`}
        meta={`${j.status} · ${j.area} · EGP ${j.amount}`}
      />
    ));
  if (tab === "Reviews")
    return (
      <div className="grid gap-4 sm:grid-cols-3">
        <Info label="Average rating" value={`${provider.rating} / 5`} />
        <Info label="Completed jobs" value={provider.jobs} />
        <Info label="Acceptance rate" value={`${provider.acceptanceRate}%`} />
      </div>
    );
  if (tab === "Complaints")
    return rows(complaints, (c) => (
      <Line key={c.id} title={c.title} meta={`${c.severity} · ${c.status}`} />
    ));
  if (tab === "Timeline")
    return rows(provider.activityTimeline, (e) => (
      <Line
        key={e.id}
        title={e.label}
        meta={`${new Date(e.at).toLocaleString()} · ${e.actor}`}
      />
    ));
  if (tab === "Availability")
    return (
      <div className="space-y-3">
        <label className="flex items-center gap-3 text-xs">
          <input
            type="checkbox"
            checked={provider.available}
            onChange={(e) =>
              actions.updateProvider(provider.id, {
                available: e.target.checked,
              })
            }
          />
          Available for dispatch now
        </label>
        {Object.entries(provider.availabilitySchedule).map(([day, hours]) => (
          <Line key={day} title={day} meta={String(hours)} />
        ))}
      </div>
    );
  if (tab === "Areas & services")
    return (
      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <h3 className="mb-3 text-xs font-semibold">Assigned coverage</h3>
          {provider.cities.map((c) => (
            <span
              key={c}
              className="mr-2 rounded-lg bg-white/[.05] px-2 py-1 text-[10px]"
            >
              {c}
            </span>
          ))}
          {provider.areas.map((a) => (
            <span
              key={a}
              className="mr-2 rounded-lg bg-white/[.05] px-2 py-1 text-[10px]"
            >
              {a}
            </span>
          ))}
        </div>
        <div>
          <h3 className="mb-3 text-xs font-semibold">Supported services</h3>
          {services
            .filter((s) => provider.serviceIds.includes(s.id))
            .map((s) => (
              <span
                key={s.id}
                className="mr-2 rounded-lg bg-indigo-500/10 px-2 py-1 text-[10px] text-indigo-300"
              >
                {s.name}
              </span>
            ))}
        </div>
      </div>
    );
  if (tab === "Commission")
    return (
      <div className="max-w-sm">
        <Info label="Platform commission" value={`${provider.commission}%`} />
        <p className="mt-3 text-[10px] text-zinc-500">
          Edit commission from the provider row action. Every change is audited.
        </p>
      </div>
    );
  if (tab === "Bank / Instapay")
    return (
      <div className="grid gap-4 sm:grid-cols-3">
        <Info
          label="Bank"
          value={provider.bankInfo.bankName || "Not configured"}
        />
        <Info label="IBAN proof" value={provider.bankInfo.iban || "Missing"} />
        <Info
          label="Instapay"
          value={provider.bankInfo.instapay || "Missing"}
        />
      </div>
    );
  if (tab === "Performance")
    return (
      <div className="grid gap-4 sm:grid-cols-4">
        <Info label="Requests received" value={allRequests.length} />
        <Info label="Offers sent" value={providerOffers.length} />
        <Info
          label="Offers accepted"
          value={
            providerOffers.filter((offer) => offer.status === "Accepted").length
          }
        />
        <Info
          label="Offers rejected / expired"
          value={
            providerOffers.filter((offer) =>
              ["Rejected", "Expired", "Withdrawn"].includes(offer.status),
            ).length
          }
        />
        <Info
          label="Cancelled jobs"
          value={jobs.filter((job) => job.cancellation).length}
        />
        <Info
          label="Cancellation rate"
          value={`${jobs.length ? ((jobs.filter((job) => job.cancellation).length / jobs.length) * 100).toFixed(1) : 0}%`}
        />
        <Info
          label="Completion rate"
          value={`${jobs.length ? ((jobs.filter((job) => job.status === "Completed").length / jobs.length) * 100).toFixed(1) : 0}%`}
        />
        <Info label="Rating" value={provider.rating} />
        <Info
          label="Earnings"
          value={`EGP ${provider.earnings.toLocaleString()}`}
        />
        <Info label="Complaints" value={complaints.length} />
        <Info label="Response time" value={provider.response} />
      </div>
    );
  if (tab === "Audit logs")
    return rows(audits, (a) => (
      <Line
        key={a.id}
        title={a.action}
        meta={`${a.detail} · ${new Date(a.createdAt).toLocaleString()} · ${a.actorName}`}
      />
    ));
  return rows(provider.notes, (note, i) => (
    <Line key={`${note}-${i}`} title={note} meta="Internal note" />
  ));
}
function Info({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="rounded-xl border border-white/[.06] bg-black/10 p-3">
      <div className="text-[9px] uppercase tracking-wide text-zinc-600">
        {label}
      </div>
      <div className="mt-1 text-xs text-zinc-200">{value}</div>
    </div>
  );
}
function Line({ title, meta }: { title: string; meta: string }) {
  return (
    <div className="rounded-xl border border-white/[.06] p-3">
      <div className="text-xs">{title}</div>
      <div className="mt-1 text-[10px] text-zinc-600">{meta}</div>
    </div>
  );
}
function Empty({ label }: { label: string }) {
  return <div className="py-12 text-center text-xs text-zinc-600">{label}</div>;
}
