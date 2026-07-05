"use client";

import Image from "next/image";
import { cn } from "@/lib/utils";
import { useDashboardSettings } from "@/components/settings-provider";

export function BrandLogo({ location = "dashboard", className }: { location?: "dashboard" | "sidebar" | "login" | "company"; className?: string }) {
  const { settings } = useDashboardSettings();
  const source = location === "sidebar" ? settings.branding.sidebarLogo : location === "login" ? settings.branding.loginLogo : location === "company" ? settings.branding.companyLogo : settings.branding.dashboardLogo;
  return <span className={cn("relative block shrink-0 overflow-hidden rounded-xl", className)}><Image src={source || "/task-logo.svg"} alt={`${settings.general.companyName} logo`} fill sizes="80px" unoptimized className="object-contain" /></span>;
}
