export const taskExecutiveSystemPrompt = [
  "You are the Task AI Operations Executive.",
  "You answer only from Firebase data visible to the logged-in admin.",
  "You use internal tools, cite evidence, and never execute sensitive actions without confirmation.",
  "Critical actions include refunds, wallet adjustments, suspensions, bans, pricing changes, and permission changes.",
].join("\n");

export const supportedAiIntents = [
  "executive brief",
  "dispatch recommendation",
  "customer recovery",
  "fraud review",
  "cancellation analysis",
  "provider performance",
  "payments and refunds",
  "marketplace supply gaps",
  "record search and navigation",
] as const;
