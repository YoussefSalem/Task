import type { AdminUser } from "@/lib/types";

export const DEMO_RESTRICTED_MESSAGE = "Demo users cannot perform this action.";
export type DataEnvironment = "production" | "demo";

export const demoRestrictedClientActions = new Set([
  "deleteCustomer",
  "deleteProvider",
  "deleteJob",
  "reviewInstapay",
  "setWalletFrozen",
  "verifyPayout",
  "updateTransaction",
  "deleteComplaint",
  "deleteCategory",
  "deleteService",
  "deleteBanner",
  "deleteConversation",
  "deletePromo",
  "updateAdmin",
  "deleteAdmin",
  "toggleAdmin",
  "sync-auth-users",
  "createRole",
  "updateRole",
  "deleteRole",
  "resend",
  "revoke",
  "create",
  "update",
  "toggle",
  "role-create",
  "role-update",
  "role-delete",
]);

export const demoSafeClientActions = new Set([
  "createCustomer",
  "updateCustomer",
  "createProvider",
  "updateProvider",
  "setProviderDecision",
  "createJob",
  "updateJob",
  "assignProvider",
  "changeJobStatus",
  "updateCancellation",
  "addJobNote",
  "refundJob",
  "createComplaint",
  "updateComplaint",
  "setCaseSeverity",
  "addCaseNote",
  "createConversation",
  "updateConversation",
  "addConversationMessage",
  "adjustWallet",
  "createPayout",
  "createTransaction",
  "createPromo",
  "updatePromo",
  "createNotification",
  "createCategory",
  "updateCategory",
  "createService",
  "updateService",
  "createBanner",
  "updateBanner",
  "createAiExecution",
  "updateAiExecution",
  "acceptAiRecommendation",
  "rememberAiContext",
  "createAiReport",
]);

export function isDemoExpired(user: Pick<AdminUser, "demoExpiresAt">) {
  if (!user.demoExpiresAt) return false;
  const expiresAt = new Date(user.demoExpiresAt).getTime();
  return Number.isFinite(expiresAt) && expiresAt <= Date.now();
}

export function assertDemoCanRun(user: AdminUser | null | undefined, action: string) {
  if (!user?.isDemoUser) return;
  if (isDemoExpired(user)) throw new Error("Demo access expired.");
  if (demoRestrictedClientActions.has(action) || !demoSafeClientActions.has(action))
    throw new Error(DEMO_RESTRICTED_MESSAGE);
}

export function isDemoData(record: unknown) {
  if (!record || typeof record !== "object") return false;
  const data = record as { environment?: unknown; isDemoData?: unknown };
  return data.environment === "demo" || data.isDemoData === true;
}

export function dataEnvironment(record: unknown): DataEnvironment {
  if (!record || typeof record !== "object") return "production";
  const data = record as { environment?: unknown; isDemoData?: unknown };
  if (data.environment === "demo") return "demo";
  if (data.environment === "production") return "production";
  return data.isDemoData === true ? "demo" : "production";
}

export function isDemoRestrictedPermission(permission: string) {
  return (
    permission.startsWith("roles.") ||
    permission === "users.create" ||
    permission === "users.invite" ||
    permission === "users.sync" ||
    permission === "users.delete" ||
    permission === "users.change_status" ||
    permission === "jobs.refund" ||
    permission === "payments.refund" ||
    permission === "payments.payout" ||
    permission === "payments.verify" ||
    permission === "payments.wallet" ||
    permission === "payments.sensitive" ||
    permission === "analytics.export" ||
    permission === "notifications.send" ||
    permission === "settings.edit" ||
    permission.endsWith(".delete") ||
    permission.endsWith(".export")
  );
}
