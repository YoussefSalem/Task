import type { Provider, ProviderDocument } from "@/lib/types";

export function effectiveDocumentStatus(document: ProviderDocument) {
  if (document.expiryDate && new Date(document.expiryDate).getTime() < Date.now()) return "Expired" as const;
  return document.status;
}

export function verificationSummary(provider: Provider) {
  const mandatoryDocumentTypes = provider.requiredDocumentTypes?.length
    ? provider.requiredDocumentTypes
    : [...new Set(provider.documents.filter((document) => document.required).map((document) => document.type))];
  const approved = mandatoryDocumentTypes.filter((type) => provider.documents.some((document) => document.type === type && effectiveDocumentStatus(document) === "Approved"));
  const missing = mandatoryDocumentTypes.filter((type) => !provider.documents.some((document) => document.type === type));
  const rejected = provider.documents.filter((document) => effectiveDocumentStatus(document) === "Rejected");
  const expired = provider.documents.filter((document) => effectiveDocumentStatus(document) === "Expired");
  const pending = provider.documents.filter((document) => ["Pending", "Under Review"].includes(effectiveDocumentStatus(document)));
  const percentage = mandatoryDocumentTypes.length ? Math.round((approved.length / mandatoryDocumentTypes.length) * 100) : 0;
  const eligible = percentage === 100 && provider.verification.backgroundCheck === "Completed" && provider.verification.contractSigned && provider.verified && provider.status === "Active";
  return { approved, missing, rejected, expired, pending, percentage, eligible };
}

export function isProviderEligible(provider: Provider) {
  return verificationSummary(provider).eligible;
}

export function expiryMessage(document: ProviderDocument) {
  if (!document.expiryDate) return null;
  const days = Math.ceil((new Date(document.expiryDate).getTime() - Date.now()) / 86400000);
  if (days < 0) return `${document.type} expired`;
  if (days <= 30) return `${document.type} expires in ${days} day${days === 1 ? "" : "s"}`;
  return null;
}
