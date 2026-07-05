"use client";

import { useState } from "react";
import { BrandLogo } from "@/components/brand-logo";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const response = await fetch("/api/firebase/password-reset", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = (await response.json().catch(() => ({}))) as {
        error?: string;
      };
      if (!response.ok) throw new Error(data.error ?? "Password reset failed");
      setSent(true);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Password reset failed");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="grid min-h-screen place-items-center bg-[#08080a] px-4 text-zinc-100">
      <form
        onSubmit={submit}
        className="w-full max-w-md rounded-3xl border border-white/[.09] bg-white/[.035] p-7"
      >
        <BrandLogo className="h-12 w-12" />
        <h1 className="mt-7 text-2xl font-semibold">Reset password</h1>
        <p className="mt-2 text-sm text-zinc-500">
          Enter your admin email and we’ll send a secure reset link.
        </p>
        <Input
          className="mt-6"
          type="email"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
        {error && (
          <p className="mt-4 rounded-xl bg-red-500/10 p-3 text-xs text-red-300">
            {error}
          </p>
        )}
        {sent ? (
          <p className="mt-4 rounded-xl bg-emerald-500/10 p-3 text-xs text-emerald-300">
            We sent a secure password reset link to your email.
          </p>
        ) : (
          <Button className="mt-4 w-full" disabled={submitting}>
            {submitting ? "Sending…" : "Send reset link"}
          </Button>
        )}
      </form>
    </main>
  );
}
