import type {
  AiEvidence,
  AiRecommendation,
  Customer,
  DatabaseState,
  Job,
  Provider,
  Transaction,
} from "@/lib/types";
import type { AiToolName } from "@/lib/ai/permissions";

export interface AiToolResult<T = unknown> {
  tool: AiToolName;
  summary: string;
  records: T[];
  evidence: AiEvidence[];
}

const norm = (value: unknown) => String(value ?? "").toLowerCase();
const money = (value: number) => `EGP ${Math.round(value).toLocaleString()}`;
const id = (prefix: string) =>
  `${prefix}-${Date.now().toString(36)}-${Math.random().toString(16).slice(2, 7)}`;

function includes(record: unknown, query: string) {
  return norm(JSON.stringify(record)).includes(norm(query));
}

export function searchCustomers(state: DatabaseState, query: string): AiToolResult<Customer> {
  const records = state.customers.filter((customer) => includes(customer, query)).slice(0, 10);
  return {
    tool: "searchCustomer",
    summary: `${records.length} customer record${records.length === 1 ? "" : "s"} matched "${query}".`,
    records,
    evidence: records.slice(0, 3).map((customer) => ({
      id: id("EV"),
      label: customer.name,
      entityType: "customer",
      entityId: customer.id,
      value: `${customer.phone} · wallet ${money(customer.walletBalance)} · ${customer.status}`,
    })),
  };
}

export function searchProviders(state: DatabaseState, query: string): AiToolResult<Provider> {
  const records = state.providers.filter((provider) => includes(provider, query)).slice(0, 10);
  return {
    tool: "searchProvider",
    summary: `${records.length} provider record${records.length === 1 ? "" : "s"} matched "${query}".`,
    records,
    evidence: records.slice(0, 3).map((provider) => ({
      id: id("EV"),
      label: `${provider.providerId} · ${provider.name}`,
      entityType: "provider",
      entityId: provider.id,
      value: `${provider.trade} · ${provider.rating.toFixed(1)}★ · ${provider.status}`,
    })),
  };
}

export function searchJobs(state: DatabaseState, query: string): AiToolResult<Job> {
  const records = state.jobs.filter((job) => includes(job, query)).slice(0, 10);
  return {
    tool: "searchJob",
    summary: `${records.length} job/request record${records.length === 1 ? "" : "s"} matched "${query}".`,
    records,
    evidence: records.slice(0, 3).map((job) => ({
      id: id("EV"),
      label: `${job.id} · ${job.service}`,
      entityType: "job",
      entityId: job.id,
      value: `${job.customer} · ${job.status} · ${job.paymentStatus}`,
    })),
  };
}

export function searchPayments(state: DatabaseState, query: string): AiToolResult<Transaction> {
  const records = state.transactions.filter((transaction) => includes(transaction, query)).slice(0, 10);
  return {
    tool: "searchPayment",
    summary: `${records.length} payment transaction${records.length === 1 ? "" : "s"} matched "${query}".`,
    records,
    evidence: records.slice(0, 3).map((transaction) => ({
      id: id("EV"),
      label: transaction.id,
      entityType: "payment",
      entityId: transaction.id,
      value: `${transaction.type} · ${money(transaction.amount)} · ${transaction.status}`,
    })),
  };
}

export function findBestJob(state: DatabaseState, query: string) {
  const exact = state.jobs.find((job) => norm(job.id) === norm(query));
  if (exact) return exact;
  return searchJobs(state, query).records[0];
}

export function summarizeJob(job: Job): AiToolResult<Job> {
  const cancellation = job.cancellation
    ? `Cancelled by ${job.cancellation.cancelledBy}: ${job.cancellation.reason}`
    : "Not cancelled";
  return {
    tool: "summarizeJob",
    summary: `${job.id} is ${job.status}. ${cancellation}. Payment is ${job.paymentStatus}.`,
    records: [job],
    evidence: [
      {
        id: id("EV"),
        label: "Timeline events",
        entityType: "job",
        entityId: job.id,
        value: `${job.timeline?.length ?? 0} events, ${job.offers?.length ?? 0} offers, ${job.messages?.length ?? 0} chat messages, ${job.calls?.length ?? 0} calls`,
      },
      {
        id: id("EV"),
        label: "Payment",
        entityType: "payment",
        entityId: job.payment?.transactionId ?? job.id,
        value: `${job.payment?.method ?? job.paymentMethod} · ${money(job.amount)} · ${job.paymentStatus}`,
      },
    ],
  };
}

export function analyzeCancellation(job: Job): { answer: string; evidence: AiEvidence[]; recommendations: AiRecommendation[] } {
  const evidence = summarizeJob(job).evidence;
  const c = job.cancellation;
  const recommendations: AiRecommendation[] = [];
  if (!c) {
    return {
      answer: `${job.id} is not recorded as cancelled in Firestore.`,
      evidence,
      recommendations,
    };
  }
  if (c.followUpStatus === "Not contacted") {
    recommendations.push({
      id: id("REC"),
      title: "Recover the customer",
      body: "The cancellation has no follow-up. Assign support, call the customer, and offer a targeted recovery action.",
      risk: "MEDIUM",
      action: {
        type: "createComplaint",
        label: "Open recovery case",
        risk: "MEDIUM",
        requiresConfirmation: true,
        payload: {
          title: `Cancellation recovery · ${job.id}`,
          description: `Customer cancelled at ${c.stage}. Reason: ${c.reason}`,
          severity: c.stage === "during job" ? "High" : "Medium",
          jobId: job.id,
          customerId: job.customerId,
          providerId: job.providerId,
          customer: job.customer,
        },
      },
    });
  }
  if (c.refundStatus === "Pending") {
    recommendations.push({
      id: id("REC"),
      title: "Review refund",
      body: "Refund status is pending. Finance should approve or reject after checking payment history.",
      risk: "CRITICAL",
      action: {
        type: "refundJob",
        label: "Refund to wallet",
        risk: "CRITICAL",
        requiresConfirmation: true,
        payload: { jobId: job.id },
      },
    });
  }
  return {
    answer: `${job.id} was cancelled by ${c.cancelledBy} ${c.stage}. Recorded reason: "${c.reason}". Follow-up is ${c.followUpStatus}; refund status is ${c.refundStatus}.`,
    evidence: [
      ...evidence,
      {
        id: id("EV"),
        label: "Cancellation record",
        entityType: "job",
        entityId: job.id,
        value: `${c.cancelledAt} · ${c.stage} · ${c.reason}`,
      },
    ],
    recommendations,
  };
}

export function marketplaceMetrics(state: DatabaseState) {
  const paidJobs = state.jobs.filter((job) => job.paymentStatus === "Paid");
  const revenue = paidJobs.reduce((sum, job) => sum + Number(job.amount ?? 0), 0);
  const cancelled = state.jobs.filter((job) => job.status === "Cancelled" || job.cancellation);
  const active = state.jobs.filter((job) => !["Completed", "Cancelled", "Refunded"].includes(job.status));
  const emergency = active.filter((job) => job.priority === "Emergency");
  const unassigned = active.filter((job) => !job.providerId);
  const onlineProviders = state.locations.filter((location) => location.status !== "Offline");
  const responseSamples = state.jobs
    .flatMap((job) => (job.offers ?? []).map((offer) => (new Date(offer.createdAt).getTime() - new Date(job.createdAt).getTime()) / 60000))
    .filter((value) => Number.isFinite(value) && value >= 0);
  return {
    revenue,
    bookings: state.jobs.length,
    active: active.length,
    cancelled: cancelled.length,
    cancellationRate: state.jobs.length ? cancelled.length / state.jobs.length : 0,
    emergency: emergency.length,
    unassigned: unassigned.length,
    onlineProviders: onlineProviders.length,
    avgResponseMinutes: responseSamples.length ? responseSamples.reduce((a, b) => a + b, 0) / responseSamples.length : 0,
  };
}

function distanceKm(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const r = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const x = Math.sin(dLat / 2) ** 2 + Math.sin(dLng / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2);
  return r * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

export function dispatchRecommendation(state: DatabaseState, job?: Job): {
  answer: string;
  evidence: AiEvidence[];
  recommendations: AiRecommendation[];
} {
  const target = job ?? state.jobs.find((item) => !item.providerId && !["Completed", "Cancelled", "Refunded"].includes(item.status));
  if (!target) {
    return { answer: "No unassigned active job was found in Firestore.", evidence: [], recommendations: [] };
  }
  const service = state.services.find((item) => item.id === target.serviceId);
  const scored = state.providers
    .filter((provider) => provider.verified && provider.status === "Active" && provider.available)
    .filter((provider) => !service || provider.serviceIds.includes(service.id) || provider.trade.toLowerCase().includes(service.name.toLowerCase()) || provider.areas.includes(target.area))
    .map((provider) => {
      const location = state.locations.find((item) => item.providerId === provider.id && item.status !== "Offline");
      const distance = location && target.gps ? distanceKm(location, target.gps) : 99;
      const complaints = state.complaints.filter((caseItem) => caseItem.providerId === provider.id && caseItem.status !== "Closed").length;
      const workload = state.jobs.filter((item) => item.providerId === provider.id && ["Assigned", "En route", "In progress", "Delayed"].includes(item.status)).length;
      const score = provider.rating * 18 + provider.acceptanceRate * 0.25 - distance * 4 - complaints * 12 - workload * 10;
      return { provider, location, distance, complaints, workload, score };
    })
    .sort((a, b) => b.score - a.score);
  const best = scored[0];
  if (!best) {
    return {
      answer: `No eligible verified provider is currently available for ${target.id}.`,
      evidence: [{ id: id("EV"), label: "Eligibility gate", entityType: "job", entityId: target.id, value: "Requires verified, active, available provider with service/area match." }],
      recommendations: [],
    };
  }
  return {
    answer: `${best.provider.providerId} ${best.provider.name} is the strongest dispatch candidate for ${target.id}. Score ${best.score.toFixed(1)}, ${best.distance === 99 ? "no live distance yet" : `${best.distance.toFixed(1)} km away`}, ${best.workload} active jobs, ${best.complaints} open complaints.`,
    evidence: scored.slice(0, 3).map((item) => ({
      id: id("EV"),
      label: `${item.provider.providerId} · ${item.provider.name}`,
      entityType: "provider",
      entityId: item.provider.id,
      value: `${item.provider.rating.toFixed(1)}★ · ${item.provider.acceptanceRate}% acceptance · ${item.distance === 99 ? "distance pending" : `${item.distance.toFixed(1)} km`} · score ${item.score.toFixed(1)}`,
    })),
    recommendations: [
      {
        id: id("REC"),
        title: "Assign recommended provider",
        body: "This will dispatch the provider after human confirmation. The AI will not auto-assign.",
        risk: "HIGH",
        action: {
          type: "assignProvider",
          label: `Assign ${best.provider.providerId}`,
          risk: "HIGH",
          requiresConfirmation: true,
          payload: { jobId: target.id, providerId: best.provider.id },
        },
      },
    ],
  };
}

export function executiveBrief(state: DatabaseState): {
  answer: string;
  metrics: ReturnType<typeof marketplaceMetrics>;
  evidence: AiEvidence[];
  recommendations: AiRecommendation[];
} {
  const metrics = marketplaceMetrics(state);
  const serviceDemand = [...state.jobs.reduce((map, job) => map.set(job.service, (map.get(job.service) ?? 0) + 1), new Map<string, number>())]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);
  const cityDemand = [...state.jobs.reduce((map, job) => map.set(job.city ?? job.area, (map.get(job.city ?? job.area) ?? 0) + 1), new Map<string, number>())]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);
  const recommendations: AiRecommendation[] = [];
  if (metrics.unassigned > 0) {
    recommendations.push({
      id: id("REC"),
      title: "Clear unassigned queue",
      body: `${metrics.unassigned} active jobs have no provider. Run dispatch recommendation for the oldest unassigned job.`,
      risk: "MEDIUM",
      action: { type: "navigate", label: "Open Live Operations", risk: "LOW", requiresConfirmation: false, payload: { section: "Live operations" } },
    });
  }
  if (metrics.cancellationRate > 0.15) {
    recommendations.push({
      id: id("REC"),
      title: "Investigate cancellation spike",
      body: `Cancellation rate is ${(metrics.cancellationRate * 100).toFixed(1)}%. Review cancelled requests without follow-up.`,
      risk: "MEDIUM",
      action: { type: "navigate", label: "Open Jobs", risk: "LOW", requiresConfirmation: false, payload: { section: "Jobs", filter: "Cancelled" } },
    });
  }
  return {
    answer: `Revenue is ${money(metrics.revenue)} across ${metrics.bookings} bookings. ${metrics.active} jobs are active, ${metrics.unassigned} are unassigned, ${metrics.emergency} are emergency, and ${metrics.onlineProviders} providers have live locations.`,
    metrics,
    evidence: [
      { id: id("EV"), label: "Top services", entityType: "system", value: serviceDemand.length ? serviceDemand.map(([name, count]) => `${name}: ${count}`).join(", ") : "No jobs yet" },
      { id: id("EV"), label: "Top cities/areas", entityType: "system", value: cityDemand.length ? cityDemand.map(([name, count]) => `${name}: ${count}`).join(", ") : "No jobs yet" },
      { id: id("EV"), label: "Average response", entityType: "system", value: `${metrics.avgResponseMinutes.toFixed(1)} minutes` },
    ],
    recommendations,
  };
}

export function fraudSignals(state: DatabaseState): {
  answer: string;
  evidence: AiEvidence[];
  recommendations: AiRecommendation[];
} {
  const refundByCustomer = new Map<string, number>();
  state.transactions
    .filter((transaction) => transaction.type === "Customer refund")
    .forEach((transaction) => refundByCustomer.set(transaction.ownerId ?? transaction.party, (refundByCustomer.get(transaction.ownerId ?? transaction.party) ?? 0) + transaction.amount));
  const suspiciousCustomers = [...refundByCustomer]
    .sort((a, b) => b[1] - a[1])
    .filter(([, amount]) => amount > 1000)
    .slice(0, 5);
  const duplicatePhones = [...state.customers.reduce((map, customer) => map.set(customer.phone, (map.get(customer.phone) ?? 0) + 1), new Map<string, number>())]
    .filter(([, count]) => count > 1);
  const evidence: AiEvidence[] = [
    { id: id("EV"), label: "High refund exposure", entityType: "payment", value: suspiciousCustomers.length ? suspiciousCustomers.map(([owner, amount]) => `${owner}: ${money(amount)}`).join(", ") : "No customer exceeds refund threshold." },
    { id: id("EV"), label: "Duplicate customer phones", entityType: "customer", value: duplicatePhones.length ? duplicatePhones.map(([phone, count]) => `${phone}: ${count}`).join(", ") : "No duplicate customer phones found." },
  ];
  return {
    answer: suspiciousCustomers.length || duplicatePhones.length
      ? "Fraud review found signals that need human investigation."
      : "No suspicious refund, duplicate phone, or obvious wallet-abuse pattern is visible in Firestore right now.",
    evidence,
    recommendations: suspiciousCustomers.length
      ? [{
          id: id("REC"),
          title: "Open trust review",
          body: "Create a Trust & Safety case for the highest refund exposure customer before more wallet adjustments.",
          risk: "HIGH",
        }]
      : [],
  };
}
