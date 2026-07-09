/**
 * Tiny, pure adapter-routing decisions extracted out of repository.ts so they
 * can be unit tested directly. Each function mirrors an existing inline
 * ternary in repository.ts (e.g. `actor.isDemoUser ? "providers" : "users"`) -
 * this module doesn't change behavior, it makes the decision testable and
 * gives the createPayout/verifyPayout collection-mismatch fix a direct
 * regression test.
 */

/** Which collection a technician/provider profile should be read from. */
export function providerSourceCollection(isDemoUser: boolean | undefined): "providers" | "users" {
  return isDemoUser ? "providers" : "users";
}

/** Which collection a customer profile should be read from. */
export function customerSourceCollection(isDemoUser: boolean | undefined): "customers" | "users" {
  return isDemoUser ? "customers" : "users";
}

/** Which collection a job/booking should be read from. */
export function jobSourceCollection(isDemoUser: boolean | undefined): "orders" | "jobs" {
  return isDemoUser ? "orders" : "jobs";
}

export type AdapterStatus = "bridged" | "native";

export interface AdapterInfo {
  status: AdapterStatus;
  /** Only set for "native": why no real Customer App equivalent exists (yet). */
  nativeReason?: string;
}

/**
 * Phase D.2 — single source of truth for adapter coverage across every
 * DatabaseState key. "bridged" means a production (non-demo) actor reads real
 * Customer App data for this concept (see the switch in resolveReadSource
 * below for the mechanics). "native" means there is genuinely no real
 * Customer App/backend equivalent to bridge to today - these stay on the
 * dashboard-native, environment-scoped collection for every actor, and the
 * reason is recorded here (not invented, not silently assumed) so a future
 * pass can revisit each one deliberately instead of guessing.
 *
 * This registry is the thing tests assert against for "every entity has a
 * documented adapter decision" - it does not itself decide field mappings.
 */
export const ADAPTER_REGISTRY: Record<string, AdapterInfo> = {
  customers: { status: "bridged" },
  providers: { status: "bridged" },
  jobs: { status: "bridged" },
  wallets: { status: "bridged" },
  transactions: { status: "bridged" },
  reviews: { status: "bridged" },
  banners: { status: "bridged" },
  complaints: { status: "bridged" },
  categories: {
    status: "native",
    nativeReason:
      "Customer App job categories are a hardcoded 26-value Dart enum, not a Firestore collection - there is nothing real to read from.",
  },
  services: {
    status: "native",
    nativeReason: "Same root cause as categories - no data-driven services collection exists in the Customer App.",
  },
  promos: {
    status: "native",
    nativeReason: "Discount-code promo campaigns have no Customer App equivalent at all.",
  },
  conversations: {
    status: "native",
    nativeReason:
      "Real chat lives at jobs/{jobId}/threads/{technicianId}/messages, a per-job model structurally different from a flat support-ticket list - not force-mapped.",
  },
  verificationRequirements: {
    status: "native",
    nativeReason: "Dashboard-only KYC policy configuration; the Customer App has no equivalent concept.",
  },
  admins: {
    status: "native",
    nativeReason:
      "Dashboard-native admin identity model, deliberately kept separate from Customer App users - see lib/firebase/admin-identity.ts.",
  },
  invitations: {
    status: "native",
    nativeReason: "Dashboard-native admin invite flow; no Customer App equivalent.",
  },
  roles: {
    status: "native",
    nativeReason: "Dashboard-native RBAC model; the Customer App has only a single inline `role` string field.",
  },
  notifications: {
    status: "native",
    nativeReason:
      "This is the dashboard's broadcast/campaign list, a different concept from the real per-user users/{uid}/notifications feed. createNotification already fans out real writes to that feed (Phase C); this list itself is not read back from real data.",
  },
  payouts: {
    status: "native",
    nativeReason: "No real technician-payout ledger concept exists in the Customer App yet.",
  },
  auditLogs: {
    status: "native",
    nativeReason: "Dashboard-native audit trail; the Customer App has no audit logging of any kind.",
  },
  locations: {
    status: "native",
    nativeReason:
      "Real technician location is per-job (jobs/{jobId}/tracking), not per-provider - a different granularity than this collection models. Aggregating per-job points into a per-provider 'current location' view would require new logic, not a simple field bridge, and was left undone rather than guessed at. The real per-job trail IS readable on demand via readRealJobTracking (repository.ts) for the live-ops map; only the per-provider aggregation stays native.",
  },
  instapayReviews: {
    status: "native",
    nativeReason: "No real Instapay payment-review concept exists in the Customer App.",
  },
  aiExecutions: {
    status: "native",
    nativeReason:
      "Dashboard-native AI assistant memory, unrelated to the Customer App's own separate Groq-based in-app assistant.",
  },
  aiMemories: { status: "native", nativeReason: "Same root cause as aiExecutions." },
  aiReports: { status: "native", nativeReason: "Same root cause as aiExecutions." },
};

/**
 * Descriptor for how a dashboard collection key should be READ. Consolidates
 * the read-side routing that was previously a stack of inline ternaries in
 * subscribeDashboard, so the demo-vs-production read decision has a single,
 * unit-testable source of truth (matching what the write-side helpers above
 * already do).
 */
export interface ReadSource {
  /** Firestore path segment to query. */
  collection: string;
  /** Top-level collection vs. a cross-parent collectionGroup query. */
  kind: "collection" | "collectionGroup";
  /** For the shared `users` collection, which role to filter to. */
  roleFilter?: "customer" | "technician";
  /** Whether to filter by `environment == demo|production` (demo-shaped only). */
  environmentScoped: boolean;
}

/**
 * Resolves the real read source for a dashboard collection key.
 *
 * For a production (non-demo) actor, the five adapter-bridged concepts read
 * the real Customer App schema: customers/providers -> `users` filtered by
 * role, jobs -> `jobs`, wallets/transactions/reviews -> the corresponding
 * per-user/per-job subcollections via collectionGroup. Everything else (and
 * every read for a demo actor) reads the dashboard-native collection, scoped
 * by the `environment` field when that collection is environment-partitioned.
 *
 * @param key the dashboard state key (e.g. "customers", "jobs")
 * @param isDemoUser whether the actor is a demo actor
 * @param demoCollectionName the dashboard-native collection name for this key
 * @param isEnvironmentScoped whether the native collection carries an `environment` field
 */
export function resolveReadSource(
  key: string,
  isDemoUser: boolean | undefined,
  demoCollectionName: string,
  isEnvironmentScoped: boolean,
): ReadSource {
  const isBridged = !isDemoUser && ADAPTER_REGISTRY[key]?.status === "bridged";
  if (isBridged) {
    switch (key) {
      case "customers":
        return { collection: "users", kind: "collection", roleFilter: "customer", environmentScoped: false };
      case "providers":
        return { collection: "users", kind: "collection", roleFilter: "technician", environmentScoped: false };
      case "jobs":
        return { collection: "jobs", kind: "collection", environmentScoped: false };
      case "wallets":
        return { collection: "wallet", kind: "collectionGroup", environmentScoped: false };
      case "transactions":
        return { collection: "wallet_transactions", kind: "collectionGroup", environmentScoped: false };
      case "reviews":
        return { collection: "reviews", kind: "collectionGroup", environmentScoped: false };
      case "banners":
        // Real Customer App equivalent is the top-level `promotions`
        // collection - same marketing-carousel purpose, different field
        // shape (no imageUrl/actionUrl on the real side). Mapped in
        // mapPromotionToBanner (repository.ts).
        return { collection: "promotions", kind: "collection", environmentScoped: false };
      case "complaints":
        // Real complaints live at jobs/{jobId}/complaints/{id} (see
        // packages/task_domain/lib/src/entities/complaint.dart) - a new
        // subcollection, read the same way reviews already are. Mapped in
        // mapJobComplaintToComplaint (repository.ts).
        return { collection: "complaints", kind: "collectionGroup", environmentScoped: false };
      default:
        break;
    }
  }
  return {
    collection: demoCollectionName,
    kind: "collection",
    environmentScoped: isEnvironmentScoped,
  };
}
