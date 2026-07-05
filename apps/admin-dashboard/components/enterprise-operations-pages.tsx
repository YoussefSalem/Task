"use client";

import { useState } from "react";
import type React from "react";
import {
  Activity,
  AlertTriangle,
  Banknote,
  Bell,
  Bot,
  CalendarClock,
  CheckCircle2,
  Clock3,
  Download,
  FileText,
  Radio,
  RefreshCcw,
  Search,
  ShieldAlert,
  Star,
  TrendingUp,
  UserCog,
  Users,
  WalletCards,
  Wrench,
  Zap,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { LiveOperationsMap } from "@/components/live-operations-map";
import { SearchableSelect } from "@/components/searchable-select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useAdminData } from "@/components/admin-data-provider";
import { usePermissions } from "@/components/use-permissions";
import type { Customer, DatabaseState, Job, Provider } from "@/lib/types";
import { cn } from "@/lib/utils";

type EnterprisePage =
  | "Command Center"
  | "Live Operations Map"
  | "Smart Alerts"
  | "Customer Intelligence"
  | "Booking Control Center"
  | "SLA Monitoring"
  | "Financial Control Center"
  | "Fraud & Risk Center"
  | "Quality Control Center"
  | "Automation Rules"
  | "Notification Center"
  | "Reports Center"
  | "Activity Timeline"
  | "System Health"
  | "Advanced Search";

type EnterpriseProps = {
  page: EnterprisePage;
  openJob: (job: Job) => void;
  notify: (message: string) => void;
  navigate?: (section: string) => void;
};

const activeStatuses = new Set(["Scheduled", "Assigned", "En route", "In progress", "Delayed"]);

function isActiveJob(job: Job) {
  return activeStatuses.has(job.status);
}

function minutesSince(value?: string) {
  if (!value) return 0;
  const time = new Date(value).getTime();
  if (!Number.isFinite(time)) return 0;
  return Math.max(0, Math.round((Date.now() - time) / 60000));
}

function bookingType(job: Job) {
  return job.bookingType ?? (job.priority === "Emergency" ? "Emergency" : "Scheduled");
}

function isDelayed(job: Job) {
  if (job.status === "Delayed" || job.slaBreached) return true;
  const elapsed = minutesSince(job.createdAt);
  const sla = job.responseSlaMinutes ?? (bookingType(job) === "Emergency" ? 10 : 45);
  return isActiveJob(job) && !job.providerId && elapsed > sla;
}

function revenue(db: DatabaseState) {
  return db.jobs.reduce((sum, job) => sum + (job.payment?.status === "Paid" ? job.payment.amount : 0), 0);
}

function todayRevenue(db: DatabaseState) {
  const today = new Date().toDateString();
  return db.jobs.reduce((sum, job) => {
    const paidToday = job.payment?.paidAt
      ? new Date(job.payment.paidAt).toDateString() === today
      : new Date(job.createdAt).toDateString() === today;
    return sum + (job.payment?.status === "Paid" && paidToday ? job.payment.amount : 0);
  }, 0);
}

function riskScoreProvider(provider: Provider, db: DatabaseState) {
  const assigned = db.jobs.filter((job) => job.providerId === provider.id);
  const cancelled = assigned.filter((job) => job.status === "Cancelled" || job.cancellation).length;
  const complaints = db.complaints.filter((caseItem) => caseItem.providerId === provider.id && caseItem.status !== "Closed").length;
  const warnings = provider.performanceWarnings?.filter((warning) => warning.status === "Open").length ?? 0;
  const lowAcceptance = provider.acceptanceRate < 45 ? 25 : 0;
  const lowRating = provider.rating < 3 ? 30 : provider.rating < 4 ? 15 : 0;
  const inactive = minutesSince(provider.lastActive) > 7 * 24 * 60 ? 15 : 0;
  return Math.min(100, lowAcceptance + lowRating + complaints * 15 + warnings * 10 + cancelled * 7 + inactive);
}

function customerIntelligence(customer: Customer, db: DatabaseState) {
  const jobs = db.jobs.filter((job) => job.customerId === customer.id);
  const cancelled = jobs.filter((job) => job.status === "Cancelled" || job.cancellation);
  const complaints = db.complaints.filter((item) => item.customerId === customer.id);
  const serviceCounts = jobs.reduce<Record<string, number>>((acc, job) => {
    acc[job.service] = (acc[job.service] ?? 0) + 1;
    return acc;
  }, {});
  const favoriteServices = Object.entries(serviceCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([name]) => name);
  const cancellationRate = jobs.length ? cancelled.length / jobs.length : 0;
  const riskLevel = complaints.length >= 3 || cancellationRate > 0.4 ? "High" : complaints.length || cancellationRate > 0.2 ? "Medium" : "Low";
  return { jobs, cancelled, complaints, favoriteServices, cancellationRate, riskLevel };
}

function smartAlerts(db: DatabaseState) {
  const alerts = [
    ...db.jobs.filter(isDelayed).map((job) => ({ id: `delay-${job.id}`, severity: bookingType(job) === "Emergency" ? "Critical" : "High", title: "Delayed technician / SLA risk", body: `${job.id} · ${job.service} · ${job.area}`, entity: job.id })),
    ...db.jobs.filter((job) => isActiveJob(job) && !job.providerId && minutesSince(job.createdAt) > 20).map((job) => ({ id: `ignored-${job.id}`, severity: "High", title: "Ignored booking", body: `${job.providersReceived ?? 0} providers received · ${job.providersOpened ?? 0} opened`, entity: job.id })),
    ...db.providers.filter((provider) => provider.acceptanceRate < 45).map((provider) => ({ id: `acceptance-${provider.id}`, severity: "Medium", title: "Low technician acceptance", body: `${provider.providerId} · ${provider.acceptanceRate}% acceptance`, entity: provider.id })),
    ...db.reviews.filter((review) => review.rating <= 2).map((review) => ({ id: `review-${review.id}`, severity: "High", title: "Bad review", body: `${review.rating}★ · ${review.comment}`, entity: review.jobId })),
    ...db.transactions.filter((txn) => txn.status === "Failed").map((txn) => ({ id: `payment-${txn.id}`, severity: "High", title: "Payment failure", body: `${txn.reference ?? txn.id} · EGP ${txn.amount}`, entity: txn.id })),
    ...db.complaints.filter((complaint) => complaint.status !== "Closed").map((complaint) => ({ id: `complaint-${complaint.id}`, severity: complaint.severity, title: "Open complaint", body: `${complaint.title} · ${complaint.customer}`, entity: complaint.id })),
  ];
  return alerts;
}

function exportCsv(name: string, rows: Array<Record<string, unknown>>) {
  const headers = Array.from(new Set(rows.flatMap((row) => Object.keys(row))));
  const csv = [
    headers.join(","),
    ...rows.map((row) =>
      headers
        .map((key) => JSON.stringify(String(row[key] ?? "")))
        .join(","),
    ),
  ].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = name;
  anchor.click();
  URL.revokeObjectURL(url);
}

function CardMetric({ label, value, icon: Icon, tone = "indigo" }: { label: string; value: string | number; icon: LucideIcon; tone?: "indigo" | "green" | "amber" | "red" | "cyan" }) {
  const tones = {
    indigo: "bg-indigo-500/10 text-indigo-300",
    green: "bg-emerald-500/10 text-emerald-300",
    amber: "bg-amber-500/10 text-amber-300",
    red: "bg-red-500/10 text-red-300",
    cyan: "bg-cyan-500/10 text-cyan-300",
  };
  return (
    <div className="rounded-2xl border border-white/[.07] bg-white/[.025] p-4">
      <div className="flex items-center justify-between">
        <span className="text-[11px] text-zinc-500">{label}</span>
        <span className={cn("grid h-8 w-8 place-items-center rounded-xl", tones[tone])}><Icon className="h-4 w-4" /></span>
      </div>
      <div className="mt-3 text-2xl font-semibold tracking-tight">{value}</div>
    </div>
  );
}

function Panel({ title, subtitle, children, action }: { title: string; subtitle?: string; children: React.ReactNode; action?: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-white/[.07] bg-white/[.025]">
      <div className="flex items-start justify-between gap-3 border-b border-white/[.06] p-4">
        <div>
          <h3 className="text-sm font-semibold">{title}</h3>
          {subtitle && <p className="mt-1 text-[11px] text-zinc-500">{subtitle}</p>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}

function Empty({ title, body }: { title: string; body: string }) {
  return <div className="p-8 text-center"><div className="text-sm font-semibold text-zinc-300">{title}</div><p className="mx-auto mt-2 max-w-md text-xs leading-5 text-zinc-500">{body}</p></div>;
}

function StatusPill({ value }: { value: string }) {
  const color = /critical|failed|high|breach|cancel|suspend|blocked/i.test(value)
    ? "border-red-500/20 bg-red-500/10 text-red-300"
    : /pending|medium|warning|delayed|quotation/i.test(value)
      ? "border-amber-500/20 bg-amber-500/10 text-amber-300"
      : /paid|active|success|converted|accepted|healthy|low/i.test(value)
        ? "border-emerald-500/20 bg-emerald-500/10 text-emerald-300"
        : "border-white/[.08] bg-white/[.04] text-zinc-400";
  return <span className={cn("rounded-full border px-2 py-0.5 text-[10px]", color)}>{value}</span>;
}

export function EnterpriseOperationsPage({ page, openJob, notify }: EnterpriseProps) {
  const { db, actions } = useAdminData();
  const { can } = usePermissions();
  const [query, setQuery] = useState("");
  const [city, setCity] = useState("All");
  const [category, setCategory] = useState("All");
  const [status, setStatus] = useState("All");
  const active = db.jobs.filter(isActiveJob);
  const alerts = smartAlerts(db);
  const delayed = db.jobs.filter(isDelayed);
  const emergency = db.jobs.filter((job) => bookingType(job) === "Emergency");
  const scheduled = db.jobs.filter((job) => bookingType(job) === "Scheduled");
  const quotations = db.jobs.filter((job) => bookingType(job) === "Quotation");
  const riskyProviders = db.providers
    .map((provider) => ({ provider, score: riskScoreProvider(provider, db) }))
    .filter((item) => item.score >= 40)
    .sort((a, b) => b.score - a.score);

  if (page === "Command Center") {
    return (
      <div className="space-y-5">
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
          <CardMetric label="Active bookings" value={active.length} icon={Radio} tone="indigo" />
          <CardMetric label="Delayed jobs" value={delayed.length} icon={Clock3} tone={delayed.length ? "red" : "green"} />
          <CardMetric label="Open complaints" value={db.complaints.filter((item) => item.status !== "Closed").length} icon={ShieldAlert} tone="amber" />
          <CardMetric label="Technicians online" value={db.providers.filter((provider) => provider.available && provider.status === "Active").length} icon={Wrench} tone="green" />
          <CardMetric label="Revenue today" value={`EGP ${todayRevenue(db).toLocaleString()}`} icon={Banknote} tone="cyan" />
        </div>
        <div className="grid gap-5 xl:grid-cols-[1.35fr_.65fr]">
          <Panel title="Operations pulse" subtitle="Bookings, risks, finance, and health from live Firestore">
            <div className="grid gap-3 p-4 md:grid-cols-2 xl:grid-cols-3">
              <CardMetric label="Emergency bookings" value={emergency.length} icon={Zap} tone="red" />
              <CardMetric label="Pending payouts" value={db.payouts.filter((item) => item.status === "Pending").length} icon={WalletCards} tone="amber" />
              <CardMetric label="Failed payments" value={db.transactions.filter((item) => item.status === "Failed").length} icon={AlertTriangle} tone="red" />
              <CardMetric label="Risky technicians" value={riskyProviders.length} icon={UserCog} tone="amber" />
              <CardMetric label="System alerts" value={alerts.length} icon={Bell} tone={alerts.length ? "amber" : "green"} />
              <CardMetric label="Bookings total" value={db.jobs.length} icon={Activity} tone="indigo" />
            </div>
          </Panel>
          <Panel title="Smart alerts" subtitle={`${alerts.length} generated from current data`}>
            <AlertList alerts={alerts.slice(0, 8)} openJob={openJob} db={db} />
          </Panel>
        </div>
      </div>
    );
  }

  if (page === "Live Operations Map") {
    const cities = ["All", ...Array.from(new Set(db.jobs.map((job) => job.city || job.area).filter(Boolean)))];
    const categories = ["All", ...Array.from(new Set(db.jobs.map((job) => job.category || job.service).filter(Boolean)))];
    const statuses = ["All", "Available", "Busy", "Offline"];
    const filteredJobs = db.jobs.filter((job) => (city === "All" || job.city === city || job.area === city) && (category === "All" || job.category === category || job.service === category));
    const filteredLocations = db.locations.filter((loc) => status === "All" || loc.status === status);
    return (
      <div className="space-y-5">
        <div className="grid gap-3 rounded-2xl border border-white/[.07] bg-white/[.025] p-4 md:grid-cols-4">
          <SearchableSelect value={city} onChange={setCity} allowEmpty={false} options={cities.map((value) => ({ label: value, value }))} />
          <SearchableSelect value={category} onChange={setCategory} allowEmpty={false} options={categories.map((value) => ({ label: value, value }))} />
          <SearchableSelect value={status} onChange={setStatus} allowEmpty={false} options={statuses.map((value) => ({ label: value, value }))} />
          <Button variant="secondary" onClick={() => notify("Map filters applied")}>Apply filters</Button>
        </div>
        <LiveOperationsMap locations={filteredLocations} providers={db.providers} jobs={filteredJobs} />
      </div>
    );
  }

  if (page === "Smart Alerts") {
    return <Panel title="Smart Alerts Center" subtitle="Operational alerts generated from live bookings, payments, complaints, reviews, and technician signals"><AlertList alerts={alerts} openJob={openJob} db={db} /></Panel>;
  }

  if (page === "Customer Intelligence") {
    return (
      <div className="space-y-5">
        <Input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search customers by name, phone, email, risk, service, or booking ID" />
        <div className="grid gap-4 lg:grid-cols-2">
          {db.customers
            .filter((customer) => `${customer.name} ${customer.phone} ${customer.email} ${customer.risk}`.toLowerCase().includes(query.toLowerCase()))
            .map((customer) => {
              const intel = customerIntelligence(customer, db);
              return (
                <Panel key={customer.id} title={customer.name} subtitle={`${customer.phone} · ${customer.email}`}>
                  <div className="grid gap-3 p-4 sm:grid-cols-3">
                    <CardMetric label="Total bookings" value={intel.jobs.length} icon={CalendarClock} />
                    <CardMetric label="Cancellation rate" value={`${Math.round(intel.cancellationRate * 100)}%`} icon={RefreshCcw} tone={intel.cancellationRate > 0.3 ? "red" : "green"} />
                    <CardMetric label="Lifetime value" value={`EGP ${customer.totalSpend.toLocaleString()}`} icon={Banknote} tone="green" />
                  </div>
                  <div className="grid gap-3 border-t border-white/[.06] p-4 text-xs text-zinc-500 md:grid-cols-2">
                    <div>Complaints: <b className="text-zinc-200">{intel.complaints.length}</b></div>
                    <div>Risk level: <StatusPill value={intel.riskLevel} /></div>
                    <div>Favorite services: <b className="text-zinc-200">{intel.favoriteServices.join(", ") || "No history yet"}</b></div>
                    <div>Payment history: <b className="text-zinc-200">{db.transactions.filter((txn) => txn.ownerId === customer.id || txn.party === customer.name).length} transactions</b></div>
                  </div>
                </Panel>
              );
            })}
        </div>
        {!db.customers.length && <Empty title="No customers" body="Customer intelligence appears after real customer records are created." />}
      </div>
    );
  }

  if (page === "Booking Control Center") {
    return (
      <div className="space-y-5">
        <div className="grid gap-4 md:grid-cols-3">
          <CardMetric label="Emergency" value={emergency.length} icon={Zap} tone="red" />
          <CardMetric label="Scheduled" value={scheduled.length} icon={CalendarClock} tone="indigo" />
          <CardMetric label="Quotation requests" value={quotations.length} icon={FileText} tone="amber" />
        </div>
        <Panel title="Booking lifecycle control" subtitle="Emergency, scheduled, and quotation requests with SLA and admin actions">
          <BookingTable jobs={db.jobs} openJob={openJob} actions={actions} can={can} />
        </Panel>
      </div>
    );
  }

  if (page === "SLA Monitoring") {
    const rows = db.jobs.map((job) => ({ job, breached: isDelayed(job), elapsed: minutesSince(job.createdAt), response: job.responseSlaMinutes ?? (bookingType(job) === "Emergency" ? 10 : 45) }));
    return (
      <div className="space-y-5">
        <div className="grid gap-4 md:grid-cols-4">
          <CardMetric label="Response breaches" value={rows.filter((row) => row.breached).length} icon={AlertTriangle} tone="red" />
          <CardMetric label="Emergency SLA avg" value={`${average(emergency.map((job) => minutesSince(job.createdAt)))} min`} icon={Zap} tone="amber" />
          <CardMetric label="Overdue jobs" value={delayed.length} icon={Clock3} tone="red" />
          <CardMetric label="Complaint resolution open" value={db.complaints.filter((item) => item.status !== "Closed").length} icon={ShieldAlert} tone="amber" />
        </div>
        <Panel title="SLA register">
          <div className="overflow-x-auto"><table className="w-full min-w-[900px] text-left text-xs"><tbody>{rows.map(({ job, breached, elapsed, response }) => <tr key={job.id} className="border-b border-white/[.06]"><td className="p-3"><button className="font-medium text-indigo-300" onClick={() => openJob(job)}>{job.id}</button><div className="text-[10px] text-zinc-600">{job.service} · {bookingType(job)}</div></td><td className="p-3">{job.area}</td><td className="p-3">{elapsed} min elapsed</td><td className="p-3">{response} min response SLA</td><td className="p-3"><StatusPill value={breached ? "Breached" : "On track"} /></td></tr>)}</tbody></table></div>
        </Panel>
      </div>
    );
  }

  if (page === "Financial Control Center") {
    const commissions = db.jobs.reduce((sum, job) => sum + (job.payment?.platformCommission ?? 0), 0);
    const refunds = db.jobs.reduce((sum, job) => sum + (job.payment?.refundAmount ?? 0), 0);
    const providerBalances = db.wallets.filter((wallet) => wallet.ownerType === "provider").reduce((sum, wallet) => sum + wallet.balance, 0);
    return (
      <div className="space-y-5">
        <div className="grid gap-4 md:grid-cols-4">
          <CardMetric label="Revenue" value={`EGP ${revenue(db).toLocaleString()}`} icon={Banknote} tone="green" />
          <CardMetric label="Commissions" value={`EGP ${Math.round(commissions).toLocaleString()}`} icon={TrendingUp} tone="indigo" />
          <CardMetric label="Refunds" value={`EGP ${Math.round(refunds).toLocaleString()}`} icon={RefreshCcw} tone="red" />
          <CardMetric label="Provider balances" value={`EGP ${providerBalances.toLocaleString()}`} icon={WalletCards} tone="amber" />
        </div>
        <Panel title="Transaction logs" action={<Button variant="secondary" onClick={() => exportCsv("financial-control.csv", db.transactions as unknown as Array<Record<string, unknown>>)}>Export</Button>}>
          <SimpleRows rows={db.transactions.map((txn) => [`${txn.type} · ${txn.party}`, `EGP ${txn.amount.toLocaleString()}`, txn.status, txn.method])} />
        </Panel>
      </div>
    );
  }

  if (page === "Fraud & Risk Center") {
    const riskyCustomers = db.customers.map((customer) => ({ customer, intel: customerIntelligence(customer, db) })).filter((item) => item.intel.riskLevel !== "Low");
    return (
      <div className="space-y-5">
        <div className="grid gap-4 md:grid-cols-3">
          <CardMetric label="Suspicious customers" value={riskyCustomers.length} icon={Users} tone="amber" />
          <CardMetric label="Suspicious technicians" value={riskyProviders.length} icon={Wrench} tone="red" />
          <CardMetric label="Unusual refunds" value={db.jobs.filter((job) => (job.payment?.refundAmount ?? 0) > job.amount * 0.5).length} icon={RefreshCcw} tone="red" />
        </div>
        <Panel title="Risk signals">
          <SimpleRows rows={[...riskyCustomers.map(({ customer, intel }) => [customer.name, `${Math.round(intel.cancellationRate * 100)}% cancellations`, `${intel.complaints.length} complaints`, intel.riskLevel]), ...riskyProviders.map(({ provider, score }) => [provider.name, `${score}/100 risk`, `${provider.acceptanceRate}% acceptance`, provider.status])]} />
        </Panel>
      </div>
    );
  }

  if (page === "Quality Control Center") {
    const lowRatedJobs = db.reviews.filter((review) => review.rating <= 3);
    return (
      <div className="space-y-5">
        <div className="grid gap-4 md:grid-cols-4">
          <CardMetric label="Low-rated jobs" value={lowRatedJobs.length} icon={Star} tone="red" />
          <CardMetric label="Open complaints" value={db.complaints.filter((item) => item.status !== "Closed").length} icon={ShieldAlert} tone="amber" />
          <CardMetric label="Refund reasons" value={db.jobs.filter((job) => job.payment?.refundAmount).length} icon={RefreshCcw} tone="red" />
          <CardMetric label="Approval cases" value={db.reviews.filter((review) => review.status !== "Approved").length} icon={CheckCircle2} tone="indigo" />
        </div>
        <Panel title="Quality review queue">
          <SimpleRows rows={lowRatedJobs.map((review) => [`${review.rating}★ · ${review.customerName}`, review.comment, review.status, review.jobId])} />
        </Panel>
      </div>
    );
  }

  if (page === "Automation Rules") {
    const rules = [
      ["Technician rating below 2.5", "Flag technician", db.providers.filter((p) => p.rating < 2.5).length],
      ["Ignored offers above 10", "Create warning", db.providers.filter((p) => p.acceptanceRate < 40).length],
      ["Complaint count above 5", "Move to review", riskyProviders.filter((p) => p.score > 70).length],
      ["Payment failed", "Alert finance", db.transactions.filter((t) => t.status === "Failed").length],
      ["Booking delayed", "Notify admin", delayed.length],
    ];
    return <Panel title="Automation Rules" subtitle="Super Admin-managed rule templates evaluated from live data"><SimpleRows rows={rules.map(([condition, action, matches]) => [condition, action, `${matches} current matches`, "Enabled"])} /></Panel>;
  }

  if (page === "Notification Center") {
    return <Panel title="Notification Center" subtitle="Admin notifications from bookings, complaints, payments, technicians, system errors, invitations, and integrations"><SimpleRows rows={db.notifications.map((item) => [item.title, item.body, item.audience, item.status])} /></Panel>;
  }

  if (page === "Reports Center") {
    const reports = [
      ["Daily operations report", db.jobs.length],
      ["Technician performance report", db.providers.length],
      ["Revenue report", db.transactions.length],
      ["Complaint report", db.complaints.length],
      ["Customer growth report", db.customers.length],
      ["Payout report", db.payouts.length],
      ["SLA report", delayed.length],
      ["Emergency response report", emergency.length],
      ["Quotation conversion report", quotations.length],
    ];
    return <Panel title="Reports Center" subtitle="Professional CSV exports generated from Firestore data"><SimpleRows rows={reports.map(([name, count]) => [name, `${count} records`, "CSV", <Button key={String(name)} size="sm" variant="secondary" onClick={() => exportCsv(`${String(name).toLowerCase().replaceAll(" ", "-")}.csv`, reportRows(String(name), db))}><Download className="h-3.5 w-3.5" />Export</Button>])} /></Panel>;
  }

  if (page === "Activity Timeline") {
    const timeline = [
      ...db.auditLogs.map((log) => ({ at: log.createdAt, title: log.action, body: log.detail, actor: log.actorName })),
      ...db.jobs.flatMap((job) => (job.timeline ?? []).map((event) => ({ at: event.at, title: `${job.id} · ${event.label}`, body: job.service, actor: event.actor }))),
      ...db.providers.flatMap((provider) => (provider.activityTimeline ?? []).map((event) => ({ at: event.at, title: `${provider.providerId} · ${event.label}`, body: provider.name, actor: event.actor }))),
    ].sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());
    return <Panel title="Audit & Activity Timeline" subtitle="Bookings, technicians, customers, admins, and payments"><SimpleRows rows={timeline.slice(0, 80).map((item) => [new Date(item.at).toLocaleString(), item.title, item.body, item.actor])} /></Panel>;
  }

  if (page === "System Health") {
    const integrationFailures = db.auditLogs.filter((log) => /integration.*failed|api.*failed|email.*failed/i.test(log.action + log.detail)).length;
    return (
      <div className="grid gap-4 md:grid-cols-3">
        <CardMetric label="Firebase data" value="Online" icon={CheckCircle2} tone="green" />
        <CardMetric label="API Center failures" value={integrationFailures} icon={AlertTriangle} tone={integrationFailures ? "red" : "green"} />
        <CardMetric label="Email provider errors" value={db.auditLogs.filter((log) => /email.*failed/i.test(log.action + log.detail)).length} icon={Bell} tone="amber" />
        <CardMetric label="Payment provider issues" value={db.transactions.filter((txn) => txn.status === "Failed").length} icon={WalletCards} tone="red" />
        <CardMetric label="AI provider status" value={db.auditLogs.filter((log) => /ai|gemini|openai/i.test(log.detail)).length ? "Configured activity" : "No activity"} icon={Bot} tone="indigo" />
        <CardMetric label="Storage documents" value={db.providers.reduce((sum, provider) => sum + provider.documents.length, 0)} icon={FileText} tone="cyan" />
      </div>
    );
  }

  const haystack = [
    ...db.jobs.map((job) => ({ type: "Booking", title: `${job.id} · ${job.customer}`, meta: `${job.service} · ${bookingType(job)} · ${job.status}`, onClick: () => openJob(job) })),
    ...db.customers.map((customer) => ({ type: "Customer", title: customer.name, meta: `${customer.phone} · ${customer.email} · ${customer.risk}` })),
    ...db.providers.map((provider) => ({ type: "Technician", title: `${provider.providerId} · ${provider.name}`, meta: `${provider.phone} · ${provider.trade} · ${provider.status}` })),
    ...db.transactions.map((txn) => ({ type: "Payment", title: txn.reference ?? txn.id, meta: `${txn.party} · EGP ${txn.amount} · ${txn.status}` })),
    ...db.complaints.map((complaint) => ({ type: "Complaint", title: complaint.title, meta: `${complaint.customer} · ${complaint.severity} · ${complaint.status}` })),
    ...db.reviews.map((review) => ({ type: "Review", title: `${review.rating}★ · ${review.customerName}`, meta: `${review.comment} · ${review.status}` })),
    ...db.roles.map((role) => ({ type: "Role", title: role.name, meta: `${role.permissions.length} permissions` })),
    ...db.invitations.map((invite) => ({ type: "Invitation", title: invite.email, meta: `${invite.status} · ${invite.roleName}` })),
    ...db.auditLogs.map((log) => ({ type: "Audit", title: log.action, meta: `${log.actorName} · ${log.detail}` })),
  ].filter((item) => `${item.type} ${item.title} ${item.meta}`.toLowerCase().includes(query.toLowerCase()));
  return (
    <div className="space-y-5">
      <div className="relative"><Search className="absolute left-3 top-3 h-4 w-4 text-zinc-600" /><Input value={query} onChange={(event) => setQuery(event.target.value)} className="pl-10" placeholder="Search bookings, customers, technicians, payments, complaints, reviews, roles, invitations, audit logs" /></div>
      <Panel title="Advanced Search Results" subtitle={`${haystack.length} result(s)`}>
        <SimpleRows rows={haystack.slice(0, 100).map((item) => {
          const open = "onClick" in item && typeof item.onClick === "function"
            ? (item.onClick as () => void)
            : null;
          return [<Badge key="type" variant="secondary">{item.type}</Badge>, item.title, item.meta, open ? <Button key="open" size="sm" variant="secondary" onClick={open}>Open</Button> : "—"];
        })} />
      </Panel>
    </div>
  );
}

function AlertList({ alerts, openJob, db }: { alerts: ReturnType<typeof smartAlerts>; openJob: (job: Job) => void; db: DatabaseState }) {
  if (!alerts.length) return <Empty title="No smart alerts" body="Alerts will appear when bookings, payments, complaints, reviews, or technicians cross risk thresholds." />;
  return (
    <div className="divide-y divide-white/[.06]">
      {alerts.map((alert) => {
        const job = db.jobs.find((item) => item.id === alert.entity);
        return (
          <button key={alert.id} onClick={() => job && openJob(job)} className="flex w-full items-start gap-3 p-4 text-left hover:bg-white/[.025]">
            <span className="mt-0.5 grid h-8 w-8 place-items-center rounded-xl bg-amber-500/10 text-amber-300"><AlertTriangle className="h-4 w-4" /></span>
            <span className="min-w-0 flex-1"><span className="flex items-center gap-2"><b className="text-xs text-zinc-200">{alert.title}</b><StatusPill value={alert.severity} /></span><span className="mt-1 block truncate text-[11px] text-zinc-500">{alert.body}</span></span>
          </button>
        );
      })}
    </div>
  );
}

function BookingTable({ jobs, openJob, actions, can }: { jobs: Job[]; openJob: (job: Job) => void; actions: ReturnType<typeof useAdminData>["actions"]; can: (permission: string) => boolean }) {
  if (!jobs.length) return <Empty title="No bookings" body="Booking control appears after customer app requests are stored in Firestore." />;
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[1100px] text-left text-xs">
        <thead className="text-[10px] uppercase text-zinc-600"><tr><th className="p-3">Booking</th><th>Type</th><th>Priority</th><th>SLA</th><th>Technician</th><th>Customer</th><th>Payment</th><th>Status</th><th /></tr></thead>
        <tbody>
          {jobs.map((job) => (
            <tr key={job.id} className="border-t border-white/[.06]">
              <td className="p-3"><button className="font-semibold text-indigo-300" onClick={() => openJob(job)}>{job.id}</button><div className="text-[10px] text-zinc-600">{job.service} · {job.area}</div></td>
              <td><StatusPill value={bookingType(job)} /></td>
              <td>{job.priority ?? "Normal"}</td>
              <td>{job.responseSlaMinutes ?? (bookingType(job) === "Emergency" ? 10 : 45)} min · <StatusPill value={isDelayed(job) ? "Breached" : "On track"} /></td>
              <td>{job.provider || "Unassigned"}</td>
              <td>{job.customer}</td>
              <td>{job.paymentStatus}</td>
              <td><StatusPill value={job.quotationStatus ?? job.status} /></td>
              <td className="space-x-2 pr-3">
                {can("jobs.assign") && <Button size="sm" variant="secondary" onClick={() => openJob(job)}>Assign</Button>}
                {can("jobs.edit") && bookingType(job) === "Quotation" && job.quotationStatus !== "Converted to booking" && <Button size="sm" variant="secondary" onClick={() => actions.updateJob(job.id, { quotationStatus: "Converted to booking", status: "Scheduled" }).then(() => undefined)}>Convert</Button>}
                {can("jobs.cancel") && job.status !== "Cancelled" && <Button size="sm" variant="destructive" onClick={() => actions.changeJobStatus(job.id, "Cancelled")}>Cancel</Button>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function SimpleRows({ rows }: { rows: Array<Array<React.ReactNode>> }) {
  if (!rows.length) return <Empty title="No records" body="This center is connected to live Firestore data and will populate when matching records exist." />;
  return <div className="divide-y divide-white/[.06]">{rows.map((row, index) => <div key={index} className="grid gap-2 p-4 text-xs text-zinc-400 md:grid-cols-4">{row.map((cell, cellIndex) => <div key={cellIndex} className={cellIndex === 0 ? "font-medium text-zinc-200" : ""}>{cell}</div>)}</div>)}</div>;
}

function average(values: number[]) {
  const clean = values.filter((value) => Number.isFinite(value));
  return clean.length ? Math.round(clean.reduce((sum, value) => sum + value, 0) / clean.length) : 0;
}

function reportRows(name: string, db: DatabaseState) {
  if (name.includes("Technician")) return db.providers as unknown as Array<Record<string, unknown>>;
  if (name.includes("Revenue") || name.includes("Payout")) return db.transactions as unknown as Array<Record<string, unknown>>;
  if (name.includes("Complaint")) return db.complaints as unknown as Array<Record<string, unknown>>;
  if (name.includes("Customer")) return db.customers as unknown as Array<Record<string, unknown>>;
  if (name.includes("SLA")) return db.jobs.filter(isDelayed) as unknown as Array<Record<string, unknown>>;
  if (name.includes("Emergency")) return db.jobs.filter((job) => bookingType(job) === "Emergency") as unknown as Array<Record<string, unknown>>;
  if (name.includes("Quotation")) return db.jobs.filter((job) => bookingType(job) === "Quotation") as unknown as Array<Record<string, unknown>>;
  return db.jobs as unknown as Array<Record<string, unknown>>;
}
