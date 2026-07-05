"use client";

import { useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  Brain,
  CheckCircle2,
  Download,
  Loader2,
  Play,
  ShieldCheck,
  Sparkles,
  Zap,
} from "lucide-react";
import type { AiActionRequest, AiExecution, AiRecommendation } from "@/lib/types";
import { useAdminData } from "@/components/admin-data-provider";
import { useAuth } from "@/components/auth-provider";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { ConfirmDialog } from "@/components/functional-dialogs";
import { cn } from "@/lib/utils";

type DashboardSection =
  | "Overview"
  | "Live operations"
  | "Jobs"
  | "Providers"
  | "Customers"
  | "Trust & safety"
  | "Payments"
  | "Services & pricing"
  | "Promotions"
  | "Analytics"
  | "Admin & roles"
  | "Account"
  | "Settings";

const quickPrompts = [
  "Generate the executive operations brief",
  "Recommend the best provider for the oldest unassigned job",
  "Why was the latest cancelled request cancelled?",
  "Find suspicious refund or wallet abuse patterns",
  "Which provider has the weakest performance signal?",
  "Why are bookings dropping?",
];

function riskTone(
  risk: AiRecommendation["risk"],
): "destructive" | "warning" | "secondary" | "success" {
  if (risk === "CRITICAL") return "destructive";
  if (risk === "HIGH") return "warning";
  if (risk === "MEDIUM") return "secondary";
  return "success";
}

export function AiExecutivePage({
  page,
  navigate,
  openJob,
  openProvider,
  notify,
}: {
  page: string;
  navigate: (section: DashboardSection) => void;
  openJob: (jobId: string) => void;
  openProvider: (providerId: string) => void;
  notify: (message: string) => void;
}) {
  const { db, actions, mutationPending } = useAdminData();
  const { user, getIdToken } = useAuth();
  const [prompt, setPrompt] = useState("");
  const [running, setRunning] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [geminiConfigured, setGeminiConfigured] = useState<boolean | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<{
    execution: AiExecution;
    recommendation: AiRecommendation;
    action: AiActionRequest;
  } | null>(null);
  const executions = useMemo(
    () =>
      [...db.aiExecutions].sort((a, b) =>
        b.createdAt.localeCompare(a.createdAt),
      ),
    [db.aiExecutions],
  );
  const selected = selectedId
    ? executions.find((item) => item.id === selectedId) ?? executions[0]
    : executions[0];

  useEffect(() => {
    let mounted = true;
    getIdToken()
      .then((token) =>
        fetch("/api/firebase/integration-status", {
          headers: { authorization: `Bearer ${token}` },
        }),
      )
      .then(async (response) => {
        const data = await response.json().catch(() => ({}));
        if (!response.ok)
          throw new Error(
            typeof data.error === "string"
              ? data.error
              : "Integration status unavailable",
          );
        if (mounted) setGeminiConfigured(Boolean(data.gemini?.configured));
      })
      .catch(() => {
        if (mounted) setGeminiConfigured(false);
      });
    return () => {
      mounted = false;
    };
  }, [getIdToken]);

  const run = async (value = prompt) => {
    if (!user || !value.trim()) return;
    if (geminiConfigured === false) {
      const message =
        "Gemini is not configured in the deployed server environment. Add GEMINI_API_KEY to the Firebase Function environment, then redeploy.";
      setError(message);
      notify(message);
      return;
    }
    setRunning(true);
    setError(null);
    try {
      const token = await getIdToken();
      const response = await fetch("/api/firebase/ai", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          prompt: value,
          page: { page },
        }),
      });
      const data = (await response.json().catch(() => ({}))) as {
        execution?: AiExecution;
        error?: string;
      };
      if (!response.ok || !data.execution)
        throw new Error(data.error ?? "Gemini AI execution failed");
      const execution = data.execution;
      setSelectedId(execution.id);
      setPrompt("");
      notify("Gemini AI execution saved to Firestore");
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Gemini AI execution failed";
      setError(message);
      notify(message);
    } finally {
      setRunning(false);
    }
  };

  const executeAction = async (
    execution: AiExecution,
    recommendation: AiRecommendation,
    action: AiActionRequest,
  ) => {
    const payload = action.payload;
    if (action.type === "navigate") {
      navigate(String(payload.section ?? "Overview") as DashboardSection);
    } else if (action.type === "openJob") {
      openJob(String(payload.jobId));
    } else if (action.type === "openProvider") {
      openProvider(String(payload.providerId));
      navigate("Providers");
    } else if (action.type === "refundJob") {
      await actions.refundJob(String(payload.jobId));
    } else if (action.type === "assignProvider") {
      await actions.assignProvider(
        String(payload.jobId),
        String(payload.providerId),
      );
    } else if (action.type === "changeJobStatus") {
      await actions.changeJobStatus(
        String(payload.jobId),
        String(payload.status) as Parameters<typeof actions.changeJobStatus>[1],
      );
    } else if (action.type === "adjustWallet") {
      await actions.adjustWallet(
        String(payload.customerId),
        Number(payload.amount),
        String(payload.reason ?? "AI-confirmed wallet adjustment"),
      );
    } else if (action.type === "createComplaint") {
      await actions.createComplaint({
        title: String(payload.title ?? recommendation.title),
        description: String(payload.description ?? recommendation.body),
        severity: String(payload.severity ?? "Medium") as Parameters<
          typeof actions.createComplaint
        >[0]["severity"],
        jobId: payload.jobId ? String(payload.jobId) : undefined,
        customerId: payload.customerId ? String(payload.customerId) : undefined,
        providerId: payload.providerId ? String(payload.providerId) : undefined,
        customer: String(payload.customer ?? "AI review"),
      });
    } else if (action.type === "setProviderDecision") {
      await actions.setProviderDecision(
        String(payload.providerId),
        String(payload.decision) as "approve" | "reject" | "suspend" | "ban",
      );
    } else if (action.type === "createNotification") {
      await actions.createNotification({
        title: String(payload.title ?? recommendation.title),
        body: String(payload.body ?? recommendation.body),
        audience: String(payload.audience ?? "All customers") as Parameters<
          typeof actions.createNotification
        >[0]["audience"],
      });
    } else if (action.type === "createPromo") {
      await actions.createPromo({
        code: String(payload.code ?? `AI${Date.now().toString().slice(-5)}`),
        description: String(payload.description ?? recommendation.body),
        discountType: "fixed",
        discount: Number(payload.discount ?? 100),
        maxUses: Number(payload.maxUses ?? 1),
        endsAt: String(
          payload.endsAt ??
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        ),
        enabled: true,
      });
    }
    await actions.acceptAiRecommendation(execution.id, recommendation.id);
    notify(`${action.label} completed`);
  };

  const downloadExecution = (execution: AiExecution) => {
    const blob = new Blob([JSON.stringify(execution, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `${execution.id}.json`;
    anchor.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="grid gap-5 xl:grid-cols-[1.1fr_.9fr]">
      <section className="space-y-5">
        <Card className="overflow-hidden p-0">
          <div className="border-b border-white/[.07] p-5">
            <div className="flex items-center gap-3">
              <span className="grid h-12 w-12 place-items-center rounded-2xl bg-indigo-500/10 text-indigo-300">
                <Brain className="h-5 w-5" />
              </span>
              <div>
                <h2 className="text-base font-semibold">
                  Task AI Operations Executive
                </h2>
                <p className="mt-1 text-xs text-zinc-500">
                  Runs Gemini server-side against live Firebase data, records
                  memory, and logs every execution.
                </p>
              </div>
              <Badge
                className="ml-auto"
                variant={geminiConfigured === false ? "warning" : "success"}
              >
                {geminiConfigured === false
                  ? "Gemini not configured"
                  : geminiConfigured === null
                    ? "Checking Gemini"
                    : "Gemini server-side"}
              </Badge>
            </div>
          </div>
          <div className="space-y-4 p-5">
            <div className="flex gap-2">
              <Input
                value={prompt}
                onChange={(event) => setPrompt(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") void run();
                }}
                placeholder="Ask: why was this request cancelled, recommend provider, find suspicious refunds…"
                className="h-12"
              />
              <Button
                onClick={() => run()}
                disabled={running || !prompt.trim() || geminiConfigured !== true}
                className="h-12"
              >
                {running ? <Loader2 className="animate-spin" /> : <Play />}
                Run
              </Button>
            </div>
            {error && (
              <div className="rounded-xl border border-red-500/25 bg-red-500/10 p-3 text-xs leading-5 text-red-200">
                {error}
              </div>
            )}
            <div className="grid gap-2 md:grid-cols-2">
              {quickPrompts.map((item) => (
                <button
                  key={item}
                  onClick={() => run(item)}
                  disabled={running || geminiConfigured !== true}
                  className="rounded-xl border border-white/[.08] bg-white/[.03] p-3 text-left text-xs text-zinc-400 transition hover:border-indigo-500/30 hover:bg-indigo-500/10 hover:text-zinc-100 disabled:cursor-not-allowed disabled:opacity-45"
                >
                  <Sparkles className="mb-2 h-3.5 w-3.5 text-indigo-400" />
                  {item}
                </button>
              ))}
            </div>
          </div>
        </Card>

        {selected ? (
          <Card className="overflow-hidden p-0">
            <div className="flex items-center gap-3 border-b border-white/[.07] p-5">
              <div className="flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <h2 className="text-sm font-semibold">{selected.prompt}</h2>
                  <Badge variant={riskTone(selected.risk)}>
                    {selected.risk}
                  </Badge>
                  <Badge variant="secondary">{selected.status}</Badge>
                </div>
                <p className="mt-1 text-[10px] text-zinc-600">
                  {selected.id} · {new Date(selected.createdAt).toLocaleString()} ·{" "}
                  {selected.actorName}
                </p>
              </div>
              <Button
                variant="secondary"
                size="sm"
                onClick={() => downloadExecution(selected)}
              >
                <Download className="h-4 w-4" />
                Export
              </Button>
            </div>
            <div className="space-y-5 p-5">
              <div className="rounded-2xl border border-indigo-500/20 bg-indigo-500/[.07] p-4 text-sm leading-6 text-zinc-200">
                {selected.answer}
              </div>
              <div className="grid gap-4 lg:grid-cols-2">
                <div>
                  <h3 className="mb-3 text-xs font-semibold text-zinc-300">
                    Execution plan
                  </h3>
                  <div className="space-y-2">
                    {selected.plan.map((step) => (
                      <div
                        key={step.id}
                        className="flex items-center gap-3 rounded-xl border border-white/[.07] bg-white/[.025] p-3"
                      >
                        <CheckCircle2 className="h-4 w-4 text-emerald-400" />
                        <span className="flex-1 text-xs">{step.label}</span>
                        <Badge variant={riskTone(step.risk)}>{step.risk}</Badge>
                      </div>
                    ))}
                  </div>
                </div>
                <div>
                  <h3 className="mb-3 text-xs font-semibold text-zinc-300">
                    Tools used
                  </h3>
                  <div className="space-y-2">
                    {selected.toolCalls.map((tool) => (
                      <div
                        key={tool.id}
                        className="rounded-xl border border-white/[.07] bg-white/[.025] p-3"
                      >
                        <div className="flex items-center gap-2">
                          <Zap className="h-3.5 w-3.5 text-indigo-400" />
                          <b className="text-xs">{tool.name}</b>
                          <Badge
                            className="ml-auto"
                            variant={
                              tool.status === "blocked"
                                ? "destructive"
                                : "success"
                            }
                          >
                            {tool.status}
                          </Badge>
                        </div>
                        <p className="mt-2 text-[10px] leading-4 text-zinc-500">
                          {tool.summary}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <div>
                <h3 className="mb-3 text-xs font-semibold text-zinc-300">
                  Evidence
                </h3>
                <div className="grid gap-2 md:grid-cols-2">
                  {selected.evidence.map((item) => (
                    <div
                      key={item.id}
                      className="rounded-xl border border-white/[.07] bg-white/[.025] p-3"
                    >
                      <div className="text-xs font-medium">{item.label}</div>
                      <div className="mt-1 text-[10px] text-zinc-500">
                        {item.value}
                      </div>
                    </div>
                  ))}
                  {!selected.evidence.length && (
                    <div className="rounded-xl border border-white/[.07] p-4 text-xs text-zinc-500">
                      No matching Firestore evidence for this request yet.
                    </div>
                  )}
                </div>
              </div>
              <div>
                <h3 className="mb-3 text-xs font-semibold text-zinc-300">
                  Recommendations
                </h3>
                <div className="space-y-3">
                  {selected.recommendations.map((recommendation) => (
                    <div
                      key={recommendation.id}
                      className="rounded-2xl border border-white/[.08] bg-white/[.03] p-4"
                    >
                      <div className="flex flex-wrap items-start gap-3">
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <ShieldCheck className="h-4 w-4 text-indigo-400" />
                            <h4 className="text-xs font-semibold">
                              {recommendation.title}
                            </h4>
                            <Badge variant={riskTone(recommendation.risk)}>
                              {recommendation.risk}
                            </Badge>
                          </div>
                          <p className="mt-2 text-xs leading-5 text-zinc-500">
                            {recommendation.body}
                          </p>
                        </div>
                        {recommendation.acceptedAt ? (
                          <Badge variant="success">Accepted</Badge>
                        ) : recommendation.action ? (
                          <Button
                            size="sm"
                            variant={
                              recommendation.action.requiresConfirmation
                                ? "destructive"
                                : "secondary"
                            }
                            onClick={() =>
                              {
                                const action = recommendation.action;
                                if (!action) return;
                                return action.requiresConfirmation
                                  ? setPendingAction({
                                      execution: selected,
                                      recommendation,
                                      action,
                                    })
                                  : executeAction(
                                      selected,
                                      recommendation,
                                      action,
                                    );
                              }
                            }
                          >
                            {recommendation.action.requiresConfirmation && (
                              <AlertTriangle className="h-4 w-4" />
                            )}
                            {recommendation.action.label}
                          </Button>
                        ) : null}
                      </div>
                    </div>
                  ))}
                  {!selected.recommendations.length && (
                    <div className="rounded-xl border border-white/[.07] p-4 text-xs text-zinc-500">
                      No action is recommended from the current Firebase data.
                    </div>
                  )}
                </div>
              </div>
            </div>
          </Card>
        ) : (
          <Card className="grid min-h-[420px] place-items-center p-8 text-center">
            <div>
              <Brain className="mx-auto h-9 w-9 text-indigo-400" />
              <h2 className="mt-4 text-sm font-semibold">
                No AI executions yet
              </h2>
              <p className="mt-2 max-w-md text-xs leading-5 text-zinc-500">
                Run an operational question. The execution, evidence, memory,
                recommendations, and audit log will be stored in Firestore.
              </p>
            </div>
          </Card>
        )}
      </section>

      <aside className="space-y-5">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold">AI memory & history</h3>
            <Badge variant="secondary">{executions.length}</Badge>
          </div>
          <div className="mt-4 max-h-[520px] space-y-2 overflow-y-auto">
            {executions.map((execution) => (
              <button
                key={execution.id}
                onClick={() => setSelectedId(execution.id)}
                className={cn(
                  "w-full rounded-xl border p-3 text-left transition",
                  selected?.id === execution.id
                    ? "border-indigo-500/30 bg-indigo-500/10"
                    : "border-white/[.07] bg-white/[.025] hover:bg-white/[.05]",
                )}
              >
                <div className="line-clamp-2 text-xs font-medium">
                  {execution.prompt}
                </div>
                <div className="mt-2 flex items-center gap-2 text-[10px] text-zinc-600">
                  <Badge variant={riskTone(execution.risk)}>
                    {execution.risk}
                  </Badge>
                  {new Date(execution.createdAt).toLocaleTimeString()}
                </div>
              </button>
            ))}
            {!executions.length && (
              <div className="rounded-xl border border-white/[.07] p-4 text-xs text-zinc-500">
                AI executions will appear here after the first run.
              </div>
            )}
          </div>
        </Card>
        <Card className="p-4">
          <h3 className="text-sm font-semibold">Database visibility</h3>
          <div className="mt-4 grid grid-cols-2 gap-2">
            {[
              ["Customers", db.customers.length],
              ["Providers", db.providers.length],
              ["Jobs", db.jobs.length],
              ["Payments", db.transactions.length],
              ["Complaints", db.complaints.length],
              ["Live locations", db.locations.length],
            ].map(([label, value]) => (
              <div
                key={label}
                className="rounded-xl border border-white/[.07] bg-white/[.025] p-3"
              >
                <div className="text-[10px] text-zinc-500">{label}</div>
                <div className="mt-1 text-lg font-semibold">{value}</div>
              </div>
            ))}
          </div>
        </Card>
        {mutationPending && (
          <Card className="flex items-center gap-3 border-indigo-500/20 bg-indigo-500/[.07] p-4 text-xs text-indigo-200">
            <Loader2 className="h-4 w-4 animate-spin" />
            Saving AI action to Firestore…
          </Card>
        )}
      </aside>
      <ConfirmDialog
        open={!!pendingAction}
        onClose={() => setPendingAction(null)}
        title={`Confirm ${pendingAction?.action.label ?? "AI action"}?`}
        description={`Risk level: ${pendingAction?.action.risk}. This action will update Firebase and create an audit log.`}
        confirmLabel="Confirm action"
        onConfirm={async () => {
          if (pendingAction) {
            await executeAction(
              pendingAction.execution,
              pendingAction.recommendation,
              pendingAction.action,
            );
          }
        }}
      />
    </div>
  );
}
