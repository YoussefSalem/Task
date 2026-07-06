import { test } from "node:test";
import assert from "node:assert/strict";
import {
  providerSourceCollection,
  customerSourceCollection,
  jobSourceCollection,
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
