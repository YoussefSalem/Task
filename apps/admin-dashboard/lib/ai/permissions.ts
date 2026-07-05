import type { AdminUser, Permission } from "@/lib/types";
import { hasPermission as hasRbacPermission } from "@/lib/permissions";

export type AiToolName =
  | "searchCustomer"
  | "searchProvider"
  | "searchJob"
  | "searchComplaint"
  | "searchPayment"
  | "searchWallet"
  | "searchDocument"
  | "searchChat"
  | "searchCall"
  | "openRecord"
  | "createComplaint"
  | "refund"
  | "walletCredit"
  | "walletDebit"
  | "createPromo"
  | "assignProvider"
  | "changeStatus"
  | "approveProvider"
  | "rejectProvider"
  | "generateReport"
  | "summarizeCustomer"
  | "summarizeProvider"
  | "summarizeJob"
  | "summarizeComplaint"
  | "dispatchRecommendation"
  | "fraudReview";

export const aiToolPermissions: Record<AiToolName, Permission | null> = {
  searchCustomer: "customers.read",
  searchProvider: "providers.read",
  searchJob: "jobs.read",
  searchComplaint: "trust.manage",
  searchPayment: "payments.read",
  searchWallet: "payments.read",
  searchDocument: "providers.read",
  searchChat: "jobs.read",
  searchCall: "jobs.read",
  openRecord: null,
  createComplaint: "trust.manage",
  refund: "payments.manage",
  walletCredit: "customers.write",
  walletDebit: "customers.write",
  createPromo: "promotions.manage",
  assignProvider: "jobs.write",
  changeStatus: "jobs.write",
  approveProvider: "providers.approve",
  rejectProvider: "providers.approve",
  generateReport: "audit.read",
  summarizeCustomer: "customers.read",
  summarizeProvider: "providers.read",
  summarizeJob: "jobs.read",
  summarizeComplaint: "trust.manage",
  dispatchRecommendation: "jobs.read",
  fraudReview: "payments.read",
};

export function hasPermission(actor: AdminUser, permission: Permission | null) {
  if (!permission) return true;
  return hasRbacPermission(actor.role, actor.permissions, permission);
}

export function canUseAiTool(actor: AdminUser, tool: AiToolName) {
  return hasPermission(actor, aiToolPermissions[tool]);
}

export function blockedToolReason(actor: AdminUser, tool: AiToolName) {
  const permission = aiToolPermissions[tool];
  if (hasPermission(actor, permission)) return "";
  return `${actor.role} is missing ${permission}`;
}
