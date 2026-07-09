"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import {
  Activity,
  AlertTriangle,
  ArrowDownRight,
  ArrowLeft,
  ArrowRight,
  ArrowUpRight,
  BadgeDollarSign,
  Banknote,
  BarChart3,
  Bell,
  BriefcaseBusiness,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  CircleDollarSign,
  Clock3,
  Command,
  Download,
  FileCheck2,
  Filter,
  Gauge,
  Gift,
  Headphones,
  House,
  MapPin,
  Megaphone,
  Menu,
  MessageSquareWarning,
  Moon,
  MoreHorizontal,
  Plus,
  Radio,
  RefreshCcw,
  Search,
  ShieldCheck,
  SlidersHorizontal,
  LogOut,
  Languages,
  Loader2,
  Monitor,
  Star,
  Sun,
  TrendingUp,
  UserCheck,
  UserCog,
  UserRound,
  Users,
  WalletCards,
  Wrench,
  X,
  Zap,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type {
  AdminUser,
  Customer,
  DatabaseState,
  Job,
  Provider,
  Service,
} from "@/lib/types";
import { cn } from "@/lib/utils";
import { useAdminData } from "@/components/admin-data-provider";
import { usePreferences } from "@/components/app-preferences-provider";
import { useAuth } from "@/components/auth-provider";
import { usePermissions } from "@/components/use-permissions";
import { LiveOperationsMap } from "@/components/live-operations-map";
import { ManualJobDialog } from "@/components/manual-job-dialog";
import { AccountPage, SettingsPage } from "@/components/account-settings-pages";
import { BrandLogo } from "@/components/brand-logo";
import { EnvironmentBadges } from "@/components/environment-badges";
import { useDashboardSettings } from "@/components/settings-provider";
import { ProviderVerificationCenter } from "@/components/provider-verification-center";
import { ProviderManagement } from "@/components/provider-management";
import { TechnicianPerformanceCenter } from "@/components/technician-performance-center";
import { ProviderSearchPicker } from "@/components/provider-search-picker";
import { SearchableSelect } from "@/components/searchable-select";
import { RequestControlCenter } from "@/components/request-control-center";
import { CustomerHistoryDrawer } from "@/components/customer-history-drawer";
import { ContentManagementPage, SupportConversationsPage } from "@/components/firebase-content-pages";
import { AiExecutivePage } from "@/components/ai-executive-page";
import { SystemResetPage } from "@/components/system-reset-page";
import { EnterpriseOperationsPage } from "@/components/enterprise-operations-pages";
import { ComplaintRealDataDialog } from "@/components/complaint-real-data-dialog";
import {
  fullAccessPermissions,
  groupPermissions,
  isSuperAdminRole,
  normalizePermissionList,
  permissionActions,
  permissionTree,
  permissionsForLeaf,
  sectionPermissions,
  viewOnlyPermissions,
} from "@/lib/permissions";
import {
  expiryMessage,
  isProviderEligible,
  verificationSummary,
} from "@/lib/provider-verification";
import { providerMatchesQuery } from "@/lib/provider-search";
import { uploadFirebaseFile } from "@/lib/firebase/storage";
import { getFirebaseClient } from "@/lib/firebase/client";
import { collection, doc, setDoc } from "firebase/firestore";
import {
  ConfirmDialog,
  FormDialog,
  RowActions,
} from "@/components/functional-dialogs";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import {
  Avatar as ShadcnAvatar,
  AvatarFallback,
  AvatarImage,
} from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export type Section =
  | "Overview"
  | "Command Center"
  | "AI Executive"
  | "Live operations"
  | "Live Operations Map"
  | "Smart Alerts"
  | "Customer Intelligence"
  | "Booking Control Center"
  | "SLA Monitoring"
  | "Financial Control Center"
  | "Fraud & Risk Center"
  | "Quality Control Center"
  | "Automation Rules"
  | "Notification Center"
  | "Reports Center"
  | "Activity Timeline"
  | "System Health"
  | "Advanced Search"
  | "Jobs"
  | "Providers"
  | "Technician Performance"
  | "Customers"
  | "Trust & safety"
  | "Payments"
  | "Services & pricing"
  | "Content & banners"
  | "Support chats"
  | "Promotions"
  | "Analytics"
  | "Admin & roles"
  | "Account"
  | "Settings"
  | "System Reset";

const sectionPaths: Record<Section, string> = {
  Overview: "/dashboard",
  "Command Center": "/dashboard/command-center",
  "AI Executive": "/dashboard/ai",
  "Live operations": "/dashboard/live-operations",
  "Live Operations Map": "/dashboard/live-map",
  "Smart Alerts": "/dashboard/alerts",
  "Customer Intelligence": "/dashboard/customer-intelligence",
  "Booking Control Center": "/dashboard/booking-control",
  "SLA Monitoring": "/dashboard/sla",
  "Financial Control Center": "/dashboard/financial-control",
  "Fraud & Risk Center": "/dashboard/fraud-risk",
  "Quality Control Center": "/dashboard/quality-control",
  "Automation Rules": "/dashboard/automation-rules",
  "Notification Center": "/dashboard/notifications",
  "Reports Center": "/dashboard/reports",
  "Activity Timeline": "/dashboard/activity-timeline",
  "System Health": "/dashboard/system-health",
  "Advanced Search": "/dashboard/search",
  Jobs: "/dashboard/jobs",
  Providers: "/dashboard/providers",
  "Technician Performance": "/dashboard/technician-performance",
  Customers: "/dashboard/customers",
  "Trust & safety": "/dashboard/trust-safety",
  Payments: "/dashboard/payments",
  "Services & pricing": "/dashboard/services",
  "Content & banners": "/dashboard/content",
  "Support chats": "/dashboard/support",
  Promotions: "/dashboard/promotions",
  Analytics: "/dashboard/analytics",
  "Admin & roles": "/dashboard/users",
  Account: "/dashboard/account",
  Settings: "/dashboard/settings",
  "System Reset": "/dashboard/settings/system-reset",
};

const routeSections: Record<string, Section> = {
  "/dashboard": "Overview",
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
};

function sectionFromPath(pathname: string): Section {
  const normalized = pathname.replace(/\/+$/, "") || "/dashboard";
  return routeSections[normalized] ?? "Overview";
}

function pathForSection(section: Section) {
  return sectionPaths[section] ?? "/dashboard";
}

const enterpriseSections = new Set<Section>([
  "Command Center",
  "Live Operations Map",
  "Smart Alerts",
  "Customer Intelligence",
  "Booking Control Center",
  "SLA Monitoring",
  "Financial Control Center",
  "Fraud & Risk Center",
  "Quality Control Center",
  "Automation Rules",
  "Notification Center",
  "Reports Center",
  "Activity Timeline",
  "System Health",
  "Advanced Search",
]);

const navigation: {
  label: Section;
  icon: typeof House;
  badge?: string;
  group: string;
}[] = [
  { label: "Overview", icon: House, group: "Command" },
  { label: "Command Center", icon: Radio, group: "Command" },
  { label: "AI Executive", icon: Zap, badge: "AI", group: "Command" },
  { label: "Live operations", icon: Radio, group: "Command" },
  { label: "Live Operations Map", icon: MapPin, group: "Command" },
  { label: "Smart Alerts", icon: Bell, group: "Command" },
  { label: "Booking Control Center", icon: BriefcaseBusiness, group: "Operations" },
  { label: "SLA Monitoring", icon: Clock3, group: "Operations" },
  { label: "Financial Control Center", icon: CircleDollarSign, group: "Operations" },
  { label: "Fraud & Risk Center", icon: ShieldCheck, group: "Operations" },
  { label: "Quality Control Center", icon: Star, group: "Operations" },
  { label: "Automation Rules", icon: Zap, group: "System" },
  { label: "Notification Center", icon: Bell, group: "Operations" },
  { label: "Reports Center", icon: FileCheck2, group: "Growth" },
  { label: "Activity Timeline", icon: Activity, group: "System" },
  { label: "System Health", icon: Gauge, group: "System" },
  { label: "Advanced Search", icon: Search, group: "Command" },
  { label: "Jobs", icon: BriefcaseBusiness, group: "Marketplace" },
  { label: "Providers", icon: Wrench, group: "Marketplace" },
  { label: "Technician Performance", icon: Gauge, group: "Marketplace" },
  { label: "Customers", icon: Users, group: "Marketplace" },
  {
    label: "Trust & safety",
    icon: ShieldCheck,
    group: "Operations",
  },
  { label: "Payments", icon: WalletCards, group: "Operations" },
  { label: "Services & pricing", icon: SlidersHorizontal, group: "Operations" },
  { label: "Content & banners", icon: Megaphone, group: "Marketplace" },
  { label: "Support chats", icon: Headphones, group: "Operations" },
  { label: "Promotions", icon: Gift, group: "Growth" },
  { label: "Analytics", icon: BarChart3, group: "Growth" },
  { label: "Admin & roles", icon: UserCheck, group: "System" },
  { label: "Account", icon: UserCog, group: "System" },
  { label: "Settings", icon: SlidersHorizontal, group: "System" },
  { label: "System Reset", icon: AlertTriangle, group: "System" },
];

const sectionMeta: Record<Section, { title: string; subtitle: string }> = {
  Overview: {
    title: "Operations overview",
    subtitle: "Here’s how Task is moving across Cairo today.",
  },
  "Command Center": {
    title: "Enterprise Command Center",
    subtitle: "Live bookings, alerts, health, finance, risk, and marketplace signals.",
  },
  "AI Executive": {
    title: "AI Operations Executive",
    subtitle: "Firestore-backed intelligence, planning, memory, and controlled actions.",
  },
  "Live operations": {
    title: "Live Operations Center",
    subtitle: "Real-time dispatch, alerts, and provider coverage.",
  },
  "Live Operations Map": {
    title: "Live Operations Map",
    subtitle: "Technicians, customers, active jobs, and service coverage with operational filters.",
  },
  "Smart Alerts": {
    title: "Smart Alerts Center",
    subtitle: "Risk and operations alerts generated from live marketplace signals.",
  },
  "Customer Intelligence": {
    title: "Customer Intelligence",
    subtitle: "Bookings, value, complaints, risk, support history, and payment context.",
  },
  "Booking Control Center": {
    title: "Booking Control Center",
    subtitle: "Emergency, scheduled, and quotation lifecycle control with SLA tracking.",
  },
  "SLA Monitoring": {
    title: "SLA Monitoring",
    subtitle: "Response, arrival, completion, and complaint-resolution SLA health.",
  },
  "Financial Control Center": {
    title: "Financial Control Center",
    subtitle: "Revenue, commissions, payouts, refunds, failed payments, and transaction logs.",
  },
  "Fraud & Risk Center": {
    title: "Fraud & Risk Center",
    subtitle: "Suspicious customers, technicians, refunds, cancellations, and payment abuse.",
  },
  "Quality Control Center": {
    title: "Quality Control Center",
    subtitle: "Low-rated jobs, technician reviews, complaints, refund reasons, and approval cases.",
  },
  "Automation Rules": {
    title: "Automation Rules",
    subtitle: "Super Admin rule templates for technician, booking, payment, and complaint triggers.",
  },
  "Notification Center": {
    title: "Notification Center",
    subtitle: "Admin notifications across bookings, complaints, payments, technicians, system, and integrations.",
  },
  "Reports Center": {
    title: "Reports Center",
    subtitle: "Export daily operations, technician, revenue, complaint, customer, payout, and SLA reports.",
  },
  "Activity Timeline": {
    title: "Audit & Activity Timeline",
    subtitle: "Every important entity timeline in one searchable operations ledger.",
  },
  "System Health": {
    title: "System Health",
    subtitle: "Firebase, API Center, email, payments, AI, storage, notifications, and delivery health.",
  },
  "Advanced Search": {
    title: "Advanced Search",
    subtitle: "Search bookings, customers, technicians, payments, complaints, reviews, roles, invitations, and audit logs.",
  },
  Jobs: {
    title: "Jobs Management",
    subtitle: "Track every booking from request to completion.",
  },
  Providers: {
    title: "Provider Management",
    subtitle: "Performance, verification, and marketplace quality.",
  },
  "Technician Performance": {
    title: "Technician Performance & Monitoring",
    subtitle: "Score technicians, detect risk, review quality, and take account actions.",
  },
  Customers: {
    title: "Customer Management",
    subtitle: "Profiles, history, refunds, and account health.",
  },
  "Trust & safety": {
    title: "Trust & Safety Center",
    subtitle: "Resolve incidents with speed, context, and care.",
  },
  Payments: {
    title: "Payments & Wallet",
    subtitle: "Transactions, settlements, and cash reconciliation.",
  },
  "Services & pricing": {
    title: "Services & Pricing",
    subtitle: "Control availability, fees, and marketplace economics.",
  },
  "Content & banners": {
    title: "Categories & Banners",
    subtitle: "Manage the catalog structure and customer-app merchandising.",
  },
  "Support chats": {
    title: "Support Conversations",
    subtitle: "Handle customer and provider conversations in real time.",
  },
  Promotions: {
    title: "Promotions & Marketing",
    subtitle: "Campaigns, promo codes, and customer engagement.",
  },
  Analytics: {
    title: "Analytics",
    subtitle: "Understand demand, economics, and marketplace health.",
  },
  "Admin & roles": {
    title: "Admin Users & Roles",
    subtitle: "People, permissions, and the audit trail.",
  },
  Account: {
    title: "Account",
    subtitle: "Profile, authentication, sessions, and connected devices.",
  },
  Settings: {
    title: "Settings Center",
    subtitle:
      "Company, branding, appearance, notifications, security, and integrations.",
  },
  "System Reset": {
    title: "System Reset",
    subtitle: "Super Admin-only production reset controls.",
  },
};

function DashboardSkeleton() {
  return (
    <div className="min-h-screen bg-[#08080a] p-6 lg:pl-[284px]">
      <div className="mb-8 flex items-center gap-3">
        <BrandLogo className="h-10 w-10" />
        <div className="h-10 w-52 animate-pulse rounded-xl bg-white/[.05]" />
      </div>
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <div
            key={i}
            className="h-36 animate-pulse rounded-2xl border border-white/[.06] bg-white/[.025]"
          />
        ))}
      </div>
      <div className="mt-5 h-80 animate-pulse rounded-2xl border border-white/[.06] bg-white/[.025]" />
    </div>
  );
}

function UnauthorizedSection({ section }: { section: Section }) {
  return (
    <div className="rounded-3xl border border-red-500/20 bg-red-500/5 p-8">
      <div className="flex max-w-2xl items-start gap-4">
        <span className="grid h-12 w-12 place-items-center rounded-2xl bg-red-500/10">
          <ShieldCheck className="h-5 w-5 text-red-300" />
        </span>
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-red-300">
            403 Unauthorized
          </p>
          <h2 className="mt-2 text-2xl font-semibold">
            You do not have access to {section}.
          </h2>
          <p className="mt-2 text-sm text-zinc-400">
            This route is protected by role permissions. Ask a Super Admin to update your role if you need access.
          </p>
        </div>
      </div>
    </div>
  );
}

function activeJobs(db: DatabaseState) {
  return db.jobs.filter(
    (job) => !["Completed", "Cancelled", "Refunded"].includes(job.status),
  );
}

function operationalAlertCount(db: DatabaseState) {
  const active = activeJobs(db);
  return (
    active.filter((job) => job.status === "Delayed").length +
    active.filter((job) => !job.providerId).length +
    db.complaints.filter((item) => item.status !== "Closed").length +
    db.instapayReviews.filter((item) => item.status === "Pending").length +
    db.payouts.filter((item) => item.status === "Pending").length
  );
}

function sidebarBadge(
  label: Section,
  db: DatabaseState,
  staticBadge?: string,
) {
  if (staticBadge) return staticBadge;
  const active = activeJobs(db);
  const counts: Partial<Record<Section, number>> = {
    "Live operations": active.length,
    Jobs: active.length,
    Providers: db.providers.filter(
      (provider) => !provider.verified || provider.status === "Review",
    ).length,
    "Trust & safety": db.complaints.filter((item) => item.status !== "Closed")
      .length,
    Payments:
      db.instapayReviews.filter((item) => item.status === "Pending").length +
      db.payouts.filter((item) => item.status === "Pending").length,
    "Support chats": db.conversations.filter((item) => item.status !== "Closed")
      .length,
    "Admin & roles": db.invitations.filter((item) => item.status === "Pending")
      .length,
  };
  const count = counts[label] ?? 0;
  return count > 0 ? String(count) : "";
}

export function AdminDashboard({ initialSection = "Overview" }: { initialSection?: Section }) {
  const { db, loading, mutationPending } = useAdminData();
  const { user } = useAuth();
  const { can } = usePermissions();
  const { settings } = useDashboardSettings();
  const router = useRouter();
  const pathname = usePathname();
  const [section, setSection] = useState<Section>(initialSection);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [commandOpen, setCommandOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [detailJob, setDetailJob] = useState<Job | null>(null);
  const [detailProviderId, setDetailProviderId] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setCommandOpen(true);
      }
      if (event.key === "Escape") {
        setCommandOpen(false);
        setNotificationsOpen(false);
        setDetailJob(null);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  useEffect(() => {
    if (toast) {
      const timer = setTimeout(() => setToast(null), 2600);
      return () => clearTimeout(timer);
    }
  }, [toast]);
  useEffect(()=>{const success=(event:Event)=>{const action=(event as CustomEvent<{action:string}>).detail.action;setToast(`${action.replace(/([A-Z])/g," $1")} completed`)};const failure=(event:Event)=>setToast(`Error: ${(event as CustomEvent<{message:string}>).detail.message}`);window.addEventListener("task:operation-success",success);window.addEventListener("task:operation-error",failure);return()=>{window.removeEventListener("task:operation-success",success);window.removeEventListener("task:operation-error",failure)}},[]);
  useEffect(() => {
    setSection(sectionFromPath(pathname));
  }, [pathname]);
  useEffect(() => {
    if (!user?.isDemoUser) return;
    const { db: firestore } = getFirebaseClient();
    const ref = doc(collection(firestore, "auditLogs"));
    void setDoc(ref, {
      id: ref.id,
      actorId: user.id,
      actorName: user.name,
      action: "demo.page_viewed",
      entityType: "dashboard_page",
      entityId: section,
      detail: `Demo user viewed ${section}`,
      environment: "demo",
      isDemoData: true,
      ipAddress: "Firebase Auth",
      device: typeof navigator !== "undefined" ? navigator.userAgent : "Task Admin",
      createdAt: new Date().toISOString(),
    }).catch(() => undefined);
  }, [section, user]);

  const navigate = (next: Section) => {
    setSection(next);
    setSidebarOpen(false);
    setDetailJob(null);
    const nextPath = pathForSection(next);
    if (nextPath !== pathname) router.push(nextPath);
  };

  if (loading) return <DashboardSkeleton />;
  const sectionAllowed = (sectionPermissions[section] ?? []).some((permission) =>
    can(permission),
  );
  return (
    <div className="relative min-h-screen overflow-x-hidden bg-transparent text-zinc-100">
      <div className="pointer-events-none fixed inset-x-0 top-0 h-[420px] bg-[radial-gradient(ellipse_at_top,rgba(99,102,241,.08),transparent_68%)]" />
      <Sidebar
        section={section}
        navigate={navigate}
        open={sidebarOpen}
        close={() => setSidebarOpen(false)}
      />
      <div
        className={cn(
          "relative transition-[padding]",
          settings.appearance.sidebarCollapsed
            ? "lg:pl-[80px]"
            : "lg:pl-[260px]",
        )}
      >
        <Topbar
          openSidebar={() => setSidebarOpen(true)}
          openCommand={() => setCommandOpen(true)}
          openNotifications={() => setNotificationsOpen(!notificationsOpen)}
          notificationsOpen={notificationsOpen}
          navigate={navigate}
        />
        <main className="min-h-[calc(100vh-64px)] px-4 pb-10 pt-5 sm:px-6 lg:px-8 lg:pt-7">
          {user?.isDemoUser && (
            <div className="mb-5 rounded-2xl border border-amber-400/25 bg-amber-400/10 px-4 py-3 text-xs text-amber-100">
              <span className="font-semibold uppercase tracking-wide text-amber-300">Demo Mode</span>
              <span className="ml-2 text-amber-100/90">
                You are using a demo workspace. Changes here do not affect production data.
              </span>
            </div>
          )}
          <PageHeader section={section} />
          <div className="mt-6">
            {!sectionAllowed && <UnauthorizedSection section={section} />}
            {sectionAllowed && section === "Overview" && (
              <Overview navigate={navigate} openJob={setDetailJob} />
            )}
            {sectionAllowed && enterpriseSections.has(section) && (
              <EnterpriseOperationsPage
                page={section as Parameters<typeof EnterpriseOperationsPage>[0]["page"]}
                openJob={setDetailJob}
                notify={setToast}
                navigate={(next) => navigate(next as Section)}
              />
            )}
            {sectionAllowed && section === "AI Executive" && (
              <AiExecutivePage
                page={section}
                navigate={navigate}
                openJob={(jobId) => {
                  const job = db.jobs.find((item) => item.id === jobId);
                  if (job) setDetailJob(job);
                }}
                openProvider={(providerId) => setDetailProviderId(providerId)}
                notify={setToast}
              />
            )}
            {sectionAllowed && section === "Live operations" && (
              <LiveOperations openJob={setDetailJob} notify={setToast} />
            )}
            {sectionAllowed && section === "Jobs" && (
              <JobsPage openJob={setDetailJob} notify={setToast} />
            )}
            {sectionAllowed && section === "Providers" && <ProviderManagement notify={setToast} openProviderId={detailProviderId} onProviderOpened={() => setDetailProviderId(null)} />}
            {sectionAllowed && section === "Technician Performance" && <TechnicianPerformanceCenter notify={setToast} />}
            {sectionAllowed && section === "Customers" && <CustomersPage notify={setToast} />}
            {sectionAllowed && section === "Trust & safety" && <TrustPage notify={setToast} />}
            {sectionAllowed && section === "Payments" && <PaymentsPage notify={setToast} openJob={setDetailJob} />}
            {sectionAllowed && section === "Services & pricing" && (
              <ServicesPage notify={setToast} />
            )}
            {sectionAllowed && section === "Content & banners" && <ContentManagementPage notify={setToast} />}
            {sectionAllowed && section === "Support chats" && <SupportConversationsPage notify={setToast} />}
            {sectionAllowed && section === "Promotions" && <PromotionsPage notify={setToast} />}
            {sectionAllowed && section === "Analytics" && <AnalyticsPage />}
            {sectionAllowed && section === "Admin & roles" && <AdminPage notify={setToast} />}
            {sectionAllowed && section === "Account" && <AccountPage notify={setToast} />}
            {sectionAllowed && section === "Settings" && <SettingsPage notify={setToast} />}
            {sectionAllowed && section === "System Reset" && <SystemResetPage notify={setToast} />}
          </div>
        </main>
      </div>
      {commandOpen && (
        <CommandMenu
          close={() => setCommandOpen(false)}
          navigate={navigate}
          openJob={setDetailJob}
          openProvider={setDetailProviderId}
        />
      )}
      {detailJob && (
        <RequestControlCenter
          job={detailJob}
          close={() => setDetailJob(null)}
          notify={setToast}
        />
      )}
      {toast && (
        <div className="fixed bottom-5 right-5 z-[80] flex items-center gap-2 rounded-lg border border-emerald-500/20 bg-[#17191a] px-4 py-3 text-sm shadow-2xl">
          <CheckCircle2 className="h-4 w-4 text-emerald-400" />
          {toast}
        </div>
      )}
      {mutationPending&&<div className="fixed bottom-5 left-5 z-[90] flex items-center gap-2 rounded-xl border border-indigo-500/20 bg-[#17171b] px-3 py-2 text-[10px] text-indigo-200 shadow-2xl"><Loader2 className="h-3.5 w-3.5 animate-spin"/>Saving to production database…</div>}
    </div>
  );
}

function Sidebar({
  section,
  navigate,
  open,
  close,
}: {
  section: Section;
  navigate: (s: Section) => void;
  open: boolean;
  close: () => void;
}) {
  const { t } = usePreferences();
  const { user } = useAuth();
  const { can } = usePermissions();
  const { db } = useAdminData();
  const { settings, profile } = useDashboardSettings();
  const collapsed = settings.appearance.sidebarCollapsed;
  const allowed = (label: Section) => {
    return (sectionPermissions[label] ?? []).some((permission) => can(permission));
  };
  const groups = ["Command", "Marketplace", "Operations", "Growth", "System"];
  return (
    <>
      {open && (
        <button
          aria-label="Close navigation"
          className="fixed inset-0 z-40 bg-black/70 lg:hidden"
          onClick={close}
        />
      )}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex flex-col border-r border-white/[.07] bg-[#0b0b0d]/95 shadow-[24px_0_80px_rgba(0,0,0,.16)] backdrop-blur-xl transition-all lg:translate-x-0",
          collapsed ? "w-[80px]" : "w-[260px]",
          open ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex h-16 items-center justify-between border-b border-white/[.06] px-5">
          <button
            onClick={() => navigate("Overview")}
            className="flex items-center gap-2.5"
          >
            <BrandLogo location="sidebar" className="h-9 w-9" />
            <span
              className={cn(
                "text-[17px] font-semibold tracking-tight",
                collapsed && "hidden",
              )}
            >
              {settings.general.companyName}
            </span>
            <Badge
              className={cn(
                "px-1.5 py-0 text-[8px] font-bold uppercase tracking-wider",
                collapsed && "hidden",
              )}
            >
              Admin
            </Badge>
          </button>
          <button className="text-zinc-500 lg:hidden" onClick={close}>
            <X className="h-5 w-5" />
          </button>
        </div>
        <nav className="flex-1 overflow-y-auto px-3 py-4">
          {groups.map((group) => {
            const visibleItems = navigation
              .filter((n) => n.group === group)
              .filter((n) => allowed(n.label));
            if (!visibleItems.length) return null;
            return (
            <div key={group} className="mb-5">
              <div
                className={cn(
                  "mb-1.5 px-2 text-[10px] font-semibold uppercase tracking-[.15em] text-zinc-600",
                  collapsed && "sr-only",
                )}
              >
                {group}
              </div>
              {visibleItems.map((item) => {
                  const badge = sidebarBadge(item.label, db, item.badge);
                  return (
                    <button
                      key={item.label}
                      onClick={() => navigate(item.label)}
                      className={cn(
                        "group mb-0.5 flex w-full items-center gap-3 rounded-lg px-2.5 py-2 text-left text-[13px] transition",
                        section === item.label
                          ? "bg-white/[.08] font-medium text-white"
                          : "text-zinc-500 hover:bg-white/[.04] hover:text-zinc-200",
                      )}
                    >
                      <item.icon
                        className={cn(
                          "h-[17px] w-[17px]",
                          section === item.label
                            ? "text-indigo-400"
                            : "text-zinc-600 group-hover:text-zinc-400",
                        )}
                      />
                      <span className={cn("flex-1", collapsed && "sr-only")}>
                        {t(item.label)}
                      </span>
                      {badge && !collapsed && (
                        <span
                          className={cn(
                            "rounded-full px-1.5 py-0.5 text-[10px]",
                            item.label === "Trust & safety" || item.label === "Payments"
                              ? "bg-red-500/10 text-red-400"
                              : "bg-white/[.06] text-zinc-500",
                          )}
                        >
                          {badge}
                        </span>
                      )}
                    </button>
                  );
                })}
            </div>
            );
          })}
        </nav>
        <div className="border-t border-white/[.06] p-3">
          <div className="flex w-full items-center gap-3 rounded-lg p-2">
            <Avatar
              src={profile.avatar}
              initials={
                profile.fullName
                  .split(" ")
                  .map((x) => x[0])
                  .join("") || "AD"
              }
              size="md"
            />
            <div
              className={cn("min-w-0 flex-1 text-left", collapsed && "hidden")}
            >
              <div className="truncate text-xs font-medium">
                {profile.fullName}
              </div>
              <div className="truncate text-[10px] text-zinc-600">
                {user?.role}
              </div>
            </div>
            {!collapsed && <MoreHorizontal className="h-4 w-4 text-zinc-600" />}
          </div>
        </div>
      </aside>
    </>
  );
}

function Topbar({
  openSidebar,
  openCommand,
  openNotifications,
  notificationsOpen,
  navigate,
}: {
  openSidebar: () => void;
  openCommand: () => void;
  openNotifications: () => void;
  notificationsOpen: boolean;
  navigate: (section: Section) => void;
}) {
  const { theme, setTheme, locale, setLocale, t } = usePreferences();
  const { logout } = useAuth();
  const { db } = useAdminData();
  const { profile } = useDashboardSettings();
  const alertCount = operationalAlertCount(db);
  const notificationCount = db.notifications.length;
  return (
    <header className="sticky top-0 z-30 flex h-16 items-center border-b border-white/[.07] bg-[#09090b]/90 px-4 backdrop-blur-xl sm:px-6 lg:px-8">
      <Button
        aria-label="Open navigation"
        variant="ghost"
        size="icon"
        className="mr-2 lg:hidden"
        onClick={openSidebar}
      >
        <Menu />
      </Button>
      <BrandLogo
        location="dashboard"
        className="mr-3 hidden h-8 w-8 sm:block"
      />
      <button
        onClick={openCommand}
        className="focus-ring flex h-9 w-full max-w-[420px] items-center gap-2 rounded-lg border border-white/[.08] bg-white/[.035] px-3 text-left text-xs text-zinc-600 transition hover:border-white/[.14] hover:bg-white/[.05]"
      >
        <Search className="h-4 w-4" />
        <span className="flex-1">
          {t("Search jobs, providers, customers...")}
        </span>
        <span className="hidden items-center gap-1 rounded border border-white/[.08] bg-black/20 px-1.5 py-0.5 text-[10px] sm:flex">
          <Command className="h-2.5 w-2.5" />K
        </span>
      </button>
      <div className="ml-auto flex items-center gap-1.5 pl-3">
        {/* Phase D.1: Demo Data / Production Read-only / Production Write
            Disabled badges. Replaces the old demo-only "Demo Mode" pill. */}
        <div className="hidden sm:flex">
          <EnvironmentBadges />
        </div>
        <div className="hidden items-center gap-2 rounded-md px-2 py-1 text-xs text-zinc-500 md:flex">
          <span
            className={cn(
              "relative h-2 w-2 rounded-full",
              alertCount
                ? "bg-amber-400 text-amber-400"
                : "bg-emerald-400 text-emerald-400",
              alertCount === 0 && "pulse-ring",
            )}
          />
          {alertCount ? `${alertCount} ${t("open alerts")}` : t("No open operational alerts")}
        </div>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button aria-label="Theme" variant="ghost" size="icon">
              {theme === "light" ? (
                <Sun />
              ) : theme === "system" ? (
                <Monitor />
              ) : (
                <Moon />
              )}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>{t("Theme")}</DropdownMenuLabel>
            <DropdownMenuItem onSelect={() => setTheme("dark")}>
              <Moon />
              {t("Dark")}
              {theme === "dark" && <Check className="ml-auto" />}
            </DropdownMenuItem>
            <DropdownMenuItem onSelect={() => setTheme("light")}>
              <Sun />
              {t("Light")}
              {theme === "light" && <Check className="ml-auto" />}
            </DropdownMenuItem>
            <DropdownMenuItem onSelect={() => setTheme("system")}>
              <Monitor />
              {t("System")}
              {theme === "system" && <Check className="ml-auto" />}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button aria-label="Language" variant="ghost" size="icon">
              <Languages />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>{t("Language")}</DropdownMenuLabel>
            <DropdownMenuItem onSelect={() => setLocale("en")}>
              English{locale === "en" && <Check className="ml-auto" />}
            </DropdownMenuItem>
            <DropdownMenuItem onSelect={() => setLocale("ar")}>
              العربية{locale === "ar" && <Check className="ml-auto" />}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        <div className="relative">
          <Button
            aria-label="Notifications"
            variant="ghost"
            size="icon"
            onClick={openNotifications}
            className="relative"
          >
            <Bell />
            {notificationCount > 0 && (
              <span className="absolute right-2 top-2 h-1.5 w-1.5 rounded-full bg-indigo-400 ring-2 ring-[#09090b]" />
            )}
          </Button>
          {notificationsOpen && <Notifications />}
        </div>
        <div className="mx-1 h-5 w-px bg-white/[.08]" />
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button
              aria-label="Open user menu"
              className="rounded-full outline-none ring-offset-black transition hover:ring-2 hover:ring-indigo-500/30"
            >
              <Avatar
                src={profile.avatar}
                initials={
                  profile.fullName
                    .split(" ")
                    .map((x) => x[0])
                    .join("") || "AD"
                }
              />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-60">
            <DropdownMenuLabel>
              <span className="block normal-case text-xs font-medium tracking-normal text-zinc-200">
                {profile.fullName}
              </span>
              <span className="mt-1 block normal-case font-normal tracking-normal text-zinc-600">
                {profile.email}
              </span>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={() => navigate("Account")}>
              <UserCog />
              Profile settings
            </DropdownMenuItem>
            <DropdownMenuItem onSelect={() => navigate("Settings")}>
              <ShieldCheck />
              Security & access
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              className="text-red-400 focus:text-red-300"
              onSelect={() => {
                void logout();
              }}
            >
              <LogOut />
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}

function Notifications() {
  const{db}=useAdminData();const rows=db.notifications.slice(0,5);
  return (
    <div className="absolute right-0 top-11 w-[340px] rounded-xl border border-white/[.1] bg-[#141416] p-2 shadow-2xl">
      <div className="flex items-center justify-between px-2 py-2">
        <span className="text-sm font-semibold">Notifications</span>
        <span className="text-[11px] text-zinc-600">{rows.length} recent</span>
      </div>
      {rows.map((item) => (
        <div
          key={item.id}
          className="flex w-full gap-3 rounded-lg p-2.5 text-left"
        >
          <span
            className={cn(
              "grid h-8 w-8 shrink-0 place-items-center rounded-lg",
              "bg-indigo-500/10 text-indigo-400",
            )}
          >
            <Bell className="h-4 w-4" />
          </span>
          <span>
            <span className="block text-xs font-medium">{item.title}</span>
            <span className="mt-0.5 block text-[11px] leading-4 text-zinc-500">
              {item.body}
            </span>
            <span className="text-[10px] text-zinc-700">{new Date(item.createdAt).toLocaleDateString()}</span>
          </span>
        </div>
      ))}
      {!rows.length&&<div className="p-5 text-center text-xs text-zinc-600">No notifications yet</div>}
    </div>
  );
}

function PageHeader({ section }: { section: Section }) {
  const { db } = useAdminData();
  const { settings } = useDashboardSettings();
  const { t } = usePreferences();
  const meta = sectionMeta[section];
  const exportData = () => {
    const resources: Partial<Record<Section, unknown[]>> = {
      Jobs: db.jobs,
      Providers: db.providers,
      Customers: db.customers,
      "Trust & safety": db.complaints,
      Payments: db.transactions,
      "Services & pricing": db.services,
      Promotions: db.promos,
      "Admin & roles": db.auditLogs,
    };
    const blob = new Blob(
      [JSON.stringify(resources[section] ?? db.jobs, null, 2)],
      { type: "application/json" },
    );
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `task-${section.toLowerCase().replaceAll(" ", "-")}.json`;
    anchor.click();
    URL.revokeObjectURL(url);
  };
  return (
    <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
      <div>
        <div className="mb-1 flex items-center gap-2 text-[11px] text-zinc-600">
          <span>{settings.general.companyName}</span>
          <ChevronRight className="h-3 w-3" />
          <span>{t(section)}</span>
        </div>
        <h1 className="text-[24px] font-semibold tracking-[-.03em] text-zinc-50 sm:text-[28px]">
          {t(meta.title)}
        </h1>
        <p className="mt-1 text-sm text-zinc-500">{t(meta.subtitle)}</p>
      </div>
      <div className="flex items-center gap-2">
        <span className="btn-secondary cursor-default">
          <CalendarDays className="h-3.5 w-3.5" />
          {t("Live Firestore")}
        </span>
        <button
          onClick={exportData}
          aria-label="Export current view"
          className="btn-secondary"
        >
          <Download className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">{t("Export")}</span>
        </button>
      </div>
    </div>
  );
}

function Overview({
  navigate,
  openJob,
}: {
  navigate: (s: Section) => void;
  openJob: (j: Job) => void;
}) {
  const { db } = useAdminData();
  const jobs = db.jobs;
  const revenueData=revenueSeries(db.jobs);
  const paidJobs=db.jobs.filter((job)=>job.payment?.status==="Paid");const commission=paidJobs.reduce((sum,job)=>sum+(job.payment?.platformCommission??0),0);const rated=db.providers.filter((provider)=>provider.rating>0);const avgRating=rated.length?rated.reduce((sum,provider)=>sum+provider.rating,0)/rated.length:0;const responseSamples=db.jobs.flatMap((job)=>job.offers?.map((offer)=>(new Date(offer.createdAt).getTime()-new Date(job.createdAt).getTime())/60000)??[]).filter((value)=>value>=0);const avgResponse=responseSamples.length?responseSamples.reduce((sum,value)=>sum+value,0)/responseSamples.length:0;
  const kpis = [
    {
      label: "Total bookings",
      value: db.jobs.length.toLocaleString(),
      change: `${db.jobs.filter((job)=>new Date(job.createdAt).toDateString()===new Date().toDateString()).length} today`,
      icon: BriefcaseBusiness,
      positive: true,
    },
    {
      label: "Active jobs",
      value: String(
        db.jobs.filter(
          (x) => !["Completed", "Cancelled", "Refunded"].includes(x.status),
        ).length,
      ),
      change: `${db.jobs.filter((item)=>item.status==="Delayed").length} delayed`,
      icon: Activity,
      positive: true,
    },
    {
      label: "Revenue",
      value: `EGP ${paidJobs.reduce((sum,job)=>sum+(job.payment?.amount??0),0).toLocaleString()}`,
      change: `${paidJobs.length} paid jobs`,
      icon: Banknote,
      positive: true,
    },
    {
      label: "Commission",
      value: `EGP ${commission.toLocaleString()}`,
      change: "from paid jobs",
      icon: BadgeDollarSign,
      positive: true,
    },
    {
      label: "Pending complaints",
      value: String(db.complaints.filter((x) => x.status !== "Closed").length),
      change: `${db.complaints.filter((item)=>item.status!=="Closed"&&item.severity==="Critical").length} critical`,
      icon: MessageSquareWarning,
      positive: false,
    },
    {
      label: "Active providers",
      value: String(db.providers.filter((x) => x.status === "Active").length),
      change: `${db.providers.filter((item)=>item.available).length} available`,
      icon: UserCheck,
      positive: true,
    },
    {
      label: "Avg. response",
      value: responseSamples.length?`${avgResponse.toFixed(1)}m`:"No data",
      change: "request to offer",
      icon: Clock3,
      positive: true,
    },
    {
      label: "Avg. rating",
      value: rated.length?avgRating.toFixed(2):"No data",
      change: `${rated.length} rated providers`,
      icon: Star,
      positive: true,
    },
  ];
  return (
    <div className="space-y-5">
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4 2xl:grid-cols-8">
        {kpis.map((kpi, i) => (
          <KpiCard key={kpi.label} {...kpi} featured={i < 4} />
        ))}
      </div>
      <div className="grid gap-5 xl:grid-cols-[minmax(0,1.65fr)_minmax(320px,.8fr)]">
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Marketplace performance"
            subtitle="Revenue and bookings · last 7 days"
            action={
              <button
                onClick={() => navigate("Analytics")}
                className="text-[11px] text-indigo-400"
              >
                View analytics
              </button>
            }
          />
          <div className="h-[280px] p-4 pt-1">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData}>
                <defs>
                  <linearGradient id="revenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6976ff" stopOpacity={0.28} />
                    <stop offset="95%" stopColor="#6976ff" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke="hsl(var(--border))"
                  vertical={false}
                />
                <XAxis
                  dataKey="day"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: "#71717a", fontSize: 10 }}
                  dy={10}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: "#71717a", fontSize: 10 }}
                  tickFormatter={(v) => `${v / 1000}k`}
                  width={36}
                />
                <Tooltip content={<ChartTooltip />} />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke="#6976ff"
                  strokeWidth={2}
                  fill="url(#revenue)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        <LivePulse navigate={navigate} />
      </div>
      <div className="grid gap-5 xl:grid-cols-[minmax(0,1.45fr)_minmax(300px,.7fr)]">
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Live jobs"
            subtitle={`${activeJobs(db).length} active jobs currently active`}
            action={
              <button
                onClick={() => navigate("Jobs")}
                className="flex items-center gap-1 text-[11px] text-indigo-400"
              >
                View all <ArrowRight className="h-3 w-3" />
              </button>
            }
          />
          <JobsTable items={jobs.slice(0, 5)} openJob={openJob} />
        </div>
        <AlertsPanel navigate={navigate} />
      </div>
    </div>
  );
}

function KpiCard({
  label,
  value,
  change,
  icon: Icon,
  positive,
  featured,
}: {
  label: string;
  value: string;
  change: string;
  icon: LucideIcon;
  positive: boolean;
  featured: boolean;
}) {
  return (
    <Card
      className={cn(
        "group relative min-h-[148px] overflow-hidden p-4 transition duration-300 hover:-translate-y-1 hover:border-white/[.14] hover:shadow-[0_24px_80px_rgba(0,0,0,.28)]",
        featured && "bg-gradient-to-br from-white/[.065] to-white/[.025]",
      )}
    >
      <div className="pointer-events-none absolute -right-8 -top-10 h-24 w-24 rounded-full bg-indigo-500/[.07] blur-2xl transition group-hover:bg-indigo-500/[.12]" />
      <div className="relative flex items-start justify-between">
        <span
          className={cn(
            "grid h-9 w-9 place-items-center rounded-xl border border-white/[.06] bg-white/[.05] text-zinc-400 shadow-inner",
            featured && "bg-indigo-500/10 text-indigo-300",
          )}
        >
          <Icon className="h-4 w-4" />
        </span>
        {featured && (
          <span className="mt-1 h-1.5 w-1.5 rounded-full bg-indigo-400 shadow-[0_0_10px_#818cf8]" />
        )}
      </div>
      <div className="relative mt-5 truncate text-[21px] font-semibold tracking-[-.04em]">
        {value}
      </div>
      <div className="relative mt-0.5 truncate text-[10px] text-zinc-500">
        {label}
      </div>
      <div
        className={cn(
          "relative mt-2 flex items-center gap-1 text-[9px]",
          positive ? "text-emerald-400" : "text-red-400",
        )}
      >
        {positive ? (
          <ArrowUpRight className="h-3 w-3" />
        ) : (
          <ArrowDownRight className="h-3 w-3" />
        )}
        {change}
      </div>
    </Card>
  );
}

function LivePulse({ navigate }: { navigate: (s: Section) => void }) {
  const{db}=useAdminData();const active=db.jobs.filter((item)=>!["Completed","Cancelled","Refunded"].includes(item.status));const rows=[["In progress",active.filter((item)=>item.status==="In progress").length,"bg-indigo-400"],["En route",active.filter((item)=>item.status==="En route").length,"bg-cyan-400"],["Delayed",active.filter((item)=>item.status==="Delayed").length,"bg-amber-400"],["Unassigned",active.filter((item)=>!item.providerId).length,"bg-red-400"]] as const;const attention=rows[2][1]+rows[3][1];
  return (
    <div className="panel overflow-hidden">
      <PanelTitle
        title="Live operations"
        subtitle="Realtime Firestore feed"
        action={
          <span className="flex items-center gap-1.5 text-[10px] text-emerald-400">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
            LIVE
          </span>
        }
      />
      <div className="grid grid-cols-2 border-b border-white/[.06]">
        <Metric label="On schedule" value={String(Math.max(0,active.length-attention))} color="text-emerald-400" />
        <Metric
          label="Needs attention"
          value={String(attention)}
          color="text-amber-400"
          border
        />
      </div>
      <div className="space-y-3 p-4">
        {rows.map(([label, count, color]) => {const value=String(count);const width=`${active.length?Math.round(count/active.length*100):0}%`;return(
          <div key={label}>
            <div className="mb-1.5 flex justify-between text-[11px]">
              <span className="text-zinc-500">{label}</span>
              <span className="font-medium">{value}</span>
            </div>
            <div className="h-1.5 overflow-hidden rounded-full bg-white/[.05]">
              <div
                className={cn("h-full rounded-full", color)}
                style={{ width }}
              />
            </div>
          </div>
        )})}
        <button
          onClick={() => navigate("Live operations")}
          className="mt-2 flex w-full items-center justify-center gap-2 rounded-lg border border-white/[.08] py-2 text-[11px] font-medium text-zinc-300 hover:bg-white/[.04]"
        >
          <Radio className="h-3.5 w-3.5 text-indigo-400" />
          Open Operations Center
        </button>
      </div>
    </div>
  );
}

function AlertsPanel({ navigate }: { navigate: (s: Section) => void }) {
  const { db } = useAdminData();
  const active = activeJobs(db);
  const alerts: Array<{
    title: string;
    sub: string;
    tone: "red" | "amber" | "indigo";
    section: Section;
  }> = [];
  active
    .filter((job) => job.status === "Delayed")
    .slice(0, 3)
    .forEach((job) =>
      alerts.push({
        title: `Job delayed · ${job.id}`,
        sub: `${job.service} · ${job.area}`,
        tone: "amber",
        section: "Live operations",
      }),
    );
  const unassigned = active.filter((job) => !job.providerId);
  if (unassigned.length)
    alerts.push({
      title: `${unassigned.length} unassigned active job${unassigned.length === 1 ? "" : "s"}`,
      sub: "Manual dispatch may be required",
      tone: "amber",
      section: "Live operations",
    });
  const complaints = db.complaints.filter((item) => item.status !== "Closed");
  if (complaints.length)
    alerts.push({
      title: `${complaints.length} open complaint${complaints.length === 1 ? "" : "s"}`,
      sub:
        complaints.filter((item) => item.severity === "Critical").length > 0
          ? "Critical cases need immediate review"
          : "Trust & Safety queue",
      tone: complaints.some((item) => item.severity === "Critical") ? "red" : "amber",
      section: "Trust & safety",
    });
  const documentAlerts = db.providers
    .flatMap((provider) =>
      provider.documents
        .map((document) => expiryMessage(document))
        .filter(Boolean)
        .map((message) => `${provider.providerId}: ${message}`),
    )
    .slice(0, 3);
  if (documentAlerts.length)
    alerts.push({
      title: `${documentAlerts.length} provider document alert${documentAlerts.length === 1 ? "" : "s"}`,
      sub: documentAlerts[0] ?? "Verification documents need review",
      tone: "indigo",
      section: "Providers",
    });
  const financeCount =
    db.instapayReviews.filter((item) => item.status === "Pending").length +
    db.payouts.filter((item) => item.status === "Pending").length;
  if (financeCount)
    alerts.push({
      title: `${financeCount} finance item${financeCount === 1 ? "" : "s"} pending`,
      sub: "Instapay reviews or payout approvals",
      tone: "red",
      section: "Payments",
    });
  return (
    <div className="panel overflow-hidden">
      <PanelTitle
        title="Needs attention"
        subtitle={`${alerts.length} real-time alert${alerts.length === 1 ? "" : "s"}`}
        action={
          <button onClick={() => navigate("Trust & safety")}>
            <ChevronRight className="h-4 w-4 text-zinc-600" />
          </button>
        }
      />
      <div className="divide-y divide-white/[.06]">
        {alerts.map(({ title, sub, tone, section }) => (
          <button
            key={title}
            onClick={() => navigate(section)}
            className="flex w-full items-start gap-3 p-3.5 text-left hover:bg-white/[.025]"
          >
            <span
              className={cn(
                "mt-1 h-2 w-2 shrink-0 rounded-full",
                tone === "red"
                  ? "bg-red-400"
                  : tone === "amber"
                    ? "bg-amber-400"
                    : "bg-indigo-400",
              )}
            />
            <span className="min-w-0 flex-1">
              <span className="block truncate text-[11px] font-medium">
                {title}
              </span>
              <span className="mt-0.5 block truncate text-[10px] text-zinc-600">
                {sub}
              </span>
            </span>
            <ChevronRight className="mt-1 h-3 w-3 text-zinc-700" />
          </button>
        ))}
        {!alerts.length && (
          <div className="p-6 text-center text-xs text-zinc-600">
            No production alerts yet. Delayed jobs, complaints, document expiry,
            and finance reviews will appear here when Firebase has data.
          </div>
        )}
      </div>
    </div>
  );
}

function LiveOperations({
  openJob,
  notify,
}: {
  openJob: (j: Job) => void;
  notify: (s: string) => void;
}) {
  const { db, actions } = useAdminData();
  const { t } = usePreferences();
  const jobs = db.jobs;
  const [area, setArea] = useState("All");
  const [service, setService] = useState("All");
  const [status, setStatus] = useState("All");
  const [provider, setProvider] = useState("All");
  const [priority, setPriority] = useState("All");
  const [opsSearch, setOpsSearch] = useState("");
  const [selected, setSelected] = useState<Job | null>(jobs[0] ?? null);
  const selectedCurrent =
    db.jobs.find((job) => job.id === selected?.id) ?? selected;
  const [assigning, setAssigning] = useState<Job | null>(null);
  const [noting, setNoting] = useState<Job | null>(null);
  const [locating, setLocating] = useState<Provider | null>(null);
  const filtered = jobs.filter((j) => {
    const customer = db.customers.find((x) => x.id === j.customerId);
    const assigned = db.providers.find((x) => x.id === j.providerId);
    const searchable =
      `${j.id} ${j.customer} ${customer?.phone ?? ""} ${j.provider} ${assigned?.phone ?? ""}`.toLowerCase();
    return (
      (area === "All" || j.area === area) &&
      (service === "All" || j.service === service) &&
      (status === "All" || j.status === status) &&
      (provider === "All" || j.providerId === provider) &&
      (priority === "All" || (j.priority ?? "Normal") === priority) &&
      searchable.includes(opsSearch.toLowerCase())
    );
  });
  const active = jobs.filter(
    (j) => !["Completed", "Cancelled", "Refunded"].includes(j.status),
  );
  const delayed = jobs.filter((j) => j.status === "Delayed");
  const unassigned = active.filter((j) => !j.providerId);
  const emergency = active.filter((j) => j.priority === "Emergency");
  return (
    <div className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatBlock
          label="Active now"
          value={String(active.length)}
          icon={Activity}
          tone="indigo"
        />
        <StatBlock
          label="Delayed"
          value={String(delayed.length)}
          icon={AlertTriangle}
          tone="amber"
        />
        <StatBlock
          label={t("Unassigned")}
          value={String(unassigned.length)}
          icon={UserRound}
          tone="red"
        />
        <StatBlock
          label="Providers online"
          value={String(
            db.providers.filter((x) => x.available && isProviderEligible(x))
              .length,
          )}
          icon={Radio}
          tone="green"
        />
        <StatBlock
          label={t("Emergency")}
          value={String(emergency.length)}
          icon={Zap}
          tone="red"
        />
      </div>
      <div className="panel flex flex-wrap items-center gap-2 p-3">
        <span className="eyebrow mr-2">{t("Operational command center")}</span>
        <div className="relative min-w-[240px] flex-1">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-zinc-600" />
          <Input
            className="h-9 pl-9"
            value={opsSearch}
            onChange={(e) => setOpsSearch(e.target.value)}
            placeholder="Order ID, customer/provider name or phone"
          />
        </div>
        <SearchableSelect
          value={area}
          onChange={setArea}
          allowEmpty={false}
          options={[
            { label: "All areas", value: "All" },
            ...[...new Set(jobs.map((x) => x.area))]
              .filter(Boolean)
              .sort()
              .map((x) => ({ label: x, value: x })),
          ]}
        />
        <SearchableSelect
          value={service}
          onChange={setService}
          allowEmpty={false}
          options={[
            { label: "All services", value: "All" },
            ...[...new Set(jobs.map((x) => x.service))]
              .filter(Boolean)
              .sort()
              .map((x) => ({ label: x, value: x })),
          ]}
        />
        <SearchableSelect
          value={status}
          onChange={setStatus}
          allowEmpty={false}
          options={[
            { label: "All statuses", value: "All" },
            ...[...new Set(jobs.map((x) => x.status))]
              .filter(Boolean)
              .sort()
              .map((x) => ({ label: x, value: x })),
          ]}
        />
        <SearchableSelect
          value={provider}
          onChange={setProvider}
          allowEmpty={false}
          options={[
            { label: "All providers", value: "All" },
            ...db.providers.map((x) => ({
              label: `${x.providerId} · ${x.name}`,
              value: x.id,
            })),
          ]}
        />
        <SearchableSelect
          value={priority}
          onChange={setPriority}
          allowEmpty={false}
          options={["All", "Emergency", "High", "Normal", "Low"].map((x) => ({
            label: x === "All" ? "All priorities" : x,
            value: x,
          }))}
        />
        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            setArea("All");
            setService("All");
            setStatus("All");
            setProvider("All");
            setPriority("All");
            setOpsSearch("");
          }}
        >
          Reset
        </Button>
        <span className="ml-auto text-[10px] text-zinc-500">
          {filtered.length} jobs visible
        </span>
      </div>
      {delayed.length > 0 && (
        <div className="flex items-center gap-3 rounded-2xl border border-amber-500/20 bg-amber-500/[.07] p-4">
          <AlertTriangle className="h-5 w-5 text-amber-400" />
          <div className="flex-1">
            <div className="text-xs font-semibold">
              {delayed.length} delayed job{delayed.length > 1 ? "s" : ""}{" "}
              require dispatch attention
            </div>
            <div className="mt-1 text-[10px] text-zinc-500">
              Oldest delay: {delayed[0].id} · {delayed[0].elapsed}
            </div>
          </div>
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              setStatus("Delayed");
              setSelected(delayed[0]);
            }}
          >
            Review alerts
          </Button>
        </div>
      )}
      <div className="grid gap-5 xl:grid-cols-[1.2fr_.8fr]">
        <LiveOperationsMap
          locations={db.locations ?? []}
          providers={db.providers}
          jobs={filtered}
          selectedJob={selectedCurrent}
        />
        <div className="panel">
          <PanelTitle title="Dispatch queue" subtitle="Realtime Firestore feed sorted by urgency" />
          <div className="divide-y divide-white/[.06]">
            {filtered
              .filter((j) =>
                ["Delayed", "Scheduled", "En route"].includes(j.status),
              )
              .map((job, i) => (
                <div
                  key={job.id}
                  onClick={() => setSelected(job)}
                  className="flex w-full items-center gap-3 p-4 text-left hover:bg-white/[.025]"
                >
                  <span
                    className={cn(
                      "grid h-8 w-8 place-items-center rounded-lg text-xs font-semibold",
                      i === 0
                        ? "bg-red-500/10 text-red-400"
                        : "bg-white/[.04] text-zinc-500",
                    )}
                  >
                    {i + 1}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="flex items-center gap-2 text-xs font-medium">
                      {job.id}
                      <StatusBadge status={job.status} />
                    </span>
                    <span className="mt-1 block truncate text-[10px] text-zinc-600">
                      {job.service} · {job.area} · {job.provider}
                    </span>
                  </span>
                  <RowActions
                    label={`Dispatch actions for ${job.id}`}
                    actions={[
                      { label: "View details", onClick: () => openJob(job) },
                      {
                        label: "Assign provider",
                        onClick: () => setAssigning(job),
                      },
                      {
                        label: "Add operational note",
                        onClick: () => setNoting(job),
                      },
                      {
                        label: "Mark en route",
                        onClick: () =>
                          actions.changeJobStatus(job.id, "En route"),
                      },
                      {
                        label: "Cancel job",
                        onClick: () => {
                          actions.changeJobStatus(job.id, "Cancelled");
                          notify(`${job.id} cancelled`);
                        },
                        danger: true,
                      },
                      {
                        label: "Refund job",
                        onClick: () => {
                          actions.refundJob(job.id);
                          notify(`${job.id} refunded`);
                        },
                        danger: true,
                      },
                      {
                        label: "Escalate emergency",
                        onClick: () => {
                          actions.updateJob(job.id, { priority: "Emergency" });
                          actions.createComplaint({
                            title: `Operations escalation · ${job.id}`,
                            description: "Escalated from live operations",
                            severity: "Critical",
                            jobId: job.id,
                            customerId: job.customerId,
                            providerId: job.providerId,
                            customer: job.customer,
                          });
                          notify(`${job.id} escalated`);
                        },
                        separator: true,
                      },
                    ]}
                  />
                </div>
              ))}
          </div>
        </div>
      </div>
      <div className="grid gap-5 xl:grid-cols-[.75fr_1.25fr]">
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Provider availability"
            subtitle="Live mobile-app presence"
          />
          <div className="max-h-[330px] divide-y divide-white/[.05] overflow-y-auto">
            {db.providers.map((p) => {
              const loc = db.locations?.find((x) => x.providerId === p.id);
              return (
                <div key={p.id} className="flex items-center gap-3 p-3">
                  <Avatar initials={p.initials} />
                  <span className="min-w-0 flex-1">
                    <b className="block truncate text-xs">{p.name}</b>
                    <span className="text-[9px] text-zinc-500">
                      {p.areas.join(", ") || "No areas"} ·{" "}
                      {loc
                        ? `${loc.lat.toFixed(4)}, ${loc.lng.toFixed(4)} · ${loc.accuracy}m`
                        : "No live location"}
                    </span>
                  </span>
                  <button onClick={() => setLocating(p)}>
                    <StatusBadge
                      status={loc?.status ?? (p.available ? "Available" : "Offline")}
                    />
                  </button>
                  <RowActions
                    label={`Location actions for ${p.providerId}`}
                    actions={[
                      {
                        label: "Update live coordinates",
                        onClick: () => setLocating(p),
                      },
                      {
                        label: "Mark available",
                        onClick: () =>
                          loc
                            ? actions.updateProviderLocation(
                                p.id,
                                loc.lat,
                                loc.lng,
                                "Available",
                                loc.accuracy,
                                loc.heading,
                              )
                            : setLocating(p),
                      },
                      {
                        label: "Mark busy",
                        onClick: () =>
                          loc
                            ? actions.updateProviderLocation(
                                p.id,
                                loc.lat,
                                loc.lng,
                                "Busy",
                                loc.accuracy,
                                loc.heading,
                              )
                            : setLocating(p),
                      },
                      {
                        label: "Mark offline",
                        onClick: () =>
                          loc
                            ? actions.updateProviderLocation(
                                p.id,
                                loc.lat,
                                loc.lng,
                                "Offline",
                                loc.accuracy,
                                loc.heading,
                              )
                            : actions.updateProvider(p.id, {
                                available: false,
                              }),
                        danger: true,
                      },
                    ]}
                  />
                </div>
              );
            })}
          </div>
        </div>
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Selected job timeline"
            subtitle={
              selectedCurrent
                ? `${selectedCurrent.id} · ${selectedCurrent.customer}`
                : "Select a job from dispatch"
            }
            action={
              selectedCurrent ? (
                <Button
                  size="sm"
                  variant="secondary"
                  onClick={() => openJob(selectedCurrent)}
                >
                  Open details
                </Button>
              ) : undefined
            }
          />
          {selectedCurrent ? (
            <div className="p-4">
              <div className="mb-4 flex flex-wrap gap-2">
                <StatusBadge status={selectedCurrent.status} />
                <Badge
                  variant={
                    selectedCurrent.priority === "Emergency"
                      ? "destructive"
                      : "secondary"
                  }
                >
                  {selectedCurrent.priority ?? "Normal"} priority
                </Badge>
                <span className="text-[10px] text-zinc-500">
                  {selectedCurrent.provider} · {selectedCurrent.area}
                </span>
              </div>
              {selectedCurrent.timeline
                .slice()
                .reverse()
                .map((e) => (
                  <div
                    key={e.id}
                    className="relative ml-2 border-l border-indigo-500/30 pb-4 pl-5 last:pb-0"
                  >
                    <span className="absolute -left-1 top-1 h-2 w-2 rounded-full bg-indigo-400" />
                    <div className="text-[11px] font-medium">{e.label}</div>
                    <div className="mt-1 text-[9px] text-zinc-600">
                      {new Date(e.at).toLocaleString()} · {e.actor}
                    </div>
                  </div>
                ))}
              {selectedCurrent.notes.map((n, i) => (
                <div
                  key={i}
                  className="mt-2 rounded-lg bg-white/[.03] p-2 text-[10px] text-zinc-400"
                >
                  Note: {n}
                </div>
              ))}
            </div>
          ) : (
            <EmptyState
              title="No job selected"
              body="Choose a dispatch item to inspect its live timeline."
            />
          )}
        </div>
      </div>
      <div className="panel overflow-hidden">
        <PanelTitle
          title="Live job feed"
          subtitle="Real-time marketplace activity"
          action={<FilterButton />}
        />
        <JobsTable items={filtered} openJob={openJob} />
      </div>
      <ProviderSearchPicker open={!!assigning} close={() => setAssigning(null)} title={`Dispatch provider · ${assigning?.id ?? ""}`} onSelect={(provider) => { if (assigning) { actions.assignProvider(assigning.id, provider.id); notify(`${assigning.id} dispatched to ${provider.providerId}`); setAssigning(null); } }} />
      <FormDialog
        open={!!locating}
        onClose={() => setLocating(null)}
        title={`Update provider location · ${locating?.providerId ?? ""}`}
        description="Writes the provider's live marker to Firestore for Google Maps and dispatch."
        initial={
          locating
            ? (() => {
                const loc = db.locations.find(
                  (item) => item.providerId === locating.id,
                );
                return {
                  lat: loc?.lat ?? "",
                  lng: loc?.lng ?? "",
                  status:
                    loc?.status ?? (locating.available ? "Available" : "Offline"),
                  accuracy: loc?.accuracy ?? 25,
                  heading: loc?.heading ?? 0,
                };
              })()
            : {}
        }
        fields={[
          { name: "lat", label: "Latitude", type: "number", required: true },
          { name: "lng", label: "Longitude", type: "number", required: true },
          {
            name: "status",
            label: "Availability status",
            type: "select",
            required: true,
            options: [
              { label: "Available", value: "Available" },
              { label: "Busy", value: "Busy" },
              { label: "Offline", value: "Offline" },
            ],
          },
          { name: "accuracy", label: "Accuracy meters", type: "number", min: 1 },
          { name: "heading", label: "Heading", type: "number", min: 0 },
        ]}
        submitLabel="Save live location"
        onSubmit={async (v) => {
          if (locating) {
            await actions.updateProviderLocation(
              locating.id,
              Number(v.lat),
              Number(v.lng),
              v.status as "Available" | "Busy" | "Offline",
              Number(v.accuracy || 25),
              Number(v.heading || 0),
            );
            notify("Provider live location saved to Firestore");
          }
        }}
      />
      <FormDialog
        open={!!noting}
        onClose={() => setNoting(null)}
        title={`Operational note · ${noting?.id ?? ""}`}
        fields={[
          {
            name: "note",
            label: "Internal note",
            type: "textarea",
            required: true,
          },
        ]}
        submitLabel="Save note"
        onSubmit={async(v) => {
          if (noting) {
            await actions.addJobNote(noting.id, v.note);
            notify("Operational note saved");
          }
        }}
      />
    </div>
  );
}

function JobsPage({
  openJob,
  notify,
}: {
  openJob: (j: Job) => void;
  notify: (message: string) => void;
}) {
  const { db } = useAdminData();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("All statuses");
  const [serviceFilter, setServiceFilter] = useState("All services");
  const [areaFilter, setAreaFilter] = useState("All areas");
  const [providerFilter, setProviderFilter] = useState("All providers");
  const [createOpen, setCreateOpen] = useState(false);
  const filtered = useMemo(
    () =>
      db.jobs.filter(
        (j) => {
          const customer = db.customers.find((item) => item.id === j.customerId);
          const provider = db.providers.find((item) => item.id === j.providerId);
          const offerAmounts = j.offers?.map((offer) => offer.price).join(" ") ?? "";
          const searchable = `${j.id} ${j.customerId} ${j.customer} ${customer?.phone ?? ""} ${provider?.providerId ?? ""} ${provider?.phone ?? ""} ${j.service} ${j.area} ${j.cancellation?.reason ?? ""} ${offerAmounts} ${j.paymentStatus}`.toLowerCase();
          return (
          (status === "All statuses" || j.status === status) &&
          (serviceFilter === "All services" || j.serviceId === serviceFilter) &&
          (areaFilter === "All areas" || j.area === areaFilter) &&
          (providerFilter === "All providers" || j.providerId === providerFilter) &&
          searchable.includes(search.toLowerCase())
          );
        },
      ),
    [areaFilter, db.customers, db.jobs, db.providers, providerFilter, search, serviceFilter, status],
  );
  const cancelled = db.jobs.filter((job) => job.status === "Cancelled" || job.cancellation);
  return (
    <>
      <div className="panel overflow-hidden">
        <div className="flex flex-col gap-3 border-b border-white/[.06] p-4 lg:flex-row lg:items-center">
          <SearchInput
            value={search}
            setValue={setSearch}
            placeholder="Search request, customer/provider ID or phone, service, reason, offer, payment…"
          />
          <SearchableSelect
            value={status}
            onChange={setStatus}
            allowEmpty={false}
            options={[
              "All statuses",
              "Scheduled",
              "Assigned",
              "En route",
              "In progress",
              "Delayed",
              "Completed",
              "Cancelled",
              "Refunded",
            ].map((s) => ({ label: s, value: s }))}
          />
          <SearchableSelect
            value={serviceFilter}
            onChange={setServiceFilter}
            allowEmpty={false}
            options={[
              { label: "All services", value: "All services" },
              ...db.services.map((service) => ({
                label: service.name,
                value: service.id,
              })),
            ]}
          />
          <SearchableSelect
            value={areaFilter}
            onChange={setAreaFilter}
            allowEmpty={false}
            options={[
              { label: "All areas", value: "All areas" },
              ...[...new Set(db.jobs.map((job) => job.area))]
                .filter(Boolean)
                .sort()
                .map((area) => ({ label: area, value: area })),
            ]}
          />
          <SearchableSelect
            value={providerFilter}
            onChange={setProviderFilter}
            allowEmpty={false}
            options={[
              { label: "All providers", value: "All providers" },
              ...db.providers.map((provider) => ({
                label: `${provider.providerId} · ${provider.name}`,
                value: provider.id,
              })),
            ]}
          />
          <button onClick={() => setStatus("Cancelled")} className={cn("btn-secondary",status==="Cancelled"&&"border-red-500/30 text-red-400")}><AlertTriangle className="h-3.5 w-3.5"/>Cancelled requests ({cancelled.length})</button>
          <button
            onClick={() => setCreateOpen(true)}
            className="btn-primary lg:ml-auto"
          >
            <Plus className="h-3.5 w-3.5" />
            Create job
          </button>
        </div>
        <div className="flex items-center justify-between border-b border-white/[.06] px-4 py-2.5 text-[10px] text-zinc-600">
          <span>
            {filtered.length} of {db.jobs.length} jobs
          </span>
          <span>Realtime Firestore data</span>
        </div>
        {status === "Cancelled" && <div className="grid gap-3 border-b border-white/[.06] p-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"><StatBlock label="Cancellation rate" value={`${((cancelled.length/Math.max(1,db.jobs.length))*100).toFixed(1)}%`} icon={AlertTriangle} tone="red"/><StatBlock label="No follow-up" value={String(cancelled.filter((job)=>job.cancellation?.followUpStatus==="Not contacted").length)} icon={Headphones} tone="amber"/><StatBlock label="Customer cancellations" value={String(cancelled.filter((job)=>job.cancellation?.cancelledBy==="Customer").length)} icon={UserRound} tone="indigo"/><StatBlock label="Refund pending" value={String(cancelled.filter((job)=>job.cancellation?.refundStatus==="Pending").length)} icon={RefreshCcw} tone="green"/><StatBlock label="Customers >2 cancels" value={String(db.customers.filter((customer)=>cancelled.filter((job)=>job.customerId===customer.id).length>2).length)} icon={Users} tone="red"/><StatBlock label="High-cancel providers" value={String(db.providers.filter((provider)=>{const assigned=db.jobs.filter((job)=>job.providerId===provider.id);return assigned.length>0&&assigned.filter((job)=>job.cancellation).length/assigned.length>.2}).length)} icon={UserCog} tone="amber"/></div>}
        {status === "Cancelled" && <div className="grid gap-4 border-b border-white/[.06] p-4 lg:grid-cols-3"><CancellationBreakdown title="By service" rows={Object.entries(cancelled.reduce<Record<string,number>>((a,j)=>(a[j.service]=(a[j.service]??0)+1,a),{}))}/><CancellationBreakdown title="By stage" rows={Object.entries(cancelled.reduce<Record<string,number>>((a,j)=>(a[j.cancellation?.stage??"Unknown"]=(a[j.cancellation?.stage??"Unknown"]??0)+1,a),{}))}/><CancellationBreakdown title="By reason" rows={Object.entries(cancelled.reduce<Record<string,number>>((a,j)=>(a[j.cancellation?.reason??"Unknown"]=(a[j.cancellation?.reason??"Unknown"]??0)+1,a),{}))}/></div>}
        <JobsTable items={filtered} openJob={openJob} />
        <Pagination />
      </div>
      <ManualJobDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onCreated={(id) => notify(`${id} created and added to operations`)}
      />
    </>
  );
}

function JobsTable({
  items,
  openJob,
}: {
  items: Job[];
  openJob: (j: Job) => void;
}) {
  const { actions } = useAdminData();
  const { user } = useAuth();
  const [assigning, setAssigning] = useState<Job | null>(null);
  const [deleting, setDeleting] = useState<Job | null>(null);
  return (
    <>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[900px] text-left">
          <thead>
            <tr className="border-b border-white/[.06] text-[9px] uppercase tracking-[.1em] text-zinc-600">
              <th className="px-4 py-3 font-semibold">Job</th>
              <th className="px-3 py-3 font-semibold">Customer</th>
              <th className="px-3 py-3 font-semibold">Provider</th>
              <th className="px-3 py-3 font-semibold">Schedule</th>
              <th className="px-3 py-3 font-semibold">Amount</th>
              <th className="px-3 py-3 font-semibold">Payment</th>
              <th className="px-3 py-3 font-semibold">Status</th>
              <th className="w-10" />
            </tr>
          </thead>
          <tbody>
            {items.map((job) => (
              <tr
                key={job.id}
                onClick={() => openJob(job)}
                className="cursor-pointer border-b border-white/[.045] text-[11px] transition last:border-0 hover:bg-white/[.025]"
              >
                <td className="px-4 py-3.5">
                  <div className="font-medium text-zinc-200">{job.id}</div>
                  <div className="mt-0.5 text-[10px] text-zinc-600">
                    {job.service} · {job.area}
                  </div>
                </td>
                <td className="px-3 py-3.5">
                  <div className="flex items-center gap-2">
                    <Avatar initials={job.customerInitials} size="sm" />
                    <span>{job.customer}</span>
                  </div>
                </td>
                <td className="px-3 py-3.5 text-zinc-400">{job.provider}</td>
                <td className="px-3 py-3.5">
                  <div>{job.scheduled}</div>
                  {job.elapsed && (
                    <div
                      className={cn(
                        "mt-0.5 text-[9px]",
                        job.status === "Delayed"
                          ? "text-amber-400"
                          : "text-zinc-600",
                      )}
                    >
                      {job.elapsed}
                    </div>
                  )}
                </td>
                <td className="px-3 py-3.5 font-medium">
                  EGP {job.amount.toLocaleString()}
                </td>
                <td className="px-3 py-3.5"><div className="text-zinc-300">{job.payment?.method ?? job.paymentMethod}</div><div className="mt-0.5 text-[9px] text-zinc-600">{job.paymentStatus}</div></td>
                <td className="px-3 py-3.5">
                  <StatusBadge status={job.status} />
                </td>
                <td className="pr-3" onClick={(e) => e.stopPropagation()}>
                  <RowActions
                    label={`Actions for ${job.id}`}
                    actions={[
                      { label: "View details", onClick: () => openJob(job) },
                      {
                        label: "Assign provider",
                        onClick: () => setAssigning(job),
                      },
                      {
                        label: "Mark in progress",
                        onClick: () =>
                          actions.changeJobStatus(job.id, "In progress"),
                      },
                      {
                        label:
                          job.status === "Cancelled"
                            ? "Reopen job"
                            : "Cancel job",
                        onClick: () =>
                          actions.changeJobStatus(
                            job.id,
                            job.status === "Cancelled"
                              ? "Scheduled"
                              : "Cancelled",
                          ),
                      },
                      {
                        label: "Issue full refund",
                        onClick: () => actions.refundJob(job.id),
                        separator: true,
                      },
                      {
                        label: "Delete job",
                        onClick: () => setDeleting(job),
                        danger: true,
                      },
                    ]}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!items.length && (
          <EmptyState
            title="No jobs found"
            body="Try changing your search or filter criteria."
          />
        )}
      </div>
      <ProviderSearchPicker open={!!assigning} close={() => setAssigning(null)} allowIneligible={user?.role === "Super admin"} title={`Assign provider · ${assigning?.id ?? ""}`} onSelect={(provider, override) => { if (assigning) { actions.assignProvider(assigning.id, provider.id, override && user?.role === "Super admin"); setAssigning(null); } }} />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete job?"
        description="This removes the booking from the admin database. Use cancel for normal operational cases."
        onConfirm={() => deleting && actions.deleteJob(deleting.id)}
      />
    </>
  );
}

function CancellationBreakdown({ title, rows }: { title: string; rows: Array<[string, number]> }) {
  const max = Math.max(1, ...rows.map((row) => row[1]));
  return <div className="rounded-xl border border-white/[.06] bg-black/10 p-4"><div className="text-[10px] font-semibold">{title}</div><div className="mt-3 space-y-3">{rows.map(([label,value])=><div key={label}><div className="mb-1 flex justify-between text-[9px] text-zinc-500"><span className="truncate">{label}</span><span>{value}</span></div><div className="h-1.5 rounded-full bg-white/[.05]"><div className="h-full rounded-full bg-red-400" style={{width:`${value/max*100}%`}}/></div></div>)}</div></div>;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function ProvidersPage({ notify }: { notify: (s: string) => void }) {
  const { db, actions } = useAdminData();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("All");
  const [verificationFilter, setVerificationFilter] =
    useState("All verification");
  const [verificationProvider, setVerificationProvider] =
    useState<Provider | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [editing, setEditing] = useState<Provider | null>(null);
  const [deleting, setDeleting] = useState<Provider | null>(null);
  const filtered = db.providers.filter((p) => {
    const summary = verificationSummary(p);
    const verificationMatch =
      verificationFilter === "All verification" ||
      (verificationFilter === "Missing documents" &&
        summary.missing.length > 0) ||
      (verificationFilter === "Expired documents" &&
        summary.expired.length > 0) ||
      (verificationFilter === "Pending verification" &&
        summary.pending.length > 0) ||
      (verificationFilter === "Rejected verification" &&
        summary.rejected.length > 0) ||
      (verificationFilter === "Fully verified" && summary.eligible);
    return (
      (status === "All" || p.status === status) &&
      `${p.name} ${p.trade}`.toLowerCase().includes(search.toLowerCase()) &&
      verificationMatch
    );
  });
  return (
    <div className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatBlock
          label="Total providers"
          value={String(db.providers.length)}
          icon={Users}
          tone="indigo"
        />
        <StatBlock
          label="Online now"
          value={String(db.providers.filter((x) => x.available).length)}
          icon={Radio}
          tone="green"
        />
        <StatBlock
          label="Pending review"
          value={String(
            db.providers.filter((x) => x.status === "Review").length,
          )}
          icon={FileCheck2}
          tone="amber"
        />
        <StatBlock
          label="Suspended"
          value={String(
            db.providers.filter(
              (x) => x.status === "Suspended" || x.status === "Banned",
            ).length,
          )}
          icon={ShieldCheck}
          tone="red"
        />
      </div>
      {db.providers.some(
        (provider) =>
          provider.documents.some((document) => expiryMessage(document)) ||
          verificationSummary(provider).missing.length > 0,
      ) && (
        <div className="rounded-2xl border border-amber-500/20 bg-amber-500/[.06] p-4">
          <div className="flex items-center gap-2 text-xs font-semibold text-amber-300">
            <AlertTriangle className="h-4 w-4" />
            Verification alerts
          </div>
          <div className="mt-2 flex flex-wrap gap-2">
            {db.providers
              .flatMap((provider) => [
                ...provider.documents
                  .map((document) => expiryMessage(document))
                  .filter(Boolean)
                  .map((message) => `${provider.name}: ${message}`),
                ...verificationSummary(provider)
                  .missing.slice(0, 1)
                  .map((document) => `${provider.name}: Missing ${document}`),
              ])
              .slice(0, 8)
              .map((message) => (
                <button
                  key={message}
                  onClick={() => {
                    const provider = db.providers.find((item) =>
                      message.startsWith(item.name),
                    );
                    if (provider) setVerificationProvider(provider);
                  }}
                  className="rounded-lg bg-black/20 px-3 py-2 text-[10px] text-zinc-300"
                >
                  {message}
                </button>
              ))}
          </div>
        </div>
      )}
      <div className="panel overflow-hidden">
        <div className="flex items-center gap-3 border-b border-white/[.06] p-4">
          <SearchInput
            value={search}
            setValue={setSearch}
            placeholder="Search providers..."
          />
          <SearchableSelect
            value={status}
            onChange={setStatus}
            allowEmpty={false}
            options={["All", "Active", "Review", "Suspended", "Banned"].map(
              (value) => ({
                label: value === "All" ? "All provider statuses" : value,
                value,
              }),
            )}
          />
          <SearchableSelect
            value={verificationFilter}
            onChange={setVerificationFilter}
            allowEmpty={false}
            options={[
              "All verification",
              "Missing documents",
              "Expired documents",
              "Pending verification",
              "Rejected verification",
              "Fully verified",
            ].map((value) => ({ label: value, value }))}
          />
          <button
            onClick={() => setCreateOpen(true)}
            className="btn-primary ml-auto"
          >
            <Plus className="h-3.5 w-3.5" />
            Add provider
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[820px]">
            <thead>
              <tr className="table-head">
                <th>Provider</th>
                <th>Verification</th>
                <th>Rating</th>
                <th>Jobs</th>
                <th>Earnings / mo</th>
                <th>Response</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {filtered.map((p) => (
                <tr key={p.id} className="table-row">
                  <td>
                    <div className="flex items-center gap-3">
                      <Avatar initials={p.initials} />
                      <div>
                        <div className="text-xs font-medium">{p.name}</div>
                        <div className="text-[10px] text-zinc-600">
                          {p.id} · {p.trade}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>
                    {(() => {
                      const summary = verificationSummary(p);
                      return (
                        <button
                          onClick={() => setVerificationProvider(p)}
                          className="text-left"
                        >
                          <span
                            className={cn(
                              "inline-flex items-center gap-1 text-[10px]",
                              summary.eligible
                                ? "text-emerald-400"
                                : summary.rejected.length
                                  ? "text-red-400"
                                  : "text-amber-400",
                            )}
                          >
                            {summary.eligible && (
                              <CheckCircle2 className="h-3.5 w-3.5" />
                            )}
                            {summary.eligible
                              ? "Verified"
                              : summary.rejected.length
                                ? "Rejected"
                                : "Pending Verification"}
                          </span>
                          <span className="mt-1 block text-[9px] text-zinc-600">
                            {summary.percentage}% complete
                          </span>
                        </button>
                      );
                    })()}
                  </td>
                  <td>
                    <span className="flex items-center gap-1 text-xs">
                      <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
                      {p.rating}
                    </span>
                  </td>
                  <td>{p.jobs}</td>
                  <td>EGP {p.earnings.toLocaleString()}</td>
                  <td>{p.response}</td>
                  <td>
                    <StatusBadge status={p.status} />
                  </td>
                  <td>
                    <RowActions
                      label={`Actions for ${p.name}`}
                      actions={[
                        {
                          label: "Edit provider",
                          onClick: () => setEditing(p),
                        },
                        {
                          label: "Documents & verification",
                          onClick: () => setVerificationProvider(p),
                        },
                        {
                          label: "Approve provider",
                          onClick: () => {
                            const summary = verificationSummary(p);
                            if (
                              summary.percentage < 100 ||
                              p.verification.backgroundCheck !== "Completed" ||
                              !p.verification.contractSigned
                            ) {
                              setVerificationProvider(p);
                              notify(
                                "Complete mandatory verification before approval",
                              );
                            } else {
                              actions.setProviderDecision(p.id, "approve");
                              notify(`${p.name} approved`);
                            }
                          },
                        },
                        {
                          label: "Reject provider",
                          onClick: () =>
                            actions.setProviderDecision(p.id, "reject"),
                        },
                        {
                          label: p.available
                            ? "Set unavailable"
                            : "Set available",
                          onClick: () =>
                            actions.updateProvider(p.id, {
                              available: !p.available,
                            }),
                        },
                        {
                          label:
                            p.status === "Disabled" || p.disabled
                              ? "Enable provider"
                              : "Disable provider",
                          onClick: () => actions.toggleProvider(p.id),
                          separator: true,
                        },
                        {
                          label: "Ban provider",
                          onClick: () =>
                            actions.setProviderDecision(p.id, "ban"),
                          danger: true,
                        },
                        {
                          label: "Delete provider",
                          onClick: () => setDeleting(p),
                          danger: true,
                        },
                      ]}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination />
      </div>
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Add provider"
        description="Provider enters review until identity documents are approved."
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "email", label: "Email", type: "email", required: true },
          { name: "phone", label: "Phone", type: "tel", required: true },
          { name: "trade", label: "Primary trade", required: true },
        ]}
        submitLabel="Add provider"
        onSubmit={async(v) => {
          await actions.createProvider({
            name: v.name,
            email: v.email,
            phone: v.phone,
            trade: v.trade,
          });
          notify("Provider added for review");
        }}
      />
      <FormDialog
        open={!!editing}
        onClose={() => setEditing(null)}
        title="Edit provider settings"
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "trade", label: "Trade", required: true },
          {
            name: "commission",
            label: "Commission %",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "areas",
            label: "Working areas (comma separated)",
            required: true,
          },
          {
            name: "serviceIds",
            label: "Service IDs (comma separated)",
            required: true,
          },
        ]}
        initial={
          editing
            ? {
                name: editing.name,
                trade: editing.trade,
                commission: editing.commission,
                areas: editing.areas.join(", "),
                serviceIds: editing.serviceIds.join(", "),
              }
            : {}
        }
        onSubmit={(v) =>
          editing &&
          actions.updateProvider(editing.id, {
            name: v.name,
            initials: v.name
              .split(" ")
              .map((x) => x[0])
              .join("")
              .slice(0, 2),
            trade: v.trade,
            commission: Number(v.commission),
            areas: v.areas
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
            serviceIds: v.serviceIds
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
          })
        }
      />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete provider?"
        description="This permanently removes the provider profile. Existing job records remain for audit purposes."
        onConfirm={() => deleting && actions.deleteProvider(deleting.id)}
      />
      {verificationProvider && (
        <ProviderVerificationCenter
          providerId={verificationProvider.id}
          close={() => setVerificationProvider(null)}
          notify={notify}
        />
      )}
    </div>
  );
}

function CustomersPage({ notify }: { notify: (s: string) => void }) {
  const { db, actions } = useAdminData();
  const [search, setSearch] = useState("");
  const [risk, setRisk] = useState("All");
  const [createOpen, setCreateOpen] = useState(false);
  const [editing, setEditing] = useState<Customer | null>(null);
  const [wallet, setWallet] = useState<Customer | null>(null);
  const [deleting, setDeleting] = useState<Customer | null>(null);
  const [profile, setProfile] = useState<Customer | null>(null);
  const customers = db.customers.filter(
    (c) =>
      (risk === "All" || c.risk === risk) &&
      `${c.name} ${c.email} ${c.phone}`
        .toLowerCase()
        .includes(search.toLowerCase()),
  );
  return (
    <div className="space-y-5">
      <div className="grid gap-4 md:grid-cols-3">
        <StatBlock
          label="Active customers"
          value={String(
            db.customers.filter((x) => x.status === "Active").length,
          )}
          icon={Users}
          tone="indigo"
        />
        <StatBlock
          label="Repeat rate"
          value={`${db.customers.length?((db.customers.filter((item)=>item.bookings>1).length/db.customers.length)*100).toFixed(1):0}%`}
          icon={RefreshCcw}
          tone="green"
        />
        <StatBlock
          label="Flagged accounts"
          value={String(
            db.customers.filter((x) => x.risk !== "Healthy").length,
          )}
          icon={AlertTriangle}
          tone="red"
        />
      </div>
      <div className="panel overflow-hidden">
        <div className="flex gap-3 border-b border-white/[.06] p-4">
          <SearchInput
            value={search}
            setValue={setSearch}
            placeholder="Search customers..."
          />
          <SearchableSelect
            value={risk}
            onChange={setRisk}
            allowEmpty={false}
            options={["All", "Healthy", "Watch", "Review"].map((value) => ({
              label: value === "All" ? "All risk levels" : value,
              value,
            }))}
          />
          <button
            onClick={() => setCreateOpen(true)}
            className="btn-primary ml-auto"
          >
            <Plus className="h-3.5 w-3.5" />
            Add customer
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px]">
            <thead>
              <tr className="table-head">
                <th>Customer</th>
                <th>Phone</th>
                <th>Bookings</th>
                <th>Total spend</th>
                <th>Rating</th>
                <th>Risk</th>
                <th>Wallet</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {customers.map((c) => (
                <tr className="table-row" key={c.id}>
                  <td onClick={() => setProfile(c)} className="cursor-pointer">
                    <div className="flex items-center gap-2">
                      <Avatar initials={c.initials} />
                      <span className="font-medium">{c.name}</span>
                    </div>
                  </td>
                  <td>{c.phone}</td>
                  <td>{c.bookings}</td>
                  <td>EGP {c.totalSpend.toLocaleString()}</td>
                  <td>{c.rating}</td>
                  <td>
                    <StatusBadge status={c.risk} />
                  </td>
                  <td>EGP {c.walletBalance.toLocaleString()}</td>
                  <td>
                    <RowActions
                      label={`Actions for ${c.name}`}
                      actions={[
                        {
                          label: "Edit customer",
                          onClick: () => setEditing(c),
                        },
                        { label: "Adjust wallet", onClick: () => setWallet(c) },
                        {
                          label: "Open complete history",
                          onClick: () => setProfile(c),
                        },
                        {
                          label: "View complaints",
                          onClick: () =>
                            notify(
                              `${db.complaints.filter((x) => x.customerId === c.id).length} complaints for ${c.name}`,
                            ),
                        },
                        {
                          label:
                            c.status === "Disabled" || c.disabled
                              ? "Enable customer"
                              : "Disable customer",
                          onClick: () => actions.toggleCustomer(c.id),
                          separator: true,
                        },
                        {
                          label: "Delete customer",
                          onClick: () => setDeleting(c),
                          danger: true,
                        },
                      ]}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Add customer"
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "email", label: "Email", type: "email", required: true },
          { name: "phone", label: "Phone", type: "tel", required: true },
        ]}
        submitLabel="Create customer"
        onSubmit={async(v) => {
          await actions.createCustomer({
            name: v.name,
            email: v.email,
            phone: v.phone,
          });
          notify("Customer created");
        }}
      />
      <FormDialog
        open={!!editing}
        onClose={() => setEditing(null)}
        title="Edit customer"
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "email", label: "Email", type: "email", required: true },
          { name: "phone", label: "Phone", required: true },
          {
            name: "risk",
            label: "Risk status",
            type: "select",
            required: true,
            options: ["Healthy", "Watch", "Review"].map((x) => ({
              label: x,
              value: x,
            })),
          },
        ]}
        initial={
          editing
            ? {
                name: editing.name,
                email: editing.email,
                phone: editing.phone,
                risk: editing.risk,
              }
            : {}
        }
        onSubmit={(v) =>
          editing &&
          actions.updateCustomer(editing.id, {
            name: v.name,
            email: v.email,
            phone: v.phone,
            risk: v.risk as Customer["risk"],
          })
        }
      />
      <FormDialog
        open={!!wallet}
        onClose={() => setWallet(null)}
        title={`Adjust wallet · ${wallet?.name ?? ""}`}
        description={`Current balance: EGP ${wallet?.walletBalance.toLocaleString() ?? 0}. Use a negative amount to deduct.`}
        fields={[
          {
            name: "amount",
            label: "Adjustment amount (EGP)",
            type: "number",
            required: true,
          },
          { name: "note", label: "Reason", required: true },
        ]}
        submitLabel="Apply adjustment"
        onSubmit={async(v) => {
          if (wallet) {
            await actions.adjustWallet(wallet.id, Number(v.amount), v.note);
            notify("Wallet balance updated");
          }
        }}
      />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete customer?"
        description="This also removes the customer's wallet. Suspend the account instead when historical access must be preserved."
        onConfirm={() => deleting && actions.deleteCustomer(deleting.id)}
      />
      {profile && <CustomerHistoryDrawer customerId={profile.id} close={()=>setProfile(null)} notify={notify}/>} 
    </div>
  );
}

function TrustPage({ notify }: { notify: (s: string) => void }) {
  const { db, actions } = useAdminData();
  const { can } = usePermissions();
  const [createOpen, setCreateOpen] = useState(false);
  const [editing, setEditing] = useState<(typeof db.complaints)[number] | null>(
    null,
  );
  const [noting, setNoting] = useState<(typeof db.complaints)[number] | null>(
    null,
  );
  const [deleting, setDeleting] = useState<
    (typeof db.complaints)[number] | null
  >(null);
  const [evidenceCase,setEvidenceCase]=useState<(typeof db.complaints)[number]|null>(null);const[evidenceUploading,setEvidenceUploading]=useState(false);
  const [viewingRealData, setViewingRealData] = useState<(typeof db.complaints)[number] | null>(null);
  const closedCases=db.complaints.filter((item)=>item.status==="Closed").length;const riskCases=db.complaints.filter((item)=>item.status!=="Closed"&&(item.severity==="High"||item.severity==="Medium")).length;const breachedCases=db.complaints.filter((item)=>item.status!=="Closed"&&item.severity==="Critical").length;const caseTotal=Math.max(1,db.complaints.length);const caseHealth=[{value:closedCases,fill:"#22c55e"},{value:riskCases,fill:"#f59e0b"},{value:breachedCases,fill:"#ef4444"}];
  return (
    <div className="space-y-5">
      <div className="grid gap-4 md:grid-cols-4">
        <StatBlock
          label="Open cases"
          value={String(
            db.complaints.filter((x) => x.status !== "Closed").length,
          )}
          icon={ShieldCheck}
          tone="indigo"
        />
        <StatBlock
          label="Critical"
          value={String(
            db.complaints.filter(
              (x) => x.severity === "Critical" && x.status !== "Closed",
            ).length,
          )}
          icon={AlertTriangle}
          tone="red"
        />
        <StatBlock
          label="Closed cases"
          value={String(db.complaints.filter((item)=>item.status==="Closed").length)}
          icon={Clock3}
          tone="green"
        />
        <StatBlock label="Priority at risk" value={String(db.complaints.filter((item)=>item.status!=="Closed"&&(item.severity==="Critical"||item.severity==="High")).length)} icon={Gauge} tone="amber" />
      </div>
      <div className="grid gap-5 xl:grid-cols-[1.35fr_.65fr]">
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Incident cases"
            subtitle="Ordered by severity and SLA"
            action={
              <button
                onClick={() => setCreateOpen(true)}
                className="btn-primary"
              >
                <Plus className="h-3.5 w-3.5" />
                New case
              </button>
            }
          />
          <div className="divide-y divide-white/[.05]">
            {db.complaints.map((i) => (
              <div
                key={i.id}
                className="flex w-full items-center gap-3 p-4 text-left hover:bg-white/[.025]"
              >
                <SeverityIcon severity={i.severity} />
                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-2 text-xs font-medium">
                    {i.title}
                    <SeverityBadge severity={i.severity} />
                  </span>
                  <span className="mt-1 block text-[10px] text-zinc-600">
                    {i.id} · {i.customer} · {i.providerId ? db.providers.find((provider) => provider.id === i.providerId)?.providerId ?? i.providerId : "No provider linked"} · {i.status}
                  </span>
                </span>
                <span className="hidden text-right sm:block">
                  <span className="block text-[10px] text-zinc-400">
                    {i.owner}
                  </span>
                  <span className="text-[9px] text-zinc-700">{i.age} ago</span>
                </span>
                <RowActions
                  label={`Actions for ${i.id}`}
                  actions={[
                    { label: "Edit case", onClick: () => setEditing(i) },
                    { label: "Add internal note", onClick: () => setNoting(i) },
                    {
                      label:
                        i.status === "Closed" ? "Reopen case" : "Close case",
                      onClick: () =>
                        i.status === "Closed"
                          ? actions.reopenCase(i.id)
                          : actions.closeCase(i.id),
                    },
                    {
                      label: "Upload evidence",
                      onClick: () => setEvidenceCase(i),
                      separator: true,
                    },
                    ...(can("chat.view") || can("notifications.view")
                      ? [
                          {
                            label: "View real chat & notifications",
                            onClick: () => setViewingRealData(i),
                          },
                        ]
                      : []),
                    {
                      label: "Delete case",
                      onClick: () => setDeleting(i),
                      danger: true,
                    },
                  ]}
                />
              </div>
            ))}
          </div>
        </div>
        <div className="panel">
          <PanelTitle title="Case health" subtitle="This week" />
          <div className="p-5">
            <div className="mx-auto h-44 w-44">
              <ResponsiveContainer>
                <PieChart>
                  <Pie
                    data={caseHealth}
                    innerRadius={55}
                    outerRadius={72}
                    dataKey="value"
                    stroke="none"
                    startAngle={90}
                    endAngle={-270}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="-mt-[106px] mb-[74px] text-center">
              <div className="text-2xl font-semibold">{Math.round(closedCases/caseTotal*100)}%</div>
              <div className="text-[10px] text-zinc-600">cases closed</div>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {[
                ["Resolved", `${Math.round(closedCases/caseTotal*100)}%`, "text-emerald-400"],
                ["At risk", `${Math.round(riskCases/caseTotal*100)}%`, "text-amber-400"],
                ["Critical", `${Math.round(breachedCases/caseTotal*100)}%`, "text-red-400"],
              ].map(([a, b, c]) => (
                <div
                  className="rounded-lg bg-white/[.03] p-2 text-center"
                  key={a}
                >
                  <div className={cn("text-xs font-semibold", c)}>{b}</div>
                  <div className="text-[9px] text-zinc-600">{a}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Create complaint"
        fields={[
          { name: "title", label: "Case title", required: true },
          {
            name: "description",
            label: "Description",
            type: "textarea",
            required: true,
          },
          {
            name: "severity",
            label: "Severity",
            type: "select",
            required: true,
            options: ["Critical", "High", "Medium", "Low"].map((x) => ({
              label: x,
              value: x,
            })),
          },
          {
            name: "customerId",
            label: "Linked customer",
            type: "select",
            options: db.customers.map((x) => ({ label: x.name, value: x.id })),
          },
          {
            name: "providerId",
            label: "Linked provider search",
            placeholder: "Provider ID, name, phone, email or national ID",
          },
          {
            name: "jobId",
            label: "Linked job",
            type: "select",
            options: db.jobs.map((x) => ({
              label: `${x.id} · ${x.service}`,
              value: x.id,
            })),
          },
        ]}
        submitLabel="Create case"
        onSubmit={async(v) => {
          const c = db.customers.find((x) => x.id === v.customerId);
          const linkedProvider = v.providerId
            ? db.providers.find((provider) => providerMatchesQuery(provider, v.providerId, db.services))
            : undefined;
          if (v.providerId && !linkedProvider) return notify("No provider matches that search");
          await actions.createComplaint({
            title: v.title,
            description: v.description,
            severity: v.severity as "Critical" | "High" | "Medium" | "Low",
            customerId: v.customerId || undefined,
            providerId: linkedProvider?.id,
            jobId: v.jobId || undefined,
            customer: c?.name ?? "Unknown",
          });
          notify("Complaint created");
        }}
      />
      <FormDialog
        open={!!editing}
        onClose={() => setEditing(null)}
        title={`Edit case · ${editing?.id ?? ""}`}
        fields={[
          {
            name: "ownerId",
            label: "Case owner",
            type: "select",
            required: true,
            options: db.admins
              .filter((x) => x.status !== "Disabled")
              .map((x) => ({ label: x.name, value: x.id })),
          },
          {
            name: "severity",
            label: "Severity",
            type: "select",
            required: true,
            options: ["Critical", "High", "Medium", "Low"].map((x) => ({
              label: x,
              value: x,
            })),
          },
          {
            name: "status",
            label: "Status",
            type: "select",
            required: true,
            options: [
              "New",
              "Investigating",
              "Evidence review",
              "Monitoring",
              "Closed",
            ].map((x) => ({ label: x, value: x })),
          },
        ]}
        initial={
          editing
            ? {
                ownerId: editing.ownerId ?? "",
                severity: editing.severity,
                status: editing.status,
              }
            : {}
        }
        onSubmit={async(v) => {
          if (editing) {
            await actions.setCaseOwner(editing.id, v.ownerId);
            await actions.setCaseSeverity(
              editing.id,
              v.severity as "Critical" | "High" | "Medium" | "Low",
            );
            await actions.updateComplaint(editing.id, {
              status: v.status as typeof editing.status,
            });
          }
        }}
      />
      <FormDialog
        open={!!noting}
        onClose={() => setNoting(null)}
        title={`Add internal note · ${noting?.id ?? ""}`}
        fields={[
          {
            name: "note",
            label: "Internal note",
            type: "textarea",
            required: true,
          },
        ]}
        onSubmit={(v) => noting && actions.addCaseNote(noting.id, v.note)}
      />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete complaint?"
        description="This removes the case and its internal evidence references."
        onConfirm={() => deleting && actions.deleteComplaint(deleting.id)}
      />
      {evidenceCase&&<div className="fixed inset-0 z-[120] grid place-items-center bg-black/75 p-4" onMouseDown={()=>setEvidenceCase(null)}><div className="panel w-full max-w-md p-5" onMouseDown={(event)=>event.stopPropagation()}><h2 className="font-semibold">Upload evidence · {evidenceCase.id}</h2><p className="mt-2 text-xs text-zinc-500">The file is stored in Firebase Storage and linked permanently to this complaint.</p><label className="btn-primary mt-5 cursor-pointer">{evidenceUploading?<Loader2 className="animate-spin"/>:<Plus className="h-4 w-4"/>} Choose evidence<input hidden type="file" accept="image/jpeg,image/png,image/webp,application/pdf,video/mp4,audio/mpeg,audio/wav" onChange={async(event)=>{const file=event.target.files?.[0];if(!file)return;setEvidenceUploading(true);try{const stored=await uploadFirebaseFile(file,`complaint-evidence/${evidenceCase.id}`);await actions.updateComplaint(evidenceCase.id,{evidence:[stored.url,...evidenceCase.evidence]});notify("Evidence uploaded and audited");setEvidenceCase(null)}catch(error){notify(error instanceof Error?error.message:"Upload failed")}finally{setEvidenceUploading(false)}}}/></label><button onClick={()=>setEvidenceCase(null)} className="btn-secondary ml-2">Cancel</button></div></div>}
      <ComplaintRealDataDialog complaint={viewingRealData} onClose={() => setViewingRealData(null)} />
    </div>
  );
}

function PaymentsPage({ notify, openJob }: { notify: (s: string) => void; openJob: (job: Job) => void }) {
  const { db, actions } = useAdminData();
  const [payoutOpen, setPayoutOpen] = useState(false);
  const [transactionOpen, setTransactionOpen] = useState(false);
  const [verify, setVerify] = useState<(typeof db.payouts)[number] | null>(
    null,
  );
  const [search, setSearch] = useState("");
  const [type, setType] = useState("All");
  const [status, setStatus] = useState("All");
  const [instapayReview, setInstapayReview] = useState<(typeof db.instapayReviews)[number] | null>(null);
  const gross = db.transactions
    .filter((x) => x.type === "Customer payment")
    .reduce((n, x) => n + x.amount, 0);
  const pendingRefunds = db.transactions
    .filter((x) => x.type === "Customer refund" && x.status !== "Completed")
    .reduce((n, x) => n + x.amount, 0);
  const cash = db.transactions
    .filter((x) => x.type === "Cash collection" && x.status !== "Completed")
    .reduce((n, x) => n + x.amount, 0);
  const filtered = db.transactions.filter(
    (x) =>
      (type === "All" || x.type === type) &&
      (status === "All" || x.status === status) &&
      `${x.id} ${x.jobId ?? ""} ${x.ownerId ?? ""} ${x.party} ${x.type} ${x.method} ${x.amount} ${x.status} ${x.reference ?? ""} ${x.providerReference ?? ""} ${db.customers.find((customer)=>customer.id===x.ownerId)?.phone ?? ""} ${db.providers.find((provider)=>provider.id===x.ownerId)?.providerId ?? ""} ${db.providers.find((provider)=>provider.id===x.ownerId)?.phone ?? ""}`
        .toLowerCase()
        .includes(search.toLowerCase()),
  );
  return (
    <div className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatBlock
          label="Gross volume"
          value={`EGP ${gross.toLocaleString()}`}
          icon={CircleDollarSign}
          tone="indigo"
        />
        <StatBlock
          label="Provider payable"
          value={`EGP ${db.payouts
            .filter((x) => x.status === "Pending")
            .reduce((n, x) => n + x.amount, 0)
            .toLocaleString()}`}
          icon={WalletCards}
          tone="green"
        />
        <StatBlock
          label="Pending refunds"
          value={`EGP ${pendingRefunds.toLocaleString()}`}
          icon={RefreshCcw}
          tone="amber"
        />
        <StatBlock
          label="Cash to collect"
          value={`EGP ${cash.toLocaleString()}`}
          icon={Banknote}
          tone="red"
        />
      </div>
      <div className="panel overflow-hidden">
        <PanelTitle
          title="Instapay manual review"
          subtitle={`${db.instapayReviews.filter((item)=>item.status==="Pending"||item.status==="Better proof requested").length} payments need finance review`}
        />
        <div className="grid gap-3 p-4 lg:grid-cols-2">
          {db.instapayReviews.length ? db.instapayReviews.map((review)=>{const job=db.jobs.find((item)=>item.id===review.jobId);const customer=db.customers.find((item)=>item.id===review.customerId);return <div key={review.id} className={cn("rounded-2xl border p-4",review.status==="Suspicious"?"border-red-500/30 bg-red-500/[.04]":"border-white/[.07] bg-white/[.02]")}><div className="flex gap-4"><div className="h-24 w-28 shrink-0 rounded-xl bg-cover bg-center" style={{backgroundImage:`url(${review.proofUrl})`}}/><div className="min-w-0 flex-1"><div className="flex items-center gap-2"><b className="text-xs">{review.id}</b><StatusBadge status={review.status}/></div><div className="mt-2 text-xs">{customer ? `${customer.name} · ${customer.phone}` : review.customerId}</div><div className="mt-1 text-[10px] text-zinc-500">{review.jobId} · EGP {review.amount.toLocaleString()} · sender {review.senderAccount}</div><div className="mt-1 text-[9px] text-zinc-600">Reference {review.transferReference??"Missing"} · submitted {new Date(review.submittedAt).toLocaleString()}</div><div className="mt-3 flex flex-wrap gap-2"><button onClick={()=>{actions.reviewInstapay(review.id,"Approved","Payment proof and reference verified");notify(`${review.jobId} payment approved`);}} className="btn-primary !h-8">Approve</button><button onClick={()=>setInstapayReview(review)} className="btn-secondary !h-8">Review actions</button>{job&&<button onClick={()=>openJob(job)} className="btn-secondary !h-8">Open job</button>}</div></div></div></div>}) : (
            <div className="lg:col-span-2">
              <EmptyState title="No Instapay payments" body="Firestore has no Instapay proof submissions waiting for finance review." />
            </div>
          )}
        </div>
      </div>
      <div className="panel overflow-hidden">
        <div className="flex flex-wrap gap-2 border-b border-white/[.06] p-4">
          <SearchInput
            value={search}
            setValue={setSearch}
            placeholder="Search transactions..."
          />
          <SearchableSelect
            value={type}
            onChange={setType}
            allowEmpty={false}
            options={[
              "All",
              "Customer payment",
              "Provider payout",
              "Customer refund",
              "Cash collection",
              "Commission",
              "Wallet credit",
              "Wallet debit",
              "Instapay verification",
            ].map((value) => ({
              label: value === "All" ? "All transaction types" : value,
              value,
            }))}
          />
          <SearchableSelect
            value={status}
            onChange={setStatus}
            allowEmpty={false}
            options={["All", "Completed", "Processing", "Pending", "Failed"].map(
              (value) => ({
                label: value === "All" ? "All transaction statuses" : value,
                value,
              }),
            )}
          />
          <button
            onClick={() => setTransactionOpen(true)}
            className="btn-secondary ml-auto"
          >
            <Plus className="h-3.5 w-3.5" />
            Record cash
          </button>
          <button onClick={() => setPayoutOpen(true)} className="btn-primary">
            <WalletCards className="h-3.5 w-3.5" />
            New payout
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px]">
            <thead>
              <tr className="table-head">
                <th>Transaction</th>
                <th>Type</th>
                <th>Party</th>
                <th>Amount</th>
                <th>Method</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {filtered.map((t) => (
                <tr className="table-row" key={t.id}>
                  <td className="font-medium text-zinc-200">{t.id}</td>
                  <td>{t.type}</td>
                  <td>{t.party}<div className="font-mono text-[9px] text-indigo-300">{db.providers.find((provider) => provider.id === t.ownerId)?.providerId ?? ""}</div></td>
                  <td className="font-medium text-white">
                    EGP {t.amount.toLocaleString()}
                  </td>
                  <td>{t.method}</td>
                  <td>
                    <StatusBadge status={t.status} />
                  </td>
                  <td>
                    <RowActions
                      actions={[
                        {
                          label: "View reference",
                          onClick: () =>
                            notify(t.reference ?? "No external reference"),
                        },
                        {
                          label: "Mark completed",
                          onClick: () =>
                            actions.updateTransaction(t.id, {
                              status: "Completed",
                            }),
                        },
                      ]}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      {db.payouts.length > 0 && (
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Provider payouts"
            subtitle={`${db.payouts.length} payout requests`}
          />
          <div className="divide-y divide-white/[.05]">
            {db.payouts.map((p) => (
              <div key={p.id} className="flex items-center gap-3 p-4 text-xs">
                <span className="flex-1">
                  <b>{p.providerName}</b>
                  <span className="ml-2 font-mono text-[9px] text-indigo-300">{db.providers.find((provider) => provider.id === p.providerId)?.providerId}</span>
                  <span className="ml-2 text-zinc-500">
                    EGP {p.amount.toLocaleString()} · {p.method}
                  </span>
                </span>
                <StatusBadge status={p.status} />
                {p.status === "Pending" && (
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={() => setVerify(p)}
                  >
                    Verify
                  </Button>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
      <FormDialog
        open={payoutOpen}
        onClose={() => setPayoutOpen(false)}
        title="Create provider payout"
        fields={[
          {
            name: "providerId",
            label: "Provider search",
            required: true,
            placeholder: "ID, name, phone, email, national ID or skill",
          },
          {
            name: "amount",
            label: "Amount (EGP)",
            type: "number",
            required: true,
            min: 1,
          },
          {
            name: "method",
            label: "Method",
            type: "select",
            required: true,
            options: ["Bank transfer", "Instapay", "Cash"].map((x) => ({
              label: x,
              value: x,
            })),
          },
        ]}
        submitLabel="Create payout"
        onSubmit={async(v) => {
          const provider = db.providers.find((item) => item.status === "Active" && providerMatchesQuery(item, v.providerId, db.services));
          if (!provider) return notify("No active provider matches that search");
          await actions.createPayout(
            provider.id,
            Number(v.amount),
            v.method as "Bank transfer" | "Instapay" | "Cash",
          );
          notify("Payout request created");
        }}
      />
      <FormDialog open={!!instapayReview} onClose={()=>setInstapayReview(null)} title={`Review Instapay · ${instapayReview?.id??""}`} fields={[{name:"status",label:"Decision",type:"select",required:true,options:["Rejected","Better proof requested","Suspicious","Approved"].map((value)=>({label:value,value}))},{name:"note",label:"Finance note",type:"textarea",required:true}]} submitLabel="Save review" onSubmit={async(v)=>{if(instapayReview){await actions.reviewInstapay(instapayReview.id,v.status as (typeof instapayReview)["status"],v.note);notify("Instapay review updated");}}}/>
      <FormDialog
        open={transactionOpen}
        onClose={() => setTransactionOpen(false)}
        title="Record cash collection"
        fields={[
          {
            name: "providerId",
            label: "Provider search",
            required: true,
            placeholder: "ID, name, phone, email, national ID or skill",
          },
          {
            name: "amount",
            label: "Amount (EGP)",
            type: "number",
            required: true,
            min: 1,
          },
          { name: "reference", label: "Collection reference", required: true },
        ]}
        onSubmit={async(v) => {
          const p = db.providers.find((item) => providerMatchesQuery(item, v.providerId, db.services));
          if (!p) return notify("No provider matches that search");
          await actions.createTransaction({
            type: "Cash collection",
            party: p.name,
            ownerId: p.id,
            amount: Number(v.amount),
            method: "Cash",
            status: "Completed",
            reference: v.reference,
          });
          notify("Cash collection recorded");
        }}
      />
      <FormDialog
        open={!!verify}
        onClose={() => setVerify(null)}
        title="Verify Instapay / transfer"
        fields={[
          { name: "reference", label: "Transfer reference", required: true },
        ]}
        submitLabel="Verify payout"
        onSubmit={(v) => verify && actions.verifyPayout(verify.id, v.reference)}
      />
    </div>
  );
}

function ServicesPage({ notify }: { notify: (s: string) => void }) {
  const { db, actions } = useAdminData();
  const [createOpen, setCreateOpen] = useState(false);
  const [categoryOpen, setCategoryOpen] = useState(false);
  const [editing, setEditing] = useState<Service | null>(null);
  const [deleting, setDeleting] = useState<Service | null>(null);
  const areaCount = new Set(db.services.flatMap((x) => x.areas)).size;
  const avg = db.services.length
    ? db.services.reduce((n, x) => n + x.commission, 0) / db.services.length
    : 0;
  return (
    <div className="space-y-5">
      <div className="grid gap-4 md:grid-cols-3">
        <StatBlock
          label="Active services"
          value={String(db.services.filter((x) => x.enabled).length)}
          icon={Wrench}
          tone="indigo"
        />
        <StatBlock
          label="Avg. commission"
          value={`${avg.toFixed(1)}%`}
          icon={BadgeDollarSign}
          tone="green"
        />
        <StatBlock
          label="Service areas"
          value={String(areaCount)}
          icon={MapPin}
          tone="amber"
        />
      </div>
      <div className="panel overflow-hidden">
        <PanelTitle
          title="Service catalog"
          subtitle="Pricing, fees, commission, and coverage"
          action={
            <div className="flex gap-2">
              <button
                onClick={() => setCategoryOpen(true)}
                className="btn-secondary"
              >
                <Plus className="h-3.5 w-3.5" />
                Category
              </button>
              <button
                onClick={() => setCreateOpen(true)}
                className="btn-primary"
              >
                <Plus className="h-3.5 w-3.5" />
                New service
              </button>
            </div>
          }
        />
        <div className="overflow-x-auto">
          <table className="w-full min-w-[740px]">
            <thead>
              <tr className="table-head">
                <th>Service</th>
                <th>Category</th>
                <th>Base price</th>
                <th>Commission</th>
                <th>Availability</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {db.services.map((s) => (
                <tr className="table-row" key={s.id}>
                  <td>
                    <div className="flex items-center gap-2">
                      <span className="grid h-8 w-8 place-items-center rounded-lg bg-indigo-500/10 text-indigo-400">
                        <Wrench className="h-3.5 w-3.5" />
                      </span>
                      <span className="font-medium text-zinc-200">
                        {s.name}
                      </span>
                    </div>
                  </td>
                  <td>
                    {db.categories.find((x) => x.id === s.categoryId)?.name ??
                      "Uncategorized"}
                  </td>
                  <td>EGP {s.basePrice.toLocaleString()}</td>
                  <td>{s.commission}%</td>
                  <td>{s.areas.length} areas</td>
                  <td>
                    <StatusBadge status={s.enabled ? "Active" : "Disabled"} />
                  </td>
                  <td>
                    <RowActions
                      label={`Actions for ${s.name}`}
                      actions={[
                        {
                          label: "Edit pricing & coverage",
                          onClick: () => setEditing(s),
                        },
                        {
                          label: s.enabled
                            ? "Disable service"
                            : "Enable service",
                          onClick: () => {
                            actions.toggleService(s.id);
                            notify(
                              `${s.name} ${s.enabled ? "disabled" : "enabled"}`,
                            );
                          },
                        },
                        {
                          label: "Delete service",
                          onClick: () => setDeleting(s),
                          danger: true,
                          separator: true,
                        },
                      ]}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Create service"
        description="Enabled services become available to customer and provider apps."
        fields={[
          { name: "name", label: "Service name", required: true },
          {
            name: "categoryId",
            label: "Category",
            type: "select",
            required: true,
            options: db.categories
              .filter((x) => x.enabled)
              .map((x) => ({ label: x.name, value: x.id })),
          },
          {
            name: "basePrice",
            label: "Base price (EGP)",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "imageUrl",
            label: "Service image URL (Firebase Storage or HTTPS)",
            required: true,
          },
          {
            name: "emergencyFee",
            label: "Emergency fee",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "inspectionFee",
            label: "Inspection fee",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "commission",
            label: "Platform commission %",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "areas",
            label: "Available areas (comma separated)",
            required: true,
          },
        ]}
        submitLabel="Create service"
        onSubmit={async(v) => {
          await actions.createService({
            name: v.name,
            categoryId: v.categoryId,
            imageUrl: v.imageUrl,
            basePrice: Number(v.basePrice),
            emergencyFee: Number(v.emergencyFee),
            inspectionFee: Number(v.inspectionFee),
            commission: Number(v.commission),
            areas: v.areas
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
          });
          notify("Service created");
        }}
      />
      <FormDialog
        open={categoryOpen}
        onClose={() => setCategoryOpen(false)}
        title="Create service category"
        fields={[
          { name: "name", label: "Category name", required: true },
          {
            name: "description",
            label: "Description",
            type: "textarea",
            required: true,
          },
        ]}
        onSubmit={(v) =>
          actions.createCategory({ name: v.name, description: v.description })
        }
      />
      <FormDialog
        open={!!editing}
        onClose={() => setEditing(null)}
        title={`Edit service · ${editing?.name ?? ""}`}
        fields={[
          {
            name: "basePrice",
            label: "Base price",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "imageUrl",
            label: "Service image URL (Firebase Storage or HTTPS)",
            required: true,
          },
          {
            name: "emergencyFee",
            label: "Emergency fee",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "inspectionFee",
            label: "Inspection fee",
            type: "number",
            required: true,
            min: 0,
          },
          {
            name: "commission",
            label: "Commission %",
            type: "number",
            required: true,
            min: 0,
          },
          { name: "cities", label: "Cities (comma separated)", required: true },
          { name: "areas", label: "Areas (comma separated)", required: true },
        ]}
        initial={
          editing
            ? {
                basePrice: editing.basePrice,
                imageUrl: editing.imageUrl ?? "",
                emergencyFee: editing.emergencyFee,
                inspectionFee: editing.inspectionFee,
                commission: editing.commission,
                cities: editing.cities.join(", "),
                areas: editing.areas.join(", "),
              }
            : {}
        }
        onSubmit={(v) =>
          editing &&
          actions.updateService(editing.id, {
            basePrice: Number(v.basePrice),
            imageUrl: v.imageUrl,
            emergencyFee: Number(v.emergencyFee),
            inspectionFee: Number(v.inspectionFee),
            commission: Number(v.commission),
            cities: v.cities
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
            areas: v.areas
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean),
          })
        }
      />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete service?"
        description="Existing jobs retain their service snapshot, but the service will no longer be bookable."
        onConfirm={() => deleting && actions.deleteService(deleting.id)}
      />
    </div>
  );
}

function PromotionsPage({ notify }: { notify: (s: string) => void }) {
  const { db, actions } = useAdminData();
  const [promoOpen, setPromoOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  return (
    <div className="space-y-5">
      <div className="grid gap-4 md:grid-cols-3">
        <StatBlock
          label="Promo redemptions"
          value={db.promos.reduce((n, x) => n + x.used, 0).toLocaleString()}
          icon={Gift}
          tone="indigo"
        />
        <StatBlock
          label="Attributed revenue"
          value={`EGP ${db.jobs.filter((job)=>job.payment?.promoCode).reduce((sum,job)=>sum+(job.payment?.amount??0),0).toLocaleString()}`}
          icon={TrendingUp}
          tone="green"
        />
        <StatBlock
          label="Campaign sends"
          value={db.notifications.filter((item)=>item.status==="Sent").length.toLocaleString()}
          icon={Megaphone}
          tone="amber"
        />
      </div>
      <div className="grid gap-5 xl:grid-cols-[1.25fr_.75fr]">
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Promo codes"
            subtitle="Manage offers and redemption rules"
            action={
              <button
                onClick={() => setPromoOpen(true)}
                className="btn-primary"
              >
                <Plus className="h-3.5 w-3.5" />
                Create promo
              </button>
            }
          />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[620px]">
              <thead>
                <tr className="table-head">
                  <th>Code</th>
                  <th>Offer</th>
                  <th>Redemptions</th>
                  <th>Ends</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {db.promos.map((p) => (
                  <tr className="table-row" key={p.id}>
                    <td>
                      <span className="rounded bg-white/[.05] px-2 py-1 font-mono text-[10px] font-semibold text-indigo-400">
                        {p.code}
                      </span>
                    </td>
                    <td>{p.description}</td>
                    <td>
                      {p.used.toLocaleString()} / {p.maxUses.toLocaleString()}
                    </td>
                    <td>{new Date(p.endsAt).toLocaleDateString()}</td>
                    <td>
                      <StatusBadge status={p.enabled ? "Active" : "Disabled"} />
                    </td>
                    <td>
                      <RowActions
                        actions={[
                          {
                            label: p.enabled ? "Disable promo" : "Enable promo",
                            onClick: () =>
                              actions.updatePromo(p.id, {
                                enabled: !p.enabled,
                              }),
                          },
                          {
                            label: "Delete promo",
                            onClick: () => actions.deletePromo(p.id),
                            danger: true,
                          },
                        ]}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
        <div className="panel p-5">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-sm font-semibold">Push composer</div>
              <div className="mt-1 text-[10px] text-zinc-600">
                Reach customers in real time
              </div>
            </div>
            <Megaphone className="h-5 w-5 text-indigo-400" />
          </div>
          <label className="mt-6 block text-[10px] font-medium text-zinc-500">
            Campaign title
          </label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="input mt-2 w-full"
            placeholder="Weekend offer"
          />
          <label className="mt-4 block text-[10px] font-medium text-zinc-500">
            Message
          </label>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="input mt-2 min-h-24 w-full resize-none py-2"
            placeholder="Write your notification..."
          />
          <div className="mt-4 flex items-center justify-between text-[10px] text-zinc-600">
            <span>Estimated reach</span>
            <span className="text-zinc-300">{db.customers.length.toLocaleString()} customers</span>
          </div>
          <button
            disabled={!title.trim() || !message.trim()}
            onClick={() => {
              actions.createNotification({
                title,
                body: message,
                audience: "All customers",
              });
              setTitle("");
              setMessage("");
              notify("Push notification sent");
            }}
            className="btn-primary mt-4 w-full justify-center"
          >
            <Zap className="h-3.5 w-3.5" />
            Schedule campaign
          </button>
        </div>
      </div>
      <FormDialog
        open={promoOpen}
        onClose={() => setPromoOpen(false)}
        title="Create promo code"
        fields={[
          { name: "code", label: "Promo code", required: true },
          { name: "description", label: "Offer description", required: true },
          {
            name: "discountType",
            label: "Discount type",
            type: "select",
            required: true,
            options: [
              { label: "Percentage", value: "percent" },
              { label: "Fixed EGP", value: "fixed" },
            ],
          },
          {
            name: "discount",
            label: "Discount value",
            type: "number",
            required: true,
            min: 1,
          },
          {
            name: "maxUses",
            label: "Maximum uses",
            type: "number",
            required: true,
            min: 1,
          },
          {
            name: "endsAt",
            label: "End date (ISO)",
            required: true,
            placeholder: "2026-12-31T23:59:59Z",
          },
        ]}
        submitLabel="Create promo"
        onSubmit={async(v) => {
          await actions.createPromo({
            code: v.code.toUpperCase(),
            description: v.description,
            discountType: v.discountType as "percent" | "fixed",
            discount: Number(v.discount),
            maxUses: Number(v.maxUses),
            endsAt: v.endsAt,
            enabled: true,
          });
          notify("Promo code created");
        }}
      />
    </div>
  );
}

function AnalyticsPage() {
  const{db}=useAdminData();const revenueData=revenueSeries(db.jobs);const serviceData=serviceSeries(db.jobs);
  const revenue=db.jobs.reduce((sum,item)=>sum+(item.payment?.status==="Paid"?item.payment.amount:0),0);const completed=db.jobs.filter((item)=>item.status==="Completed").length;
  return (
    <div className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatBlock
          label="Revenue"
          value={`EGP ${revenue.toLocaleString()}`}
          icon={Banknote}
          tone="indigo"
        />
        <StatBlock
          label="Bookings"
          value={db.jobs.length.toLocaleString()}
          icon={BriefcaseBusiness}
          tone="green"
        />
        <StatBlock
          label="Completion rate"
          value={`${db.jobs.length?((completed/db.jobs.length)*100).toFixed(1):0}%`}
          icon={CheckCircle2}
          tone="green"
        />
        <StatBlock
          label="Customer retention"
          value={`${db.customers.length?((db.customers.filter((customer)=>customer.bookings>1).length/db.customers.length)*100).toFixed(1):0}%`}
          icon={RefreshCcw}
          tone="amber"
        />
      </div>
      <div className="grid gap-5 xl:grid-cols-[1.4fr_.6fr]">
        <div className="panel">
          <PanelTitle
            title="Revenue & bookings"
            subtitle="Last 7 days"
            action={<FilterButton label="7 days" />}
          />
          <div className="h-[320px] p-4">
            <ResponsiveContainer>
              <AreaChart data={revenueData}>
                <defs>
                  <linearGradient id="analytics" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0" stopColor="#6976ff" stopOpacity=".32" />
                    <stop offset="1" stopColor="#6976ff" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  vertical={false}
                  stroke="hsl(var(--border))"
                  strokeDasharray="3 3"
                />
                <XAxis
                  dataKey="day"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: "#71717a", fontSize: 10 }}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: "#71717a", fontSize: 10 }}
                  tickFormatter={(v) => `${v / 1000}k`}
                />
                <Tooltip content={<ChartTooltip />} />
                <Area
                  dataKey="revenue"
                  type="monotone"
                  stroke="#6976ff"
                  strokeWidth={2}
                  fill="url(#analytics)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="panel">
          <PanelTitle title="Top services" subtitle="Share of bookings" />
          {serviceData.length ? (
            <>
              <div className="h-[210px] p-2">
                <ResponsiveContainer>
                  <PieChart>
                    <Pie
                      data={serviceData}
                      innerRadius={55}
                      outerRadius={78}
                      paddingAngle={4}
                      dataKey="value"
                      stroke="none"
                    >
                      {serviceData.map((s) => (
                        <Cell key={s.name} fill={s.color} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{
                        background: "hsl(var(--popover))",
                        color: "hsl(var(--popover-foreground))",
                        border: "1px solid hsl(var(--border))",
                        borderRadius: 8,
                        fontSize: 11,
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="space-y-2 px-5 pb-5">
                {serviceData.map((s) => (
                  <div key={s.name} className="flex items-center text-[10px]">
                    <i
                      className="mr-2 h-2 w-2 rounded-full"
                      style={{ background: s.color }}
                    />
                    <span className="flex-1 text-zinc-500">{s.name}</span>
                    <span>{s.value}%</span>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <div className="p-4">
              <EmptyState title="No service bookings" body="Service shares will appear after real jobs are created in Firestore." />
            </div>
          )}
        </div>
      </div>
      <div className="grid gap-5 lg:grid-cols-2">
        <MiniBarChart />
        <CancellationPanel />
      </div>
    </div>
  );
}

function MiniBarChart() {
  const{db}=useAdminData();const counts=new Map<string,number>();db.jobs.forEach((job)=>counts.set(job.area,(counts.get(job.area)??0)+1));const data=[...counts].map(([name,v])=>({name,v})).sort((a,b)=>b.v-a.v).slice(0,5);
  return (
    <div className="panel">
      <PanelTitle title="Top service areas" subtitle="Bookings this week" />
      {data.length ? (
        <div className="h-[250px] p-4">
          <ResponsiveContainer>
            <BarChart data={data} layout="vertical">
              <CartesianGrid horizontal={false} stroke="hsl(var(--border))" />
              <XAxis type="number" hide />
              <YAxis
                dataKey="name"
                type="category"
                axisLine={false}
                tickLine={false}
                width={72}
                tick={{ fill: "#71717a", fontSize: 9 }}
              />
              <Tooltip
                contentStyle={{
                  background: "hsl(var(--popover))",
                  color: "hsl(var(--popover-foreground))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: 8,
                  fontSize: 11,
                }}
              />
              <Bar
                dataKey="v"
                fill="#6976ff"
                radius={[0, 4, 4, 0]}
                barSize={13}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      ) : (
        <div className="p-4">
          <EmptyState title="No service areas" body="Top areas will appear after real jobs are created in Firestore." />
        </div>
      )}
    </div>
  );
}
function CancellationPanel() {
  const{db}=useAdminData();const cancelled=db.jobs.filter((job)=>job.cancellation);const counts=new Map<string,number>();cancelled.forEach((job)=>counts.set(job.cancellation!.reason,(counts.get(job.cancellation!.reason)??0)+1));const reasons=[...counts].sort((a,b)=>b[1]-a[1]).slice(0,5);const colors=["bg-red-400","bg-amber-400","bg-indigo-400","bg-cyan-400","bg-zinc-500"];
  return (
    <div className="panel">
      <PanelTitle
        title="Cancellation reasons"
        subtitle={`${db.jobs.length?((cancelled.length/db.jobs.length)*100).toFixed(1):0}% overall cancellation rate`}
      />
      <div className="space-y-4 p-5">
        {reasons.length ? reasons.map(([a,count],index) => {const b=`${cancelled.length?Math.round(count/cancelled.length*100):0}%`;const c=colors[index];return(
          <div key={a}>
            <div className="mb-1.5 flex justify-between text-[10px]">
              <span className="text-zinc-500">{a}</span>
              <span>{b}</span>
            </div>
            <div className="h-1.5 rounded-full bg-white/[.04]">
              <div
                className={cn("h-full rounded-full", c)}
                style={{ width: b }}
              />
            </div>
          </div>
        )}) : (
          <EmptyState title="No cancellations" body="Cancellation analytics will appear when real cancelled requests exist." />
        )}
      </div>
    </div>
  );
}

function revenueSeries(jobs:Job[]){const days=Array.from({length:7},(_,index)=>{const date=new Date();date.setHours(0,0,0,0);date.setDate(date.getDate()-(6-index));return date});return days.map((date)=>{const next=new Date(date);next.setDate(next.getDate()+1);const rows=jobs.filter((job)=>{const created=new Date(job.createdAt);return created>=date&&created<next});return{day:date.toLocaleDateString("en",{weekday:"short"}),revenue:rows.reduce((sum,job)=>sum+(job.payment?.status==="Paid"?job.payment.amount:0),0),bookings:rows.length}})}
function serviceSeries(jobs:Job[]){const counts=new Map<string,number>();jobs.forEach((job)=>counts.set(job.service,(counts.get(job.service)??0)+1));const colors=["#6976ff","#22c55e","#f59e0b","#06b6d4","#a855f7"];const total=Math.max(1,jobs.length);return[...counts].sort((a,b)=>b[1]-a[1]).slice(0,5).map(([name,count],index)=>({name,value:Math.round(count/total*100),color:colors[index]}))}
function toDateTimeLocal(value?: string) { if (!value) return ""; const date = new Date(value); if (!Number.isFinite(date.getTime())) return ""; return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16); }
function fromDateTimeLocal(value?: string) { if (!value) return ""; const date = new Date(value); return Number.isFinite(date.getTime()) ? date.toISOString() : ""; }
function demoExpiryInfo(value?: string) { if (!value) return null; const time = new Date(value).getTime(); if (!Number.isFinite(time)) return null; const ms = time - Date.now(); return { expired: ms <= 0, days: Math.ceil(ms / 86_400_000), label: new Date(value).toLocaleString() }; }
function effectiveInvitationStatus(invite?: { status?: string; expiresAt?: string }) {
  if (!invite) return "No invitation";
  if (invite.status === "Pending" && invite.expiresAt) {
    const expires = new Date(invite.expiresAt).getTime();
    if (Number.isFinite(expires) && expires <= Date.now()) return "Expired";
  }
  return invite.status || "Pending";
}
function invitationDate(value?: string) {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date.toLocaleString() : "—";
}

function AdminPage({ notify }: { notify: (s: string) => void }) {
  const { db, actions, error, loading } = useAdminData();
  const { user } = useAuth();
  const { can } = usePermissions();
  const [tab, setTab] = useState<"users" | "invitations" | "roles" | "audit">(
    "users",
  );
  const [createOpen, setCreateOpen] = useState(false);
  const [roleOpen, setRoleOpen] = useState(false);
  const [editingRole, setEditingRole] = useState<(typeof db.roles)[number] | null>(null);
  const [deletingRole, setDeletingRole] = useState<(typeof db.roles)[number] | null>(null);
  const [editingAdmin, setEditingAdmin] = useState<AdminUser | null>(null);
  const [manualInvitation, setManualInvitation] = useState<{
    email: string;
    setupLink: string;
    instructions: string;
    expiresAt?: string;
  } | null>(null);
  const [demoFilter, setDemoFilter] = useState<"all" | "real" | "demo" | "expired">("all");
  const [authSyncAttempted, setAuthSyncAttempted] = useState(false);
  const [deleting, setDeleting] = useState<(typeof db.admins)[number] | null>(
    null,
  );
  const visibleAdminTabs = useMemo(
    () =>
      [
        can("adminUsers.view") && { id: "users" as const, label: "Admin users" },
        can("invitations.view") && { id: "invitations" as const, label: "Invitation center" },
        can("roles.view") && { id: "roles" as const, label: "Roles & permissions" },
        can("audit.view") && { id: "audit" as const, label: "Audit log" },
      ].filter(Boolean) as Array<{ id: "users" | "invitations" | "roles" | "audit"; label: string }>,
    [can],
  );
  const filteredAdmins = db.admins.filter((admin) => {
    const expired = Boolean(admin.isDemoUser && admin.demoExpiresAt && new Date(admin.demoExpiresAt).getTime() <= Date.now());
    if (demoFilter === "real") return !admin.isDemoUser;
    if (demoFilter === "demo") return Boolean(admin.isDemoUser) && !expired;
    if (demoFilter === "expired") return expired;
    return true;
  });
  const invitationForAdmin = useCallback((admin: AdminUser) => {
    const email = String(admin.email ?? "").toLowerCase();
    return db.invitations.find(
      (invite) =>
        invite.adminId === admin.id ||
        invite.id === admin.id ||
        String(invite.email ?? "").toLowerCase() === email,
      );
  }, [db.invitations]);
  const handleInvitationResult = useCallback((result: { invitationEmail?: { setupLink?: string; instructions?: string; expiresAt?: string } }, email: string) => {
    if (result.invitationEmail?.setupLink) {
      throw new Error(`Invitation email was not sent to ${email}. Configure Resend in API Center or environment settings and try again.`);
    }
    setManualInvitation(null);
    notify("Invitation email sent through Resend");
  }, [notify]);
  useEffect(() => {
    console.info("[Task Admin Users] render state", {
      currentAdmin: user
        ? {
            id: user.id,
            uid: user.uid,
            email: user.email,
            role: user.role,
            roleId: user.roleId,
            status: user.status,
            isDemoUser: user.isDemoUser,
            permissionsCount: user.permissions?.length ?? 0,
            superAdminBypass: isSuperAdminRole(user.role),
          }
        : null,
      loading,
      error,
      collection: "admins",
      dbAdminsCount: db.admins.length,
      filteredAdminsCount: filteredAdmins.length,
      demoFilter,
      roleCount: db.roles.length,
    });
  }, [db.admins.length, db.roles.length, demoFilter, error, filteredAdmins.length, loading, user]);
  useEffect(() => {
    const canSync =
      can("users.sync") ||
      isSuperAdminRole(user?.role) ||
      user?.roleId === "super-admin" ||
      user?.roleId === "super_admin";
    if (
      tab !== "users" ||
      loading ||
      authSyncAttempted ||
      db.admins.length > 0 ||
      !canSync
    )
      return;
    setAuthSyncAttempted(true);
    console.info("[Task Admin Users] admins collection empty; starting safe Firebase Auth sync");
    actions
      .syncAuthUsers()
      .then((result) => {
        const created = (result as { created?: string[] })?.created?.length ?? 0;
        console.info("[Task Admin Users] Firebase Auth sync finished", { created });
        if (created > 0) notify(`Synced ${created} Firebase Auth user(s)`);
      })
      .catch((reason) => {
        console.error("[Task Admin Users] Firebase Auth sync failed", reason);
      });
  }, [actions, authSyncAttempted, can, db.admins.length, loading, notify, tab, user?.role, user?.roleId]);
  useEffect(() => {
    if (visibleAdminTabs.length && !visibleAdminTabs.some((item) => item.id === tab))
      setTab(visibleAdminTabs[0].id);
  }, [tab, visibleAdminTabs]);
  return (
    <div className="space-y-5">
      <div className="flex gap-1 rounded-lg border border-white/[.06] bg-white/[.02] p-1 w-fit">
        {visibleAdminTabs.map((item) => (
          <button
            key={item.id}
            onClick={() => setTab(item.id)}
            className={cn(
              "rounded-md px-3 py-1.5 text-[11px]",
              tab === item.id ? "bg-white/[.08]" : "text-zinc-500",
            )}
          >
            {item.label}
          </button>
        ))}
      </div>
      {tab === "users" && (
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Admin users"
            subtitle={`${filteredAdmins.length} shown · ${db.admins.length} users across ${db.roles.length} roles`}
            action={
              <div className="flex gap-2">
                {can("settings.edit") && !user?.isDemoUser && <button
                  onClick={async () => {
                    await actions.resetDemoData();
                    notify("Demo workspace reset with realistic data");
                  }}
                  className="btn-secondary"
                >
                  <RefreshCcw className="h-3.5 w-3.5" />
                  Reset demo data
                </button>}
                {can("users.sync") && <button
                  onClick={async () => {
                    const result = (await actions.syncAuthUsers()) as {
                      created?: string[];
                    };
                    notify(
                      `Synced ${result.created?.length ?? 0} Firebase Auth user(s)`,
                    );
                  }}
                  className="btn-secondary"
                >
                  <RefreshCcw className="h-3.5 w-3.5" />
                  Sync Auth users
                </button>}
                {(can("users.invite") || can("users.create")) && (
                  <button
                    onClick={() => setCreateOpen(true)}
                    className="btn-primary"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    Invite admin
                  </button>
                )}
              </div>
            }
          />
          <div className="flex flex-wrap gap-2 border-b border-white/[.06] px-4 pb-4">
            {[
              ["all", "All"],
              ["real", "Real Users"],
              ["demo", "Demo Users"],
              ["expired", "Expired Demo Users"],
            ].map(([value, label]) => (
              <button
                key={value}
                onClick={() => setDemoFilter(value as typeof demoFilter)}
                className={cn(
                  "rounded-lg border px-3 py-1.5 text-[11px]",
                  demoFilter === value
                    ? "border-indigo-400/30 bg-indigo-500/15 text-indigo-200"
                    : "border-white/[.07] bg-white/[.025] text-zinc-500 hover:text-zinc-200",
                )}
              >
                {label}
              </button>
            ))}
          </div>
          {error && (
            <div className="mx-4 mb-4 rounded-xl border border-red-500/20 bg-red-500/10 p-3 text-xs text-red-200">
              Users could not be loaded from Firestore: {error}
            </div>
          )}
          {manualInvitation && (
            <div className="mx-4 mb-4 rounded-xl border border-amber-400/25 bg-amber-400/10 p-4 text-xs text-amber-100">
              <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                <div className="min-w-0">
                  <div className="font-semibold text-amber-200">Invitation email was not sent</div>
                  <p className="mt-1 text-amber-100/80">{manualInvitation.instructions}</p>
                  <p className="mt-2 truncate rounded-lg border border-amber-400/20 bg-black/20 px-3 py-2 font-mono text-[10px] text-amber-50">
                    {manualInvitation.setupLink}
                  </p>
                  {manualInvitation.expiresAt && (
                    <p className="mt-1 text-[10px] text-amber-200/80">
                      Expires {new Date(manualInvitation.expiresAt).toLocaleString()}
                    </p>
                  )}
                </div>
                <div className="flex shrink-0 gap-2">
                  <button
                    className="btn-secondary"
                    onClick={async () => {
                      await navigator.clipboard.writeText(manualInvitation.setupLink);
                      notify("Activation link copied");
                    }}
                  >
                    <Check className="h-3.5 w-3.5" />
                    Copy Link
                  </button>
                  <button className="btn-secondary" onClick={() => setManualInvitation(null)}>
                    Dismiss
                  </button>
                </div>
              </div>
            </div>
          )}
          {!loading && db.admins.length === 0 && (
            <div className="mx-4 mb-4 rounded-xl border border-amber-400/20 bg-amber-400/10 p-4">
              <EmptyState
                title="No admin profiles returned"
                body="Firestore returned zero documents from the admins collection. If users exist only in Firebase Authentication, use Sync Auth users to create safe disabled admin profiles."
              />
            </div>
          )}
          {!loading && db.admins.length > 0 && filteredAdmins.length === 0 && (
            <div className="mx-4 mb-4 rounded-xl border border-white/[.07] bg-white/[.025] p-4">
              <EmptyState
                title="No users match the active filters"
                body="The admins collection loaded successfully, but the current Demo User filter hides every row. Switch the filter to All to see every admin."
              />
            </div>
          )}
          <div className="overflow-x-auto">
              <table className="w-full min-w-[1250px]">
                <thead>
                  <tr className="table-head">
                    <th>User</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Invitation Status</th>
                    <th>Sent At</th>
                    <th>Expires At</th>
                    <th>Accepted At</th>
                    <th>Last Resent At</th>
                    <th>Resend Count</th>
                    <th>Last active</th>
                    <th>2FA</th>
                    <th />
                </tr>
              </thead>
              <tbody>
                {filteredAdmins.map((a) => {
                  const displayName = a.name || a.email || a.id || "Unknown user";
                  const initials = displayName
                    .split(" ")
                    .filter(Boolean)
                    .map((x) => x[0])
                    .join("")
                    .slice(0, 2)
                    .toUpperCase() || "AD";
                  const roleLabel = a.role || "No role assigned";
                  const status = a.status || (a.enabled === false || a.authDisabled ? "Disabled" : "Active");
                  const invite = invitationForAdmin(a);
                  const inviteStatus = effectiveInvitationStatus(invite);
                  return (
                  <tr key={a.id} className="table-row">
                    <td>
                      <div className="flex items-center gap-2">
                        <Avatar
                          initials={initials}
                        />
                        <div>
                          <div className="font-medium text-zinc-200">
                            {displayName}
                            {a.isDemoUser && (
                              <span className="ml-2 rounded-full bg-amber-400/10 px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-wide text-amber-300">
                                Demo
                              </span>
                            )}
                          </div>
                          <div className="text-[9px] text-zinc-600">
                            {a.email || "No email on profile"}
                          </div>
                          {a.isDemoUser && a.demoExpiresAt && (() => {
                            const info = demoExpiryInfo(a.demoExpiresAt);
                            if (!info) return null;
                            const urgent = info.expired || info.days <= 1;
                            const soon = info.days <= 3;
                            const visible = info.expired || info.days <= 7;
                            if (!visible) return <div className="mt-1 text-[9px] text-zinc-600">Demo expires {info.label}</div>;
                            return (
                              <div className={cn("mt-1 w-fit rounded-full px-1.5 py-0.5 text-[8px]", urgent ? "bg-red-500/10 text-red-300" : soon ? "bg-orange-500/10 text-orange-300" : "bg-amber-400/10 text-amber-300")}>
                                {info.expired ? "Demo expired" : `Demo expires in ${info.days} day${info.days === 1 ? "" : "s"}`}
                              </div>
                            );
                          })()}
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className="rounded bg-indigo-500/10 px-2 py-1 text-[10px] text-indigo-400">
                        {roleLabel}
                      </span>
                    </td>
                    <td>
                      <StatusBadge status={status} />
                    </td>
                    <td>
                      <div className="flex flex-col gap-1">
                        <StatusBadge status={inviteStatus} />
                      </div>
                    </td>
                    <td className="text-[10px] text-zinc-500">{invitationDate(invite?.emailSentAt)}</td>
                    <td className="text-[10px] text-zinc-500">{invitationDate(invite?.expiresAt)}</td>
                    <td className="text-[10px] text-zinc-500">{invitationDate(invite?.acceptedAt)}</td>
                    <td className="text-[10px] text-zinc-500">{invitationDate(invite?.lastResentAt ?? invite?.resentAt)}</td>
                    <td>{invite?.resendCount ?? 0}</td>
                    <td>{a.lastSeen || "Never"}</td>
                    <td>
                      <span className="flex items-center gap-1 text-[10px] text-emerald-400">
                        <ShieldCheck className="h-3.5 w-3.5" />
                        {a.twoFactorEnabled ? "Enabled" : "Disabled"}
                      </span>
                    </td>
                    <td>
                      <RowActions
                        label={`Actions for ${displayName}`}
                        actions={[
                          ...(can("users.edit") ? [{
                            label: "Edit administrator",
                            onClick: () => setEditingAdmin(a),
                          }] : []),
                          ...(can("users.edit") && a.isDemoUser ? [{
                            label: "Extend demo 7 days",
                            onClick: async () => {
                              await actions.updateAdmin(a.id, {
                                demoExpiresAt: new Date(Date.now() + 7 * 86_400_000).toISOString(),
                                isDemoUser: true,
                              });
                              notify("Demo extended by 7 days");
                            },
                          }] : []),
                          ...((can("users.invite") || can("invitations.resend") || can("users.create")) && invite && ["Pending", "Expired"].includes(inviteStatus) ? [{
                            label: "Resend invitation",
                            onClick: async () => {
                              const result = await actions.resendInvitation(invite.id) as { invitationEmail?: { setupLink?: string; instructions?: string; expiresAt?: string } };
                              handleInvitationResult(result, a.email || displayName);
                            },
                          }] : []),
                          ...(can("users.change_status") ? [{
                            label:
                              a.status === "Disabled" || a.enabled === false || a.authDisabled
                                ? "Enable user"
                                : "Disable user",
                            onClick: () => actions.toggleAdmin(a.id),
                          }] : []),
                          ...(can("users.delete") ? [{
                            label: "Delete admin",
                            onClick: () => setDeleting(a),
                            danger: true,
                          }] : []),
                        ]}
                      />
                    </td>
                  </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
      {tab === "roles" && (
        <div className="panel">
          <PanelTitle
            title="Roles & permissions"
            subtitle="Access policies enforced at UI and API boundaries"
            action={
              can("roles.create") ? (
                <button onClick={() => setRoleOpen(true)} className="btn-primary">
                  <Plus className="h-3.5 w-3.5" />
                  Create role
                </button>
              ) : null
            }
          />
          <div className="grid gap-3 p-4 md:grid-cols-2">
            {db.roles.map((role) => (
              <div
                key={role.id}
                className="rounded-xl border border-white/[.07] bg-white/[.02] p-4"
              >
                <div className="flex items-center justify-between">
                  <b className="text-sm">{role.name}</b>
                  <div className="flex items-center gap-2">
                    <Badge variant={role.system ? "secondary" : "default"}>
                      {role.system ? "System" : "Custom"}
                    </Badge>
                    {(can("roles.edit") || can("roles.delete")) && (
                      <RowActions
                        label={`Role actions for ${role.name}`}
                        actions={[
                          ...(can("roles.edit") ? [{
                            label: "Edit permissions",
                            onClick: () => setEditingRole(role),
                          }] : []),
                          ...(can("roles.delete") && !role.system && role.name !== "Super admin" ? [{
                            label: "Delete role",
                            danger: true,
                            onClick: () => setDeletingRole(role),
                          }] : []),
                        ]}
                      />
                    )}
                  </div>
                </div>
                <p className="mt-2 text-[11px] text-zinc-500">
                  {role.description}
                </p>
                <div className="mt-3 flex flex-wrap gap-1">
                  {role.permissions.map((p) => (
                    <span
                      key={p}
                      className="rounded bg-white/[.05] px-1.5 py-1 text-[8px] text-zinc-500"
                    >
                      {p}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      {tab === "invitations" && (
        <div className="panel overflow-hidden">
          <PanelTitle
            title="Invitation center"
            subtitle={`${db.invitations.filter((x) => x.status === "Pending").length} pending dashboard invitations`}
            action={
              (can("users.invite") || can("users.create")) ? (
                <button
                  onClick={() => setCreateOpen(true)}
                  className="btn-primary"
                >
                  <Plus className="h-3.5 w-3.5" />
                  Invite admin
                </button>
              ) : null
            }
          />
          {db.invitations.length ? (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[1200px]">
                <thead>
                  <tr className="table-head">
                    <th>Email</th>
                    <th>Role</th>
                    <th>Invited by</th>
                    <th>Status</th>
                    <th>Email delivery</th>
                    <th>Created</th>
                    <th>Sent At</th>
                    <th>Expires</th>
                    <th>Accepted At</th>
                    <th>Last Resent At</th>
                    <th>Resend Count</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {db.invitations.map((invite) => {
                    const status = effectiveInvitationStatus(invite);
                    return (
                    <tr key={invite.id} className="table-row">
                      <td>
                        <div className="font-medium text-zinc-200">
                          {invite.email}
                        </div>
                        <div className="text-[9px] text-zinc-600">
                          {invite.id}
                        </div>
                      </td>
                      <td>{invite.roleName}</td>
                      <td>{invite.invitedBy}</td>
                      <td>
                        <StatusBadge status={status} />
                      </td>
                      <td>
                        <div className="flex flex-col gap-1">
                          <StatusBadge
                            status={invite.emailDeliveryStatus ?? "Pending"}
                          />
                          {invite.emailSentAt && (
                            <span className="text-[9px] text-zinc-600">
                              {new Date(invite.emailSentAt).toLocaleString()}
                            </span>
                          )}
                          {invite.lastEmailError && (
                            <span className="max-w-[220px] truncate text-[9px] text-red-400">
                              {invite.lastEmailError}
                            </span>
                          )}
                        </div>
                      </td>
                      <td>{invitationDate(invite.createdAt)}</td>
                      <td>{invitationDate(invite.emailSentAt)}</td>
                      <td>{invitationDate(invite.expiresAt)}</td>
                      <td>{invitationDate(invite.acceptedAt)}</td>
                      <td>
                        <div className="flex flex-col text-[10px] text-zinc-500">
                          <span>{invitationDate(invite.lastResentAt ?? invite.resentAt)}</span>
                          {invite.lastResentBy && <span>by {invite.lastResentBy}</span>}
                        </div>
                      </td>
                      <td>{invite.resendCount ?? 0}</td>
                      <td>
                        <RowActions
                          label={`Invitation actions for ${invite.email}`}
                          actions={[
                            ...((can("users.invite") || can("invitations.resend") || can("users.create")) && ["Pending", "Expired"].includes(status) ? [{
                              label: "Resend invitation",
                              onClick: async () => {
                                const result = await actions.resendInvitation(invite.id) as { invitationEmail?: { setupLink?: string; instructions?: string; expiresAt?: string } };
                                handleInvitationResult(result, invite.email);
                              },
                            }] : []),
                            ...(
                              status === "Accepted" || status === "Revoked"
                                ? []
                                : [{
                              label: "Revoke invitation",
                              danger: true,
                              onClick: async () => {
                                await actions.revokeInvitation(invite.id);
                                notify("Invitation revoked");
                              },
                            }]
                            ),
                          ]}
                        />
                      </td>
                    </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          ) : (
            <EmptyState
              title="No invitations yet"
              body="Invite an administrator to create the first pending invitation."
            />
          )}
        </div>
      )}
      {tab === "audit" && (
        <div className="panel">
          <PanelTitle
            title="Recent audit activity"
            subtitle="Immutable record of administrative actions"
          />
          <div className="divide-y divide-white/[.05]">
            {db.auditLogs.map((x) => (
              <div key={x.id} className="flex items-center gap-3 px-4 py-3">
                <span className="grid h-7 w-7 place-items-center rounded-full bg-white/[.04] text-[9px] text-zinc-500">
                  {x.actorName
                    .split(" ")
                    .map((y) => y[0])
                    .join("")}
                </span>
                <div className="flex-1 text-[11px]">
                  <span className="font-medium">{x.actorName}</span>{" "}
                  <span className="text-zinc-500">{x.detail}</span>
                </div>
                <span className="text-[9px] text-zinc-700">
                  {new Date(x.createdAt).toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Invite dashboard user"
        initial={{ isDemoUser: "false" }}
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "email", label: "Work email", type: "email", required: true },
          { name: "phone", label: "Phone (optional)", type: "tel" },
          { name: "department", label: "Department", required: true },
          {
            name: "roleId",
            label: "Role",
            type: "select",
            required: true,
            options: db.roles.map((x) => ({ label: x.name, value: x.id })),
          },
          {
            name: "isDemoUser",
            label: "Demo User",
            type: "select",
            required: true,
            options: [
              { label: "False", value: "false" },
              { label: "True", value: "true" },
            ],
          },
          { name: "demoExpiresAt", label: "Demo expires at", type: "datetime-local", showWhen: { field: "isDemoUser", value: "true" } },
          { name: "demoCompanyName", label: "Demo company/prospect", showWhen: { field: "isDemoUser", value: "true" } },
          { name: "demoContactName", label: "Demo contact name", showWhen: { field: "isDemoUser", value: "true" } },
          { name: "demoNotes", label: "Demo notes", type: "textarea", showWhen: { field: "isDemoUser", value: "true" } },
        ]}
        submitLabel="Send invitation"
        onSubmit={async (v) => {
          const role=db.roles.find((item)=>item.id===v.roleId);if(!role)throw new Error("Role not found");const isDemo=v.isDemoUser==="true";const result=await actions.createAdmin({name:v.name,email:v.email,phone:v.phone||undefined,department:v.department,roleId:v.roleId,role:role.name as AdminUser["role"],isDemoUser:isDemo,demoExpiresAt:isDemo?fromDateTimeLocal(v.demoExpiresAt):"",demoCompanyName:isDemo?v.demoCompanyName||undefined:"",demoContactName:isDemo?v.demoContactName||undefined:"",demoNotes:isDemo?v.demoNotes||undefined:""}) as AdminUser & { invitationEmail?: { provider?: string; setupLink?: string; instructions?: string; expiresAt?: string; error?: string } };handleInvitationResult(result,v.email)
        }}
      />
      <FormDialog
        open={!!editingAdmin}
        onClose={() => setEditingAdmin(null)}
        title={`Edit administrator · ${editingAdmin?.name ?? ""}`}
        initial={editingAdmin?{name:editingAdmin.name,email:editingAdmin.email,phone:editingAdmin.phone??"",department:editingAdmin.department??"",jobTitle:editingAdmin.jobTitle??"",roleId:editingAdmin.roleId,isDemoUser:String(Boolean(editingAdmin.isDemoUser)),demoExpiresAt:toDateTimeLocal(editingAdmin.demoExpiresAt),demoCompanyName:editingAdmin.demoCompanyName??"",demoContactName:editingAdmin.demoContactName??"",demoNotes:editingAdmin.demoNotes??""}:{}}
        fields={[
          { name: "name", label: "Full name", required: true },
          { name: "email", label: "Work email", type: "email", required: true },
          { name: "phone", label: "Phone", type: "tel" },
          { name: "department", label: "Department", required: true },
          { name: "jobTitle", label: "Job title", required: true },
          { name: "roleId", label: "Role", type: "select", required: true, options: db.roles.map((role)=>({label:role.name,value:role.id})) },
          { name: "isDemoUser", label: "Demo User", type: "select", required: true, options: [{label:"False",value:"false"},{label:"True",value:"true"}] },
          { name: "demoExpiresAt", label: "Demo expires at", type: "datetime-local", showWhen: { field: "isDemoUser", value: "true" } },
          { name: "demoCompanyName", label: "Demo company/prospect", showWhen: { field: "isDemoUser", value: "true" } },
          { name: "demoContactName", label: "Demo contact name", showWhen: { field: "isDemoUser", value: "true" } },
          { name: "demoNotes", label: "Demo notes", type: "textarea", showWhen: { field: "isDemoUser", value: "true" } },
        ]}
        submitLabel="Save administrator"
        onSubmit={async(values)=>{if(!editingAdmin)return;const isDemo=values.isDemoUser==="true";await actions.updateAdmin(editingAdmin.id,{name:values.name,email:values.email,phone:values.phone,department:values.department,jobTitle:values.jobTitle,roleId:values.roleId,isDemoUser:isDemo,demoExpiresAt:isDemo?fromDateTimeLocal(values.demoExpiresAt):"",demoCompanyName:isDemo?values.demoCompanyName:"",demoContactName:isDemo?values.demoContactName:"",demoNotes:isDemo?values.demoNotes:""});notify("Firebase administrator updated")}}
      />
      <RolePermissionDialog
        open={roleOpen}
        mode="create"
        onClose={() => setRoleOpen(false)}
        onSubmit={async (values) => {
          await actions.createRole(values);
          notify("Role created with structured permissions");
        }}
      />
      <RolePermissionDialog
        open={!!editingRole}
        mode="edit"
        role={editingRole ?? undefined}
        onClose={() => setEditingRole(null)}
        onSubmit={async (values) => {
          if (!editingRole) return;
          await actions.updateRole(editingRole.id, values);
          notify("Role permissions updated");
        }}
      />
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        title="Delete admin user?"
        description="The user immediately loses dashboard access. Their audit history is retained."
        onConfirm={() => deleting && actions.deleteAdmin(deleting.id)}
      />
      <ConfirmDialog
        open={!!deletingRole}
        onClose={() => setDeletingRole(null)}
        title="Delete role?"
        description="This is blocked automatically if any admin is still assigned to the role."
        onConfirm={() => deletingRole && actions.deleteRole(deletingRole.id)}
      />
    </div>
  );
}

function RolePermissionDialog({
  open,
  mode,
  role,
  onClose,
  onSubmit,
}: {
  open: boolean;
  mode: "create" | "edit";
  role?: DatabaseState["roles"][number];
  onClose: () => void;
  onSubmit: (values: { name: string; description: string; permissions: string[] }) => Promise<void>;
}) {
  const protectedSuperAdmin = role?.system === true || role?.name === "Super admin";
  const [name, setName] = useState(role?.name ?? "");
  const [description, setDescription] = useState(role?.description ?? "");
  const [permissions, setPermissions] = useState<Set<string>>(
    new Set(protectedSuperAdmin ? fullAccessPermissions : normalizePermissionList(role?.permissions ?? [])),
  );
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(
    new Set(permissionTree.map((group) => group.id)),
  );
  const [expandedLeaves, setExpandedLeaves] = useState<Set<string>>(new Set());
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!open) return;
    const isProtected = role?.system === true || role?.name === "Super admin";
    setName(role?.name ?? "");
    setDescription(role?.description ?? "");
    setPermissions(
      new Set(isProtected ? fullAccessPermissions : normalizePermissionList(role?.permissions ?? [])),
    );
    setExpandedGroups(new Set(permissionTree.map((group) => group.id)));
    setExpandedLeaves(new Set());
    setError("");
    setSaving(false);
  }, [open, role]);

  if (!open) return null;

  const replacePermissions = (next: string[]) => {
    if (protectedSuperAdmin) return;
    setPermissions(new Set(normalizePermissionList(next)));
  };
  const setPermissionChecked = (permission: string, checked: boolean) => {
    if (protectedSuperAdmin) return;
    setPermissions((current) => {
      const next = new Set(current);
      const dot = permission.lastIndexOf(".");
      const leafId = permission.slice(0, dot);
      const action = permission.slice(dot + 1);
      if (checked) {
        next.add(permission);
        if (action !== "view") next.add(`${leafId}.view`);
      } else {
        next.delete(permission);
        if (action === "view") {
          permissionsForLeaf(leafId).forEach((item) => next.delete(item));
        }
      }
      return new Set(normalizePermissionList([...next]));
    });
  };
  const toggleLeaf = (leafId: string, checked: boolean) => {
    const leafPermissions = permissionsForLeaf(leafId);
    replacePermissions(
      checked
        ? [...permissions, ...leafPermissions]
        : [...permissions].filter((permission) => !leafPermissions.includes(permission)),
    );
  };
  const toggleGroup = (groupId: string, checked: boolean) => {
    const modulePermissions = groupPermissions(groupId);
    replacePermissions(
      checked
        ? [...permissions, ...modulePermissions]
        : [...permissions].filter((permission) => !modulePermissions.includes(permission)),
    );
  };
  const setGroupPreset = (groupId: string, preset: "clear" | "view" | "full") => {
    const group = permissionTree.find((item) => item.id === groupId);
    if (!group) return;
    const modulePermissions = groupPermissions(groupId);
    const next = [...permissions].filter((permission) => !modulePermissions.includes(permission));
    if (preset === "view")
      next.push(...group.children.flatMap((child) => (child.actions as readonly string[]).includes("view") ? [`${child.id}.view`] : []));
    if (preset === "full") next.push(...modulePermissions);
    replacePermissions(next);
  };
  const toggleGroupExpanded = (groupId: string) =>
    setExpandedGroups((current) => {
      const next = new Set(current);
      if (next.has(groupId)) next.delete(groupId);
      else next.add(groupId);
      return next;
    });
  const toggleLeafExpanded = (leafId: string) =>
    setExpandedLeaves((current) => {
      const next = new Set(current);
      if (next.has(leafId)) next.delete(leafId);
      else next.add(leafId);
      return next;
    });
  const save = async () => {
    const cleanName = name.trim();
    if (!cleanName) {
      setError("Role name is required.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      await onSubmit({
        name: protectedSuperAdmin ? "Super admin" : cleanName,
        description: description.trim(),
        permissions: protectedSuperAdmin ? fullAccessPermissions : normalizePermissionList([...permissions]),
      });
      onClose();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Could not save this role.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[80] grid place-items-center bg-black/70 p-4 backdrop-blur-sm">
      <div className="max-h-[92vh] w-full max-w-6xl overflow-hidden rounded-2xl border border-white/[.08] bg-[#111113] shadow-2xl">
        <div className="flex items-start justify-between border-b border-white/[.07] p-5">
          <div>
            <h3 className="text-lg font-semibold">
              {mode === "create" ? "Create role" : `Edit role · ${role?.name ?? ""}`}
            </h3>
            <p className="mt-1 text-xs text-zinc-500">
              Select structured permissions. These keys are enforced by UI, API routes, and Firebase rules.
            </p>
          </div>
          <button onClick={onClose} className="icon-btn" disabled={saving}>
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="max-h-[calc(92vh-150px)] overflow-y-auto p-5">
          <div className="grid gap-3 md:grid-cols-[1fr_1.5fr]">
            <label className="space-y-1.5 text-xs text-zinc-500">
              Role name
              <Input
                value={protectedSuperAdmin ? "Super admin" : name}
                onChange={(event) => setName(event.target.value)}
                disabled={protectedSuperAdmin || saving}
                placeholder="Operations manager"
              />
            </label>
            <label className="space-y-1.5 text-xs text-zinc-500">
              Description
              <Input
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                disabled={saving}
                placeholder="What this role can access"
              />
            </label>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            {[
              ["Select All", fullAccessPermissions],
              ["Clear All", []],
              ["View Only", viewOnlyPermissions],
              ["Full Access", fullAccessPermissions],
            ].map(([label, next]) => (
              <Button
                key={label as string}
                type="button"
                variant="secondary"
                size="sm"
                disabled={protectedSuperAdmin || saving}
                onClick={() => replacePermissions(next as string[])}
              >
                {label as string}
              </Button>
            ))}
            <Badge variant="secondary" className="ml-auto">
              {protectedSuperAdmin ? "Protected full access" : `${permissions.size} selected`}
            </Badge>
          </div>
          {error && (
            <div className="mt-4 rounded-xl border border-red-500/20 bg-red-500/10 px-3 py-2 text-xs text-red-300">
              {error}
            </div>
          )}
          <div className="mt-5 space-y-3">
            {permissionTree
              .filter((group) => protectedSuperAdmin || group.id !== "system")
              .map((group) => {
                const modulePermissions = groupPermissions(group.id);
                const checkedCount = modulePermissions.filter((permission) => permissions.has(permission)).length;
                const expanded = expandedGroups.has(group.id);
                return (
                  <div key={group.id} className="rounded-2xl border border-white/[.07] bg-white/[.02]">
                    <div className="flex flex-col gap-3 p-4 lg:flex-row lg:items-center lg:justify-between">
                      <div className="flex items-start gap-3">
                        <button
                          type="button"
                          className="mt-0.5 rounded-lg p-1 text-zinc-500 hover:bg-white/[.05] hover:text-zinc-200"
                          onClick={() => toggleGroupExpanded(group.id)}
                        >
                          {expanded ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                        </button>
                        <input
                          type="checkbox"
                          className="mt-1.5 h-4 w-4 accent-indigo-500"
                          checked={checkedCount === modulePermissions.length && modulePermissions.length > 0}
                          ref={(input) => {
                            if (input) input.indeterminate = checkedCount > 0 && checkedCount < modulePermissions.length;
                          }}
                          disabled={protectedSuperAdmin || saving}
                          onChange={(event) => toggleGroup(group.id, event.target.checked)}
                        />
                        <div>
                          <div className="font-medium text-zinc-100">{group.label}</div>
                          <div className="mt-1 max-w-2xl text-[10px] text-zinc-500">{group.description}</div>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {[
                          ["Clear module", "clear"],
                          ["View only module", "view"],
                          ["Full access module", "full"],
                        ].map(([label, preset]) => (
                          <Button
                            key={preset}
                            type="button"
                            variant="secondary"
                            size="sm"
                            disabled={protectedSuperAdmin || saving}
                            onClick={() => setGroupPreset(group.id, preset as "clear" | "view" | "full")}
                          >
                            {label}
                          </Button>
                        ))}
                        <Badge variant="secondary">{checkedCount}/{modulePermissions.length}</Badge>
                      </div>
                    </div>
                    {expanded && (
                      <div className="divide-y divide-white/[.06] border-t border-white/[.06]">
                        {group.children.map((leaf) => {
                          const leafPermissions = permissionsForLeaf(leaf.id);
                          const leafChecked = leafPermissions.filter((permission) => permissions.has(permission)).length;
                          const leafExpanded = expandedLeaves.has(leaf.id);
                          return (
                            <div key={leaf.id} className="p-3 pl-8">
                              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                                <div className="flex items-center gap-3">
                                  <button
                                    type="button"
                                    className="rounded-lg p-1 text-zinc-600 hover:bg-white/[.05] hover:text-zinc-200"
                                    onClick={() => toggleLeafExpanded(leaf.id)}
                                  >
                                    {leafExpanded ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronRight className="h-3.5 w-3.5" />}
                                  </button>
                                  <input
                                    type="checkbox"
                                    className="h-4 w-4 accent-indigo-500"
                                    checked={leafChecked === leafPermissions.length && leafPermissions.length > 0}
                                    ref={(input) => {
                                      if (input) input.indeterminate = leafChecked > 0 && leafChecked < leafPermissions.length;
                                    }}
                                    disabled={protectedSuperAdmin || saving}
                                    onChange={(event) => toggleLeaf(leaf.id, event.target.checked)}
                                  />
                                  <div>
                                    <div className="text-sm font-medium">{leaf.label}</div>
                                    <div className="text-[9px] text-zinc-600">{leaf.id}</div>
                                  </div>
                                </div>
                                <div className="flex flex-wrap gap-1.5">
                                  {leaf.actions.map((action) => {
                                    const permission = `${leaf.id}.${action}`;
                                    const actionLabel = permissionActions.find((item) => item.id === action)?.label ?? action;
                                    return (
                                      <label
                                        key={permission}
                                        className="flex items-center gap-1.5 rounded-full border border-white/[.07] bg-white/[.03] px-2 py-1 text-[10px] text-zinc-400"
                                      >
                                        <input
                                          type="checkbox"
                                          className="h-3.5 w-3.5 accent-indigo-500"
                                          checked={permissions.has(permission)}
                                          disabled={protectedSuperAdmin || saving}
                                          onChange={(event) => setPermissionChecked(permission, event.target.checked)}
                                        />
                                        {actionLabel}
                                      </label>
                                    );
                                  })}
                                </div>
                              </div>
                              {leafExpanded && (
                                <div className="mt-2 flex flex-wrap gap-1 pl-10">
                                  {leafPermissions.map((permission) => (
                                    <span
                                      key={permission}
                                      className={cn(
                                        "rounded px-1.5 py-1 text-[9px]",
                                        permissions.has(permission)
                                          ? "bg-indigo-500/10 text-indigo-200"
                                          : "bg-white/[.04] text-zinc-600",
                                      )}
                                    >
                                      {permission}
                                    </span>
                                  ))}
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}
          </div>
        </div>
        <div className="flex justify-end gap-2 border-t border-white/[.07] p-4">
          <Button variant="secondary" onClick={onClose} disabled={saving}>
            Cancel
          </Button>
          <Button onClick={save} disabled={saving}>
            {saving && <Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" />}
            Save role
          </Button>
        </div>
      </div>
    </div>
  );
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function JobDrawer({
  job,
  close,
  notify,
}: {
  job: Job;
  close: () => void;
  notify: (s: string) => void;
}) {
  const { db, actions } = useAdminData();
  const current = db.jobs.find((x) => x.id === job.id) ?? job;
  const customer = db.customers.find((item) => item.id === current.customerId);
  const provider = db.providers.find((item) => item.id === current.providerId);
  const providerPhone = provider?.phone;
  const [note, setNote] = useState("");
  const [assignOpen, setAssignOpen] = useState(false);
  return (
    <div
      className="fixed inset-0 z-[70] flex justify-end bg-black/60 backdrop-blur-sm"
      onMouseDown={close}
    >
      <aside
        onMouseDown={(e) => e.stopPropagation()}
        className="h-full w-full max-w-[560px] overflow-y-auto border-l border-white/[.08] bg-[#111113] shadow-2xl"
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-white/[.07] bg-[#111113]/95 px-5 py-4 backdrop-blur">
          <div>
            <div className="flex items-center gap-2">
              <span className="text-sm font-semibold">{current.id}</span>
              <StatusBadge status={current.status} />
            </div>
            <div className="mt-1 text-[10px] text-zinc-600">
              Created {new Date(current.createdAt).toLocaleString()}
            </div>
          </div>
          <button onClick={close} className="icon-btn">
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="space-y-5 p-5">
          <div className="rounded-xl border border-white/[.06] bg-white/[.025] p-4">
            <div className="eyebrow">Service details</div>
            <div className="mt-4 flex items-start gap-3">
              <span className="grid h-10 w-10 place-items-center rounded-lg bg-indigo-500/10 text-indigo-400">
                <Wrench className="h-5 w-5" />
              </span>
              <div>
                <div className="text-sm font-medium">{current.service}</div>
                <div className="mt-1 text-[11px] text-zinc-500">
                  Scheduled {current.scheduled || "not set"} · {current.area || "No area"}
                </div>
                <div className="mt-1 flex items-center gap-1 text-[10px] text-zinc-600">
                  <MapPin className="h-3 w-3" />
                  {current.address || `${current.area}, ${current.city || "Egypt"}`}
                </div>
              </div>
              <div className="ml-auto text-sm font-semibold">
                EGP {current.amount.toLocaleString()}
              </div>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <PersonCard
              label="Customer"
              name={current.customer}
              detail={customer ? `${customer.phone} · ${customer.bookings} bookings` : current.customerId}
              initials={current.customerInitials}
            />
            <PersonCard
              label="Provider"
              name={current.provider}
              detail={provider ? `${provider.providerId} · ${provider.rating || "—"}★ · ${provider.verified ? "Verified" : "Not verified"}` : "Search and assign a provider"}
              initials={
                current.provider === "Unassigned"
                  ? "?"
                  : current.provider
                      .split(" ")
                      .map((x) => x[0])
                      .join("")
              }
            />
          </div>
          <div>
            <div className="eyebrow mb-4">Job timeline</div>
            {current.timeline.length ? (
              current.timeline
                .slice()
                .reverse()
                .map((event) => (
                  <div
                    key={event.id}
                    className="mt-2 flex justify-between rounded-lg bg-white/[.025] px-3 py-2 text-[10px]"
                  >
                    <span>{event.label}</span>
                    <span className="text-zinc-600">
                      {new Date(event.at).toLocaleString()}
                    </span>
                  </div>
                ))
            ) : (
              <EmptyState
                title="No timeline events"
                body="Firestore does not have timeline events for this job yet."
              />
            )}
          </div>
          <div className="rounded-xl border border-white/[.06]">
            <div className="border-b border-white/[.06] p-4">
              <div className="eyebrow">Payment</div>
            </div>
            <div className="grid grid-cols-3 p-4 text-[11px]">
              <div>
                <div className="text-zinc-600">Method</div>
                <div className="mt-1">{current.paymentMethod}</div>
              </div>
              <div>
                <div className="text-zinc-600">Platform fee</div>
                <div className="mt-1">EGP {(current.payment?.platformCommission ?? 0).toLocaleString()}</div>
              </div>
              <div>
                <div className="text-zinc-600">Status</div>
                <div className="mt-1 text-emerald-400">
                  {current.paymentStatus}
                </div>
              </div>
            </div>
          </div>
          <div>
            <div className="eyebrow mb-2">Internal note</div>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="input min-h-20 w-full resize-none py-2"
              placeholder="Add context visible to Task admins only..."
            />
            <div className="mt-2 flex items-center justify-between">
              <span className="text-[9px] text-zinc-600">
                {current.notes.length} saved notes
              </span>
              <Button
                size="sm"
                variant="secondary"
                disabled={!note.trim()}
                onClick={() => {
                  actions.addJobNote(current.id, note);
                  setNote("");
                  notify("Internal note saved");
                }}
              >
                Save note
              </Button>
            </div>
          </div>
        </div>
        <div className="sticky bottom-0 flex gap-2 border-t border-white/[.07] bg-[#111113]/95 p-4 backdrop-blur">
          {providerPhone ? <a href={`tel:${providerPhone}`} className="btn-secondary flex-1 justify-center"><Headphones className="h-3.5 w-3.5" />Contact provider</a> : <button disabled className="btn-secondary flex-1 justify-center"><Headphones className="h-3.5 w-3.5" />No provider assigned</button>}
          <button
            onClick={() => {
              actions.createComplaint({
                title: `Emergency escalation · ${current.id}`,
                description: "Escalated from job control center",
                severity: "Critical",
                jobId: current.id,
                customerId: current.customerId,
                providerId: current.providerId,
                customer: current.customer,
              });
              notify(`Job ${current.id} escalated`);
            }}
            className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-red-500 px-3 py-2 text-xs font-medium text-white hover:bg-red-400"
          >
            <AlertTriangle className="h-3.5 w-3.5" />
            Escalate
          </button>
          <RowActions
            label={`Job actions for ${current.id}`}
            actions={[
              { label: "Assign provider", onClick: () => setAssignOpen(true) },
              {
                label: "Mark en route",
                onClick: () => actions.changeJobStatus(current.id, "En route"),
              },
              {
                label: "Mark in progress",
                onClick: () =>
                  actions.changeJobStatus(current.id, "In progress"),
              },
              {
                label: "Complete job",
                onClick: () => actions.changeJobStatus(current.id, "Completed"),
              },
              {
                label:
                  current.status === "Cancelled" ? "Reopen job" : "Cancel job",
                onClick: () =>
                  actions.changeJobStatus(
                    current.id,
                    current.status === "Cancelled" ? "Scheduled" : "Cancelled",
                  ),
                separator: true,
              },
              {
                label: "Issue refund",
                onClick: () => actions.refundJob(current.id),
                danger: true,
              },
            ]}
          />
        </div>
      </aside>
      <ProviderSearchPicker open={assignOpen} close={() => setAssignOpen(false)} title={`Assign provider · ${current.id}`} onSelect={(provider) => { actions.assignProvider(current.id, provider.id); notify(`${provider.providerId} assigned`); setAssignOpen(false); }} />
    </div>
  );
}

function CommandMenu({
  close,
  navigate,
  openJob,
  openProvider,
}: {
  close: () => void;
  navigate: (s: Section) => void;
  openJob: (job: Job) => void;
  openProvider: (providerId: string) => void;
}) {
  const { db } = useAdminData();
  const { can } = usePermissions();
  const canNavigate = useCallback(
    (label: Section) =>
      (sectionPermissions[label] ?? []).some((permission) => can(permission)),
    [can],
  );
  const [query, setQuery] = useState("");
  const [activeResult, setActiveResult] = useState(0);
  const normalized = query.trim().toLowerCase();
  const results = useMemo(() => {
    if (!normalized) return [];
    const matches = (values: Array<string | undefined | number>) =>
      values.some((value) => {
        const raw = String(value ?? "").toLowerCase();
        const digits = raw.replace(/\D/g, "");
        const localPhone = digits.startsWith("20")
          ? `0${digits.slice(2)}`
          : digits;
        const queryDigits = normalized.replace(/\D/g, "");
        return (
          raw.includes(normalized) ||
          (!!queryDigits &&
            (digits.includes(queryDigits) || localPhone.includes(queryDigits)))
        );
      });
    const rows: Array<{
      id: string;
      type: string;
      label: string;
      meta: string;
      section: Section;
      job?: Job;
    }> = [];
    db.customers
      .filter((x) => matches([x.id, x.name, x.email, x.phone]))
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Customers",
          label: x.name,
          meta: `${x.id} · ${x.phone} · ${x.email}`,
          section: "Customers",
        }),
      );
    db.providers
      .filter((x) =>
        matches([
          x.id,
          x.providerId,
          x.name,
          x.email,
          x.phone,
          x.nationalIdNumber,
          x.trade,
          x.rating,
          x.status,
          ...x.areas,
          ...x.cities,
          ...db.services
            .filter((service) => x.serviceIds.includes(service.id))
            .map((service) => service.name),
        ]),
      )
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Providers",
          label: x.name,
          meta: `${x.providerId} · ${x.phone} · ${x.email} · ${x.trade}`,
          section: "Providers",
        }),
      );
    db.jobs
      .filter((x) => {
        const customer = db.customers.find((item) => item.id === x.customerId);
        const provider = db.providers.find((item) => item.id === x.providerId);
        return matches([
          x.id,
          x.customerId,
          x.customer,
          customer?.phone,
          customer?.email,
          x.providerId,
          provider?.providerId,
          provider?.phone,
          provider?.email,
          x.provider,
          x.service,
          x.area,
          x.paymentStatus,
          x.paymentMethod,
          x.amount,
          x.customerBudget,
          x.payment?.transactionId,
          x.payment?.providerReference,
          ...(x.offers ?? []).flatMap((offer) => [
            offer.id,
            offer.providerId,
            offer.price,
            offer.status,
          ]),
        ]);
      })
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Jobs",
          label: `${x.id} · ${x.service}`,
          meta: `${x.customer} · ${x.provider} · ${x.status}`,
          section: "Jobs",
          job: x,
        }),
      );
    db.complaints
      .filter((x) =>
        matches([
          x.id,
          x.title,
          x.customer,
          x.jobId,
          x.customerId,
          x.providerId,
        ]),
      )
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Complaints",
          label: x.title,
          meta: `${x.id} · ${x.severity} · ${x.status}`,
          section: "Trust & safety",
        }),
      );
    db.transactions
      .filter((x) => matches([x.id, x.party, x.ownerId, x.reference, x.type]))
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Payments",
          label: `${x.type} · EGP ${x.amount}`,
          meta: `${x.id} · ${x.party} · ${x.status}`,
          section: "Payments",
        }),
      );
    db.services
      .filter((x) =>
        matches([x.id, x.name, x.description, ...x.areas, ...x.cities]),
      )
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Services",
          label: x.name,
          meta: `${x.id} · EGP ${x.basePrice}`,
          section: "Services & pricing",
        }),
      );
    db.admins
      .filter((x) => matches([x.id, x.name, x.email, x.role]))
      .forEach((x) =>
        rows.push({
          id: x.id,
          type: "Admin users",
          label: x.name,
          meta: `${x.email} · ${x.role}`,
          section: "Admin & roles",
        }),
      );
    return rows.filter((row) => canNavigate(row.section)).slice(0, 30);
  }, [canNavigate, db, normalized]);
  const grouped = results.reduce<Record<string, typeof results>>(
    (acc, item) => {
      (acc[item.type] ??= []).push(item);
      return acc;
    },
    {},
  );
  const openResult = (item: (typeof results)[number]) => {
    if (item.type === "Providers") {
      openProvider(item.id);
    }
    navigate(item.section);
    if (item.job) openJob(item.job);
    close();
  };
  return (
    <div
      className="fixed inset-0 z-[90] flex justify-center bg-black/65 px-4 pt-[12vh] backdrop-blur-sm"
      onMouseDown={close}
    >
      <div
        onMouseDown={(e) => e.stopPropagation()}
        className="h-fit w-full max-w-[600px] overflow-hidden rounded-xl border border-white/[.1] bg-[#161619] shadow-2xl"
      >
        <div className="flex items-center gap-3 border-b border-white/[.07] px-4">
          <Search className="h-4 w-4 text-zinc-500" />
          <input
            autoFocus
            value={query}
            onChange={(e) => { setQuery(e.target.value); setActiveResult(0); }}
            onKeyDown={(e) => {
              if (e.key === "ArrowDown") { e.preventDefault(); setActiveResult((value) => Math.min(value + 1, results.length - 1)); }
              if (e.key === "ArrowUp") { e.preventDefault(); setActiveResult((value) => Math.max(value - 1, 0)); }
              if (e.key === "Enter" && results[activeResult]) openResult(results[activeResult]);
              if (e.key === "Escape") close();
            }}
            placeholder="Search or jump to..."
            className="h-12 flex-1 bg-transparent text-sm outline-none placeholder:text-zinc-700"
          />
          <span className="rounded border border-white/[.08] px-1.5 py-0.5 text-[9px] text-zinc-600">
            ESC
          </span>
        </div>
        <div className="max-h-[420px] overflow-y-auto p-2">
          {!normalized ? (
            <>
              <div className="eyebrow px-2 py-2">Navigate</div>
              {navigation
                .filter((n) => canNavigate(n.label))
                .map((n) => (
                  <button
                    key={n.label}
                    onClick={() => {
                      navigate(n.label);
                      close();
                    }}
                    className="flex w-full items-center gap-3 rounded-lg p-2.5 text-left hover:bg-white/[.05]"
                  >
                    <span className="grid h-7 w-7 place-items-center rounded-md bg-white/[.04] text-zinc-500">
                      <n.icon className="h-3.5 w-3.5" />
                    </span>
                    <span className="flex-1 text-xs">{n.label}</span>
                    <span className="text-[9px] text-zinc-700">Go to page</span>
                  </button>
                ))}
            </>
          ) : results.length ? (
            Object.entries(grouped).map(([group, items]) => (
              <div key={group}>
                <div className="eyebrow px-2 py-2">{group}</div>
                {items.map((item) => (
                  <button
                    key={`${group}-${item.id}`}
                    onClick={() => openResult(item)}
                    className={cn("flex w-full items-center gap-3 rounded-lg p-2.5 text-left hover:bg-white/[.05]", results[activeResult] === item && "bg-white/[.05]")}
                  >
                    <span className="grid h-8 w-8 place-items-center rounded-md bg-indigo-500/10 text-indigo-400">
                      <Search className="h-3.5 w-3.5" />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-xs text-zinc-200">
                        {item.label}
                      </span>
                      <span className="block truncate text-[10px] text-zinc-600">
                        {item.meta}
                      </span>
                    </span>
                    <ChevronRight className="h-3.5 w-3.5 text-zinc-700" />
                  </button>
                ))}
              </div>
            ))
          ) : (
            <EmptyState
              title="No results"
              body="Try a phone, email, ID, name, service, complaint, or transaction reference."
            />
          )}
        </div>
        <div className="flex gap-4 border-t border-white/[.06] px-4 py-2 text-[9px] text-zinc-700">
          <span>↑↓ navigate</span>
          <span>↵ select</span>
          <span>esc close</span>
        </div>
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const { t } = usePreferences();
  const variants: Record<
    string,
    "default" | "secondary" | "success" | "warning" | "destructive" | "outline"
  > = {
    "In progress": "default",
    "En route": "default",
    Scheduled: "secondary",
    Assigned: "default",
    Delayed: "warning",
    Completed: "success",
    Refunded: "warning",
    Verified: "success",
    Paid: "success",
    Active: "success",
    Healthy: "success",
    Cancelled: "destructive",
    Suspended: "destructive",
    Banned: "destructive",
    Blocked: "destructive",
    Rejected: "destructive",
    Disabled: "secondary",
    Review: "warning",
    Watch: "warning",
    Pending: "warning",
    Sent: "success",
    Failed: "destructive",
    Processing: "default",
    Invited: "default",
    Draft: "secondary",
    Ended: "outline",
  };
  return (
    <Badge
      variant={variants[status] || "secondary"}
      className={cn(
        "whitespace-nowrap px-2 py-0.5 text-[9px] font-medium",
        status === "En route" &&
          "border-cyan-500/20 bg-cyan-500/10 text-cyan-400",
      )}
    >
      {t(status)}
    </Badge>
  );
}
function SeverityBadge({ severity }: { severity: string }) {
  const c: Record<string, string> = {
    Critical: "bg-red-500/10 text-red-400",
    High: "bg-orange-500/10 text-orange-400",
    Medium: "bg-amber-500/10 text-amber-400",
    Low: "bg-zinc-500/10 text-zinc-500",
  };
  return (
    <span
      className={cn(
        "rounded-full px-2 py-0.5 text-[8px] uppercase tracking-wider",
        c[severity],
      )}
    >
      {severity}
    </span>
  );
}
function SeverityIcon({ severity }: { severity: string }) {
  const c: Record<string, string> = {
    Critical: "bg-red-500/10 text-red-400",
    High: "bg-orange-500/10 text-orange-400",
    Medium: "bg-amber-500/10 text-amber-400",
    Low: "bg-zinc-500/10 text-zinc-500",
  };
  return (
    <span
      className={cn(
        "grid h-9 w-9 shrink-0 place-items-center rounded-lg",
        c[severity],
      )}
    >
      <AlertTriangle className="h-4 w-4" />
    </span>
  );
}
function Avatar({
  initials,
  src,
  size = "md",
}: {
  initials: string;
  src?: string;
  size?: "sm" | "md";
}) {
  return (
    <ShadcnAvatar className={size === "sm" ? "h-6 w-6" : "h-8 w-8"}>
      {src && <AvatarImage src={src} alt="Profile" />}
      <AvatarFallback className={size === "sm" ? "text-[8px]" : "text-[9px]"}>
        {initials}
      </AvatarFallback>
    </ShadcnAvatar>
  );
}
function PanelTitle({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex min-h-[61px] items-center justify-between border-b border-white/[.06] px-4 py-3">
      <div>
        <h2 className="text-xs font-semibold tracking-tight">{title}</h2>
        {subtitle && (
          <p className="mt-1 text-[9px] text-zinc-600">{subtitle}</p>
        )}
      </div>
      {action}
    </div>
  );
}
function Metric({
  label,
  value,
  color,
  border,
}: {
  label: string;
  value: string;
  color: string;
  border?: boolean;
}) {
  return (
    <div className={cn("p-4", border && "border-l border-white/[.06]")}>
      <div className={cn("text-xl font-semibold", color)}>{value}</div>
      <div className="mt-1 text-[9px] text-zinc-600">{label}</div>
    </div>
  );
}
function StatBlock({
  label,
  value,
  icon: Icon,
  tone,
}: {
  label: string;
  value: string;
  icon: LucideIcon;
  tone: string;
}) {
  const c: Record<string, string> = {
    indigo: "bg-indigo-500/10 text-indigo-400",
    green: "bg-emerald-500/10 text-emerald-400",
    amber: "bg-amber-500/10 text-amber-400",
    red: "bg-red-500/10 text-red-400",
  };
  return (
    <Card className="flex items-center gap-4 p-4 transition hover:-translate-y-0.5 hover:border-white/[.13]">
      <span
        className={cn(
          "grid h-11 w-11 place-items-center rounded-xl border border-white/[.05]",
          c[tone],
        )}
      >
        <Icon className="h-[18px] w-[18px]" />
      </span>
      <div>
        <div className="text-xl font-semibold tracking-[-.03em]">{value}</div>
        <div className="mt-0.5 text-[10px] text-zinc-500">{label}</div>
      </div>
    </Card>
  );
}
function SearchInput({
  value,
  setValue,
  placeholder,
}: {
  value?: string;
  setValue?: (s: string) => void;
  placeholder: string;
}) {
  return (
    <div className="relative min-w-[190px] max-w-[310px] flex-1">
      <Search className="pointer-events-none absolute left-3 top-3 h-3.5 w-3.5 text-zinc-600" />
      <Input
        value={value}
        onChange={(e) => setValue?.(e.target.value)}
        className="h-10 pl-9 text-xs"
        placeholder={placeholder}
      />
    </div>
  );
}
function FilterButton({ label = "Filters" }: { label?: string }) {
  return (
    <span className="inline-flex h-9 items-center gap-2 rounded-xl border border-white/[.08] bg-white/[.035] px-3 text-[11px] font-medium text-zinc-500">
      <Filter className="h-3.5 w-3.5" />
      {label}
    </span>
  );
}
function Pagination() {
  return (
    <div className="flex items-center justify-between border-t border-white/[.06] px-4 py-3 text-[10px] text-zinc-600">
      <span>Page 1 of 1</span>
      <div className="flex gap-1">
        <button
          disabled
          aria-label="Previous page"
          className="icon-btn disabled:opacity-30"
        >
          <ArrowLeft className="h-3 w-3" />
        </button>
        <button
          disabled
          aria-label="Next page"
          className="icon-btn disabled:opacity-30"
        >
          <ArrowRight className="h-3 w-3" />
        </button>
      </div>
    </div>
  );
}
function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="grid place-items-center py-16 text-center">
      <span className="grid h-10 w-10 place-items-center rounded-full bg-white/[.04]">
        <Search className="h-4 w-4 text-zinc-600" />
      </span>
      <div className="mt-3 text-xs font-medium">{title}</div>
      <div className="mt-1 text-[10px] text-zinc-600">{body}</div>
    </div>
  );
}
function ChartTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: Array<{ value: number }>;
  label?: string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border border-white/[.1] bg-[#18181b] px-3 py-2 shadow-xl">
      <div className="text-[9px] text-zinc-500">{label}</div>
      <div className="mt-1 text-xs font-semibold">
        EGP {payload[0].value.toLocaleString()}
      </div>
    </div>
  );
}
function PersonCard({
  label,
  name,
  detail,
  initials,
}: {
  label: string;
  name: string;
  detail: string;
  initials: string;
}) {
  return (
    <div className="rounded-xl border border-white/[.06] p-3">
      <div className="eyebrow">{label}</div>
      <div className="mt-3 flex items-center gap-2">
        <Avatar initials={initials} />
        <div className="min-w-0">
          <div className="truncate text-[11px] font-medium">{name}</div>
          <div className="text-[9px] text-zinc-600">{detail}</div>
        </div>
      </div>
    </div>
  );
}
