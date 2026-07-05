"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, KeyRound, Loader2, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { BrandLogo } from "@/components/brand-logo";
import Link from "next/link";
import { useDashboardSettings } from "@/components/settings-provider";
import { useAuth } from "@/components/auth-provider";

export default function LoginPage() {
  const router = useRouter();
  const { user, loading, login, error: configurationError } = useAuth();
  const { settings } = useDashboardSettings();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [hasInvite, setHasInvite] = useState(false);

  useEffect(() => {
    if (!loading && user) {
      console.info("[Task Admin Auth] dashboard redirect started", {
        source: "existing-session",
        target: "/dashboard",
      });
      router.replace("/dashboard");
    }
  }, [loading, router, user]);
  useEffect(() => setHasInvite(new URLSearchParams(window.location.search).has("invite")), []);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError("");
    if (!/^\S+@\S+\.\S+$/.test(email)) return setError("Enter a valid work email.");
    if (!password) return setError("Password is required.");
    setSubmitting(true);
    try {
      await login(email, password);
      console.info("[Task Admin Auth] dashboard redirect started", {
        source: "login-submit",
        target: "/dashboard",
      });
      router.replace("/dashboard");
    } catch (reason) {
      setError(
        reason instanceof Error
          ? reason.message
          : "Invalid credentials or this account is not active.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return null;
  return (
    <main className="relative grid min-h-screen place-items-center overflow-hidden bg-[#08080a] px-4 text-zinc-100">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(99,102,241,.18),transparent_38%)]" />
      <section className="relative w-full max-w-md rounded-3xl border border-white/[.09] bg-white/[.035] p-7 shadow-[0_40px_140px_rgba(0,0,0,.7)] backdrop-blur-2xl">
        <div className="mb-8 flex items-center gap-3">
          <BrandLogo location="login" className="h-11 w-11" />
          <div><h1 className="font-semibold">{settings.general.companyName} Admin</h1><p className="text-xs text-zinc-500">Secure operations console</p></div>
        </div>
        <div className="mb-6"><h2 className="text-2xl font-semibold tracking-tight">Welcome back</h2><p className="mt-2 text-sm text-zinc-500">Sign in with an active dashboard account.</p></div>
        {hasInvite && <div className="mb-4 rounded-xl border border-indigo-500/20 bg-indigo-500/10 p-3 text-xs text-indigo-300">Invitation detected. Sign in after your account has been activated.</div>}
        <form onSubmit={submit} className="space-y-4">
          <label className="block"><span className="mb-2 block text-xs text-zinc-400">Work email</span><Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} /></label>
          <label className="block"><span className="mb-2 block text-xs text-zinc-400">Password</span><Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} /></label>
          {(error||configurationError) && <p role="alert" className="rounded-xl border border-red-500/20 bg-red-500/10 p-3 text-xs text-red-300">{error||configurationError}</p>}
          <Button className="h-11 w-full" disabled={submitting}>{submitting ? <Loader2 className="animate-spin" /> : <KeyRound />}Sign in<ArrowRight className="ml-auto" /></Button>
          <Link href="/forgot-password" className="block text-center text-xs text-indigo-300 hover:text-indigo-200">Forgot password?</Link>
        </form>
        <div className="mt-6 rounded-xl border border-white/[.06] bg-black/20 p-3 text-[11px] text-zinc-500"><div className="mb-1 flex items-center gap-2 text-zinc-300"><ShieldCheck className="h-3.5 w-3.5 text-emerald-400" />Protected access</div><div>Use an active admin account or an emailed invitation link.</div></div>
      </section>
    </main>
  );
}
