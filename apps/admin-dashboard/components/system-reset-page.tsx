"use client";

import { useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  CheckCircle2,
  Loader2,
  RefreshCcw,
  ShieldAlert,
  Trash2,
  X,
} from "lucide-react";
import { useAuth } from "@/components/auth-provider";
import { useAdminData } from "@/components/admin-data-provider";
import { usePermissions } from "@/components/use-permissions";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

const RESET_PHRASE = "RESET TASK";

const resetModules = [
  { id: "customers", label: "Delete all Customers" },
  { id: "providers", label: "Delete all Providers" },
  { id: "jobs", label: "Delete all Jobs" },
  { id: "quotations", label: "Delete all Quotations" },
  { id: "payments", label: "Delete all Payments" },
  { id: "walletTransactions", label: "Delete all Wallet Transactions" },
  { id: "reviews", label: "Delete all Reviews" },
  { id: "notifications", label: "Delete all Notifications" },
  { id: "reports", label: "Delete all Reports" },
  { id: "analytics", label: "Delete all Analytics" },
  { id: "uploadedFiles", label: "Delete uploaded files" },
] as const;

type ResetModuleId = (typeof resetModules)[number]["id"];
type ModuleCounts = Record<
  ResetModuleId,
  { label: string; count: number; collections: Record<string, number> }
>;
type ResetResult = {
  module: ResetModuleId;
  label: string;
  deleted: number;
  collections: Record<string, number>;
};

async function parseResponse<T>(response: Response) {
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = (data as { error?: unknown }).error;
    throw new Error(typeof error === "string" ? error : "System reset failed");
  }
  return data as T;
}

export function SystemResetPage({ notify }: { notify: (message: string) => void }) {
  const { can } = usePermissions();
  const { getIdToken } = useAuth();
  const { actions } = useAdminData();
  const [counts, setCounts] = useState<ModuleCounts | null>(null);
  const [loadingCounts, setLoadingCounts] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [mode, setMode] = useState<"single" | "entire">("single");
  const [moduleId, setModuleId] = useState<ResetModuleId>("customers");
  const [phrase, setPhrase] = useState("");
  const [secondConfirm, setSecondConfirm] = useState(false);
  const [running, setRunning] = useState(false);
  const [progress, setProgress] = useState<Record<string, string>>({});
  const [summary, setSummary] = useState<ResetResult[]>([]);
  const [error, setError] = useState("");

  const allowed = can("system.reset");
  const selectedModules = useMemo(
    () => (mode === "entire" ? resetModules.map((item) => item.id) : [moduleId]),
    [mode, moduleId],
  );
  const selectedTotal = selectedModules.reduce(
    (sum, id) => sum + (counts?.[id]?.count ?? 0),
    0,
  );

  const api = async <T,>(body: Record<string, unknown>) => {
    const token = await getIdToken();
    const response = await fetch("/api/firebase/system-reset", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    });
    return parseResponse<T>(response);
  };

  const loadCounts = async () => {
    if (!allowed) return;
    setLoadingCounts(true);
    setError("");
    try {
      const data = await api<{ modules: ModuleCounts }>({ action: "counts" });
      setCounts(data.modules);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Could not load reset counts.");
    } finally {
      setLoadingCounts(false);
    }
  };

  useEffect(() => {
    void loadCounts();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [allowed]);

  const openReset = (nextMode: "single" | "entire", nextModule?: ResetModuleId) => {
    setMode(nextMode);
    if (nextModule) setModuleId(nextModule);
    setPhrase("");
    setSecondConfirm(false);
    setSummary([]);
    setProgress({});
    setError("");
    setDialogOpen(true);
  };

  const runReset = async () => {
    if (phrase !== RESET_PHRASE || !secondConfirm || running) return;
    setRunning(true);
    setError("");
    setSummary([]);
    const results: ResetResult[] = [];
    try {
      for (const id of selectedModules) {
        setProgress((current) => ({ ...current, [id]: "Running" }));
        const data = await api<{ result: ResetResult }>({
          action: "reset-module",
          module: id,
          confirmation: RESET_PHRASE,
          secondConfirmation: true,
        });
        results.push(data.result);
        setSummary([...results]);
        setProgress((current) => ({ ...current, [id]: "Completed" }));
      }
      notify(
        mode === "entire"
          ? "Production system reset completed"
          : `${resetModules.find((item) => item.id === moduleId)?.label ?? "Reset"} completed`,
      );
      await loadCounts();
      await actions.refresh();
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "System reset failed.";
      setError(message);
      selectedModules.forEach((id) => {
        setProgress((current) =>
          current[id] === "Completed" ? current : { ...current, [id]: "Failed" },
        );
      });
    } finally {
      setRunning(false);
    }
  };

  if (!allowed) {
    return (
      <Card className="rounded-2xl border-red-500/20 bg-red-500/5 p-6">
        <div className="flex items-start gap-3">
          <ShieldAlert className="mt-1 h-5 w-5 text-red-400" />
          <div>
            <h3 className="text-lg font-semibold text-red-100">Restricted system tool</h3>
            <p className="mt-1 max-w-2xl text-sm text-zinc-400">
              System Reset is available only to Super Admin users. This page is hidden from all other roles and direct access is blocked.
            </p>
          </div>
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-5">
      <Card className="rounded-2xl border-red-500/20 bg-red-500/5 p-5">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-start gap-3">
            <span className="grid h-11 w-11 place-items-center rounded-2xl bg-red-500/15">
              <ShieldAlert className="h-5 w-5 text-red-300" />
            </span>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-xl font-semibold">System Reset</h3>
                <Badge className="border-red-500/30 bg-red-500/10 text-red-200">
                  Super Admin only
                </Badge>
              </div>
              <p className="mt-1 max-w-3xl text-sm text-zinc-400">
                Permanently clears production workspace records while preserving admins, roles, permissions, settings, feature flags, Firebase Authentication users, and the demo workspace.
              </p>
            </div>
          </div>
          <div className="flex gap-2">
            <Button variant="secondary" onClick={loadCounts} disabled={loadingCounts || running}>
              {loadingCounts ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <RefreshCcw className="mr-2 h-4 w-4" />}
              Refresh counts
            </Button>
            <Button
              className="bg-red-600 text-white hover:bg-red-500"
              onClick={() => openReset("entire")}
              disabled={running || loadingCounts}
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Reset Entire System
            </Button>
          </div>
        </div>
      </Card>

      {error && (
        <div className="rounded-2xl border border-red-500/25 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </div>
      )}

      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {resetModules.map((item) => {
          const count = counts?.[item.id]?.count ?? 0;
          return (
            <Card key={item.id} className="rounded-2xl border-white/[.08] bg-white/[.025] p-4">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-sm font-semibold">{item.label}</p>
                  <p className="mt-1 text-xs text-zinc-500">
                    {loadingCounts ? "Counting production records…" : `${count.toLocaleString()} production record(s)`}
                  </p>
                </div>
                <Badge variant={count ? "destructive" : "secondary"}>
                  {count.toLocaleString()}
                </Badge>
              </div>
              <div className="mt-3 rounded-xl bg-black/20 p-2 text-[10px] text-zinc-500">
                {counts?.[item.id]
                  ? Object.entries(counts[item.id].collections).map(([name, value]) => (
                      <div key={name} className="flex justify-between gap-3">
                        <span>{name}</span>
                        <span>{value}</span>
                      </div>
                    ))
                  : "Counts unavailable"}
              </div>
              <Button
                className="mt-4 w-full"
                variant="secondary"
                disabled={running || loadingCounts}
                onClick={() => openReset("single", item.id)}
              >
                Reset this module
              </Button>
            </Card>
          );
        })}
      </div>

      {dialogOpen && (
        <div className="fixed inset-0 z-[100] overflow-y-auto bg-black/90 p-4 backdrop-blur-md">
          <div className="mx-auto my-8 max-w-4xl rounded-3xl border border-red-500/25 bg-[#100f10] shadow-2xl">
            <div className="flex items-start justify-between border-b border-red-500/20 p-5">
              <div className="flex items-start gap-3">
                <span className="grid h-11 w-11 place-items-center rounded-2xl bg-red-500/15">
                  <AlertTriangle className="h-5 w-5 text-red-300" />
                </span>
                <div>
                  <h3 className="text-xl font-semibold text-red-100">
                    Full-screen destructive action warning
                  </h3>
                  <p className="mt-1 text-sm text-zinc-400">
                    This will permanently delete production workspace data only. Demo data, admins, roles, settings, and Firebase Authentication users are not deleted.
                  </p>
                </div>
              </div>
              <button className="icon-btn" disabled={running} onClick={() => setDialogOpen(false)}>
                <X className="h-4 w-4" />
              </button>
            </div>
            <div className="space-y-5 p-5">
              <div className="rounded-2xl border border-red-500/20 bg-red-500/10 p-4 text-sm text-red-100">
                You are about to delete {selectedTotal.toLocaleString()} production record(s) from{" "}
                {mode === "entire" ? "the entire production workspace" : counts?.[moduleId]?.label}.
              </div>
              <div className="grid gap-2 md:grid-cols-2">
                {selectedModules.map((id) => (
                  <div key={id} className="rounded-xl border border-white/[.07] bg-white/[.03] p-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">{counts?.[id]?.label ?? id}</span>
                      <Badge variant={progress[id] === "Completed" ? "default" : progress[id] === "Failed" ? "destructive" : "secondary"}>
                        {progress[id] ?? `${counts?.[id]?.count ?? 0} records`}
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
              <label className="block space-y-2 text-sm text-zinc-400">
                Type <span className="font-mono text-red-200">{RESET_PHRASE}</span> to enable reset.
                <Input
                  value={phrase}
                  onChange={(event) => setPhrase(event.target.value)}
                  disabled={running}
                  placeholder={RESET_PHRASE}
                  className="font-mono"
                />
              </label>
              <label className="flex items-start gap-3 rounded-2xl border border-white/[.07] bg-white/[.03] p-3 text-sm text-zinc-300">
                <input
                  type="checkbox"
                  className="mt-1 h-4 w-4 accent-red-500"
                  checked={secondConfirm}
                  disabled={running}
                  onChange={(event) => setSecondConfirm(event.target.checked)}
                />
                <span>
                  I understand this permanently deletes production records and cannot be undone from the dashboard.
                </span>
              </label>
              {error && (
                <div className="rounded-xl border border-red-500/25 bg-red-500/10 px-3 py-2 text-sm text-red-200">
                  {error}
                </div>
              )}
              {summary.length > 0 && (
                <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/10 p-4">
                  <div className="flex items-center gap-2 text-sm font-semibold text-emerald-200">
                    <CheckCircle2 className="h-4 w-4" />
                    Reset summary
                  </div>
                  <div className="mt-3 space-y-2 text-xs text-emerald-100/80">
                    {summary.map((item) => (
                      <div key={item.module} className="flex justify-between gap-3">
                        <span>{item.label}</span>
                        <span>{item.deleted.toLocaleString()} deleted</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <div className="flex justify-end gap-2 border-t border-white/[.07] p-5">
              <Button variant="secondary" disabled={running} onClick={() => setDialogOpen(false)}>
                Cancel
              </Button>
              <Button
                className="bg-red-600 text-white hover:bg-red-500"
                disabled={running || phrase !== RESET_PHRASE || !secondConfirm}
                onClick={runReset}
              >
                {running ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Trash2 className="mr-2 h-4 w-4" />}
                Confirm reset
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
