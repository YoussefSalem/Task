import type { AiExecution, AiEvidence, AiRecommendation } from "@/lib/types";
import { executionStatus, highestRisk } from "@/lib/ai/action-engine";
import type { AiRuntimeContext } from "@/lib/ai/context";
import { canUseAiTool, type AiToolName } from "@/lib/ai/permissions";
import { detectIntent, planForIntent } from "@/lib/ai/planner";
import {
  analyzeCancellation,
  dispatchRecommendation,
  executiveBrief,
  findBestJob,
  fraudSignals,
  marketplaceMetrics,
  searchCustomers,
  searchJobs,
  searchPayments,
  searchProviders,
} from "@/lib/ai/tools";

const id = (prefix: string) =>
  `${prefix}-${Date.now().toString(36)}-${Math.random().toString(16).slice(2, 7)}`;

function allowedToolCall(context: AiRuntimeContext, tool: AiToolName, summary: string, entityId?: string) {
  const allowed = canUseAiTool(context.actor, tool);
  return {
    id: id("TOOL"),
    name: tool,
    status: allowed ? "executed" as const : "blocked" as const,
    risk: "LOW" as const,
    summary: allowed ? summary : `${tool} blocked by role permissions.`,
    entityId,
  };
}

export function runAiExecution(context: AiRuntimeContext, prompt: string): Partial<AiExecution> {
  const normalizedPrompt = prompt.trim().toLowerCase();
  const intent = detectIntent(prompt);
  const plan = planForIntent(intent);
  const toolCalls = [];
  let answer = "";
  let evidence: AiEvidence[] = [];
  let recommendations: AiRecommendation[] = [];
  let resolvedEntityType: string | undefined;
  let resolvedEntityId: string | undefined;

  if (intent === "executiveBrief" || intent === "bookingsDrop") {
    const brief = executiveBrief(context.state);
    answer = intent === "bookingsDrop"
      ? `${brief.answer} Booking movement should be compared with mobile-app traffic once customer-app analytics are connected. Current Firestore demand signals show ${marketplaceMetrics(context.state).bookings} total job records.`
      : brief.answer;
    evidence = brief.evidence;
    recommendations = brief.recommendations;
    toolCalls.push(allowedToolCall(context, "generateReport", "Generated executive brief from Firestore orders, providers, locations and payments."));
  } else if (intent === "dispatch") {
    const job = context.page.currentEntityType === "job"
      ? context.state.jobs.find((item) => item.id === context.page.currentEntityId)
      : findBestJob(context.state, prompt);
    const result = dispatchRecommendation(context.state, job);
    answer = result.answer;
    evidence = result.evidence;
    recommendations = result.recommendations;
    resolvedEntityType = job ? "job" : undefined;
    resolvedEntityId = job?.id;
    toolCalls.push(allowedToolCall(context, "dispatchRecommendation", "Scored eligible providers with verification, workload, rating and live location.", job?.id));
  } else if (intent === "cancellation" || intent === "customerRecovery") {
    const job = context.page.currentEntityType === "job"
      ? context.state.jobs.find((item) => item.id === context.page.currentEntityId)
      : findBestJob(context.state, prompt) ?? context.state.jobs.find((item) => item.cancellation);
    if (job) {
      const result = analyzeCancellation(job);
      answer = result.answer;
      evidence = result.evidence;
      recommendations = result.recommendations;
      resolvedEntityType = "job";
      resolvedEntityId = job.id;
    } else {
      answer = "No cancelled request was found in Firestore for this query.";
    }
    toolCalls.push(allowedToolCall(context, "summarizeJob", "Analyzed cancellation, timeline, offers, messages, calls and payment state.", job?.id));
  } else if (intent === "fraud") {
    const result = fraudSignals(context.state);
    answer = result.answer;
    evidence = result.evidence;
    recommendations = result.recommendations;
    toolCalls.push(allowedToolCall(context, "fraudReview", "Inspected Firestore refunds, wallets and duplicate customer signals."));
  } else if (intent === "payment") {
    const payments = searchPayments(context.state, prompt);
    const jobs = searchJobs(context.state, prompt);
    answer = `${payments.summary} ${jobs.summary}`;
    evidence = [...payments.evidence, ...jobs.evidence];
    toolCalls.push(allowedToolCall(context, "searchPayment", payments.summary));
    toolCalls.push(allowedToolCall(context, "searchJob", jobs.summary));
  } else if (intent === "providerPerformance") {
    const providers = [...context.state.providers]
      .map((provider) => {
        const complaints = context.state.complaints.filter((item) => item.providerId === provider.id).length;
        const jobs = context.state.jobs.filter((item) => item.providerId === provider.id);
        const cancelled = jobs.filter((item) => item.cancellation).length;
        return { provider, complaints, jobs: jobs.length, cancelled, score: provider.rating - complaints * 0.7 - cancelled * 0.4 };
      })
      .sort((a, b) => a.score - b.score);
    const worst = providers[0];
    answer = worst
      ? `${worst.provider.providerId} ${worst.provider.name} is currently the weakest provider signal: ${worst.provider.rating.toFixed(1)}★, ${worst.complaints} complaints, ${worst.cancelled} cancelled jobs.`
      : "No provider records exist in Firestore yet.";
    evidence = providers.slice(0, 5).map((item) => ({
      id: id("EV"),
      label: `${item.provider.providerId} · ${item.provider.name}`,
      entityType: "provider" as const,
      entityId: item.provider.id,
      value: `${item.provider.rating.toFixed(1)}★ · complaints ${item.complaints} · cancellations ${item.cancelled}`,
    }));
    if (worst?.complaints || worst?.cancelled) {
      recommendations = [{
        id: id("REC"),
        title: "Review provider quality",
        body: "Open a Trust & Safety review before suspension. Do not auto-suspend without human confirmation.",
        risk: "HIGH" as const,
        action: {
          type: "createComplaint",
          label: "Open provider review",
          risk: "HIGH" as const,
          requiresConfirmation: true,
          payload: {
            title: `Provider quality review · ${worst.provider.providerId}`,
            description: `${worst.provider.name} has ${worst.complaints} complaints and ${worst.cancelled} cancellations.`,
            severity: "High",
            providerId: worst.provider.id,
            customer: "Provider quality",
          },
        },
      }];
    }
    toolCalls.push(allowedToolCall(context, "summarizeProvider", "Ranked providers by rating, complaints and cancellation outcomes.", worst?.provider.id));
  } else {
    const customers = searchCustomers(context.state, prompt);
    const providers = searchProviders(context.state, prompt);
    const jobs = searchJobs(context.state, prompt);
    answer = [customers.summary, providers.summary, jobs.summary].join(" ");
    evidence = [...customers.evidence, ...providers.evidence, ...jobs.evidence].slice(0, 8);
    const firstJob = jobs.records[0];
    const firstProvider = providers.records[0];
    if (firstJob) {
      recommendations.push({
        id: id("REC"),
        title: `Open ${firstJob.id}`,
        body: "Navigate directly to this request/job details.",
        risk: "LOW",
        action: { type: "openJob", label: "Open job", risk: "LOW", requiresConfirmation: false, payload: { jobId: firstJob.id } },
      });
      resolvedEntityType = "job";
      resolvedEntityId = firstJob.id;
    } else if (firstProvider) {
      recommendations.push({
        id: id("REC"),
        title: `Open ${firstProvider.providerId}`,
        body: "Navigate directly to this provider profile.",
        risk: "LOW",
        action: { type: "openProvider", label: "Open provider", risk: "LOW", requiresConfirmation: false, payload: { providerId: firstProvider.id } },
      });
      resolvedEntityType = "provider";
      resolvedEntityId = firstProvider.id;
    }
    toolCalls.push(allowedToolCall(context, "searchCustomer", customers.summary));
    toolCalls.push(allowedToolCall(context, "searchProvider", providers.summary));
    toolCalls.push(allowedToolCall(context, "searchJob", jobs.summary));
  }

  const risk = highestRisk(recommendations);
  return {
    prompt,
    normalizedPrompt,
    actorId: context.actor.id,
    actorName: context.actor.name,
    actorRole: context.actor.role,
    page: context.page.page,
    status: executionStatus(risk),
    risk,
    answer,
    plan,
    toolCalls,
    evidence,
    recommendations,
    context: {
      currentEntityType: context.page.currentEntityType,
      currentEntityId: context.page.currentEntityId,
      resolvedEntityType,
      resolvedEntityId,
    },
  };
}
