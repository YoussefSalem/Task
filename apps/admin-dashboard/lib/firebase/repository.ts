import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  limit,
  onSnapshot,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
  type DocumentData,
  type QueryConstraint,
  type Unsubscribe,
} from "firebase/firestore";
import { getFirebaseClient } from "@/lib/firebase/client";
import type {
  AdminUser,
  AiExecution,
  AiMemory,
  AiReport,
  Banner,
  Complaint,
  DatabaseState,
  Job,
  JobPaymentStatus,
  ProviderLocation,
  Provider,
  ProviderDocument,
  Role,
  Service,
  SupportConversation,
} from "@/lib/types";
import {
  DEMO_RESTRICTED_MESSAGE,
  assertDemoCanRun,
  dataEnvironment,
  isDemoData,
} from "@/lib/demo-mode";
import { hasPermission, isSuperAdminRole } from "@/lib/permissions";
import { adminJobStatusFromWire, jobWireStatusFromAdmin } from "@/lib/firebase/job-status-mapping";
import {
  buildRealNotificationDoc,
  resolveNotificationFanout,
  type NotificationAudience,
} from "@/lib/firebase/notification-fanout";
import {
  providerSourceCollection,
  customerSourceCollection,
  jobSourceCollection,
  resolveReadSource,
} from "@/lib/firebase/entity-routing";
import { adminStatusFromUser } from "@/lib/firebase/account-status-mapping";
import { checkProductionWriteAccess } from "@/lib/firebase/read-only-mode";
import {
  mapRealChatMessage,
  mapRealChatThread,
  mapRealNotification,
  type RealChatMessage,
  type RealChatThread,
  type RealNotification,
} from "@/lib/firebase/real-schema-types";

const emptyState: DatabaseState = {
  aiExecutions: [],
  aiMemories: [],
  aiReports: [],
  customers: [],
  providers: [],
  jobs: [],
  categories: [],
  services: [],
  banners: [],
  conversations: [],
  verificationRequirements: [],
  wallets: [],
  transactions: [],
  complaints: [],
  reviews: [],
  admins: [],
  invitations: [],
  roles: [],
  promos: [],
  notifications: [],
  payouts: [],
  auditLogs: [],
  locations: [],
  instapayReviews: [],
  sequences: { provider: 0 },
  issuedProviderIds: [],
};
const collections = {
  aiExecutions: "aiExecutions",
  aiMemories: "aiMemories",
  aiReports: "aiReports",
  customers: "customers",
  providers: "providers",
  jobs: "orders",
  categories: "categories",
  services: "services",
  banners: "banners",
  conversations: "conversations",
  verificationRequirements: "verificationRequirements",
  wallets: "wallets",
  transactions: "transactions",
  complaints: "complaints",
  reviews: "reviews",
  admins: "admins",
  invitations: "adminInvites",
  roles: "roles",
  promos: "promos",
  notifications: "notifications",
  payouts: "payouts",
  auditLogs: "auditLogs",
  locations: "providerLocations",
  instapayReviews: "instapayReviews",
} as const;
const environmentScopedCollections = new Set<StateArrayKey>([
  "categories",
  "services",
  "banners",
  "customers",
  "providers",
  "jobs",
  "conversations",
  "wallets",
  "transactions",
  "complaints",
  "reviews",
  "payouts",
  "instapayReviews",
  "locations",
  "promos",
  "notifications",
  "auditLogs",
  "aiExecutions",
  "aiMemories",
  "aiReports",
]);
type StateArrayKey = Exclude<
  keyof DatabaseState,
  "sequences" | "issuedProviderIds"
>;
const now = () => new Date().toISOString();
const publicId = (prefix: string) =>
  `${prefix}-${Date.now().toString(36).toUpperCase()}-${crypto.randomUUID().slice(0, 6).toUpperCase()}`;
const clean = <T>(value: T): T =>
  JSON.parse(
    JSON.stringify(value, (key, item) => (item === undefined ? null : item)),
  ) as T;
const environmentForActor = (actor: AdminUser) =>
  actor.isDemoUser ? "demo" : "production";

type FirestoreLikeDate =
  | string
  | Date
  | { toDate?: () => Date; seconds?: number; nanoseconds?: number }
  | null
  | undefined;

const asIso = (value: FirestoreLikeDate, fallback = now()) => {
  if (!value) return fallback;
  if (typeof value === "string") return value;
  if (value instanceof Date) return value.toISOString();
  if (typeof value.toDate === "function") return value.toDate().toISOString();
  if (typeof value.seconds === "number")
    return new Date(value.seconds * 1000).toISOString();
  return fallback;
};

const initials = (name: string) =>
  name
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

const displayNameFromUser = (data: Record<string, unknown>) => {
  const full = String(data.name ?? data.display_name ?? "").trim();
  if (full) return full;
  return [data.first_name, data.last_name]
    .map((part) => String(part ?? "").trim())
    .filter(Boolean)
    .join(" ")
    .trim();
};

// adminStatusFromUser moved to account-status-mapping.ts so an unrecognized
// (but present) status value never silently defaults to "Active".

const providerStatusFromUser = (data: Record<string, unknown>): Provider["status"] => {
  if (data.disabled === true) return "Disabled";
  const status = String(data.status ?? data.kyc_status ?? "").toLowerCase();
  if (status === "approved" || status === "active") return "Active";
  if (status === "rejected") return "Rejected";
  if (status === "suspended") return "Suspended";
  if (status === "banned") return "Banned";
  if (status === "blacklisted") return "Blacklisted";
  if (status === "blocked") return "Blocked";
  if (status === "under_review") return "Under Review";
  return "Review";
};

const providerVerifiedFromUser = (data: Record<string, unknown>) =>
  data.verified === true ||
  data.kyc_status === "approved" ||
  data.status === "approved" ||
  data.status === "active";

// adminJobStatusFromWire / jobWireStatusFromAdmin moved to job-status-mapping.ts
// so unknown/new Customer App status values (e.g. disputed, pausedForApproval)
// are mapped explicitly instead of silently coerced to "Scheduled".

const bookingTypeFromWire = (value: unknown, urgency?: unknown): Job["bookingType"] => {
  const normalized = String(value ?? "").trim();
  if (normalized === "asap" || normalized === "Emergency") return "Emergency";
  if (normalized === "quote" || normalized === "Quotation") return "Quotation";
  if (String(urgency ?? "").toLowerCase() === "emergency") return "Emergency";
  return "Scheduled";
};

const bookingTypeToWire = (value: unknown) => {
  if (value === "Emergency") return "asap";
  if (value === "Quotation") return "quote";
  return "scheduled";
};

const paymentStatusFromWire = (value: unknown): JobPaymentStatus => {
  switch (String(value ?? "").trim()) {
    case "authorized":
      return "Authorized";
    case "captured":
      return "Paid";
    case "failed":
      return "Failed";
    case "refunded":
      return "Refunded";
    case "pending_admin_approval":
      return "Instapay Pending Review";
    default:
      return "Pending";
  }
};

const mapCustomerDoc = (id: string, data: Record<string, unknown>) => {
  const name = displayNameFromUser(data) || String(data.email ?? data.phone ?? id);
  return {
    id,
    customerId: String(data.customer_id ?? data.customerId ?? id),
    name,
    initials: String(data.initials ?? initials(name)),
    email: String(data.email ?? ""),
    phone: String(data.phone ?? data.phone_number ?? ""),
    status: adminStatusFromUser(data),
    disabled: data.disabled === true,
    walletBalance: Number(data.walletBalance ?? data.wallet_balance ?? 0),
    bookings: Number(data.bookings ?? data.jobs_count ?? 0),
    totalSpend: Number(data.totalSpend ?? data.total_spend ?? 0),
    rating: Number(data.rating ?? 5),
    risk: (data.risk as "Healthy" | "Watch" | "Review") ?? "Healthy",
    addresses: (data.addresses as string[] | undefined) ?? [],
    createdAt: asIso(data.created_at as FirestoreLikeDate, asIso(data.createdAt as FirestoreLikeDate)),
    environment: dataEnvironment(data),
    isDemoData: isDemoData(data),
  };
};

const mapProviderDoc = (id: string, data: Record<string, unknown>): Provider => {
  const name = displayNameFromUser(data) || String(data.email ?? data.phone ?? id);
  const primaryCategory = String(data.primary_category ?? data.trade ?? "General");
  return {
    id,
    providerId: String(data.provider_id ?? data.providerId ?? id),
    name,
    initials: String(data.initials ?? initials(name)),
    email: String(data.email ?? ""),
    phone: String(data.phone ?? data.phone_number ?? ""),
    nationalIdNumber: String(data.national_id_number ?? data.nationalIdNumber ?? ""),
    photo: String(data.photo_url ?? data.photo ?? "") || undefined,
    trade: primaryCategory,
    rating: Number(data.rating ?? 0),
    acceptanceRate: Number(data.acceptance_rate ?? data.acceptanceRate ?? 0),
    jobs: Number(data.jobs_done ?? data.jobs ?? 0),
    earnings: Number(data.earnings ?? 0),
    status: providerStatusFromUser(data),
    disabled: data.disabled === true,
    verified: providerVerifiedFromUser(data),
    response: String(data.response ?? data.response_time ?? "—"),
    serviceIds: (data.service_ids as string[] | undefined) ?? (data.serviceIds as string[] | undefined) ?? [],
    areas: (data.areas as string[] | undefined) ?? [],
    cities: (data.cities as string[] | undefined) ?? [],
    commission: Number(data.commission ?? 18),
    available: Boolean(data.available ?? data.online ?? false),
    requiredDocumentTypes: (data.requiredDocumentTypes as string[] | undefined) ?? [],
    documents: (data.documents as ProviderDocument[] | undefined) ?? [],
    verification: (data.verification as Provider["verification"] | undefined) ?? {
      stage: providerVerifiedFromUser(data) ? "Provider Active" : "Registration",
      backgroundCheck: "Not Started",
      contractSigned: false,
      internalNotes: [],
      updatedAt: now(),
    },
    activityTimeline: (data.activityTimeline as Provider["activityTimeline"] | undefined) ?? [],
    lastLogin: asIso(data.last_login as FirestoreLikeDate, ""),
    lastActive: String(data.last_active ?? data.lastActive ?? "Never"),
    availabilitySchedule: (data.availabilitySchedule as Record<string, string> | undefined) ?? {},
    bankInfo: (data.bankInfo as Provider["bankInfo"] | undefined) ?? { bankName: "", iban: "", instapay: "" },
    notes: Array.isArray(data.notes)
      ? (data.notes as string[])
      : String(data.notes ?? "")
          .split("\n")
          .map((item) => item.trim())
          .filter(Boolean),
    performanceWarnings: data.performanceWarnings as Provider["performanceWarnings"],
    createdAt: asIso(data.created_at as FirestoreLikeDate, asIso(data.createdAt as FirestoreLikeDate)),
    environment: dataEnvironment(data),
    isDemoData: isDemoData(data),
  };
};

const mapOffer = (jobId: string, offer: Record<string, unknown>) => {
  const status: "Pending" | "Accepted" | "Rejected" | "Expired" | "Withdrawn" =
    offer.status === "accepted"
      ? "Accepted"
      : offer.status === "declined"
        ? "Rejected"
        : offer.status === "withdrawn"
          ? "Withdrawn"
          : "Pending";
  return {
    id: String(offer.id ?? offer.technician_id ?? crypto.randomUUID()),
    jobId,
    providerId: String(offer.technician_id ?? offer.providerId ?? ""),
    price: Number(
      offer.price ??
        (Array.isArray(offer.proposals)
          ? (offer.proposals.at(-1) as Record<string, unknown> | undefined)?.amount
          : 0) ??
        0,
    ),
    message: String(offer.message ?? ""),
    arrivalMinutes: Number(offer.arrivalMinutes ?? 30),
    completionMinutes: Number(offer.completionMinutes ?? 120),
    status,
    createdAt: asIso(offer.created_at as FirestoreLikeDate, now()),
  };
};

/**
 * Maps a real Customer App `promotions/{id}` doc to the dashboard's Banner
 * shape (Phase D.2). Same marketing-carousel purpose, different field shape:
 * the real collection has no image/action-link fields at all (it's a
 * headline/subtitle/badge/accent-color carousel, not an image banner), so
 * `imageUrl`/`actionUrl` are left empty rather than guessed at - the banner
 * list UI will show these entries without an image, which is honest given
 * what's actually there.
 */
export const mapPromotionToBanner = (id: string, data: Record<string, unknown>): Banner => ({
  id,
  title: String(data.headline ?? ""),
  subtitle: String(data.subtitle ?? ""),
  imageUrl: "",
  actionUrl: undefined,
  enabled: Boolean(data.active ?? true),
  sortOrder: Number(data.order ?? 0),
  createdAt: asIso(data.created_at as FirestoreLikeDate),
  updatedAt: asIso(data.updated_at as FirestoreLikeDate, asIso(data.created_at as FirestoreLikeDate)),
  environment: "production",
  isDemoData: false,
});

/**
 * Real complaints live at jobs/{jobId}/complaints/{id} (see
 * packages/task_domain/lib/src/entities/complaint.dart) - a subcollection of
 * the job, read here via collectionGroup('complaints') the same way reviews
 * already are. `jobId` is read off the document's own path rather than
 * trusted from a `job_id` field, since the path is authoritative.
 */
export const mapJobComplaintToComplaint = (
  id: string,
  jobId: string,
  data: Record<string, unknown>,
): Complaint => {
  const status = String(data.status ?? "open").toLowerCase();
  const dashboardStatus: Complaint["status"] =
    status === "investigating"
      ? "Investigating"
      : status === "resolved" || status === "closed"
        ? "Closed"
        : "New";
  return {
    id,
    title: String(data.category ?? "Complaint"),
    description: String(data.description ?? ""),
    jobId,
    customerId: data.raised_by === "customer" ? String(data.reporter_id ?? "") : String(data.subject_id ?? ""),
    providerId: data.raised_by === "technician" ? String(data.reporter_id ?? "") : String(data.subject_id ?? ""),
    customer: "Customer",
    severity: "Medium",
    owner: "Unassigned",
    status: dashboardStatus,
    age: asIso(data.created_at as FirestoreLikeDate),
    notes: data.resolution_note ? [String(data.resolution_note)] : [],
    evidence: (data.evidence as string[] | undefined) ?? [],
    createdAt: asIso(data.created_at as FirestoreLikeDate),
    environment: "production",
    isDemoData: false,
  };
};

const mapJobDoc = (id: string, data: Record<string, unknown>): Job => {
  const offers = ((data.offers as Record<string, unknown>[] | undefined) ?? []).map((offer) =>
    mapOffer(id, offer),
  );
  const acceptedOffer = offers.find((offer) => offer.status === "Accepted");
  const amount = Number(data.amount ?? data.fixed_price ?? acceptedOffer?.price ?? 0);
  const serviceName = String(data.service ?? data.title ?? data.category ?? "Service request");
  return {
    id,
    customerId: String(data.customer_id ?? data.customerId ?? ""),
    providerId: String(data.provider_id ?? data.providerId ?? acceptedOffer?.providerId ?? "") || undefined,
    serviceId: String(data.service_id ?? data.serviceId ?? data.category ?? ""),
    customer: String(data.customer ?? data.customer_name ?? data.customerName ?? "Customer"),
    customerInitials: String(data.customerInitials ?? initials(String(data.customer ?? data.customer_name ?? "Customer"))),
    service: serviceName,
    provider: String(data.provider ?? data.provider_name ?? data.technician_name ?? "Unassigned"),
    area: String(data.area ?? data.location_label ?? ""),
    address: String(data.address ?? data.location_label ?? ""),
    scheduled: String(data.scheduled ?? data.scheduled_at ?? ""),
    amount,
    status: adminJobStatusFromWire(data.status),
    paymentStatus: paymentStatusFromWire(data.payment_status ?? data.paymentStatus),
    paymentMethod: String(data.payment_method ?? data.paymentMethod ?? "Card"),
    notes: (data.notes as string[] | undefined) ?? [],
    timeline: (data.timeline as Job["timeline"] | undefined) ?? [
      { id: `evt-${id}`, label: "Request created", at: asIso(data.created_at as FirestoreLikeDate), actor: "Customer", actorType: "customer" },
    ],
    createdAt: asIso(data.created_at as FirestoreLikeDate, asIso(data.createdAt as FirestoreLikeDate)),
    bookingType: bookingTypeFromWire(data.booking_type ?? data.bookingType, data.urgency),
    scheduledAt: asIso(data.scheduled_at as FirestoreLikeDate, String(data.scheduledAt ?? "")),
    priority: String(data.urgency ?? "").toLowerCase() === "emergency" ? "Emergency" : "Normal",
    category: String(data.category ?? ""),
    problemDescription: String(data.description ?? data.problemDescription ?? ""),
    customerBudget: Number(data.fixed_price ?? data.customerBudget ?? amount),
    city: String(data.city ?? ""),
    media: ((data.photos as string[] | undefined) ?? []).map((url, index) => ({
      id: `${id}-photo-${index}`,
      jobId: id,
      type: "photo" as const,
      fileName: `photo-${index + 1}`,
      mimeType: "image/*",
      size: 0,
      url,
      uploadedAt: asIso(data.created_at as FirestoreLikeDate),
      uploadedByType: "customer" as const,
      uploadedById: String(data.customer_id ?? ""),
      uploadedByName: "Customer",
    })),
    offers,
    providersReceived: Number(data.providers_received ?? offers.length),
    providersOpened: Number(data.providers_opened ?? 0),
    acceptedOfferId: acceptedOffer?.id,
    messages: [],
    calls: [],
    cancellation:
      adminJobStatusFromWire(data.status) === "Cancelled"
        ? {
            cancelledAt: asIso(data.cancelled_at as FirestoreLikeDate),
            cancelledBy: "Customer",
            reason: String(data.cancellation_reason ?? "Cancelled"),
            stage: acceptedOffer ? "after provider accepted" : "before offers",
            refundStatus: "Pending",
            followUpStatus: "Not contacted",
            followUpNotes: [],
          }
        : undefined,
    payment: {
      method: "Card",
      status: paymentStatusFromWire(data.payment_status ?? data.paymentStatus),
      amount,
      servicePrice: amount,
      customerOfferPrice: Number(data.fixed_price ?? amount),
      acceptedOfferPrice: acceptedOffer?.price,
      platformCommission: Number(data.platform_commission ?? 0),
      providerEarnings: Number(data.provider_earnings ?? 0),
      discount: 0,
      walletAmount: 0,
      cardAmount: 0,
      instapayAmount: 0,
      refundAmount: 0,
      outstandingAmount: amount,
    },
    environment: dataEnvironment(data),
    isDemoData: isDemoData(data),
  };
};

function mayRead(actor: AdminUser, key: StateArrayKey) {
  if (actor.isDemoUser)
    return (
      environmentScopedCollections.has(key) ||
      ["roles"].includes(key)
    );
  if (
    isSuperAdminRole(actor.role) ||
    actor.roleId === "super-admin" ||
    actor.roleId === "super_admin"
  )
    return true;
  if (key === "customers")
    return (
      hasPermission(actor.role, actor.permissions, "customers.view") ||
      hasPermission(actor.role, actor.permissions, "customers.edit")
    );
  if (key === "providers")
    return (
      hasPermission(actor.role, actor.permissions, "providers.view") ||
      hasPermission(actor.role, actor.permissions, "technicians.performance.view") ||
      hasPermission(actor.role, actor.permissions, "providers.approve") ||
      hasPermission(actor.role, actor.permissions, "providers.suspend")
    );
  if (key === "jobs" || key === "locations" || key === "conversations")
    return (
      hasPermission(actor.role, actor.permissions, "jobs.view") ||
      hasPermission(actor.role, actor.permissions, "technicians.performance.view") ||
      hasPermission(actor.role, actor.permissions, "operations.view") ||
      hasPermission(actor.role, actor.permissions, "trust.view") ||
      hasPermission(actor.role, actor.permissions, "support.view")
    );
  if (key === "aiExecutions" || key === "aiMemories" || key === "aiReports")
    return hasPermission(actor.role, actor.permissions, "ai.view");
  if (key === "wallets" || key === "transactions")
    return (
      hasPermission(actor.role, actor.permissions, "payments.view") ||
      hasPermission(actor.role, actor.permissions, "customers.view") ||
      hasPermission(actor.role, actor.permissions, "providers.view") ||
      hasPermission(actor.role, actor.permissions, "technicians.performance.view")
    );
  if (key === "payouts" || key === "instapayReviews")
    return (
      hasPermission(actor.role, actor.permissions, "payments.view") ||
      hasPermission(actor.role, actor.permissions, "payments.verify") ||
      hasPermission(actor.role, actor.permissions, "payments.payout")
    );
  if (key === "complaints")
    return (
      hasPermission(actor.role, actor.permissions, "trust.view") ||
      hasPermission(actor.role, actor.permissions, "technicians.complaints.view")
    );
  if (key === "reviews")
    return (
      hasPermission(actor.role, actor.permissions, "reviews.view") ||
      hasPermission(actor.role, actor.permissions, "technicians.reviews.view") ||
      hasPermission(actor.role, actor.permissions, "technicians.performance.view")
    );
  if (key === "admins") return hasPermission(actor.role, actor.permissions, "users.view");
  if (key === "roles") return hasPermission(actor.role, actor.permissions, "roles.view");
  if (key === "invitations")
    return (
      hasPermission(actor.role, actor.permissions, "users.invite") ||
      hasPermission(actor.role, actor.permissions, "users.create")
    );
  if (key === "auditLogs") return hasPermission(actor.role, actor.permissions, "audit.view");
  if (key === "categories" || key === "services")
    return hasPermission(actor.role, actor.permissions, "services.view");
  if (key === "banners") return hasPermission(actor.role, actor.permissions, "content.view");
  if (key === "promos") return hasPermission(actor.role, actor.permissions, "promotions.view");
  if (key === "notifications") return hasPermission(actor.role, actor.permissions, "notifications.view");
  return true;
}

export function subscribeDashboard(
  actor: AdminUser,
  onData: (state: DatabaseState) => void,
  onError: (error: Error) => void,
) {
  const state: DatabaseState = structuredClone(emptyState);
  const unsubs: Unsubscribe[] = [];
  const { db } = getFirebaseClient();
  if (typeof window !== "undefined") {
    console.info("[Task Admin Users] authenticated admin", {
      id: actor.id,
      uid: actor.uid,
      email: actor.email,
      role: actor.role,
      roleId: actor.roleId,
      status: actor.status,
      enabled: actor.enabled,
      authDisabled: actor.authDisabled,
      isDemoUser: actor.isDemoUser,
      permissionsCount: actor.permissions?.length ?? 0,
      canReadAdmins: mayRead(actor, "admins"),
    });
  }
  for (const [key, name] of Object.entries(collections) as Array<
    [StateArrayKey, string]
  >) {
    if (!mayRead(actor, key)) {
      if (key === "admins" && typeof window !== "undefined") {
        console.warn("[Task Admin Users] admins collection subscription skipped by permissions", {
          actorId: actor.id,
          role: actor.role,
          roleId: actor.roleId,
          permissions: actor.permissions ?? [],
        });
      }
      continue;
    }
    // Read routing is centralized in resolveReadSource (entity-routing.ts):
    // non-demo actors read the real Customer App schema for the five bridged
    // concepts; everyone else reads the dashboard-native collection, scoped by
    // the environment field so demo and production reads never mix.
    const source = resolveReadSource(
      key,
      actor.isDemoUser,
      name,
      environmentScopedCollections.has(key),
    );
    const sourceName = source.collection;
    const baseRef =
      source.kind === "collectionGroup"
        ? collectionGroup(db, source.collection)
        : collection(db, source.collection);
    const constraints: QueryConstraint[] = [];
    if (source.roleFilter) constraints.push(where("role", "==", source.roleFilter));
    if (source.environmentScoped)
      constraints.push(where("environment", "==", environmentForActor(actor)));
    constraints.push(limit(1000));
    const sourceQuery = query(baseRef, ...constraints);
    unsubs.push(
      onSnapshot(
        sourceQuery,
        (snapshot) => {
          if (key === "admins" && typeof window !== "undefined") {
            console.info("[Task Admin Users] Firestore admins query result before render", {
              collection: name,
              count: snapshot.size,
              ids: snapshot.docs.map((item) => item.id),
            });
          }
          const mapped = snapshot.docs.map((item) => {
            const data = item.data() as Record<string, unknown>;
            if (!actor.isDemoUser && key === "customers")
              return mapCustomerDoc(item.id, data);
            if (!actor.isDemoUser && key === "providers")
              return mapProviderDoc(item.id, data);
            if (!actor.isDemoUser && key === "jobs")
              return mapJobDoc(item.id, data);
            if (!actor.isDemoUser && key === "wallets") {
              const ownerId = item.ref.parent.parent?.id ?? String(data.ownerId ?? "");
              return {
                id: `${ownerId}-${item.id}`,
                ownerType: "customer",
                ownerId,
                balance: Number(data.balance_minor ?? 0) / 100,
                currency: String(data.currency ?? "EGP") as "EGP",
                updatedAt: asIso(data.updated_at as FirestoreLikeDate),
                frozen: Boolean(data.frozen ?? false),
                promoCredit: Number(data.promo_credit ?? 0) / 100,
                environment: "production",
                isDemoData: false,
              };
            }
            if (!actor.isDemoUser && key === "transactions") {
              const ownerId = item.ref.parent.parent?.id ?? String(data.ownerId ?? "");
              return {
                id: item.id,
                type:
                  data.type === "refund"
                    ? "Customer refund"
                    : data.type === "debit"
                      ? "Wallet debit"
                      : "Wallet credit",
                party: ownerId,
                ownerId,
                amount: Math.abs(Number(data.amount_minor ?? 0)) / 100,
                method: "Customer wallet",
                status: "Completed",
                createdAt: asIso(data.created_at as FirestoreLikeDate),
                reference: String(data.title ?? ""),
                environment: "production",
                isDemoData: false,
              };
            }
            if (!actor.isDemoUser && key === "reviews") {
              // Real reviews live at jobs/{jobId}/reviews/{reviewerId} - the
              // Customer App is write-only here today (no moderation status
              // field exists), so newly-read reviews default to "Visible".
              const jobId = item.ref.parent.parent?.id ?? "";
              const tags = Array.isArray(data.tags) ? (data.tags as string[]) : [];
              const note = String(data.note ?? "").trim();
              return {
                id: item.id,
                providerId: String(data.technician_id ?? ""),
                customerId: String(data.reviewer_id ?? item.id),
                customerName: "Customer",
                jobId,
                rating: (Number(data.rating ?? 5) || 5) as 1 | 2 | 3 | 4 | 5,
                comment: note || tags.join(", "),
                pictures: [],
                adminNotes: [],
                status: "Visible" as const,
                createdAt: asIso(data.created_at as FirestoreLikeDate),
                environment: "production",
                isDemoData: false,
              };
            }
            if (!actor.isDemoUser && key === "banners") {
              return mapPromotionToBanner(item.id, data);
            }
            if (!actor.isDemoUser && key === "complaints") {
              const jobId = item.ref.parent.parent?.id ?? "";
              return mapJobComplaintToComplaint(item.id, jobId, data);
            }
            return { id: item.id, ...data };
          });
          (state[key] as unknown[]) = mapped;
          state.sequences.provider = state.providers.length;
          state.issuedProviderIds = state.providers.map(
            (provider) => provider.providerId,
          );
          onData(structuredClone(state));
        },
        (error) => {
          const message = `${sourceName} listener failed: ${error.message}`;
          console.error("[Task Admin Firebase] collection listener failed", {
            key,
            collection: sourceName,
            code: (error as { code?: string }).code,
            message: error.message,
          });
          onError(new Error(message));
        },
      ),
    );
  }
  if (unsubs.length === 0) onData(state);
  return () => unsubs.forEach((unsubscribe) => unsubscribe());
}

async function read<T>(name: string, id: string) {
  const snapshot = await getDoc(doc(getFirebaseClient().db, name, id));
  if (!snapshot.exists()) throw new Error(`${name} record not found`);
  return { id: snapshot.id, ...snapshot.data() } as T;
}
async function audit(
  actor: AdminUser,
  action: string,
  entityType: string,
  entityId: string,
  detail: string,
  before?: unknown,
  after?: unknown,
) {
  const target = doc(collection(getFirebaseClient().db, "auditLogs"));
  await setDoc(
    target,
    clean({
      id: target.id,
      actorId: actor.id,
      actorName: actor.name,
      action,
      entityType,
      entityId,
      detail,
      environment: environmentForActor(actor),
      isDemoData: Boolean(actor.isDemoUser),
      before: before ? JSON.stringify(before) : null,
      after: after ? JSON.stringify(after) : null,
      ipAddress: "Firebase Auth",
      device:
        typeof navigator !== "undefined" ? navigator.userAgent : "Task Admin",
      createdAt: now(),
    }),
  );
}
async function auditDemoBlocked(actor: AdminUser, action: string, entityId: string) {
  await audit(
    actor,
    "demo.restricted_action_attempted",
    "demo",
    entityId,
    `Demo user attempted restricted action ${action}`,
  ).catch(() => undefined);
}
async function patch(name: string, id: string, value: Record<string, unknown>) {
  await updateDoc(doc(getFirebaseClient().db, name, id), clean(value));
  return read(name, id);
}
async function assertDemoRecord(
  actor: AdminUser,
  action: string,
  collectionName: string,
  id: string,
) {
  if (!actor.isDemoUser) return;
  const record = await read<Record<string, unknown>>(collectionName, id);
  if (dataEnvironment(record) !== "demo" && !isDemoData(record)) {
    await auditDemoBlocked(actor, action, id);
    throw new Error(DEMO_RESTRICTED_MESSAGE);
  }
}

export async function performFirestoreOperation<T>(
  action: string,
  p: Record<string, unknown>,
  actor: AdminUser,
): Promise<T> {
  const { db } = getFirebaseClient();
  try {
    assertDemoCanRun(actor, action);
  } catch (error) {
    await auditDemoBlocked(actor, action, String(p.id ?? p.providerId ?? p.jobId ?? "batch"));
    throw error;
  }
  // Phase D.1: production is read-only until migration is approved. Every
  // action in the switch below mutates data; for a non-demo actor we refuse
  // ALL of them here (a single choke point), so no production write - refund,
  // payout, notification fan-out, status change, delete, wallet adjustment,
  // etc. - can run. Demo actors are unaffected (their writes are isolated to
  // demo data). See lib/firebase/read-only-mode.ts.
  const writeAccess = checkProductionWriteAccess(actor);
  if (!writeAccess.allowed) {
    throw new Error(writeAccess.reason);
  }
  if (actor.isDemoUser) {
    if (action === "updateCustomer") await assertDemoRecord(actor, action, "customers", String(p.id));
    if (["updateProvider", "setProviderDecision", "updateProviderLocation"].includes(action))
      await assertDemoRecord(actor, action, "providers", String(p.id ?? p.providerId));
    if (["updateJob", "changeJobStatus", "addJobNote"].includes(action))
      await assertDemoRecord(actor, action, "orders", String(p.id));
    if (["assignProvider"].includes(action)) {
      await assertDemoRecord(actor, action, "orders", String(p.jobId));
      await assertDemoRecord(actor, action, "providers", String(p.providerId));
    }
    if (["refundJob", "updateCancellation", "flagMessage", "reviewCall"].includes(action))
      await assertDemoRecord(actor, action, "orders", String(p.id ?? p.jobId));
    if (["updateComplaint", "addCaseNote"].includes(action))
      await assertDemoRecord(actor, action, "complaints", String(p.id));
    if (["updateConversation", "addConversationMessage"].includes(action))
      await assertDemoRecord(actor, action, "conversations", String(p.id));
    if (["adjustWallet"].includes(action))
      await assertDemoRecord(actor, action, "customers", String(p.id));
    if (["createPayout"].includes(action))
      await assertDemoRecord(actor, action, "providers", String(p.providerId));
    if (["updatePromo"].includes(action))
      await assertDemoRecord(actor, action, "promos", String(p.id));
    if (["updateCategory"].includes(action))
      await assertDemoRecord(actor, action, "categories", String(p.id));
    if (["updateService", "toggleService"].includes(action))
      await assertDemoRecord(actor, action, "services", String(p.id));
    if (["updateBanner"].includes(action))
      await assertDemoRecord(actor, action, "banners", String(p.id));
  }
  let result: unknown;
  let entityId = String(p.id ?? p.providerId ?? p.jobId ?? "batch");
  switch (action) {
    case "createAiExecution": {
      const input = p.input as Partial<AiExecution>;
      const ref = doc(collection(db, "aiExecutions"));
      result = clean({
        id: ref.id,
        prompt: input.prompt ?? "",
        normalizedPrompt: input.normalizedPrompt ?? "",
        actorId: actor.id,
        actorName: actor.name,
        actorRole: actor.role,
        page: input.page ?? "Unknown",
        status: input.status ?? "Completed",
        risk: input.risk ?? "LOW",
        answer: input.answer ?? "",
        plan: input.plan ?? [],
        toolCalls: input.toolCalls ?? [],
        evidence: input.evidence ?? [],
        recommendations: input.recommendations ?? [],
        context: input.context ?? {},
        createdAt: now(),
        updatedAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "updateAiExecution":
      result = await patch("aiExecutions", String(p.id), {
        ...(p.patch as object),
        updatedAt: now(),
      });
      break;
    case "acceptAiRecommendation": {
      const execution = await read<AiExecution>(
        "aiExecutions",
        String(p.id),
      );
      result = await patch("aiExecutions", execution.id, {
        recommendations: execution.recommendations.map((item) =>
          item.id === p.recommendationId
            ? { ...item, acceptedAt: now() }
            : item,
        ),
        updatedAt: now(),
      });
      entityId = String(p.recommendationId);
      break;
    }
    case "rememberAiContext": {
      const input = p.input as Partial<AiMemory>;
      const ref = input.id
        ? doc(db, "aiMemories", input.id)
        : doc(collection(db, "aiMemories"));
      result = clean({
        id: ref.id,
        actorId: actor.id,
        scope: input.scope ?? "admin",
        key: input.key ?? "context",
        value: input.value ?? "",
        recordType: input.recordType ?? null,
        recordId: input.recordId ?? null,
        createdAt: input.createdAt ?? now(),
        updatedAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(ref, result as DocumentData, { merge: true });
      entityId = ref.id;
      break;
    }
    case "createAiReport": {
      const input = p.input as Partial<AiReport>;
      const ref = doc(collection(db, "aiReports"));
      result = clean({
        id: ref.id,
        type: input.type ?? "executive-brief",
        title: input.title ?? "Task AI report",
        summary: input.summary ?? "",
        metrics: input.metrics ?? {},
        recommendations: input.recommendations ?? [],
        generatedAt: now(),
        generatedBy: actor.name,
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "createCustomer": {
      const input = p.input as Record<string, string>;
      const id = doc(collection(db, customerSourceCollection(actor.isDemoUser))).id;
      const name = String(input.name ?? "").trim();
      const [firstName = name, ...lastParts] = name.split(/\s+/);
      const item = {
        id,
        role: "customer",
        first_name: firstName,
        last_name: lastParts.join(" "),
        name,
        display_name: name,
        customer_id: id,
        customerId: publicId("TASK-C"),
        email: input.email,
        phone: input.phone,
        phone_number: input.phone,
        initials: initials(name),
        status: "Active",
        disabled: false,
        walletBalance: 0,
        bookings: 0,
        totalSpend: 0,
        rating: 5,
        risk: "Healthy",
        addresses: [],
        created_at: now(),
        createdAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      };
      const batch = writeBatch(db);
      batch.set(doc(db, customerSourceCollection(actor.isDemoUser), id), item);
      if (actor.isDemoUser) {
        batch.set(doc(db, "wallets", `wallet-${id}`), {
          id: `wallet-${id}`,
          ownerType: "customer",
          ownerId: id,
          balance: 0,
          currency: "EGP",
          updatedAt: now(),
          frozen: false,
          promoCredit: 0,
          environment: environmentForActor(actor),
          isDemoData: true,
        });
      } else {
        batch.set(doc(db, "users", id, "wallet", "summary"), {
          balance_minor: 0,
          currency: "EGP",
          updated_at: now(),
        });
      }
      await batch.commit();
      result = actor.isDemoUser ? item : mapCustomerDoc(id, item);
      entityId = id;
      break;
    }
    case "updateCustomer":
      result = await patch(
        customerSourceCollection(actor.isDemoUser),
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "deleteCustomer":
      await deleteDoc(doc(db, customerSourceCollection(actor.isDemoUser), String(p.id)));
      result = { ok: true, id: String(p.id) };
      break;
    case "suspendCustomer": {
      const collectionName = customerSourceCollection(actor.isDemoUser);
      const item = await read<{ status: string }>(collectionName, String(p.id));
      result = await patch(collectionName, String(p.id), {
        status: item.status === "Suspended" || item.status === "suspended" ? "active" : "suspended",
        disabled: !(item.status === "Suspended" || item.status === "suspended"),
      });
      break;
    }
    case "adjustWallet": {
      const customerId = String(p.id),
        amount = Number(p.amount),
        reason = String(p.note);
      if (!actor.isDemoUser) {
        const walletRef = doc(db, "users", customerId, "wallet", "summary");
        const customerRef = doc(db, "users", customerId);
        result = await runTransaction(db, async (transaction) => {
          const [walletSnapshot, customerSnapshot] = await Promise.all([
            transaction.get(walletRef),
            transaction.get(customerRef),
          ]);
          if (!customerSnapshot.exists()) throw new Error("Customer profile not found");
          const currentMinor = Number(walletSnapshot.data()?.balance_minor ?? 0);
          const deltaMinor = Math.round(amount * 100);
          const balanceMinor = currentMinor + deltaMinor;
          if (balanceMinor < 0) throw new Error("Insufficient wallet balance");
          transaction.set(
            walletRef,
            { balance_minor: balanceMinor, currency: "EGP", updated_at: now() },
            { merge: true },
          );
          transaction.update(customerRef, { wallet_balance: balanceMinor / 100 });
          const transactionRef = doc(collection(db, "users", customerId, "wallet_transactions"));
          transaction.set(transactionRef, {
            type: amount >= 0 ? "credit" : "debit",
            amount_minor: deltaMinor,
            title: reason,
            created_at: now(),
            created_by: actor.id,
          });
          return {
            id: `${customerId}-summary`,
            ownerType: "customer",
            ownerId: customerId,
            balance: balanceMinor / 100,
            currency: "EGP",
            updatedAt: now(),
          };
        });
        break;
      }
      const wallets = await import("firebase/firestore").then(
        ({ getDocs, where }) =>
          getDocs(
            query(
              collection(db, "wallets"),
              where("ownerId", "==", customerId),
              where("environment", "==", environmentForActor(actor)),
              limit(1),
            ),
          ),
      );
      if (wallets.empty) throw new Error("Customer wallet not found");
      const walletRef = wallets.docs[0].ref;
      const customerRef = doc(db, "customers", customerId);
      result = await runTransaction(db, async (transaction) => {
        const [snapshot, customerSnapshot] = await Promise.all([
          transaction.get(walletRef),
          transaction.get(customerRef),
        ]);
        const wallet = snapshot.data();
        if (!wallet || !customerSnapshot.exists())
          throw new Error("Customer wallet not found");
        if (wallet.frozen) throw new Error("Wallet is frozen");
        const balance = Number(wallet.balance) + amount;
        if (balance < 0) throw new Error("Insufficient wallet balance");
        transaction.update(walletRef, { balance, updatedAt: now() });
        transaction.update(customerRef, { walletBalance: balance });
        const transactionRef = doc(collection(db, "transactions"));
        transaction.set(transactionRef, {
          id: transactionRef.id,
          type: amount >= 0 ? "Wallet credit" : "Wallet debit",
          party: customerId,
          ownerId: customerId,
          amount: Math.abs(amount),
          method: "Admin adjustment",
          status: "Completed",
          reference: reason,
          createdAt: now(),
          environment: environmentForActor(actor),
          isDemoData: Boolean(actor.isDemoUser),
        });
        return { ...wallet, balance };
      });
      break;
    }
    case "setWalletFrozen": {
      const { getDocs, where } = await import("firebase/firestore");
      const snapshot = await getDocs(
        query(
          collection(db, "wallets"),
          where("ownerId", "==", String(p.ownerId)),
          where("environment", "==", environmentForActor(actor)),
          limit(1),
        ),
      );
      if (snapshot.empty) throw new Error("Wallet not found");
      result = await patch("wallets", snapshot.docs[0].id, {
        frozen: Boolean(p.frozen),
        updatedAt: now(),
      });
      break;
    }
    case "createProvider": {
      const input = p.input as Record<string, unknown>;
      const providerRef = doc(collection(db, providerSourceCollection(actor.isDemoUser)));
      const { getDocs } = await import("firebase/firestore");
      const requirements = await getDocs(
        collection(db, "verificationRequirements"),
      );
      const requiredDocumentTypes = requirements.docs
        .map((item) => item.data())
        .filter((item) => item.enabled !== false && item.required === true)
        .sort((a, b) => Number(a.sortOrder ?? 0) - Number(b.sortOrder ?? 0))
        .map((item) => String(item.type));
      if (!requiredDocumentTypes.length)
        throw new Error(
          "Provider verification requirements are not configured in Firestore",
        );
      result = await runTransaction(db, async (transaction) => {
        const counterRef = doc(db, "system", "counters");
        const counter = await transaction.get(counterRef);
        const next = Number(counter.data()?.provider ?? 0) + 1;
        const providerId = `TASK-P-${String(next).padStart(6, "0")}`;
        const name = String(input.name ?? "").trim();
        const [firstName = name, ...lastParts] = name.split(/\s+/);
        const item = {
          id: providerRef.id,
          role: "technician",
          providerId,
          provider_id: providerId,
          name: input.name,
          display_name: input.name,
          first_name: firstName,
          last_name: lastParts.join(" "),
          email: input.email,
          phone: input.phone,
          phone_number: input.phone,
          nationalIdNumber: input.nationalIdNumber ?? "",
          national_id_number: input.nationalIdNumber ?? "",
          trade: input.trade,
          primary_category: input.trade,
          initials: String(input.name)
            .split(/\s+/)
            .map((x) => x[0])
            .join("")
            .slice(0, 2),
          rating: 0,
          acceptanceRate: 0,
          jobs: 0,
          earnings: 0,
          status: "Review",
          kyc_status: "applied",
          verified: false,
          response: "—",
          serviceIds: [],
          areas: input.areas ?? [],
          cities: input.cities ?? [],
          commission: 18,
          available: false,
          requiredDocumentTypes,
          documents: [],
          verification: {
            stage: "Registration",
            backgroundCheck: "Not Started",
            contractSigned: false,
            internalNotes: [],
            updatedAt: now(),
          },
          activityTimeline: [
            {
              id: publicId("EVT"),
              type: "account.created",
              label: `Account created with permanent ID ${providerId}`,
              at: now(),
              actor: actor.name,
            },
          ],
          lastActive: "Never",
          availabilitySchedule: {},
          bankInfo: { bankName: "", iban: "", instapay: "" },
          notes: [],
          createdAt: now(),
          environment: environmentForActor(actor),
          isDemoData: Boolean(actor.isDemoUser),
        };
        transaction.set(counterRef, { provider: next }, { merge: true });
        transaction.set(providerRef, clean(item));
        if (actor.isDemoUser) {
          const walletRef = doc(db, "wallets", `wallet-${providerRef.id}`);
          transaction.set(walletRef, {
            id: walletRef.id,
            ownerType: "provider",
            ownerId: providerRef.id,
            balance: 0,
            currency: "EGP",
            updatedAt: now(),
            frozen: false,
            promoCredit: 0,
            environment: environmentForActor(actor),
            isDemoData: true,
          });
        }
        return item;
      });
      entityId = (result as Provider).id;
      break;
    }
    case "updateProvider":
      result = await patch(
        providerSourceCollection(actor.isDemoUser),
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "updateProviderLocation": {
      const provider = await read<Provider>(providerSourceCollection(actor.isDemoUser), String(p.providerId));
      const status =
        String(p.status ?? (provider.available ? "Available" : "Offline")) as
          | "Available"
          | "Busy"
          | "Offline";
      const item: ProviderLocation = {
        id: provider.id,
        providerId: provider.id,
        lat: Number(p.lat),
        lng: Number(p.lng),
        heading: Number(p.heading ?? 0),
        accuracy: Number(p.accuracy ?? 25),
        updatedAt: now(),
        status,
        source: "admin",
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      };
      if (!Number.isFinite(item.lat) || !Number.isFinite(item.lng))
        throw new Error("Provider latitude and longitude are required");
      if (Math.abs(item.lat) > 90 || Math.abs(item.lng) > 180)
        throw new Error("Provider coordinates are outside valid GPS bounds");
      const batch = writeBatch(db);
      batch.set(doc(db, "providerLocations", provider.id), clean(item), {
        merge: true,
      });
      batch.update(doc(db, providerSourceCollection(actor.isDemoUser), provider.id), {
        available: status !== "Offline",
        online: status !== "Offline",
        lastActive: now(),
        last_active: now(),
      });
      await batch.commit();
      result = item;
      entityId = provider.id;
      break;
    }
    case "deleteProvider":
      await deleteDoc(doc(db, providerSourceCollection(actor.isDemoUser), String(p.id)));
      result = { ok: true, id: String(p.id) };
      break;
    case "setProviderDecision": {
      const collectionName = providerSourceCollection(actor.isDemoUser);
      const provider = mapProviderDoc(String(p.id), await read<Record<string, unknown>>(collectionName, String(p.id)));
      const decision = String(p.decision);
      const required =
        provider.requiredDocumentTypes ??
        provider.documents
          .filter((document) => document.required)
          .map((document) => document.type);
      if (
        decision === "approve" &&
        required.some(
          (type) =>
            !provider.documents.some(
              (document) =>
                document.type === type && document.status === "Approved",
            ),
        )
      )
        throw new Error("All mandatory documents must be approved first");
      result = await patch(collectionName, provider.id, {
        status:
          decision === "approve"
            ? "approved"
            : decision === "reject"
              ? "rejected"
              : decision === "ban"
                ? "banned"
                : "suspended",
        kyc_status:
          decision === "approve"
            ? "approved"
            : decision === "reject"
              ? "rejected"
              : "suspended",
        verified: decision === "approve",
        available: decision === "approve",
      });
      break;
    }
    case "uploadProviderDocument":
    case "replaceProviderDocument":
    case "reviewProviderDocument":
    case "deleteProviderDocument": {
      const providerId = String(p.providerId);
      const providerCollection = providerSourceCollection(actor.isDemoUser);
      const provider = mapProviderDoc(
        providerId,
        await read<Record<string, unknown>>(providerCollection, providerId),
      );
      let documents = [...provider.documents];
      if (action === "uploadProviderDocument") {
        const input = p.input as Record<string, unknown>;
        documents.unshift(
          clean({
            id: publicId("DOC"),
            type: input.type,
            customLabel: input.customLabel,
            name: input.fileName,
            fileName: input.fileName,
            fileType: input.fileType,
            fileSize: input.fileSize,
            mimeType: input.mimeType,
            storageUrl: input.storageUrl,
            storagePath: input.storageKey ?? input.path,
            checksum: input.checksum ?? "firebase-storage",
            status: "Pending",
            uploadedAt: now(),
            uploadedBy: actor.name,
            expiryDate: input.expiryDate,
            required: Boolean(input.required),
            versions: [],
          } as unknown as ProviderDocument),
        );
      } else if (action === "replaceProviderDocument") {
        const input = p.input as Record<string, unknown>;
        documents = documents.map((item) =>
          item.id === p.documentId
            ? {
                ...item,
                versions: [
                  {
                    id: publicId("VER"),
                    version: item.versions.length + 1,
                    fileName: item.fileName,
                    storageUrl: item.storageUrl,
                    fileSize: item.fileSize,
                    mimeType: item.mimeType,
                    checksum: item.checksum,
                    uploadedAt: item.uploadedAt,
                    uploadedBy: item.uploadedBy,
                  },
                  ...item.versions,
                ],
                fileName: String(input.fileName),
                name: String(input.fileName),
                fileSize: Number(input.fileSize),
                mimeType: String(input.mimeType),
                storageUrl: String(input.storageUrl),
                checksum: String(input.checksum ?? "firebase-storage"),
                status: "Pending",
                uploadedAt: now(),
                uploadedBy: actor.name,
              }
            : item,
        );
      } else if (action === "reviewProviderDocument") {
        documents = documents.map((item) =>
          item.id === p.documentId
            ? {
                ...item,
                status: p.status as ProviderDocument["status"],
                reviewNotes: String(p.notes ?? ""),
                reviewerName: actor.name,
                reviewedAt: now(),
              }
            : item,
        );
      } else {
        documents = documents.filter((item) => item.id !== p.documentId);
      }
      result = await patch(providerCollection, providerId, {
        documents,
        verified: false,
        available: false,
      });
      entityId = String(p.documentId);
      break;
    }
    case "recordProviderDocumentAccess":
      result = { ok: true };
      break;
    case "assignVerificationOfficer":
    case "addProviderVerificationNote":
    case "updateProviderBackgroundCheck": {
      const providerCollection = providerSourceCollection(actor.isDemoUser);
      const provider = mapProviderDoc(
        String(p.providerId),
        await read<Record<string, unknown>>(providerCollection, String(p.providerId)),
      );
      const verification = {
        ...provider.verification,
        ...(action === "assignVerificationOfficer"
          ? { officerId: p.adminId }
          : {}),
        ...(action === "addProviderVerificationNote"
          ? {
              internalNotes: [
                String(p.note),
                ...provider.verification.internalNotes,
              ],
            }
          : {}),
        ...(action === "updateProviderBackgroundCheck"
          ? { backgroundCheck: p.status }
          : {}),
        updatedAt: now(),
      };
      result = await patch(providerCollection, provider.id, { verification });
      break;
    }
    case "createCategory": {
      const input = p.input as Record<string, string>;
      const ref = doc(collection(db, "categories"));
      result = {
        id: ref.id,
        name: input.name,
        description: input.description,
        enabled: true,
        serviceCount: 0,
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      };
      await setDoc(ref, result);
      entityId = ref.id;
      break;
    }
    case "updateCategory":
      result = await patch(
        "categories",
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "deleteCategory": {
      const { getDocs, where } = await import("firebase/firestore");
      const services = await getDocs(
        query(
          collection(db, "services"),
          where("categoryId", "==", String(p.id)),
          where("environment", "==", environmentForActor(actor)),
          limit(1),
        ),
      );
      if (!services.empty)
        throw new Error("Move or delete services in this category first");
      await deleteDoc(doc(db, "categories", String(p.id)));
      result = { id: p.id };
      break;
    }
    case "createService": {
      const input = p.input as Partial<Service>;
      const ref = doc(collection(db, "services"));
      result = clean({
        id: ref.id,
        name: input.name,
        categoryId: input.categoryId,
        description: input.description ?? "",
        imageUrl: input.imageUrl ?? null,
        basePrice: Number(input.basePrice),
        emergencyFee: Number(input.emergencyFee ?? 0),
        inspectionFee: Number(input.inspectionFee ?? 0),
        commission: Number(input.commission ?? 18),
        enabled: input.enabled ?? true,
        cities: input.cities ?? [],
        areas: input.areas ?? [],
        updatedAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "updateService":
      result = await patch("services", String(p.id), {
        ...(p.patch as object),
        updatedAt: now(),
      });
      break;
    case "deleteService":
      await deleteDoc(doc(db, "services", String(p.id)));
      result = { id: p.id };
      break;
    case "toggleService": {
      const item = await read<Service>("services", String(p.id));
      result = await patch("services", item.id, {
        enabled: !item.enabled,
        updatedAt: now(),
      });
      break;
    }
    case "createBanner": {
      const input = p.input as Partial<Banner>;
      const ref = doc(collection(db, "banners"));
      result = clean({
        id: ref.id,
        title: input.title,
        subtitle: input.subtitle ?? "",
        imageUrl: input.imageUrl,
        actionUrl: input.actionUrl ?? null,
        enabled: input.enabled ?? true,
        sortOrder: Number(input.sortOrder ?? 0),
        createdAt: now(),
        updatedAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "updateBanner":
      result = await patch("banners", String(p.id), {
        ...(p.patch as object),
        updatedAt: now(),
      });
      break;
    case "deleteBanner":
      await deleteDoc(doc(db, "banners", String(p.id)));
      result = { id: p.id };
      break;
    case "createJob": {
      const input = p.input as Record<string, unknown>;
      const customer = mapCustomerDoc(
        String(input.customerId),
        await read<Record<string, unknown>>(
          customerSourceCollection(actor.isDemoUser),
          String(input.customerId),
        ),
      );
      const service = await read<Service>("services", String(input.serviceId));
      const assignedProvider = input.providerId
        ? mapProviderDoc(
            String(input.providerId),
            await read<Record<string, unknown>>(
              providerSourceCollection(actor.isDemoUser),
              String(input.providerId),
            ),
          )
        : null;
      const gps =
        input.gps &&
        typeof input.gps === "object" &&
        "lat" in input.gps &&
        "lng" in input.gps
          ? {
              lat: Number((input.gps as { lat: unknown }).lat),
              lng: Number((input.gps as { lng: unknown }).lng),
            }
          : undefined;
      if (
        gps &&
        (!Number.isFinite(gps.lat) ||
          !Number.isFinite(gps.lng) ||
          Math.abs(gps.lat) > 90 ||
          Math.abs(gps.lng) > 180)
      )
        throw new Error("Job GPS coordinates are outside valid bounds");
      const jobId = doc(collection(db, jobSourceCollection(actor.isDemoUser))).id;
      const item: Job = clean({
        id: jobId,
        customerId: String(input.customerId),
        providerId: input.providerId ? String(input.providerId) : undefined,
        serviceId: service.id,
        customer: customer.name,
        customerInitials: customer.initials,
        service: service.name,
        provider: assignedProvider?.name ?? "Unassigned",
        area: String(input.area),
        address: String(input.address),
        scheduled: String(input.scheduled),
        amount: Number(input.amount),
        status: input.providerId ? "Assigned" : "Scheduled",
        paymentStatus: "Pending",
        paymentMethod: "Cash",
        notes: input.priceOverrideReason
          ? [`Price override: ${input.priceOverrideReason}`]
          : [],
        timeline: [
          {
            id: publicId("EVT"),
            label: `${String(input.bookingType ?? "Scheduled")} booking created`,
            at: now(),
            actor: actor.name,
          },
        ],
        createdAt: now(),
        bookingType: (input.bookingType as Job["bookingType"]) ?? (input.priority === "Emergency" ? "Emergency" : "Scheduled"),
        emergencyFee: Number(input.emergencyFee ?? 0),
        emergencyResponseSlaMinutes: input.emergencyResponseSlaMinutes ? Number(input.emergencyResponseSlaMinutes) : undefined,
        scheduledAt: String(input.scheduledAt ?? input.scheduled ?? ""),
        appointmentReminderAt: String(input.appointmentReminderAt ?? ""),
        responseSlaMinutes: input.responseSlaMinutes ? Number(input.responseSlaMinutes) : undefined,
        arrivalSlaMinutes: input.arrivalSlaMinutes ? Number(input.arrivalSlaMinutes) : undefined,
        completionSlaMinutes: input.completionSlaMinutes ? Number(input.completionSlaMinutes) : undefined,
        slaBreached: false,
        quotationStatus: input.quotationStatus as Job["quotationStatus"],
        quotedPrice: input.quotedPrice ? Number(input.quotedPrice) : undefined,
        quotationNotes: String(input.quotationNotes ?? ""),
        quotationPhotos: [],
        priority: (input.priority as Job["priority"]) ?? "Normal",
        problemDescription:
          String(input.problemDescription ?? "") ||
          "Manual request created by admin",
        customerBudget: Number(input.customerBudget ?? input.amount),
        gps,
        city: String(input.city ?? "") || service.cities[0] || "",
        media: [],
        offers: [],
        providersReceived: 0,
        providersOpened: 0,
        messages: [],
        calls: [],
        payment: {
          method: "Cash",
          status: "Pending",
          amount: Number(input.amount),
          servicePrice: service.basePrice,
          customerOfferPrice: Number(input.amount),
          platformCommission: (Number(input.amount) * service.commission) / 100,
          providerEarnings:
            Number(input.amount) * (1 - service.commission / 100),
          discount: 0,
          walletAmount: 0,
          cardAmount: 0,
          instapayAmount: 0,
          refundAmount: 0,
          outstandingAmount: Number(input.amount),
        },
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      const { increment } = await import("firebase/firestore");
      const batch = writeBatch(db);
      if (actor.isDemoUser) {
        batch.set(doc(db, "orders", item.id), item);
        batch.update(doc(db, "customers", String(input.customerId)), {
          bookings: increment(1),
        });
      } else {
        batch.set(doc(db, "jobs", item.id), clean({
          id: item.id,
          customer_id: item.customerId,
          provider_id: item.providerId ?? null,
          service_id: item.serviceId,
          customer_name: item.customer,
          provider_name: assignedProvider?.name ?? null,
          category: service.categoryId || service.name,
          title: service.name,
          description: item.problemDescription,
          fixed_price: item.amount,
          currency: "EGP",
          urgency: item.bookingType === "Emergency" ? "emergency" : "soon",
          property_type: "apartment",
          floor: null,
          parking: null,
          photos: [],
          location_label: item.address || item.area,
          address: item.address ?? "",
          area: item.area,
          city: item.city ?? "",
          notes: item.notes.join("\n"),
          status: item.providerId ? "accepted" : item.bookingType === "Scheduled" ? "pendingScheduled" : "biddingActive",
          booking_type: bookingTypeToWire(item.bookingType),
          scheduled_at: item.scheduledAt || null,
          offers: [],
          payment_status: "pending",
          payment_method: "card",
          created_at: now(),
          timeline: item.timeline,
        }));
        batch.update(doc(db, "users", String(input.customerId)), {
          bookings: increment(1),
          jobs_count: increment(1),
        });
      }
      await batch.commit();
      result = item;
      entityId = item.id;
      break;
    }
    case "updateJob":
      result = await patch(
        jobSourceCollection(actor.isDemoUser),
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "assignProvider": {
      const provider = mapProviderDoc(
        String(p.providerId),
        await read<Record<string, unknown>>(
          providerSourceCollection(actor.isDemoUser),
          String(p.providerId),
        ),
      );
      if (
        !p.override &&
        (!provider.verified ||
          provider.status !== "Active" ||
          !provider.available)
      )
        throw new Error("Provider is not verified, active, and available");
      const jobCollection = jobSourceCollection(actor.isDemoUser);
      const order = actor.isDemoUser
        ? await read<Job>(jobCollection, String(p.jobId))
        : mapJobDoc(String(p.jobId), await read<Record<string, unknown>>(jobCollection, String(p.jobId)));
      result = await patch(jobCollection, order.id, {
        providerId: provider.id,
        provider_id: provider.id,
        provider: provider.name,
        provider_name: provider.name,
        status: actor.isDemoUser ? "Assigned" : "accepted",
        timeline: [
          {
            id: publicId("EVT"),
            label: `Assigned to ${provider.name}`,
            at: now(),
            actor: actor.name,
          },
          ...order.timeline,
        ],
      });
      break;
    }
    case "changeJobStatus": {
      const jobCollection = jobSourceCollection(actor.isDemoUser);
      const order = actor.isDemoUser
        ? await read<Job>(jobCollection, String(p.id))
        : mapJobDoc(String(p.id), await read<Record<string, unknown>>(jobCollection, String(p.id)));
      const status = String(p.status) as Job["status"];
      result = await patch(jobCollection, order.id, {
        status: actor.isDemoUser ? status : jobWireStatusFromAdmin(status),
        ...(status === "Cancelled" ? { cancelled_at: now(), cancellation_reason: "Cancelled by operations" } : {}),
        cancellation:
          status === "Cancelled"
            ? (order.cancellation ?? {
                cancelledAt: now(),
                cancelledBy: "Admin",
                reason: "Cancelled by operations",
                stage: order.providerId
                  ? "after provider accepted"
                  : "before offers",
                refundStatus: "Pending",
                followUpStatus: "Not contacted",
                followUpNotes: [],
              })
            : order.cancellation,
        timeline: [
          {
            id: publicId("EVT"),
            label: `Status changed to ${status}`,
            at: now(),
            actor: actor.name,
          },
          ...order.timeline,
        ],
      });
      break;
    }
    case "refundJob": {
      if (!actor.isDemoUser) {
        const order = mapJobDoc(String(p.id), await read<Record<string, unknown>>("jobs", String(p.id)));
        if (order.payment?.status === "Refunded")
          throw new Error("This order is already refunded");
        const orderRef = doc(db, "jobs", order.id);
        const walletRef = doc(db, "users", order.customerId, "wallet", "summary");
        const customerRef = doc(db, "users", order.customerId);
        result = await runTransaction(db, async (transaction) => {
          const [orderSnapshot, walletSnapshot, customerSnapshot] = await Promise.all([
            transaction.get(orderRef),
            transaction.get(walletRef),
            transaction.get(customerRef),
          ]);
          if (!orderSnapshot.exists() || !customerSnapshot.exists())
            throw new Error("Refund records changed; retry the operation");
          const latest = mapJobDoc(order.id, orderSnapshot.data() as Record<string, unknown>);
          // Re-check inside the transaction, not just before it started (the
          // pre-transaction check above is a fast-path only and is racy on
          // its own - two concurrent refundJob calls for the same job would
          // both pass it before either transaction commits). Without this,
          // a double-click or retried request double-credits the customer's
          // real wallet. The demo branch of this same action already has an
          // equivalent in-transaction re-check further down; this mirrors it.
          if (latest.payment?.status === "Refunded")
            throw new Error("This order is already refunded");
          const amount = Number(latest.payment?.amount ?? latest.amount ?? 0);
          const currentMinor = Number(walletSnapshot.data()?.balance_minor ?? 0);
          const amountMinor = Math.round(amount * 100);
          // Do not write status: "refunded" - the real Customer App JobStatus
          // enum has no such value, and this job doc is read by the real
          // Customer App client. "payment_status: refunded" is safe: it's a
          // real value in the Customer App's own PaymentStatus enum (just
          // never written by the app itself yet).
          transaction.update(orderRef, {
            payment_status: "refunded",
            refunded_at: now(),
          });
          transaction.set(
            walletRef,
            { balance_minor: currentMinor + amountMinor, currency: "EGP", updated_at: now() },
            { merge: true },
          );
          transaction.update(customerRef, { wallet_balance: (currentMinor + amountMinor) / 100 });
          const transactionRef = doc(collection(db, "users", order.customerId, "wallet_transactions"));
          transaction.set(transactionRef, {
            type: "refund",
            amount_minor: amountMinor,
            title: `Refund for job ${order.id}`,
            created_at: now(),
            job_id: order.id,
            created_by: actor.id,
          });
          return { ...latest, status: "Refunded" };
        });
        break;
      }
      const order = await read<Job>("orders", String(p.id));
      if (!order.payment) throw new Error("Payment record not found");
      if (order.payment.status === "Refunded")
        throw new Error("This order is already refunded");
      const { getDocs, where } = await import("firebase/firestore");
      const wallets = await getDocs(
        query(
          collection(db, "wallets"),
          where("ownerId", "==", order.customerId),
          where("environment", "==", environmentForActor(actor)),
          limit(1),
        ),
      );
      if (wallets.empty) throw new Error("Customer wallet not found");
      const orderRef = doc(db, "orders", order.id),
        walletRef = wallets.docs[0].ref,
        customerRef = doc(db, "customers", order.customerId);
      result = await runTransaction(db, async (transaction) => {
        const [orderSnapshot, walletSnapshot, customerSnapshot] =
          await Promise.all([
            transaction.get(orderRef),
            transaction.get(walletRef),
            transaction.get(customerRef),
          ]);
        if (
          !orderSnapshot.exists() ||
          !walletSnapshot.exists() ||
          !customerSnapshot.exists()
        )
          throw new Error("Refund records changed; retry the operation");
        const latest = orderSnapshot.data() as Job;
        if (latest.payment?.status === "Refunded")
          throw new Error("This order is already refunded");
        const amount = Number(latest.payment?.amount ?? 0);
        const balance = Number(walletSnapshot.data().balance ?? 0) + amount;
        transaction.update(orderRef, {
          status: "Refunded",
          paymentStatus: "Refunded",
          payment: {
            ...latest.payment,
            status: "Refunded",
            refundAmount: amount,
            outstandingAmount: 0,
          },
        });
        transaction.update(walletRef, { balance, updatedAt: now() });
        transaction.update(customerRef, { walletBalance: balance });
        const transactionRef = doc(collection(db, "transactions"));
        transaction.set(transactionRef, {
          id: transactionRef.id,
          type: "Customer refund",
          party: order.customer,
          ownerId: order.customerId,
          amount,
          method: "Customer wallet",
          status: "Completed",
          reference: order.id,
          createdAt: now(),
          environment: environmentForActor(actor),
          isDemoData: Boolean(actor.isDemoUser),
        });
        return { ...latest, status: "Refunded" };
      });
      break;
    }
    case "addJobNote": {
      const jobCollection = jobSourceCollection(actor.isDemoUser);
      const order = actor.isDemoUser
        ? await read<Job>(jobCollection, String(p.id))
        : mapJobDoc(String(p.id), await read<Record<string, unknown>>(jobCollection, String(p.id)));
      result = await patch(jobCollection, order.id, {
        notes: actor.isDemoUser
          ? [String(p.note), ...order.notes]
          : [String(p.note), ...order.notes].join("\n"),
        timeline: [
          {
            id: publicId("EVT"),
            label: "Admin note added",
            at: now(),
            actor: actor.name,
            actorType: "admin",
            actorId: actor.id,
            metadata: { note: String(p.note) },
          },
          ...order.timeline,
        ],
      });
      break;
    }
    case "updateCancellation": {
      const jobCollection = jobSourceCollection(actor.isDemoUser);
      const order = actor.isDemoUser
        ? await read<Job>(jobCollection, String(p.id))
        : mapJobDoc(String(p.id), await read<Record<string, unknown>>(jobCollection, String(p.id)));
      result = await patch(jobCollection, order.id, {
        cancellation: { ...order.cancellation, ...(p.patch as object) },
        cancellation_reason: String((p.patch as Record<string, unknown>).reason ?? order.cancellation?.reason ?? ""),
      });
      break;
    }
    case "flagMessage": {
      const jobCollection = jobSourceCollection(actor.isDemoUser);
      if (!actor.isDemoUser) {
        // The real Customer App `jobs` document has no inline `messages`
        // array - chat lives in a separate jobs/{id}/threads/{tech}/messages
        // subcollection with a different shape entirely. mapJobDoc() always
        // reports `messages: []` for real jobs, so silently patching would
        // write a meaningless empty array to a real production document
        // instead of actually flagging anything. Refuse explicitly rather
        // than pretend this succeeded - do not invent a new schema for it.
        throw new Error(
          "Flagging chat messages is not supported for real Customer App jobs yet " +
            "(chat lives in a separate threads/messages subcollection, not an inline array). " +
            "This action currently only works in demo mode.",
        );
      }
      const order = await read<Job>(jobCollection, String(p.jobId));
      result = await patch(jobCollection, order.id, {
        messages: (order.messages ?? []).map((item) =>
          item.id === p.messageId
            ? { ...item, flagged: true, reviewNote: String(p.note) }
            : item,
        ),
      });
      break;
    }
    case "reviewCall": {
      const jobCollection = jobSourceCollection(actor.isDemoUser);
      if (!actor.isDemoUser) {
        // Same reasoning as flagMessage: real jobs have no persisted call
        // history (mapJobDoc() always reports `calls: []`), so there is
        // nothing real to review yet. Refuse rather than silently no-op.
        throw new Error(
          "Reviewing calls is not supported for real Customer App jobs yet " +
            "(no call history is persisted on the real jobs schema today). " +
            "This action currently only works in demo mode.",
        );
      }
      const order = await read<Job>(jobCollection, String(p.jobId));
      result = await patch(jobCollection, order.id, {
        calls: (order.calls ?? []).map((item) =>
          item.id === p.callId ? { ...item, ...(p.patch as object) } : item,
        ),
      });
      break;
    }
    case "deleteJob":
      throw new Error("Orders are protected by permanent retention policy");
    case "createComplaint": {
      const input = p.input as Partial<Complaint>;
      result = clean({
        id: publicId("TASK-INC"),
        title: input.title,
        description: input.description,
        customerId: input.customerId,
        providerId: input.providerId,
        jobId: input.jobId,
        customer: input.customer ?? "Linked customer",
        severity: input.severity,
        status: "New",
        owner: "Unassigned",
        age: "now",
        notes: [],
        evidence: [],
        createdAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(
        doc(db, "complaints", (result as Complaint).id),
        result as DocumentData,
      );
      entityId = (result as Complaint).id;
      break;
    }
    case "updateComplaint":
      result = await patch(
        "complaints",
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "setCaseOwner": {
      const admin = await read<AdminUser>("admins", String(p.adminId));
      result = await patch("complaints", String(p.id), {
        ownerId: admin.id,
        owner: admin.name,
      });
      break;
    }
    case "setCaseSeverity":
      result = await patch("complaints", String(p.id), {
        severity: p.severity,
      });
      break;
    case "addCaseNote": {
      const item = await read<Complaint>("complaints", String(p.id));
      result = await patch("complaints", item.id, {
        notes: [String(p.note), ...item.notes],
      });
      break;
    }
    case "closeCase":
      result = await patch("complaints", String(p.id), { status: "Closed" });
      break;
    case "reopenCase":
      result = await patch("complaints", String(p.id), {
        status: "Investigating",
      });
      break;
    case "deleteComplaint":
      await deleteDoc(doc(db, "complaints", String(p.id)));
      result = { id: p.id };
      break;
    case "createPayout": {
      const providerCollection = providerSourceCollection(actor.isDemoUser);
      const provider = actor.isDemoUser
        ? await read<Provider>(providerCollection, String(p.providerId))
        : mapProviderDoc(
            String(p.providerId),
            await read<Record<string, unknown>>(providerCollection, String(p.providerId)),
          );
      const amount = Number(p.amount);
      if (amount <= 0)
        throw new Error("Payout amount must be greater than zero");
      // Real technician wallets live at users/{uid}/wallet/summary (the same
      // schema the Customer App uses for customer wallets - role is
      // irrelevant to the wallet subcollection's own schema). The dashboard's
      // demo mode keeps using its flat top-level "wallets" collection since
      // there is no real per-provider wallet concept to bridge to there.
      const walletRef = actor.isDemoUser
        ? await (async () => {
            const { getDocs, where } = await import("firebase/firestore");
            const wallets = await getDocs(
              query(
                collection(db, "wallets"),
                where("ownerId", "==", provider.id),
                where("environment", "==", environmentForActor(actor)),
                limit(1),
              ),
            );
            if (wallets.empty) throw new Error("Provider wallet not found");
            return wallets.docs[0].ref;
          })()
        : doc(db, "users", provider.id, "wallet", "summary");
      const payoutId = publicId("PAY");
      result = await runTransaction(db, async (transaction) => {
        const walletSnapshot = await transaction.get(walletRef);
        const balance = actor.isDemoUser
          ? Number(walletSnapshot.data()?.balance ?? 0)
          : Number(walletSnapshot.data()?.balance_minor ?? 0) / 100;
        if (balance < amount) throw new Error("Insufficient provider balance");
        const payout = {
          id: payoutId,
          providerId: provider.id,
          providerName: provider.name,
          amount,
          method: p.method,
          status: "Pending",
          createdAt: now(),
        };
        if (actor.isDemoUser) {
          transaction.update(walletRef, {
            balance: balance - amount,
            updatedAt: now(),
          });
        } else {
          transaction.set(
            walletRef,
            { balance_minor: Math.round((balance - amount) * 100), currency: "EGP", updated_at: now() },
            { merge: true },
          );
          const transactionRef = doc(collection(db, "users", provider.id, "wallet_transactions"));
          transaction.set(transactionRef, {
            type: "debit",
            amount_minor: -Math.round(amount * 100),
            title: `Payout ${payoutId}`,
            created_at: now(),
            created_by: actor.id,
          });
        }
        transaction.set(doc(db, "payouts", payoutId), payout);
        const transactionRef = doc(collection(db, "transactions"));
        transaction.set(transactionRef, {
          id: transactionRef.id,
          type: "Provider payout",
          party: provider.name,
          ownerId: provider.id,
          amount,
          method: String(p.method),
          status: "Pending",
          reference: payoutId,
        createdAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
        return payout;
      });
      entityId = payoutId;
      break;
    }
    case "verifyPayout": {
      const payout = await read<{
        id: string;
        providerId: string;
        providerName: string;
        amount: number;
        status: string;
      }>("payouts", String(p.id));
      if (payout.status === "Paid")
        throw new Error("Payout is already verified");
      const { getDocs, where } = await import("firebase/firestore");
      const transactions = await getDocs(
        query(
          collection(db, "transactions"),
          where("reference", "==", payout.id),
          where("environment", "==", environmentForActor(actor)),
          limit(1),
        ),
      );
      const batch = writeBatch(db);
      batch.update(doc(db, "payouts", payout.id), {
        status: "Paid",
        reference: p.reference,
        paidAt: now(),
      });
      if (!transactions.empty)
        batch.update(transactions.docs[0].ref, {
          status: "Completed",
          providerReference: p.reference,
        });
      await batch.commit();
      result = { ...payout, status: "Paid", reference: p.reference };
      break;
    }
    case "createTransaction": {
      const input = p.input as Record<string, unknown>;
      const ref = doc(collection(db, "transactions"));
      result = clean({ id: ref.id, ...input, createdAt: now(), environment: environmentForActor(actor), isDemoData: Boolean(actor.isDemoUser) });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "updateTransaction":
      result = await patch(
        "transactions",
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "reviewInstapay": {
      const review = await read<Record<string, unknown>>(
        "instapayReviews",
        String(p.id),
      );
      const batch = writeBatch(db);
      batch.update(doc(db, "instapayReviews", String(p.id)), {
        status: p.status,
        financeNote: p.note,
        reviewedAt: now(),
      });
      if (p.status === "Approved" && review.jobId) {
        const jobCollection = jobSourceCollection(actor.isDemoUser);
        const order = actor.isDemoUser
          ? await read<Job>(jobCollection, String(review.jobId))
          : mapJobDoc(
              String(review.jobId),
              await read<Record<string, unknown>>(jobCollection, String(review.jobId)),
            );
        if (actor.isDemoUser) {
          batch.update(doc(db, jobCollection, order.id), {
            paymentStatus: "Paid",
            payment: order.payment
              ? {
                  ...order.payment,
                  status: "Paid",
                  instapayAmount: Number(review.amount ?? order.amount),
                  outstandingAmount: 0,
                  paidAt: now(),
                }
              : null,
          });
        } else {
          // Real jobs have no "paymentStatus"/"payment" object - the closest
          // real, valid field is payment_status, using the Customer App's own
          // PaymentStatus enum value "captured" (mapped to "Paid" by
          // paymentStatusFromWire). No new schema invented.
          batch.update(doc(db, jobCollection, order.id), {
            payment_status: "captured",
          });
        }
        const transactionRef = doc(collection(db, "transactions"));
        batch.set(transactionRef, {
          id: transactionRef.id,
          type: "Instapay verification",
          party: order.customer,
          ownerId: order.customerId,
          amount: Number(review.amount ?? order.amount),
          method: "Instapay",
          status: "Completed",
          reference: String(review.transferReference ?? review.id),
          jobId: order.id,
          createdAt: now(),
          environment: environmentForActor(actor),
          isDemoData: Boolean(actor.isDemoUser),
        });
      }
      await batch.commit();
      result = {
        ...review,
        status: p.status,
        financeNote: p.note,
        reviewedAt: now(),
      };
      break;
    }
    case "updateAdmin":
      result = await patch(
        "admins",
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "deleteAdmin":
      await deleteDoc(doc(db, "admins", String(p.id)));
      result = { ok: true, id: String(p.id) };
      break;
    case "toggleAdmin": {
      const admin = await read<AdminUser>("admins", String(p.id));
      result = await patch("admins", admin.id, {
        status: admin.status === "Disabled" ? "Active" : "Disabled",
      });
      break;
    }
    case "createRole": {
      const input = p.input as Partial<Role>;
      const ref = doc(collection(db, "roles"));
      result = {
        id: ref.id,
        name: input.name,
        description: input.description,
        permissions: input.permissions ?? [],
        system: false,
      };
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "createPromo": {
      const input = p.input as Record<string, unknown>;
      const ref = doc(collection(db, "promos"));
      result = clean({ id: ref.id, ...input, used: 0, startsAt: now(), environment: environmentForActor(actor), isDemoData: Boolean(actor.isDemoUser) });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "updatePromo":
      result = await patch(
        "promos",
        String(p.id),
        p.patch as Record<string, unknown>,
      );
      break;
    case "deletePromo":
      await deleteDoc(doc(db, "promos", String(p.id)));
      result = { id: p.id };
      break;
    case "createNotification": {
      const input = p.input as Record<string, unknown> & {
        audience: NotificationAudience;
        targetUserId?: string;
        targetUserIds?: string[];
      };
      const ref = doc(collection(db, "notifications"));
      result = { id: ref.id, ...input, status: "Sent", createdAt: now(), environment: environmentForActor(actor), isDemoData: Boolean(actor.isDemoUser) };
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      // Fan out to the real Customer App per-user feed for non-demo admins,
      // bounded to whatever recipients the caller actually specified. Throws
      // for unbounded broadcast audiences instead of silently doing nothing.
      if (!actor.isDemoUser) {
        const plan = resolveNotificationFanout(
          input.audience,
          input.targetUserId,
          input.targetUserIds,
        );
        const doc_ = buildRealNotificationDoc(
          String(input.title ?? ""),
          String(input.body ?? ""),
          serverTimestamp(),
        );
        await Promise.all(
          plan.targetUserIds.map((uid) =>
            setDoc(doc(collection(db, "users", uid, "notifications")), doc_ as DocumentData),
          ),
        );
      }
      break;
    }
    case "createConversation": {
      const input = p.input as Partial<SupportConversation>;
      const ref = doc(collection(db, "conversations"));
      result = clean({
        id: ref.id,
        subject: input.subject,
        customerId: input.customerId,
        providerId: input.providerId,
        jobId: input.jobId,
        status: "Open",
        priority: input.priority ?? "Normal",
        assignedAdminId: actor.id,
        messages: [],
        createdAt: now(),
        updatedAt: now(),
        environment: environmentForActor(actor),
        isDemoData: Boolean(actor.isDemoUser),
      });
      await setDoc(ref, result as DocumentData);
      entityId = ref.id;
      break;
    }
    case "updateConversation":
      result = await patch("conversations", String(p.id), {
        ...(p.patch as object),
        updatedAt: now(),
      });
      break;
    case "addConversationMessage": {
      const conversation = await read<SupportConversation>(
        "conversations",
        String(p.id),
      );
      const message = {
        id: publicId("MSG"),
        jobId: conversation.jobId ?? "support",
        senderType: "admin" as const,
        senderId: actor.id,
        senderName: actor.name,
        text: String(p.text),
        attachments: [],
        sentAt: now(),
        delivered: true,
        read: false,
        edited: false,
        deleted: false,
        flagged: false,
      };
      result = await patch("conversations", conversation.id, {
        messages: [...conversation.messages, message],
        updatedAt: now(),
      });
      break;
    }
    case "deleteConversation":
      await deleteDoc(doc(db, "conversations", String(p.id)));
      result = { id: p.id };
      break;
    default:
      throw new Error(`Unsupported Firestore operation: ${action}`);
  }
  await audit(
    actor,
    action,
    "firestore",
    entityId,
    `Executed ${action}`,
    undefined,
    result,
  );
  return result as T;
}

export async function loadAdminProfile(uid: string) {
  return read<AdminUser>("admins", uid);
}

/**
 * Read-only drill-down into a single job's REAL chat thread with one
 * technician (jobs/{jobId}/threads/{technicianId}(+/messages)) - additive to,
 * not a replacement for, the dashboard's native `conversations` list (see
 * real-schema-types.ts's module doc for why these stay separate concepts).
 * One-shot reads (not a live listener) since this is an on-demand
 * investigation view, not part of the main dashboard subscription set.
 * Demo actors have no real jobs to inspect, so this always returns empty for
 * them rather than attempting a lookup against a nonexistent path.
 */
export async function readRealJobChat(
  jobId: string,
  technicianId: string,
  actor: AdminUser,
): Promise<{ thread: RealChatThread | null; messages: RealChatMessage[] }> {
  if (
    actor.isDemoUser ||
    !(hasPermission(actor.role, actor.permissions, "trust.view") || hasPermission(actor.role, actor.permissions, "support.view"))
  ) {
    return { thread: null, messages: [] };
  }
  const { getDoc, getDocs, orderBy, query: buildQuery } = await import("firebase/firestore");
  const { db } = getFirebaseClient();
  const threadRef = doc(db, "jobs", jobId, "threads", technicianId);
  const threadSnapshot = await getDoc(threadRef);
  const thread = threadSnapshot.exists()
    ? mapRealChatThread(jobId, technicianId, threadSnapshot.data() as Record<string, unknown>)
    : null;
  const messagesSnapshot = await getDocs(
    buildQuery(collection(threadRef, "messages"), orderBy("created_at")),
  );
  const messages = messagesSnapshot.docs.map((item) =>
    mapRealChatMessage(item.id, item.data() as Record<string, unknown>),
  );
  return { thread, messages };
}

/**
 * Read-only drill-down into one user's REAL notification feed
 * (users/{uid}/notifications) - additive to, not a replacement for, the
 * dashboard's native `notifications` broadcast list. One-shot read, same
 * reasoning as readRealJobChat above.
 */
export async function readRealUserNotifications(
  uid: string,
  actor: AdminUser,
): Promise<RealNotification[]> {
  if (actor.isDemoUser || !hasPermission(actor.role, actor.permissions, "notifications.view")) {
    return [];
  }
  const { getDocs, orderBy, query: buildQuery, limit: limitDocs } = await import("firebase/firestore");
  const { db } = getFirebaseClient();
  const snapshot = await getDocs(
    buildQuery(
      collection(db, "users", uid, "notifications"),
      orderBy("created_at", "desc"),
      limitDocs(200),
    ),
  );
  return snapshot.docs.map((item) => mapRealNotification(item.id, item.data() as Record<string, unknown>));
}
