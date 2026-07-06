import { hasPermission } from "@/lib/permissions";

/**
 * Collections that must NEVER be sent to a third-party LLM (Gemini/OpenAI),
 * under any actor/permission combination - they hold admin identity/role
 * assignments or direct financial-balance data. The AI route's readState()
 * must never populate these; they stay as empty arrays in AiRuntimeContext.
 */
export const AI_FORBIDDEN_COLLECTIONS = new Set(["admins", "invitations", "roles", "wallets"]);

/**
 * Maps a collection key to the permission required for it to be included in
 * AI context at all. A support-role admin's AI query should not see the same
 * data a Super Admin's would. Collections not listed here are allowed for any
 * admin who can already reach the AI route (low-sensitivity catalog data like
 * categories/services/banners).
 */
const AI_COLLECTION_PERMISSION: Partial<Record<string, string>> = {
  customers: "customers.view",
  providers: "providers.view",
  jobs: "jobs.view",
  transactions: "payments.view",
  payouts: "payments.view",
  complaints: "trust.view",
  reviews: "reviews.view",
  conversations: "support.view",
  notifications: "notifications.view",
  auditLogs: "audit.view",
  instapayReviews: "payments.view",
  locations: "providers.view",
  promos: "promotions.view",
  verificationRequirements: "providers.view",
};

export function isCollectionAllowedForAi(
  collectionKey: string,
  actor: { role?: string; permissions?: string[] },
): boolean {
  if (AI_FORBIDDEN_COLLECTIONS.has(collectionKey)) return false;
  const permission = AI_COLLECTION_PERMISSION[collectionKey];
  if (!permission) return true;
  return hasPermission(actor.role, actor.permissions, permission);
}

/**
 * Field names stripped from every document before it reaches AI context,
 * regardless of collection - PII, bank/payment credentials, secrets, and
 * balance figures. Matching is on the field NAME (case-insensitive substring),
 * so this catches both snake_case (real Customer App fields) and camelCase
 * (dashboard-native fields) variants without needing a second list.
 */
const FORBIDDEN_FIELD_PATTERN =
  /email|phone|national[-_]?id|bank[-_]?info|\biban\b|wallet[-_]?balance|\bbalance\b|api[-_]?key|secret|password|\btoken\b|\bssn\b|instapay(account|number)/i;

/**
 * Removes any field whose name matches the forbidden pattern. Fields are
 * OMITTED entirely (not replaced with a placeholder string) so the LLM never
 * even sees that a redaction happened, and no placeholder value can be
 * mistaken for real data.
 */
export function redactDocForAi<T extends Record<string, unknown>>(doc: T): Partial<T> {
  const redacted: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(doc)) {
    if (FORBIDDEN_FIELD_PATTERN.test(key)) continue;
    redacted[key] = value;
  }
  return redacted as Partial<T>;
}
