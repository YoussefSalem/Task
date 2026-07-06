"use client";

import { useMemo, useState } from "react";
import {
  AlertTriangle,
  Ban,
  Download,
  Gauge,
  RefreshCcw,
  Star,
  UserCog,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { useAdminData } from "@/components/admin-data-provider";
import { useAuth } from "@/components/auth-provider";
import { usePermissions } from "@/components/use-permissions";
import { FormDialog, RowActions } from "@/components/functional-dialogs";
import { SearchableSelect } from "@/components/searchable-select";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import type {
  Complaint,
  Job,
  JobPayment,
  Provider,
  ProviderReview,
  ProviderWarning,
  Transaction,
} from "@/lib/types";

type TechnicianStatus =
  | "Active"
  | "Warning"
  | "Under Review"
  | "Suspended"
  | "Disabled"
  | "Blacklisted";

type TechnicianMetrics = {
  provider: Provider;
  score: number;
  grade: "Excellent" | "Very Good" | "Average" | "Poor" | "Critical";
  flags: string[];
  jobsReceived: number;
  acceptedJobs: number;
  rejectedJobs: number;
  ignoredJobs: number;
  expiredOffers: number;
  completedJobs: number;
  cancelledJobs: number;
  providerCancelledJobs: number;
  customerCancelledJobs: number;
  completionRate: number;
  acceptanceRate: number;
  offerResponseRate: number;
  averageCompletionMinutes: number;
  averageArrivalDelayMinutes: number;
  averageJobDurationMinutes: number;
  averageOfferResponseMinutes: number;
  averageMessageResponseMinutes: number;
  longestUnansweredOfferMinutes: number;
  ignoredChats: number;
  lateArrivals: number;
  missedAppointments: number;
  totalComplaints: number;
  openComplaints: number;
  resolvedComplaints: number;
  revenueGenerated: number;
  jobsValue: number;
  commissionPaid: number;
  pendingPayouts: number;
  refunds: number;
  averageOrderValue: number;
  daysActive: number;
  daysInactive: number;
  loginFrequency: string;
  lastCompletedJob?: Job;
  currentJob?: Job;
  currentLocation?: string;
  warningCount: number;
  reviewDistribution: Record<number, number>;
  latestReviews: ProviderReview[];
  commonComplaints: Array<[string, number]>;
  commonCompliments: Array<[string, number]>;
};

const minutesBetween = (a?: string, b?: string) => {
  if (!a || !b) return 0;
  const start = new Date(a).getTime();
  const end = new Date(b).getTime();
  if (!Number.isFinite(start) || !Number.isFinite(end) || end < start) return 0;
  return Math.round((end - start) / 60000);
};

const daysSince = (date?: string) => {
  if (!date || date === "Never") return 999;
  const time = new Date(date).getTime();
  if (!Number.isFinite(time)) return 999;
  return Math.max(0, Math.floor((Date.now() - time) / 86400000));
};

const average = (values: number[]) =>
  values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : 0;

const pct = (value: number, total: number) =>
  total > 0 ? Math.round((value / total) * 100) : 0;

function providerOffers(provider: Provider, jobs: Job[]) {
  return jobs.flatMap((job) =>
    (job.offers ?? [])
      .filter((offer) => offer.providerId === provider.id)
      .map((offer) => ({ job, offer })),
  );
}

function countWords(items: string[]) {
  const buckets = new Map<string, number>();
  for (const item of items) {
    const normalized = item
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .split(/\s+/)
      .filter((word) => word.length > 4 && !["customer", "provider", "technician", "issue"].includes(word));
    for (const word of normalized) buckets.set(word, (buckets.get(word) ?? 0) + 1);
  }
  return Array.from(buckets.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
}

function starLabel(score: number) {
  if (score >= 90) return "★★★★★ Excellent";
  if (score >= 75) return "★★★★ Very Good";
  if (score >= 55) return "★★★ Average";
  if (score >= 35) return "★★ Poor";
  return "★ Critical";
}

function calculateTechnicianMetrics(
  provider: Provider,
  jobs: Job[],
  complaints: Complaint[],
  transactions: Transaction[],
  reviews: ProviderReview[],
): TechnicianMetrics {
  const assignedJobs = jobs.filter((job) => job.providerId === provider.id);
  const offers = providerOffers(provider, jobs);
  const uniqueOfferJobIds = new Set(offers.map(({ job }) => job.id));
  const jobsReceived = new Set([...assignedJobs.map((job) => job.id), ...uniqueOfferJobIds]).size;
  const acceptedJobs = offers.filter(({ offer }) => offer.status === "Accepted").length || assignedJobs.length;
  const rejectedJobs = offers.filter(({ offer }) => offer.status === "Rejected" || offer.status === "Withdrawn").length;
  const expiredOffers = offers.filter(({ offer }) => offer.status === "Expired").length;
  const ignoredJobs = offers.filter(({ offer }) => offer.status === "Pending" && !offer.openedAt).length;
  const completedJobs = assignedJobs.filter((job) => job.status === "Completed").length;
  const cancelledJobs = assignedJobs.filter((job) => job.status === "Cancelled" || job.cancellation).length;
  const providerCancelledJobs = assignedJobs.filter((job) => job.cancellation?.cancelledBy === "Provider").length;
  const customerCancelledJobs = assignedJobs.filter((job) => job.cancellation?.cancelledBy === "Customer").length;
  const providerComplaints = complaints.filter((complaint) => complaint.providerId === provider.id);
  const providerReviews = reviews.filter((review) => review.providerId === provider.id && review.status !== "Deleted" && review.status !== "Hidden");
  const openComplaints = providerComplaints.filter((complaint) => complaint.status !== "Closed").length;
  const responseMinutes = offers
    .map(({ job, offer }) => minutesBetween(job.createdAt, offer.createdAt))
    .filter((value) => value > 0);
  const messageResponseMinutes = assignedJobs.flatMap((job) => {
    const messages = [...(job.messages ?? [])].sort(
      (a, b) => new Date(a.sentAt).getTime() - new Date(b.sentAt).getTime(),
    );
    return messages.flatMap((message, index) => {
      if (message.senderType !== "customer") return [];
      const reply = messages.slice(index + 1).find((item) => item.senderType === "provider");
      return reply ? [minutesBetween(message.sentAt, reply.sentAt)] : [];
    });
  });
  const ignoredChats = assignedJobs.reduce(
    (sum, job) =>
      sum +
      (job.messages ?? []).filter((message) => message.senderType === "customer" && !message.read).length,
    0,
  );
  const completionTimes = assignedJobs
    .filter((job) => job.status === "Completed")
    .map((job) => minutesBetween(job.createdAt, job.timeline.find((event) => /completed/i.test(event.label))?.at))
    .filter((value) => value > 0);
  const durationTimes = assignedJobs
    .map((job) => {
      const started = job.timeline.find((event) => /started|in progress/i.test(event.label))?.at;
      const completed = job.timeline.find((event) => /completed/i.test(event.label))?.at;
      return minutesBetween(started, completed);
    })
    .filter((value) => value > 0);
  const arrivalDelays = assignedJobs
    .map((job) => {
      const arrived = job.timeline.find((event) => /arrived/i.test(event.label))?.at;
      return arrived ? minutesBetween(job.scheduled || job.createdAt, arrived) : 0;
    })
    .filter((value) => value > 0);
  const lateArrivals = arrivalDelays.filter((value) => value > 15).length;
  const missedAppointments = assignedJobs.filter(
    (job) => job.cancellation?.cancelledBy === "Provider" && /miss|no.?show|appointment/i.test(job.cancellation.reason),
  ).length;
  const paidJobs = assignedJobs.filter((job) => job.payment?.status === "Paid" || job.paymentStatus === "Paid");
  const payments = assignedJobs.map((job) => job.payment).filter(Boolean) as JobPayment[];
  const revenueGenerated = paidJobs.reduce((sum, job) => sum + Number(job.amount ?? job.payment?.amount ?? 0), 0);
  const jobsValue = assignedJobs.reduce((sum, job) => sum + Number(job.amount ?? 0), 0);
  const commissionPaid = payments.reduce((sum, payment) => sum + Number(payment.platformCommission ?? 0), 0);
  const refunds = payments.reduce((sum, payment) => sum + Number(payment.refundAmount ?? 0), 0);
  const pendingPayouts = transactions
    .filter((transaction) => transaction.ownerId === provider.id && transaction.type === "Provider payout" && transaction.status !== "Completed")
    .reduce((sum, transaction) => sum + Number(transaction.amount ?? 0), 0);
  const warnings = provider.performanceWarnings ?? [];
  const warningCount = warnings.filter((warning) => warning.status === "Open").length;
  const completionRate = pct(completedJobs, Math.max(assignedJobs.length, acceptedJobs));
  const acceptanceRate = pct(acceptedJobs, offers.length || jobsReceived);
  const offerResponseRate = pct(offers.filter(({ offer }) => offer.openedAt || offer.createdAt).length - ignoredJobs, offers.length);
  const complaintPenalty = Math.min(25, providerComplaints.length * 5);
  const cancelPenalty = Math.min(20, pct(providerCancelledJobs, Math.max(1, assignedJobs.length)) * 0.35);
  const ignoredPenalty = Math.min(15, pct(ignoredJobs, Math.max(1, offers.length)) * 0.25);
  const latenessPenalty = Math.min(10, lateArrivals * 2 + missedAppointments * 4);
  const inactivityPenalty = Math.min(15, daysSince(provider.lastActive) > 30 ? 15 : daysSince(provider.lastActive) > 7 ? 7 : 0);
  const ratingScore = Math.min(100, Math.max(0, provider.rating * 20 || 0));
  const score = Math.max(
    0,
    Math.min(
      100,
      Math.round(
        ratingScore * 0.25 +
          completionRate * 0.25 +
          acceptanceRate * 0.2 +
          offerResponseRate * 0.15 +
          (100 - complaintPenalty - cancelPenalty - ignoredPenalty - latenessPenalty - inactivityPenalty) * 0.15,
      ),
    ),
  );
  const flags = [
    score >= 90 ? "Top Performer" : "",
    score >= 80 && providerComplaints.length === 0 ? "Reliable" : "",
    average(responseMinutes) <= 10 && offers.length > 0 ? "Fast Responder" : "",
    lateArrivals > 0 ? "Late" : "",
    daysSince(provider.lastActive) > 14 ? "Inactive" : "",
    providerComplaints.length >= 3 ? "Many Complaints" : "",
    acceptanceRate < 30 && offers.length > 0 ? "Low Acceptance" : "",
    score < 40 || provider.status === "Banned" || provider.status === "Blocked" ? "Risk" : "",
    score < 60 || warningCount > 0 || openComplaints > 0 ? "Needs Review" : "",
  ].filter(Boolean);
  const currentJob = assignedJobs.find((job) =>
    ["Assigned", "En route", "In progress", "Delayed"].includes(job.status),
  );
  const lastCompletedJob = [...assignedJobs]
    .filter((job) => job.status === "Completed")
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())[0];
  const currentLocation = provider.cities[0] || provider.areas[0] || "Location not reported";

  return {
    provider,
    score,
    grade: score >= 90 ? "Excellent" : score >= 75 ? "Very Good" : score >= 55 ? "Average" : score >= 35 ? "Poor" : "Critical",
    flags,
    jobsReceived,
    acceptedJobs,
    rejectedJobs,
    ignoredJobs,
    expiredOffers,
    completedJobs,
    cancelledJobs,
    providerCancelledJobs,
    customerCancelledJobs,
    completionRate,
    acceptanceRate,
    offerResponseRate,
    averageCompletionMinutes: Math.round(average(completionTimes)),
    averageArrivalDelayMinutes: Math.round(average(arrivalDelays)),
    averageJobDurationMinutes: Math.round(average(durationTimes)),
    averageOfferResponseMinutes: Math.round(average(responseMinutes)),
    averageMessageResponseMinutes: Math.round(average(messageResponseMinutes)),
    longestUnansweredOfferMinutes: Math.max(0, ...offers.filter(({ offer }) => offer.status === "Pending").map(({ job }) => minutesBetween(job.createdAt, new Date().toISOString()))),
    ignoredChats,
    lateArrivals,
    missedAppointments,
    totalComplaints: providerComplaints.length,
    openComplaints,
    resolvedComplaints: providerComplaints.length - openComplaints,
    revenueGenerated,
    jobsValue,
    commissionPaid,
    pendingPayouts,
    refunds,
    averageOrderValue: Math.round(jobsValue / Math.max(1, assignedJobs.length)),
    daysActive: Math.max(0, Math.ceil((Date.now() - new Date(provider.createdAt).getTime()) / 86400000) - daysSince(provider.lastActive)),
    daysInactive: daysSince(provider.lastActive),
    loginFrequency: provider.lastLogin ? `${daysSince(provider.lastLogin)} days since login` : "No login recorded",
    lastCompletedJob,
    currentJob,
    currentLocation,
    warningCount,
    reviewDistribution: [1, 2, 3, 4, 5].reduce(
      (acc, rating) => ({ ...acc, [rating]: providerReviews.filter((review) => review.rating === rating).length }),
      {} as Record<number, number>,
    ),
    latestReviews: [...providerReviews].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 8),
    commonComplaints: countWords(providerComplaints.map((complaint) => `${complaint.title} ${complaint.description}`)),
    commonCompliments: countWords(assignedJobs.flatMap((job) => job.notes ?? []).filter((note) => /great|excellent|fast|clean|professional|good/i.test(note))),
  };
}

function exportCsv(filename: string, rows: Array<Record<string, string | number>>) {
  const headers = Object.keys(rows[0] ?? { empty: "No data" });
  const csv = [
    headers.join(","),
    ...rows.map((row) =>
      headers
        .map((header) => `"${String(row[header] ?? "").replace(/"/g, '""')}"`)
        .join(","),
    ),
  ].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

function scoreTone(score: number) {
  if (score >= 80) return "text-emerald-400 bg-emerald-500/10 border-emerald-500/20";
  if (score >= 60) return "text-amber-400 bg-amber-500/10 border-amber-500/20";
  return "text-red-400 bg-red-500/10 border-red-500/20";
}

export function TechnicianPerformanceCenter({ notify }: { notify: (message: string) => void }) {
  const { db, actions, mutationPending } = useAdminData();
  const { user, getIdToken } = useAuth();
  const { can } = usePermissions();
  const [search, setSearch] = useState("");
  const [city, setCity] = useState("All cities");
  const [category, setCategory] = useState("All categories");
  const [status, setStatus] = useState("All statuses");
  const [scoreFilter, setScoreFilter] = useState("All scores");
  const [sort, setSort] = useState("Lowest score");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [warningProvider, setWarningProvider] = useState<Provider | null>(null);
  const [noteProvider, setNoteProvider] = useState<Provider | null>(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState("");
  const [aiSummary, setAiSummary] = useState("");

  const metrics = useMemo(
    () =>
      db.providers.map((provider) =>
        calculateTechnicianMetrics(provider, db.jobs, db.complaints, db.transactions, db.reviews),
      ),
    [db.complaints, db.jobs, db.providers, db.reviews, db.transactions],
  );
  const selected = metrics.find((item) => item.provider.id === selectedId) ?? metrics[0];
  const cities = Array.from(new Set(db.providers.flatMap((provider) => provider.cities.length ? provider.cities : provider.areas))).filter(Boolean);
  const categories = Array.from(new Set(db.providers.map((provider) => provider.trade))).filter(Boolean);

  const filtered = metrics
    .filter((item) => {
      const haystack = `${item.provider.providerId} ${item.provider.name} ${item.provider.phone} ${item.provider.email} ${item.provider.trade} ${item.provider.cities.join(" ")} ${item.provider.areas.join(" ")}`.toLowerCase();
      const scoreMatch =
        scoreFilter === "All scores" ||
        (scoreFilter === "Critical" && item.score < 35) ||
        (scoreFilter === "Needs review" && item.score < 60) ||
        (scoreFilter === "Top performers" && item.score >= 85);
      return (
        haystack.includes(search.toLowerCase()) &&
        (city === "All cities" || item.provider.cities.includes(city) || item.provider.areas.includes(city)) &&
        (category === "All categories" || item.provider.trade === category) &&
        (status === "All statuses" || item.provider.status === status) &&
        scoreMatch
      );
    })
    .sort((a, b) => {
      if (sort === "Highest revenue") return b.revenueGenerated - a.revenueGenerated;
      if (sort === "Lowest revenue") return a.revenueGenerated - b.revenueGenerated;
      if (sort === "Best rating") return b.provider.rating - a.provider.rating;
      if (sort === "Worst rating") return a.provider.rating - b.provider.rating;
      if (sort === "Highest complaints") return b.totalComplaints - a.totalComplaints;
      if (sort === "Lowest acceptance") return a.acceptanceRate - b.acceptanceRate;
      if (sort === "Highest completion") return b.completionRate - a.completionRate;
      if (sort === "Inactive") return b.daysInactive - a.daysInactive;
      if (sort === "Newest") return new Date(b.provider.createdAt).getTime() - new Date(a.provider.createdAt).getTime();
      if (sort === "Oldest") return new Date(a.provider.createdAt).getTime() - new Date(b.provider.createdAt).getTime();
      return a.score - b.score;
    });

  const widgets = [
    ["Top 10 technicians", [...metrics].sort((a, b) => b.score - a.score).slice(0, 10)],
    ["Worst technicians", [...metrics].sort((a, b) => a.score - b.score).slice(0, 10)],
    ["Most complaints", [...metrics].sort((a, b) => b.totalComplaints - a.totalComplaints).slice(0, 10)],
    ["Most revenue", [...metrics].sort((a, b) => b.revenueGenerated - a.revenueGenerated).slice(0, 10)],
  ] as const;

  const runAiAnalysis = async () => {
    if (!selected || !user) return;
    setAiLoading(true);
    setAiError("");
    try {
      const token = await getIdToken();
      const response = await fetch("/api/firebase/ai", {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
        body: JSON.stringify({
          prompt: `Analyze technician performance for ${selected.provider.name} (${selected.provider.providerId}). Score ${selected.score}. Acceptance ${selected.acceptanceRate}%. Completion ${selected.completionRate}%. Complaints ${selected.totalComplaints}. Cancellations ${selected.cancelledJobs}. Ignored offers ${selected.ignoredJobs}. Recommend whether to keep, warn, suspend, or deactivate with explanation.`,
          page: { page: "Technician Performance", currentEntityType: "provider", currentEntityId: selected.provider.id },
        }),
      });
      const data = (await response.json().catch(() => ({}))) as { execution?: { summary?: string; answer?: string }; error?: string };
      if (!response.ok) throw new Error(data.error ?? "Gemini analysis failed");
      setAiSummary(data.execution?.summary ?? data.execution?.answer ?? "Gemini analysis saved to Firestore.");
      notify("Technician AI analysis generated");
    } catch (error) {
      const fallback = `${selected.provider.name} has a ${selected.score}/100 score (${selected.grade}). Key risk signals: ${selected.flags.join(", ") || "none detected"}. Review acceptance, complaints, lateness, refunds, and warning history before any account action.`;
      setAiSummary(fallback);
      setAiError(error instanceof Error ? error.message : "Gemini analysis failed");
    } finally {
      setAiLoading(false);
    }
  };

  const updateStatus = async (provider: Provider, nextStatus: TechnicianStatus) => {
    if (nextStatus === "Suspended") await actions.setProviderDecision(provider.id, "suspend");
    else if (nextStatus === "Disabled") await actions.toggleProvider(provider.id);
    else if (nextStatus === "Blacklisted") await actions.setProviderDecision(provider.id, "ban");
    else
      await actions.updateProvider(provider.id, {
        status: nextStatus,
        disabled: false,
        available: nextStatus === "Active" ? provider.available : false,
        activityTimeline: [
          {
            id: `EVT-${Date.now()}`,
            type: "performance.status",
            label: `Performance status changed to ${nextStatus}`,
            at: new Date().toISOString(),
            actor: user?.name ?? "Admin",
          },
          ...(provider.activityTimeline ?? []),
        ],
      });
    notify(`${provider.name} status updated to ${nextStatus}`);
  };

  return (
    <div className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <Kpi label="Technicians monitored" value={metrics.length} icon={UserCog} />
        <Kpi label="Average score" value={Math.round(average(metrics.map((item) => item.score)))} icon={Gauge} />
        <Kpi label="Needs review" value={metrics.filter((item) => item.flags.includes("Needs Review")).length} icon={AlertTriangle} tone="amber" />
        <Kpi label="High risk" value={metrics.filter((item) => item.flags.includes("Risk")).length} icon={Ban} tone="red" />
        <Kpi label="Top performers" value={metrics.filter((item) => item.score >= 85).length} icon={Star} tone="green" />
      </div>

      <Card className="overflow-hidden">
        <div className="flex flex-col gap-3 border-b border-white/[.06] p-4 xl:flex-row xl:items-center">
          <div className="relative min-w-[240px] flex-1">
            <Input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search by ID, name, phone, city, category..." className="h-10 text-xs" />
          </div>
          <SearchableSelect value={city} onChange={setCity} allowEmpty={false} options={["All cities", ...cities].map((value) => ({ label: value, value }))} />
          <SearchableSelect value={category} onChange={setCategory} allowEmpty={false} options={["All categories", ...categories].map((value) => ({ label: value, value }))} />
          <SearchableSelect value={status} onChange={setStatus} allowEmpty={false} options={["All statuses", "Active", "Warning", "Under Review", "Suspended", "Disabled", "Blacklisted", "Review", "Banned", "Blocked"].map((value) => ({ label: value, value }))} />
          <SearchableSelect value={scoreFilter} onChange={setScoreFilter} allowEmpty={false} options={["All scores", "Top performers", "Needs review", "Critical"].map((value) => ({ label: value, value }))} />
          <SearchableSelect value={sort} onChange={setSort} allowEmpty={false} options={["Lowest score", "Highest revenue", "Lowest revenue", "Best rating", "Worst rating", "Highest complaints", "Lowest acceptance", "Highest completion", "Inactive", "Newest", "Oldest"].map((value) => ({ label: value, value }))} />
          {(can("technicians.performance.export") || can("technicians.analytics.export")) && (
            <Button
              variant="secondary"
              onClick={() =>
                exportCsv(
                  "technician-performance.csv",
                  filtered.map((item) => ({
                    providerId: item.provider.providerId,
                    name: item.provider.name,
                    score: item.score,
                    status: item.provider.status,
                    acceptanceRate: item.acceptanceRate,
                    completionRate: item.completionRate,
                    complaints: item.totalComplaints,
                    revenue: item.revenueGenerated,
                  })),
                )
              }
            >
              <Download className="mr-2 h-3.5 w-3.5" />
              CSV
            </Button>
          )}
        </div>

        {filtered.length === 0 ? (
          <div className="py-16 text-center text-xs text-zinc-500">No technicians match the selected real-data filters.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1180px]">
              <thead>
                <tr className="table-head">
                  <th>Technician</th>
                  <th>Score</th>
                  <th>Status</th>
                  <th>Jobs</th>
                  <th>Acceptance</th>
                  <th>Completion</th>
                  <th>Complaints</th>
                  <th>Revenue</th>
                  <th>Flags</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {filtered.map((item) => (
                  <tr key={item.provider.id} className="table-row">
                    <td>
                      <button onClick={() => setSelectedId(item.provider.id)} className="flex items-center gap-3 text-left">
                        <Avatar className="h-9 w-9">
                          {item.provider.photo && <AvatarImage src={item.provider.photo} alt={item.provider.name} />}
                          <AvatarFallback>{item.provider.initials}</AvatarFallback>
                        </Avatar>
                        <span>
                          <span className="block text-xs font-semibold">{item.provider.name}</span>
                          <span className="block font-mono text-[10px] text-indigo-300">{item.provider.providerId}</span>
                          <span className="block text-[9px] text-zinc-500">{item.provider.trade} · Last active {item.provider.lastActive}</span>
                        </span>
                      </button>
                    </td>
                    <td>
                      <span className={cn("inline-flex rounded-full border px-2 py-1 text-[10px] font-semibold", scoreTone(item.score))}>
                        {starLabel(item.score)} ({item.score})
                      </span>
                    </td>
                    <td><StatusPill status={item.provider.status} /></td>
                    <td>{item.jobsReceived}</td>
                    <td>{item.acceptanceRate}%</td>
                    <td>{item.completionRate}%</td>
                    <td>{item.totalComplaints}</td>
                    <td>EGP {item.revenueGenerated.toLocaleString()}</td>
                    <td>
                      <div className="flex max-w-[260px] flex-wrap gap-1">
                        {item.flags.slice(0, 4).map((flag) => <Flag key={flag} label={flag} />)}
                      </div>
                    </td>
                    <td>
                      <RowActions
                        label={`Actions for ${item.provider.name}`}
                        actions={[
                          { label: "View profile", onClick: () => setSelectedId(item.provider.id) },
                          { label: "Open bookings", onClick: () => setSelectedId(item.provider.id) },
                          { label: "Open chats", onClick: () => setSelectedId(item.provider.id) },
                          { label: "Open reviews", onClick: () => setSelectedId(item.provider.id) },
                          { label: "Open complaints", onClick: () => setSelectedId(item.provider.id) },
                          ...(can("technicians.warnings.create") || can("technicians.status.warn") ? [{ label: "Warn technician", onClick: () => setWarningProvider(item.provider), separator: true }] : []),
                          ...(can("technicians.notes.create") ? [{ label: "Add private note", onClick: () => setNoteProvider(item.provider) }] : []),
                          ...(can("notifications.send") ? [{ label: "Send notification", onClick: () => actions.createNotification({ title: `Task update for ${item.provider.name}`, body: "Please review the latest update in your Task Provider app.", audience: "Individual", targetUserId: item.provider.id }).then(() => notify("Notification queued")) }] : []),
                          ...(can("technicians.warnings.create") ? [{ label: "Request explanation", onClick: () => setWarningProvider(item.provider) }] : []),
                          ...(can("technicians.status.suspend") ? [{ label: "Suspend technician", onClick: () => updateStatus(item.provider, "Suspended"), danger: true }] : []),
                          ...(can("technicians.status.disable") ? [{ label: "Disable account", onClick: () => updateStatus(item.provider, "Disabled"), danger: true }] : []),
                          ...(can("technicians.status.blacklist") ? [{ label: "Blacklist technician", onClick: () => updateStatus(item.provider, "Blacklisted"), danger: true }] : []),
                          ...(can("technicians.status.reactivate") ? [{ label: "Reactivate account", onClick: () => updateStatus(item.provider, "Active") }] : []),
                          ...(can("technicians.warnings.reset") ? [{ label: "Reset warnings", onClick: () => actions.updateProvider(item.provider.id, { performanceWarnings: [] }).then(() => notify("Warnings reset")) }] : []),
                        ]}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {selected && (
        <div className="grid gap-5 xl:grid-cols-[1.15fr_.85fr]">
          <Card className="p-5">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
              <div className="flex items-center gap-4">
                <Avatar className="h-14 w-14">
                  {selected.provider.photo && <AvatarImage src={selected.provider.photo} alt={selected.provider.name} />}
                  <AvatarFallback>{selected.provider.initials}</AvatarFallback>
                </Avatar>
                <div>
                  <h2 className="text-lg font-semibold">{selected.provider.name}</h2>
                  <p className="font-mono text-[11px] text-indigo-300">{selected.provider.providerId}</p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    <StatusPill status={selected.provider.available ? "Online" : "Offline"} />
                    <StatusPill status={selected.provider.available ? "Available" : "Busy"} />
                    <StatusPill status={selected.provider.verified ? "Verified" : "Unverified"} />
                    <StatusPill status={selected.provider.status} />
                  </div>
                </div>
              </div>
              <div className={cn("rounded-2xl border p-4 text-center", scoreTone(selected.score))}>
                <div className="text-3xl font-bold">{selected.score}</div>
                <div className="text-[10px] uppercase tracking-wider">{selected.grade}</div>
              </div>
            </div>

            <div className="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
              <Mini label="Received" value={selected.jobsReceived} />
              <Mini label="Accepted" value={selected.acceptedJobs} />
              <Mini label="Rejected" value={selected.rejectedJobs} />
              <Mini label="Ignored" value={selected.ignoredJobs} />
              <Mini label="Completed" value={selected.completedJobs} />
              <Mini label="Cancelled" value={selected.cancelledJobs} />
              <Mini label="Provider cancelled" value={selected.providerCancelledJobs} />
              <Mini label="Customer cancelled" value={selected.customerCancelledJobs} />
            </div>

            <div className="mt-5 grid gap-4 lg:grid-cols-3">
              <MetricPanel title="Job performance" rows={[
                ["Completion rate", `${selected.completionRate}%`],
                ["Acceptance rate", `${selected.acceptanceRate}%`],
                ["Offer response rate", `${selected.offerResponseRate}%`],
                ["Avg completion", `${selected.averageCompletionMinutes} min`],
                ["Avg arrival delay", `${selected.averageArrivalDelayMinutes} min`],
                ["Avg job duration", `${selected.averageJobDurationMinutes} min`],
              ]} />
              <MetricPanel title="Response performance" rows={[
                ["Avg offer response", `${selected.averageOfferResponseMinutes} min`],
                ["Avg chat response", `${selected.averageMessageResponseMinutes} min`],
                ["Longest unanswered", `${selected.longestUnansweredOfferMinutes} min`],
                ["Ignored chats", selected.ignoredChats],
                ["Late arrivals", selected.lateArrivals],
                ["Missed appointments", selected.missedAppointments],
              ]} />
              <MetricPanel title="Financial" rows={[
                ["Revenue generated", `EGP ${selected.revenueGenerated.toLocaleString()}`],
                ["Jobs value", `EGP ${selected.jobsValue.toLocaleString()}`],
                ["Commission paid", `EGP ${selected.commissionPaid.toLocaleString()}`],
                ["Pending payouts", `EGP ${selected.pendingPayouts.toLocaleString()}`],
                ["Refunds", `EGP ${selected.refunds.toLocaleString()}`],
                ["Avg order value", `EGP ${selected.averageOrderValue.toLocaleString()}`],
              ]} />
            </div>
          </Card>

          <Card className="p-5">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-semibold">AI analysis</h3>
                <p className="mt-1 text-[10px] text-zinc-500">Gemini server-side if configured; otherwise live rule summary.</p>
              </div>
              <Button onClick={runAiAnalysis} disabled={aiLoading || !can("technicians.performance.aiSummary")}>
                {aiLoading ? <RefreshCcw className="mr-2 h-3.5 w-3.5 animate-spin" /> : <Gauge className="mr-2 h-3.5 w-3.5" />}
                Generate
              </Button>
            </div>
            <div className="mt-4 rounded-2xl border border-white/[.06] bg-black/10 p-4 text-sm leading-6 text-zinc-300">
              {aiSummary || `${selected.provider.name} currently scores ${selected.score}/100. ${selected.flags.length ? `Detected flags: ${selected.flags.join(", ")}.` : "No major risk flags detected."} Use warnings, suspension, or reactivation only after reviewing jobs, complaints, and timeline evidence.`}
            </div>
            {aiError && <p className="mt-2 text-[10px] text-amber-400">Gemini unavailable: {aiError}</p>}
            <div className="mt-5 h-[220px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={[
                  { name: "Acceptance", value: selected.acceptanceRate },
                  { name: "Completion", value: selected.completionRate },
                  { name: "Response", value: selected.offerResponseRate },
                  { name: "Score", value: selected.score },
                ]}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,.08)" />
                  <XAxis dataKey="name" tick={{ fontSize: 10 }} />
                  <YAxis tick={{ fontSize: 10 }} />
                  <Tooltip />
                  <Bar dataKey="value" radius={[8, 8, 0, 0]} fill="#8b5cf6" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Card>

          <Card className="p-5 xl:col-span-2">
            <div className="grid gap-5 xl:grid-cols-4">
              {widgets.map(([title, rows]) => (
                <div key={title} className="rounded-2xl border border-white/[.06] bg-white/[.025] p-4">
                  <h3 className="text-xs font-semibold">{title}</h3>
                  <div className="mt-3 space-y-2">
                    {rows.length === 0 && <p className="text-[10px] text-zinc-500">No real data yet.</p>}
                    {rows.slice(0, 5).map((item) => (
                      <button key={item.provider.id} onClick={() => setSelectedId(item.provider.id)} className="flex w-full items-center justify-between gap-2 text-left text-[10px]">
                        <span className="truncate">{item.provider.name}</span>
                        <span className="text-zinc-500">{item.score}</span>
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card className="p-5">
            <h3 className="text-sm font-semibold">Reviews & quality</h3>
            <div className="mt-4 grid grid-cols-[160px_1fr] gap-4">
              <div className="h-[160px]">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={Object.entries(selected.reviewDistribution).map(([name, value]) => ({ name: `${name}★`, value }))} dataKey="value" innerRadius={42} outerRadius={70}>
                      {Object.keys(selected.reviewDistribution).map((key, index) => <Cell key={key} fill={["#ef4444", "#f97316", "#f59e0b", "#84cc16", "#22c55e"][index]} />)}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <MetricPanel title="Quality signals" rows={[
                ["Average rating", `${selected.provider.rating || 0} / 5`],
                ["Total reviews", selected.latestReviews.length],
                ["1-star reviews", selected.reviewDistribution[1]],
                ["2-star reviews", selected.reviewDistribution[2]],
                ["3-star reviews", selected.reviewDistribution[3]],
                ["4-star reviews", selected.reviewDistribution[4]],
                ["5-star reviews", selected.reviewDistribution[5]],
              ]} />
            </div>
            <div className="mt-4 rounded-2xl border border-white/[.06] p-4 text-[10px] text-zinc-500">
              {selected.latestReviews.length ? (
                <div className="space-y-3">
                  {selected.latestReviews.map((review) => (
                    <div key={review.id} className="rounded-xl border border-white/[.06] bg-white/[.025] p-3">
                      <div className="flex items-center justify-between gap-3">
                        <span className="text-xs font-medium">{review.customerName}</span>
                        <span className="text-amber-400">{"★".repeat(review.rating)}</span>
                      </div>
                      <p className="mt-2 text-[10px] text-zinc-500">{review.comment}</p>
                      <p className="mt-1 text-[9px] text-zinc-600">{review.jobId ?? "No job linked"} · {new Date(review.createdAt).toLocaleString()}</p>
                    </div>
                  ))}
                </div>
              ) : "No review records exist for this technician yet."}
            </div>
          </Card>

          <Card className="p-5">
            <h3 className="text-sm font-semibold">Complaints & timeline</h3>
            <div className="mt-4 grid gap-3 sm:grid-cols-3">
              <Mini label="Total complaints" value={selected.totalComplaints} />
              <Mini label="Open" value={selected.openComplaints} />
              <Mini label="Resolved" value={selected.resolvedComplaints} />
            </div>
            <div className="mt-4 space-y-2">
              {selected.commonComplaints.length === 0 && <p className="text-[10px] text-zinc-500">No repeated complaint patterns detected.</p>}
              {selected.commonComplaints.map(([label, count]) => <Flag key={label} label={`${label} × ${count}`} />)}
            </div>
            <div className="mt-5 max-h-72 space-y-3 overflow-auto">
              {[...(selected.provider.performanceWarnings ?? []).map((warning) => ({ id: warning.id, label: `Warning: ${warning.reason}`, at: warning.createdAt, actor: warning.createdBy })), ...(selected.provider.activityTimeline ?? [])]
                .sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime())
                .slice(0, 12)
                .map((event) => (
                  <div key={event.id} className="rounded-xl border border-white/[.06] bg-white/[.025] p-3">
                    <div className="text-xs font-medium">{event.label}</div>
                    <div className="mt-1 text-[10px] text-zinc-500">{new Date(event.at).toLocaleString()} · {event.actor}</div>
                  </div>
                ))}
            </div>
          </Card>
        </div>
      )}

      <FormDialog
        open={!!warningProvider}
        onClose={() => setWarningProvider(null)}
        title="Warn technician"
        description="Warnings are private operational records and are stored on the technician profile."
        fields={[
          { name: "reason", label: "Reason", required: true },
          { name: "notes", label: "Internal notes", type: "textarea", required: true },
        ]}
        submitLabel="Save warning"
        onSubmit={async (values) => {
          if (!warningProvider) return;
          const warning: ProviderWarning = {
            id: `WRN-${Date.now()}`,
            reason: values.reason,
            notes: values.notes,
            status: "Open",
            createdAt: new Date().toISOString(),
            createdBy: user?.name ?? "Admin",
            createdById: user?.id,
          };
          await actions.updateProvider(warningProvider.id, {
            status: "Warning",
            performanceWarnings: [warning, ...(warningProvider.performanceWarnings ?? [])],
            activityTimeline: [
              {
                id: `EVT-${Date.now()}`,
                type: "performance.warning",
                label: `Warning issued: ${warning.reason}`,
                at: warning.createdAt,
                actor: warning.createdBy,
              },
              ...(warningProvider.activityTimeline ?? []),
            ],
          });
          notify("Technician warning saved");
        }}
      />
      <FormDialog
        open={!!noteProvider}
        onClose={() => setNoteProvider(null)}
        title="Add private technician note"
        fields={[{ name: "note", label: "Private note", type: "textarea", required: true }]}
        submitLabel="Save note"
        onSubmit={async (values) => {
          if (!noteProvider) return;
          const note = `${new Date().toLocaleString()} · ${user?.name ?? "Admin"}: ${values.note}`;
          await actions.updateProvider(noteProvider.id, { notes: [note, ...(noteProvider.notes ?? [])] });
          notify("Private technician note saved");
        }}
      />
      {mutationPending && <div className="fixed bottom-4 right-4 rounded-full border border-white/[.08] bg-black/80 px-4 py-2 text-xs text-zinc-200">Saving technician action…</div>}
    </div>
  );
}

function Kpi({ label, value, icon: Icon, tone = "indigo" }: { label: string; value: number; icon: typeof Gauge; tone?: "indigo" | "green" | "amber" | "red" }) {
  const tones = {
    indigo: "text-indigo-400 bg-indigo-500/10",
    green: "text-emerald-400 bg-emerald-500/10",
    amber: "text-amber-400 bg-amber-500/10",
    red: "text-red-400 bg-red-500/10",
  };
  return (
    <Card className="flex items-center gap-4 p-4">
      <span className={cn("grid h-11 w-11 place-items-center rounded-xl", tones[tone])}><Icon className="h-5 w-5" /></span>
      <div><div className="text-2xl font-semibold">{value}</div><div className="text-[10px] text-zinc-500">{label}</div></div>
    </Card>
  );
}

function Mini({ label, value }: { label: string; value: string | number }) {
  return <div className="rounded-2xl border border-white/[.06] bg-white/[.025] p-3"><div className="text-lg font-semibold">{value}</div><div className="text-[10px] text-zinc-500">{label}</div></div>;
}

function MetricPanel({ title, rows }: { title: string; rows: Array<[string, string | number]> }) {
  return (
    <div className="rounded-2xl border border-white/[.06] bg-white/[.025] p-4">
      <h3 className="text-xs font-semibold">{title}</h3>
      <div className="mt-3 space-y-2">
        {rows.map(([label, value]) => (
          <div key={label} className="flex items-center justify-between gap-3 text-[10px]">
            <span className="text-zinc-500">{label}</span>
            <span className="font-medium text-zinc-200">{value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function StatusPill({ status }: { status: string }) {
  const danger = ["Suspended", "Disabled", "Blacklisted", "Banned", "Blocked", "Offline"].includes(status);
  const warning = ["Warning", "Under Review", "Review", "Busy", "Unverified"].includes(status);
  return <Badge variant={danger ? "destructive" : warning ? "warning" : "success"} className="text-[9px]">{status}</Badge>;
}

function Flag({ label }: { label: string }) {
  return <span className="inline-flex rounded-full border border-white/[.08] bg-white/[.04] px-2 py-1 text-[9px] text-zinc-300">{label}</span>;
}
