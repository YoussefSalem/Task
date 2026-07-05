import type { AiPlanStep, AiRiskLevel } from "@/lib/types";

const id = (prefix: string) =>
  `${prefix}-${Date.now().toString(36)}-${Math.random().toString(16).slice(2, 7)}`;

export type AiIntent =
  | "executiveBrief"
  | "dispatch"
  | "cancellation"
  | "fraud"
  | "providerPerformance"
  | "bookingsDrop"
  | "search"
  | "customerRecovery"
  | "payment"
  | "unknown";

export function detectIntent(prompt: string): AiIntent {
  const text = prompt.toLowerCase();
  if (/morning|executive|summary|brief|today/.test(text)) return "executiveBrief";
  if (/dispatch|assign|best provider|recommend provider/.test(text)) return "dispatch";
  if (/cancel|why.*order|why.*request|recover/.test(text)) return text.includes("recover") ? "customerRecovery" : "cancellation";
  if (/fraud|suspicious|abuse|duplicate/.test(text)) return "fraud";
  if (/worst provider|complaints|performance|rating|cancel.*provider/.test(text)) return "providerPerformance";
  if (/booking.*drop|bookings.*down|demand/.test(text)) return "bookingsDrop";
  if (/payment|refund|wallet|instapay|payout|transaction/.test(text)) return "payment";
  if (/open|find|search|show|go to|customer|provider|job|order|request/.test(text)) return "search";
  return "unknown";
}

export function planForIntent(intent: AiIntent): AiPlanStep[] {
  const specs: Array<[string, AiRiskLevel, string?]> =
    intent === "executiveBrief"
      ? [["Read marketplace KPIs", "LOW", "generateReport"], ["Detect operational risks", "LOW", "generateReport"], ["Recommend next actions", "MEDIUM", "generateReport"]]
      : intent === "dispatch"
        ? [["Resolve target job/request", "LOW", "searchJob"], ["Score eligible providers", "LOW", "dispatchRecommendation"], ["Prepare assignment for confirmation", "HIGH", "assignProvider"]]
        : intent === "cancellation" || intent === "customerRecovery"
          ? [["Resolve cancelled request", "LOW", "searchJob"], ["Analyze timeline, offers, chat, calls and payment", "LOW", "summarizeJob"], ["Prepare recovery action", "MEDIUM", "createComplaint"]]
          : intent === "fraud"
            ? [["Inspect refunds, wallets and duplicate identities", "LOW", "fraudReview"], ["Score visible risk signals", "MEDIUM", "fraudReview"], ["Recommend human review", "HIGH", "createComplaint"]]
            : intent === "payment"
              ? [["Search transactions and wallets", "LOW", "searchPayment"], ["Verify related job/payment state", "LOW", "searchJob"], ["Prepare finance action if needed", "CRITICAL", "refund"]]
              : [["Search records", "LOW", "openRecord"], ["Summarize matching evidence", "LOW", "openRecord"], ["Recommend safe next step", "LOW", "openRecord"]];
  return specs.map(([label, risk, toolName]) => ({
    id: id("STEP"),
    label,
    risk,
    toolName,
    status: risk === "HIGH" || risk === "CRITICAL" ? "needs_confirmation" : "executed",
  }));
}
