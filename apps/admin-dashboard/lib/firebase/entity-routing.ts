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
  if (!isDemoUser) {
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
