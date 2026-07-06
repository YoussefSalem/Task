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
