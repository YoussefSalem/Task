import { test } from "node:test";
import assert from "node:assert/strict";
import { ADAPTER_REGISTRY, resolveReadSource } from "../lib/firebase/entity-routing";

const ALL_DATABASE_STATE_KEYS = [
  "aiExecutions",
  "aiMemories",
  "aiReports",
  "customers",
  "providers",
  "jobs",
  "categories",
  "services",
  "banners",
  "conversations",
  "verificationRequirements",
  "wallets",
  "transactions",
  "complaints",
  "reviews",
  "admins",
  "invitations",
  "roles",
  "promos",
  "notifications",
  "payouts",
  "auditLogs",
  "locations",
  "instapayReviews",
];

test("every DatabaseState collection key has a registered adapter decision (item 1/2/3: finish adapter coverage)", () => {
  for (const key of ALL_DATABASE_STATE_KEYS) {
    assert.ok(ADAPTER_REGISTRY[key], `${key} must have an ADAPTER_REGISTRY entry`);
  }
});

test("every 'native' entry documents WHY - no silent dashboard-only assumptions", () => {
  for (const [key, info] of Object.entries(ADAPTER_REGISTRY)) {
    if (info.status === "native") {
      assert.ok(
        info.nativeReason && info.nativeReason.length > 10,
        `${key} is native but has no documented reason`,
      );
    }
  }
});

test("bridged entries have no leftover nativeReason", () => {
  for (const [key, info] of Object.entries(ADAPTER_REGISTRY)) {
    if (info.status === "bridged") {
      assert.equal(info.nativeReason, undefined, `${key} is bridged and should not carry a native reason`);
    }
  }
});

test("the 8 genuinely bridged concepts are exactly: customers, providers, jobs, wallets, transactions, reviews, banners, complaints", () => {
  const bridged = Object.entries(ADAPTER_REGISTRY)
    .filter(([, info]) => info.status === "bridged")
    .map(([key]) => key)
    .sort();
  assert.deepEqual(bridged, [
    "banners",
    "complaints",
    "customers",
    "jobs",
    "providers",
    "reviews",
    "transactions",
    "wallets",
  ]);
});

test("resolveReadSource agrees with the registry: every 'native' key stays on the demo-native collection for production actors too", () => {
  for (const [key, info] of Object.entries(ADAPTER_REGISTRY)) {
    if (info.status !== "native") continue;
    const source = resolveReadSource(key, false, `native-${key}`, true);
    assert.equal(source.collection, `native-${key}`, `${key} should not be bridged`);
  }
});

test("resolveReadSource agrees with the registry: every 'bridged' key resolves away from its demo-native name for production actors", () => {
  for (const [key, info] of Object.entries(ADAPTER_REGISTRY)) {
    if (info.status !== "bridged") continue;
    const source = resolveReadSource(key, false, `demo-native-name-for-${key}`, true);
    assert.notEqual(
      source.collection,
      `demo-native-name-for-${key}`,
      `${key} is registered bridged but resolveReadSource didn't route it anywhere real`,
    );
  }
});

test("production read routing: banners bridges to the real top-level promotions collection", () => {
  const source = resolveReadSource("banners", false, "banners", true);
  assert.deepEqual(source, { collection: "promotions", kind: "collection", environmentScoped: false });
});

test("demo separation: a demo actor reading banners stays on the dashboard-native banners collection, never promotions", () => {
  const source = resolveReadSource("banners", true, "banners", true);
  assert.equal(source.collection, "banners");
  assert.equal(source.environmentScoped, true);
});

test("production read routing: complaints bridge to the real jobs/{jobId}/complaints collectionGroup", () => {
  const source = resolveReadSource("complaints", false, "complaints", true);
  assert.deepEqual(source, { collection: "complaints", kind: "collectionGroup", environmentScoped: false });
});

test("demo separation: a demo actor reading complaints stays on the dashboard-native, environment-scoped complaints collection", () => {
  const source = resolveReadSource("complaints", true, "complaints", true);
  assert.equal(source.collection, "complaints");
  assert.equal(source.kind, "collection");
  assert.equal(source.environmentScoped, true);
});
