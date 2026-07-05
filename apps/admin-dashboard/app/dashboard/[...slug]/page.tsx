import { redirect } from "next/navigation";
import { ProtectedDashboard } from "@/components/protected-dashboard";

const routeSections = {
  "/dashboard/command-center": "Command Center",
  "/dashboard/ai": "AI Executive",
  "/dashboard/live-operations": "Live operations",
  "/dashboard/live-map": "Live Operations Map",
  "/dashboard/alerts": "Smart Alerts",
  "/dashboard/customer-intelligence": "Customer Intelligence",
  "/dashboard/booking-control": "Booking Control Center",
  "/dashboard/sla": "SLA Monitoring",
  "/dashboard/financial-control": "Financial Control Center",
  "/dashboard/fraud-risk": "Fraud & Risk Center",
  "/dashboard/quality-control": "Quality Control Center",
  "/dashboard/automation-rules": "Automation Rules",
  "/dashboard/notifications": "Notification Center",
  "/dashboard/reports": "Reports Center",
  "/dashboard/activity-timeline": "Activity Timeline",
  "/dashboard/system-health": "System Health",
  "/dashboard/search": "Advanced Search",
  "/dashboard/jobs": "Jobs",
  "/dashboard/providers": "Providers",
  "/dashboard/technician-performance": "Technician Performance",
  "/dashboard/customers": "Customers",
  "/dashboard/trust-safety": "Trust & safety",
  "/dashboard/payments": "Payments",
  "/dashboard/services": "Services & pricing",
  "/dashboard/content": "Content & banners",
  "/dashboard/support": "Support chats",
  "/dashboard/promotions": "Promotions",
  "/dashboard/analytics": "Analytics",
  "/dashboard/users": "Admin & roles",
  "/dashboard/account": "Account",
  "/dashboard/settings": "Settings",
  "/dashboard/settings/system-reset": "System Reset",
} as const;

export default async function DashboardSectionPage({
  params,
}: {
  params: Promise<{ slug?: string[] }>;
}) {
  const { slug = [] } = await params;
  const path = `/dashboard/${slug.join("/")}`.replace(/\/+$/, "");
  const section = routeSections[path as keyof typeof routeSections];
  if (!section) redirect("/dashboard");
  return <ProtectedDashboard section={section} />;
}
