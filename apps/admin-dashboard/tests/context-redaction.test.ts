import { test } from "node:test";
import assert from "node:assert/strict";
import {
  isCollectionAllowedForAi,
  redactDocForAi,
  AI_FORBIDDEN_COLLECTIONS,
} from "../lib/ai/context-redaction";

test("admins, invitations, roles, and wallets are always forbidden regardless of permissions (the fixed bug)", () => {
  const superAdmin = { role: "Super Admin", permissions: ["*"] };
  assert.equal(isCollectionAllowedForAi("admins", superAdmin), false);
  assert.equal(isCollectionAllowedForAi("invitations", superAdmin), false);
  assert.equal(isCollectionAllowedForAi("roles", superAdmin), false);
  assert.equal(isCollectionAllowedForAi("wallets", superAdmin), false);
  assert.deepEqual(
    [...AI_FORBIDDEN_COLLECTIONS].sort(),
    ["admins", "invitations", "roles", "wallets"],
  );
});

test("permission-scoped collections require the matching permission", () => {
  const noPerms = { role: "Support", permissions: [] };
  assert.equal(isCollectionAllowedForAi("customers", noPerms), false);
  assert.equal(isCollectionAllowedForAi("providers", noPerms), false);
  assert.equal(isCollectionAllowedForAi("transactions", noPerms), false);
});

test("permission-scoped collections are allowed once the actor has the matching permission", () => {
  const withPerm = { role: "Support", permissions: ["customers.view"] };
  assert.equal(isCollectionAllowedForAi("customers", withPerm), true);
  // still doesn't grant an unrelated permission-scoped collection
  assert.equal(isCollectionAllowedForAi("providers", withPerm), false);
});

test("unlisted (low-sensitivity) collections are allowed for any actor who reaches the AI route", () => {
  assert.equal(isCollectionAllowedForAi("categories", { role: "Support", permissions: [] }), true);
  assert.equal(isCollectionAllowedForAi("banners", { role: "Support", permissions: [] }), true);
});

test("redacts PII, bank details, wallet balances, and secrets by field name", () => {
  const doc = {
    id: "cust_1",
    name: "Jane Doe",
    email: "jane@example.com",
    phone: "+201234567890",
    nationalIdNumber: "12345678901234",
    bankInfo: { bankName: "Bank", iban: "EG..." },
    walletBalance: 500,
    wallet_balance: 500,
    balance: 500,
    apiKey: "sk-live-xxx",
    secret: "shh",
    token: "abc.def.ghi",
    status: "Active",
  };
  const redacted = redactDocForAi(doc);
  assert.equal(redacted.name, "Jane Doe");
  assert.equal(redacted.status, "Active");
  assert.equal("email" in redacted, false);
  assert.equal("phone" in redacted, false);
  assert.equal("nationalIdNumber" in redacted, false);
  assert.equal("bankInfo" in redacted, false);
  assert.equal("walletBalance" in redacted, false);
  assert.equal("wallet_balance" in redacted, false);
  assert.equal("balance" in redacted, false);
  assert.equal("apiKey" in redacted, false);
  assert.equal("secret" in redacted, false);
  assert.equal("token" in redacted, false);
});

test("redaction is case/style-insensitive across snake_case and camelCase", () => {
  const doc = { EMAIL: "x@y.com", Phone_Number: "123", national_id: "1", walletbalance: 1 };
  const redacted = redactDocForAi(doc);
  assert.deepEqual(redacted, {});
});

test("does not redact unrelated fields that merely contain similar substrings innocuously", () => {
  const doc = { title: "Balance sheet review", id: "x" };
  // "Balance" appears inside a normal field value, but the FIELD NAME "title"
  // does not match the pattern, so it must survive.
  const redacted = redactDocForAi(doc);
  assert.equal(redacted.title, "Balance sheet review");
});
