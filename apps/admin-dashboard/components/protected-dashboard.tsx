"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AdminDashboard } from "@/components/admin-dashboard";
import type { Section } from "@/components/admin-dashboard";
import { useAuth } from "@/components/auth-provider";
import { BrandLogo } from "@/components/brand-logo";

export function ProtectedDashboard({ section = "Overview" }: { section?: Section }) {
  const router = useRouter();
  const { user, loading } = useAuth();
  useEffect(() => {
    if (!loading && !user) {
      console.info("[Task Admin Auth] protected route redirect", {
        target: "/login",
      });
      router.replace("/login");
    }
  }, [loading, router, user]);
  if (loading || !user)
    return <div className="grid min-h-screen place-items-center bg-[#08080a] text-sm text-zinc-500"><div className="flex flex-col items-center gap-4"><BrandLogo className="h-14 w-14 animate-pulse"/>Securing workspace…</div></div>;
  return <AdminDashboard initialSection={section} />;
}
