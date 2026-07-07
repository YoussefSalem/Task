import { test } from "node:test";
import assert from "node:assert/strict";
import {
  providerSourceCollection,
  customerSourceCollection,
  jobSourceCollection,
  resolveReadSource,
} from "../lib/firebase/entity-routing";

test("non-demo (production) admins read providers from the real users collection (the fixed payout/verify bug)", () => {
  assert.equal(providerSourceCollection(false), "users");
});

test("demo admins keep reading the dashboard's own providers collection", () => {
  assert.equal(providerSourceCollection(true), "providers");
});

test("customer routing mirrors the same pattern", () => {
  assert.equal(customerSourceCollection(false), "users");
  assert.equal(customerSourceCollection(true), "customers");
});

test("job routing mirrors the same pattern", () => {
  assert.equal(jobSourceCollection(false), "jobs");
  assert.equal(jobSourceCollection(true), "orders");
});

// --- Phase D.1: read-source routing (resolveReadSource) ---

test("production read routing: customers/providers read the real users collection filtered by role", () => {
  const customers = resolveReadSource("customers", false, "customers", true);
  assert.equal(customers.collection, "users");
  assert.equal(customers.kind, "collection");
  assert.equal(customers.roleFilter, "customer");
  assert.equal(customers.environmentScoped, false);

  const providers = resolveReadSource("providers", false, "providers", true);
  assert.equal(providers.collection, "users");
  assert.equal(providers.roleFilter, "technician");
});

test("production read routing: jobs reads the real jobs collection (not orders)", () => {
  const jobs = resolveReadSource("jobs", false, "orders", true);
  assert.equal(jobs.collection, "jobs");
  assert.equal(jobs.kind, "collection");
  assert.equal(jobs.environmentScoped, false);
});

test("production read routing: wallets/transactions/reviews use real subcollection collectionGroups", () => {
  assert.deepEqual(resolveReadSource("wallets", false, "wallets", true), {
    collection: "wallet",
    kind: "collectionGroup",
    environmentScoped: false,
  });
  assert.deepEqual(resolveReadSource("transactions", false, "transactions", true), {
    collection: "wallet_transactions",
    kind: "collectionGroup",
    environmentScoped: false,
  });
  assert.deepEqual(resolveReadSource("reviews", false, "reviews", true), {
    collection: "reviews",
    kind: "collectionGroup",
    environmentScoped: false,
  });
});

test("production read routing: non-bridged collections read the native collection scoped by environment=production", () => {
  const categories = resolveReadSource("categories", false, "categories", true);
  assert.equal(categories.collection, "categories");
  assert.equal(categories.kind, "collection");
  assert.equal(categories.roleFilter, undefined);
  assert.equal(categories.environmentScoped, true);
});

test("demo separation: a demo actor ALWAYS reads the demo-native collection scoped by environment, never the real schema", () => {
  // Even for the bridged concepts, a demo actor stays on the dashboard-native
  // collection (customers/providers/orders/etc.) with environment scoping -
  // it must never fall through to `users`/`jobs`/collectionGroup real reads.
  for (const [key, demoName] of [
    ["customers", "customers"],
    ["providers", "providers"],
    ["jobs", "orders"],
    ["wallets", "wallets"],
    ["transactions", "transactions"],
    ["reviews", "reviews"],
    ["categories", "categories"],
  ] as const) {
    const source = resolveReadSource(key, true, demoName, true);
    assert.equal(source.collection, demoName, `${key} demo read collection`);
    assert.equal(source.kind, "collection", `${key} demo read kind`);
    assert.equal(source.roleFilter, undefined, `${key} demo read has no role filter`);
    assert.equal(source.environmentScoped, true, `${key} demo read is environment-scoped`);
  }
});

test("demo separation: a non-environment-scoped native collection is not environment-filtered", () => {
  const source = resolveReadSource("someUnpartitioned", true, "someUnpartitioned", false);
  assert.equal(source.environmentScoped, false);
});
