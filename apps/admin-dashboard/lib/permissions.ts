import type { Permission } from "@/lib/types";

export const permissionActions = [
  { id: "view", label: "View" },
  { id: "create", label: "Create" },
  { id: "edit", label: "Edit" },
  { id: "delete", label: "Delete" },
  { id: "export", label: "Export" },
  { id: "aiSummary", label: "AI Summary" },
  { id: "approve", label: "Approve" },
  { id: "hide", label: "Hide" },
  { id: "reject", label: "Reject" },
  { id: "assign", label: "Assign" },
  { id: "enable", label: "Enable" },
  { id: "disable", label: "Disable" },
  { id: "sync", label: "Sync" },
  { id: "send", label: "Send" },
  { id: "resend", label: "Resend" },
  { id: "test", label: "Test" },
  { id: "cancel", label: "Cancel" },
  { id: "reschedule", label: "Reschedule" },
  { id: "refund", label: "Refund" },
  { id: "editFee", label: "Edit Fee" },
  { id: "convertToBooking", label: "Convert to Booking" },
  { id: "payout", label: "Payout" },
  { id: "verify", label: "Verify" },
  { id: "rotateKey", label: "Rotate Key" },
  { id: "wallet", label: "Wallet" },
  { id: "documents", label: "Documents" },
  { id: "notes", label: "Private Notes" },
  { id: "reply", label: "Reply" },
  { id: "resolve", label: "Resolve" },
  { id: "reopen", label: "Reopen" },
  { id: "resetPassword", label: "Reset Password" },
  { id: "warn", label: "Warn" },
  { id: "suspend", label: "Suspend" },
  { id: "reactivate", label: "Reactivate" },
  { id: "blacklist", label: "Blacklist" },
  { id: "sensitive", label: "Sensitive Data" },
  { id: "reset", label: "System Reset" },
] as const;

type PermissionActionId = (typeof permissionActions)[number]["id"];

export type PermissionLeaf = {
  id: string;
  label: string;
  description?: string;
  actions: readonly PermissionActionId[];
};

export type PermissionGroup = {
  id: string;
  label: string;
  description: string;
  children: readonly PermissionLeaf[];
};

export const permissionTree = [
  {
    id: "dashboard",
    label: "Dashboard",
    description: "Overview, widgets, reports, statistics, and quick actions",
    children: [
      { id: "overview", label: "Overview", actions: ["view", "export"] },
      { id: "dashboard.widgets", label: "Widgets", actions: ["view", "edit"] },
      { id: "dashboard.reports", label: "Reports", actions: ["view", "export"] },
      { id: "dashboard.statistics", label: "Statistics", actions: ["view", "export"] },
      { id: "dashboard.quickActions", label: "Quick Actions", actions: ["view", "create", "edit"] },
    ],
  },
  {
    id: "ai",
    label: "AI Executive",
    description: "AI assistant, automations, history, prompt library, and settings",
    children: [
      { id: "ai.chat", label: "Chat", actions: ["view", "create"] },
      { id: "ai.agents", label: "Agents", actions: ["view", "create", "edit", "delete"] },
      { id: "ai.automation", label: "Automation", actions: ["view", "create", "edit", "delete"] },
      { id: "ai.tasks", label: "Tasks", actions: ["view", "create", "edit", "delete"] },
      { id: "ai.history", label: "History", actions: ["view", "delete"] },
      { id: "ai.promptLibrary", label: "Prompt Library", actions: ["view", "create", "edit", "delete"] },
      { id: "ai.settings", label: "Settings", actions: ["view", "edit"] },
    ],
  },
  {
    id: "operations",
    label: "Live Operations",
    description: "Dispatch, provider assignment, live status, and escalations",
    children: [
      { id: "operations.dispatch", label: "Dispatch Center", actions: ["view", "assign", "edit"] },
      { id: "operations.liveJobs", label: "Live Jobs", actions: ["view", "edit", "assign"] },
      { id: "operations.escalations", label: "Escalations", actions: ["view", "create", "edit", "resolve"] },
      { id: "operations.map", label: "Live Map", actions: ["view"] },
      { id: "operations.commandCenter", label: "Command Center", actions: ["view", "export"] },
      { id: "operations.smartAlerts", label: "Smart Alerts", actions: ["view", "resolve"] },
      { id: "operations.sla", label: "SLA Monitoring", actions: ["view", "export"] },
      { id: "operations.bookingControl", label: "Booking Control Center", actions: ["view", "assign", "edit", "cancel", "refund"] },
      { id: "operations.automationRules", label: "Automation Rules", actions: ["view", "create", "edit", "delete"] },
      { id: "operations.notifications", label: "Notification Center", actions: ["view", "send", "delete"] },
      { id: "operations.reports", label: "Reports Center", actions: ["view", "export"] },
      { id: "operations.timeline", label: "Activity Timeline", actions: ["view", "export"] },
      { id: "operations.systemHealth", label: "System Health", actions: ["view"] },
      { id: "operations.advancedSearch", label: "Advanced Search", actions: ["view"] },
    ],
  },
  {
    id: "admin",
    label: "Admin & Roles",
    description: "Admins, invitations, roles, permissions, and audit logs",
    children: [
      { id: "adminUsers", label: "Admin Users", actions: ["view", "create", "edit", "delete", "enable", "disable", "sync", "resetPassword"] },
      { id: "invitations", label: "Invitation Center", actions: ["view", "send", "resend", "cancel", "delete"] },
      { id: "roles", label: "Roles & Permissions", actions: ["view", "create", "edit", "delete", "assign"] },
      { id: "audit", label: "Audit Logs", actions: ["view", "export"] },
    ],
  },
  {
    id: "marketplace",
    label: "Marketplace",
    description: "Customers, technicians, bookings, complaints, and reviews",
    children: [
      { id: "customers", label: "Customers", actions: ["view", "create", "edit", "delete", "enable", "disable", "wallet", "sensitive", "export"] },
      { id: "providers", label: "Technicians", actions: ["view", "create", "edit", "delete", "approve", "reject", "enable", "disable", "assign", "documents", "sensitive", "export"] },
      { id: "technicians.performance", label: "Technician Performance", actions: ["view", "export", "aiSummary"] },
      { id: "technicians.reviews", label: "Technician Reviews", actions: ["view", "approve", "hide", "delete"] },
      { id: "technicians.complaints", label: "Technician Complaints", actions: ["view", "resolve", "reopen"] },
      { id: "technicians.warnings", label: "Technician Warnings", actions: ["view", "create", "delete", "reset"] },
      { id: "technicians.notes", label: "Technician Private Notes", actions: ["view", "create", "edit", "delete"] },
      { id: "technicians.status", label: "Technician Account Status", actions: ["warn", "suspend", "disable", "reactivate", "blacklist"] },
      { id: "technicians.analytics", label: "Technician Analytics", actions: ["view", "export"] },
      { id: "jobs", label: "Bookings / Jobs", actions: ["view", "create", "edit", "delete", "assign", "cancel", "refund", "export"] },
      { id: "bookings.emergency", label: "Emergency Bookings", actions: ["view", "assign", "cancel", "refund", "editFee"] },
      { id: "bookings.scheduled", label: "Scheduled Bookings", actions: ["view", "reschedule", "assign", "cancel"] },
      { id: "bookings.quotation", label: "Quotation Requests", actions: ["view", "assign", "approve", "reject", "convertToBooking", "export"] },
      { id: "complaints", label: "Complaints", actions: ["view", "create", "edit", "delete", "assign", "resolve", "sensitive", "export"] },
      { id: "reviews", label: "Reviews", actions: ["view", "edit", "delete", "export"] },
    ],
  },
  {
    id: "payments",
    label: "Payments",
    description: "Transactions, refunds, payouts, invoices, disputes, and reports",
    children: [
      { id: "payments.transactions", label: "Transactions", actions: ["view", "edit", "export", "sensitive"] },
      { id: "payments.refunds", label: "Refunds", actions: ["view", "create", "approve", "reject", "export"] },
      { id: "payments.payouts", label: "Payouts", actions: ["view", "create", "approve", "reject", "payout", "export"] },
      { id: "payments.invoices", label: "Invoices", actions: ["view", "create", "export"] },
      { id: "payments.methods", label: "Payment Methods", actions: ["view", "create", "edit", "delete"] },
      { id: "payments.disputes", label: "Disputes", actions: ["view", "resolve", "export"] },
      { id: "payments.reports", label: "Reports", actions: ["view", "export"] },
    ],
  },
  {
    id: "services",
    label: "Services & Pricing",
    description: "Categories, services, pricing, add-ons, availability, areas, and packages",
    children: [
      { id: "services.categories", label: "Categories", actions: ["view", "create", "edit", "delete"] },
      { id: "services.services", label: "Services", actions: ["view", "create", "edit", "delete"] },
      { id: "services.pricing", label: "Pricing", actions: ["view", "edit"] },
      { id: "services.addons", label: "Add-ons", actions: ["view", "create", "edit", "delete"] },
      { id: "services.availability", label: "Availability", actions: ["view", "edit"] },
      { id: "services.areas", label: "Service Areas", actions: ["view", "create", "edit", "delete"] },
      { id: "services.packages", label: "Packages", actions: ["view", "create", "edit", "delete"] },
      { id: "content.banners", label: "Banners", actions: ["view", "create", "edit", "delete"] },
    ],
  },
  {
    id: "support",
    label: "Support Chats",
    description: "Live chat, tickets, templates, canned replies, knowledge base, and reports",
    children: [
      { id: "support.liveChat", label: "Live Chat", actions: ["view", "reply", "edit", "delete"] },
      { id: "support.tickets", label: "Tickets", actions: ["view", "create", "edit", "delete", "assign", "resolve"] },
      { id: "support.templates", label: "Templates", actions: ["view", "create", "edit", "delete"] },
      { id: "support.cannedReplies", label: "Canned Replies", actions: ["view", "create", "edit", "delete"] },
      { id: "support.knowledgeBase", label: "Knowledge Base", actions: ["view", "create", "edit", "delete"] },
      { id: "support.reports", label: "Reports", actions: ["view", "export"] },
    ],
  },
  {
    id: "growth",
    label: "Growth",
    description: "Promotions and notification workflows",
    children: [
      { id: "promotions", label: "Promotions", actions: ["view", "create", "edit", "delete", "export"] },
      { id: "notifications", label: "Notifications", actions: ["view", "create", "edit", "delete", "send", "export"] },
    ],
  },
  {
    id: "analytics",
    label: "Analytics",
    description: "Overview, revenue, bookings, users, technicians, growth, reports, and export",
    children: [
      { id: "analytics.overview", label: "Overview", actions: ["view", "export"] },
      { id: "analytics.revenue", label: "Revenue", actions: ["view", "export"] },
      { id: "analytics.bookings", label: "Bookings", actions: ["view", "export"] },
      { id: "analytics.users", label: "Users", actions: ["view", "export"] },
      { id: "analytics.technicians", label: "Technicians", actions: ["view", "export"] },
      { id: "analytics.growth", label: "Growth", actions: ["view", "export"] },
      { id: "analytics.reports", label: "Reports", actions: ["view", "export"] },
    ],
  },
  {
    id: "account",
    label: "Account",
    description: "Profile, sessions, password, 2FA, devices, notifications, and API tokens",
    children: [
      { id: "account.profile", label: "Profile", actions: ["view", "edit"] },
      { id: "account.sessions", label: "Sessions", actions: ["view", "delete"] },
      { id: "account.password", label: "Password", actions: ["view", "edit"] },
      { id: "account.twoFactor", label: "Two Factor", actions: ["view", "edit"] },
      { id: "account.devices", label: "Devices", actions: ["view", "delete"] },
      { id: "account.notifications", label: "Notifications", actions: ["view", "edit"] },
      { id: "account.apiTokens", label: "API Tokens", actions: ["view", "create", "delete"] },
    ],
  },
  {
    id: "settings",
    label: "Settings",
    description: "Company, branding, appearance, integrations, security, notifications, billing, API keys, backup, and system",
    children: [
      { id: "settings.company", label: "Company", actions: ["view", "edit"] },
      { id: "settings.branding", label: "Branding", actions: ["view", "edit"] },
      { id: "settings.appearance", label: "Appearance", actions: ["view", "edit"] },
      { id: "settings.integrations", label: "Integrations", actions: ["view", "edit"] },
      { id: "settings.integrations.ai", label: "AI Providers", actions: ["view", "edit", "test", "disable", "rotateKey"] },
      { id: "settings.integrations.apiCenter", label: "API Center", actions: ["view", "edit", "test", "enable", "disable", "rotateKey", "delete"] },
      { id: "settings.security", label: "Security", actions: ["view", "edit"] },
      { id: "settings.notifications", label: "Notifications", actions: ["view", "edit"] },
      { id: "settings.billing", label: "Billing", actions: ["view", "edit"] },
      { id: "settings.apiKeys", label: "API Keys", actions: ["view", "create", "delete"] },
      { id: "settings.backup", label: "Backup", actions: ["view", "create"] },
      { id: "settings.system", label: "System", actions: ["view", "edit"] },
    ],
  },
  {
    id: "system",
    label: "System",
    description: "Super Admin-only destructive system tools",
    children: [
      { id: "system", label: "System Reset", actions: ["reset"] },
    ],
  },
] as const satisfies readonly PermissionGroup[];

export type PermissionTreeGroupId = (typeof permissionTree)[number]["id"];
export type PermissionLeafId = (typeof permissionTree)[number]["children"][number]["id"];
export type StructuredPermission = `${string}.${string}`;

export const permissionModules = permissionTree.flatMap((group) =>
  group.children.map((child) => {
    const item = child as PermissionLeaf;
    return {
      ...item,
      description: item.description ?? `${group.label} / ${item.label}`,
    };
  }),
);

export const allPermissions = permissionModules.flatMap((module) =>
  module.actions.map((action) => `${module.id}.${action}` as StructuredPermission),
);

export const viewOnlyPermissions = permissionModules.flatMap((module) =>
  module.actions.includes("view") ? [`${module.id}.view` as StructuredPermission] : [],
);

export const fullAccessPermissions = [...allPermissions];
export const superAdminOnlyPermissions: Permission[] = ["system.reset"];

const legacyPermissionAliases: Record<string, Permission[]> = {
  "dashboard.view": ["overview.view"],
  "overview.view": ["overview.view"],
  "ai.view": ["ai.chat.view", "ai.history.view"],
  "ai.create": ["ai.chat.create"],
  "ai.edit": ["ai.settings.edit"],
  "operations.view": ["operations.dispatch.view", "operations.liveJobs.view", "operations.map.view"],
  "operations.assign": ["operations.dispatch.assign", "operations.liveJobs.assign", "operations.bookingControl.assign"],
  "operations.edit": ["operations.dispatch.edit", "operations.liveJobs.edit", "operations.bookingControl.edit"],
  "operations.change_status": ["operations.liveJobs.edit"],
  "commandCenter.view": ["operations.commandCenter.view"],
  "alerts.view": ["operations.smartAlerts.view"],
  "sla.view": ["operations.sla.view"],
  "bookingControl.view": ["operations.bookingControl.view"],
  "financialControl.view": ["payments.transactions.view", "payments.reports.view"],
  "fraudRisk.view": ["complaints.view", "customers.view", "providers.view", "payments.transactions.view"],
  "qualityControl.view": ["reviews.view", "complaints.view"],
  "automationRules.view": ["operations.automationRules.view"],
  "notificationCenter.view": ["operations.notifications.view", "notifications.view"],
  "reportsCenter.view": ["operations.reports.view", "analytics.reports.view"],
  "activityTimeline.view": ["operations.timeline.view", "audit.view"],
  "systemHealth.view": ["operations.systemHealth.view", "settings.integrations.apiCenter.view"],
  "advancedSearch.view": ["operations.advancedSearch.view"],
  "users.view": ["adminUsers.view"],
  "users.create": ["adminUsers.create"],
  "users.edit": ["adminUsers.edit"],
  "users.delete": ["adminUsers.delete"],
  "users.invite": ["invitations.send", "invitations.view"],
  "users.sync": ["adminUsers.sync"],
  "users.change_status": ["adminUsers.enable", "adminUsers.disable"],
  "roles.view": ["roles.view"],
  "roles.create": ["roles.create"],
  "roles.edit": ["roles.edit"],
  "roles.delete": ["roles.delete"],
  "audit.view": ["audit.view"],
  "audit.read": ["audit.view"],
  "admins.manage": ["adminUsers.view", "adminUsers.create", "adminUsers.edit", "adminUsers.delete", "adminUsers.enable", "adminUsers.disable", "adminUsers.sync", "invitations.view", "invitations.send", "invitations.resend", "invitations.cancel", "roles.view", "roles.create", "roles.edit", "roles.delete", "roles.assign"],
  "customers.view": ["customers.view"],
  "customers.create": ["customers.create"],
  "customers.edit": ["customers.edit"],
  "customers.delete": ["customers.delete"],
  "customers.suspend": ["customers.disable", "customers.enable"],
  "customers.wallet": ["customers.wallet"],
  "customers.sensitive": ["customers.sensitive"],
  "customers.read": ["customers.view"],
  "customers.write": ["customers.create", "customers.edit", "customers.delete", "customers.disable", "customers.wallet"],
  "providers.view": ["providers.view"],
  "providers.create": ["providers.create"],
  "providers.edit": ["providers.edit"],
  "providers.delete": ["providers.delete"],
  "providers.approve": ["providers.approve", "providers.reject", "providers.documents", "providers.view"],
  "providers.suspend": ["providers.disable", "providers.enable"],
  "providers.ban": ["providers.disable"],
  "providers.documents": ["providers.documents"],
  "providers.read": ["providers.view"],
  "technicians.view": ["providers.view"],
  "technicians.performance.view": ["technicians.performance.view", "providers.view"],
  "technicians.performance.export": ["technicians.performance.export", "technicians.performance.view", "providers.export"],
  "technicians.performance.aiSummary": ["technicians.performance.aiSummary", "technicians.performance.view"],
  "technicians.warning.view": ["technicians.warnings.view"],
  "technicians.warning.create": ["technicians.warnings.create"],
  "technicians.warning.delete": ["technicians.warnings.delete"],
  "technicians.warnings.create": ["technicians.warnings.create", "technicians.warnings.view", "providers.edit"],
  "technicians.warnings.delete": ["technicians.warnings.delete", "technicians.warnings.view", "providers.edit"],
  "technicians.warnings.reset": ["technicians.warnings.reset", "technicians.warnings.view", "providers.edit"],
  "technicians.suspend": ["technicians.status.suspend", "providers.disable", "providers.enable"],
  "technicians.enable": ["technicians.status.reactivate", "providers.enable"],
  "technicians.disable": ["technicians.status.disable", "providers.disable"],
  "technicians.notes": ["technicians.notes.view", "technicians.notes.create", "providers.edit"],
  "technicians.reviews": ["technicians.reviews.view"],
  "technicians.complaints": ["technicians.complaints.view", "complaints.view"],
  "technicians.complaints.resolve": ["technicians.complaints.resolve", "technicians.complaints.view", "complaints.resolve"],
  "technicians.complaints.reopen": ["technicians.complaints.reopen", "technicians.complaints.view", "complaints.resolve"],
  "technicians.status.warn": ["technicians.status.warn", "technicians.warnings.create"],
  "technicians.status.suspend": ["technicians.status.suspend", "providers.disable"],
  "technicians.status.disable": ["technicians.status.disable", "providers.disable"],
  "technicians.status.reactivate": ["technicians.status.reactivate", "providers.enable"],
  "technicians.status.blacklist": ["technicians.status.blacklist", "providers.disable"],
  "technicians.analytics.view": ["technicians.analytics.view", "technicians.performance.view"],
  "technicians.analytics.export": ["technicians.analytics.export", "technicians.analytics.view", "technicians.performance.export"],
  "technicians.approve": ["providers.approve"],
  "technicians.reject": ["providers.reject"],
  "technicians.edit": ["providers.edit"],
  "technicians.delete": ["providers.delete"],
  "technicians.change_status": ["providers.disable", "providers.enable"],
  "jobs.view": ["jobs.view"],
  "jobs.create": ["jobs.create"],
  "jobs.edit": ["jobs.edit"],
  "jobs.delete": ["jobs.delete"],
  "jobs.assign": ["jobs.assign"],
  "jobs.change_status": ["jobs.edit"],
  "jobs.cancel": ["jobs.cancel"],
  "jobs.refund": ["jobs.refund", "payments.refunds.create"],
  "jobs.read": ["jobs.view", "operations.liveJobs.view"],
  "jobs.write": ["jobs.create", "jobs.edit", "jobs.assign", "jobs.cancel"],
  "bookings.emergency.view": ["bookings.emergency.view", "jobs.view", "operations.bookingControl.view"],
  "bookings.emergency.assign": ["bookings.emergency.assign", "jobs.assign", "operations.bookingControl.assign"],
  "bookings.emergency.cancel": ["bookings.emergency.cancel", "jobs.cancel"],
  "bookings.emergency.refund": ["bookings.emergency.refund", "jobs.refund", "payments.refunds.create"],
  "bookings.emergency.editFee": ["bookings.emergency.editFee", "jobs.edit"],
  "bookings.scheduled.view": ["bookings.scheduled.view", "jobs.view", "operations.bookingControl.view"],
  "bookings.scheduled.reschedule": ["bookings.scheduled.reschedule", "jobs.edit"],
  "bookings.scheduled.assign": ["bookings.scheduled.assign", "jobs.assign"],
  "bookings.scheduled.cancel": ["bookings.scheduled.cancel", "jobs.cancel"],
  "bookings.quotation.view": ["bookings.quotation.view", "jobs.view", "operations.bookingControl.view"],
  "bookings.quotation.assign": ["bookings.quotation.assign", "jobs.assign"],
  "bookings.quotation.approve": ["bookings.quotation.approve", "jobs.edit"],
  "bookings.quotation.reject": ["bookings.quotation.reject", "jobs.cancel"],
  "bookings.quotation.convertToBooking": ["bookings.quotation.convertToBooking", "jobs.edit", "jobs.create"],
  "bookings.quotation.export": ["bookings.quotation.export", "jobs.export"],
  "trust.view": ["complaints.view"],
  "trust.create": ["complaints.create"],
  "trust.edit": ["complaints.edit"],
  "trust.delete": ["complaints.delete"],
  "trust.assign": ["complaints.assign"],
  "trust.change_status": ["complaints.resolve"],
  "trust.sensitive": ["complaints.sensitive"],
  "trust.manage": ["complaints.view", "complaints.create", "complaints.edit", "complaints.delete", "complaints.assign", "complaints.resolve", "support.liveChat.view"],
  "payments.view": ["payments.transactions.view", "payments.refunds.view", "payments.payouts.view", "payments.reports.view"],
  "payments.edit": ["payments.transactions.edit"],
  "payments.refund": ["payments.refunds.create", "payments.refunds.approve"],
  "payments.payout": ["payments.payouts.create", "payments.payouts.approve", "payments.payouts.payout"],
  "payments.verify": ["payments.transactions.edit", "payments.disputes.resolve"],
  "payments.wallet": ["payments.transactions.edit", "customers.wallet"],
  "payments.sensitive": ["payments.transactions.sensitive"],
  "payments.read": ["payments.transactions.view"],
  "payments.manage": ["payments.transactions.view", "payments.transactions.edit", "payments.refunds.create", "payments.refunds.approve", "payments.payouts.approve", "payments.payouts.payout"],
  "services.view": ["services.categories.view", "services.services.view", "services.pricing.view", "services.availability.view", "services.areas.view"],
  "services.create": ["services.categories.create", "services.services.create"],
  "services.edit": ["services.categories.edit", "services.services.edit", "services.pricing.edit", "services.availability.edit", "services.areas.edit"],
  "services.delete": ["services.categories.delete", "services.services.delete"],
  "services.change_status": ["services.services.edit", "services.availability.edit"],
  "services.manage": ["services.categories.view", "services.categories.create", "services.categories.edit", "services.categories.delete", "services.services.view", "services.services.create", "services.services.edit", "services.services.delete", "services.pricing.view", "services.pricing.edit", "content.banners.view", "content.banners.create", "content.banners.edit", "content.banners.delete"],
  "content.view": ["content.banners.view"],
  "content.create": ["content.banners.create"],
  "content.edit": ["content.banners.edit"],
  "content.delete": ["content.banners.delete"],
  "support.view": ["support.liveChat.view", "support.tickets.view"],
  "support.create": ["support.tickets.create"],
  "support.edit": ["support.liveChat.edit", "support.tickets.edit"],
  "support.reply": ["support.liveChat.reply"],
  "support.assign": ["support.tickets.assign"],
  "support.change_status": ["support.tickets.resolve"],
  "promotions.view": ["promotions.view"],
  "promotions.create": ["promotions.create"],
  "promotions.edit": ["promotions.edit"],
  "promotions.delete": ["promotions.delete"],
  "promotions.manage": ["promotions.view", "promotions.create", "promotions.edit", "promotions.delete"],
  "notifications.view": ["notifications.view"],
  "notifications.create": ["notifications.create"],
  "notifications.edit": ["notifications.edit"],
  "notifications.delete": ["notifications.delete"],
  "notifications.send": ["notifications.view", "notifications.send"],
  "analytics.view": ["analytics.overview.view", "analytics.revenue.view", "analytics.bookings.view", "analytics.users.view", "analytics.technicians.view", "analytics.growth.view", "analytics.reports.view"],
  "analytics.export": ["analytics.overview.export", "analytics.revenue.export", "analytics.bookings.export", "analytics.users.export", "analytics.technicians.export", "analytics.growth.export", "analytics.reports.export"],
  "reports.view": ["analytics.reports.view"],
  "reports.export": ["analytics.reports.export"],
  "account.view": ["account.profile.view", "account.sessions.view", "account.password.view", "account.twoFactor.view", "account.devices.view", "account.notifications.view", "account.apiTokens.view"],
  "account.edit": ["account.profile.edit", "account.password.edit", "account.twoFactor.edit", "account.notifications.edit"],
  "settings.view": ["settings.company.view", "settings.branding.view", "settings.appearance.view", "settings.integrations.view", "settings.security.view", "settings.notifications.view", "settings.billing.view", "settings.apiKeys.view", "settings.backup.view", "settings.system.view"],
  "settings.edit": ["settings.company.edit", "settings.branding.edit", "settings.appearance.edit", "settings.integrations.edit", "settings.integrations.apiCenter.edit", "settings.security.edit", "settings.notifications.edit", "settings.billing.edit", "settings.system.edit"],
  "settings.integrations.ai.view": ["settings.integrations.ai.view", "settings.integrations.apiCenter.view"],
  "settings.integrations.ai.edit": ["settings.integrations.ai.edit", "settings.integrations.apiCenter.edit"],
  "settings.integrations.ai.test": ["settings.integrations.ai.test", "settings.integrations.apiCenter.test"],
  "settings.integrations.ai.disable": ["settings.integrations.ai.disable", "settings.integrations.apiCenter.disable"],
  "settings.integrations.ai.rotateKey": ["settings.integrations.ai.rotateKey", "settings.integrations.apiCenter.rotateKey"],
};

const impliedByAction: Record<string, string[]> = {
  create: ["view"],
  edit: ["view"],
  delete: ["view"],
  export: ["view"],
  aiSummary: ["view"],
  approve: ["view"],
  hide: ["view"],
  reject: ["view"],
  assign: ["view"],
  enable: ["view"],
  disable: ["view"],
  sync: ["view"],
  send: ["view"],
  resend: ["view"],
  test: ["view"],
  cancel: ["view"],
  refund: ["view"],
  payout: ["view"],
  verify: ["view"],
  rotateKey: ["view"],
  wallet: ["view"],
  documents: ["view"],
  reply: ["view"],
  resolve: ["view"],
  reopen: ["view"],
  resetPassword: ["view"],
  warn: ["view"],
  suspend: ["view"],
  reactivate: ["view"],
  blacklist: ["view"],
  sensitive: ["view"],
};

export function isSuperAdminRole(roleName: string | undefined | null) {
  const normalized = String(roleName ?? "")
    .trim()
    .toLowerCase()
    .replace(/[_-]+/g, " ");
  return normalized === "super admin";
}

function addPermissionWithImplications(target: Set<Permission>, permission: Permission) {
  target.add(permission);
  const dot = permission.lastIndexOf(".");
  if (dot <= 0) return;
  const leaf = permission.slice(0, dot);
  const action = permission.slice(dot + 1);
  for (const impliedAction of impliedByAction[action] ?? []) {
    target.add(`${leaf}.${impliedAction}`);
  }
}

export function expandPermissions(permissions: Permission[] = []) {
  const expanded = new Set<Permission>();
  const queue = [...permissions];
  while (queue.length) {
    const permission = queue.shift();
    if (!permission || expanded.has(permission)) continue;
    addPermissionWithImplications(expanded, permission);
    for (const alias of legacyPermissionAliases[permission] ?? []) {
      if (!expanded.has(alias)) queue.push(alias);
    }
  }
  return expanded;
}

export function hasPermission(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  permission: Permission,
) {
  if (isSuperAdminRole(roleName)) return true;
  if (superAdminOnlyPermissions.includes(permission)) return false;
  const expanded = expandPermissions(permissions);
  if (expanded.has(permission)) return true;
  return (legacyPermissionAliases[permission] ?? []).some((alias) =>
    expanded.has(alias),
  );
}

export function normalizePermissionList(permissions: Permission[]) {
  const allowed = new Set(allPermissions);
  const normalized = new Set<Permission>();
  const expanded = expandPermissions(permissions);
  for (const permission of expanded) {
    if (!allowed.has(permission as StructuredPermission)) continue;
    if (superAdminOnlyPermissions.includes(permission)) continue;
    addPermissionWithImplications(normalized, permission);
  }
  return Array.from(normalized)
    .filter((permission) => allowed.has(permission as StructuredPermission))
    .sort() as StructuredPermission[];
}

export function normalizeRolePermissions(permissions: Permission[]) {
  const normalized = new Set<Permission>(normalizePermissionList(permissions));
  normalized.add("overview.view");
  return Array.from(normalized)
    .filter((permission) => new Set(allPermissions).has(permission as StructuredPermission))
    .sort() as StructuredPermission[];
}

export function permissionsForLeaf(leafId: string) {
  const leaf = permissionModules.find((module) => module.id === leafId);
  return (leaf?.actions ?? []).map((action) => `${leafId}.${action}` as Permission);
}

export function groupPermissions(groupId: string) {
  const group = permissionTree.find((item) => item.id === groupId);
  return (group?.children ?? []).flatMap((child) => permissionsForLeaf(child.id));
}

export const sectionPermissions = {
  Overview: ["overview.view"],
  "Command Center": ["operations.commandCenter.view", "overview.view"],
  "AI Executive": ["ai.chat.view", "ai.history.view"],
  "Live operations": ["operations.dispatch.view", "operations.liveJobs.view", "operations.map.view"],
  "Live Operations Map": ["operations.map.view"],
  "Smart Alerts": ["operations.smartAlerts.view"],
  "Customer Intelligence": ["customers.view"],
  "Booking Control Center": ["operations.bookingControl.view", "jobs.view", "bookings.emergency.view", "bookings.scheduled.view", "bookings.quotation.view"],
  "SLA Monitoring": ["operations.sla.view"],
  "Financial Control Center": ["payments.transactions.view", "payments.reports.view"],
  "Fraud & Risk Center": ["complaints.view", "customers.view", "providers.view"],
  "Quality Control Center": ["reviews.view", "complaints.view", "technicians.reviews.view"],
  "Automation Rules": ["operations.automationRules.view"],
  "Notification Center": ["operations.notifications.view", "notifications.view"],
  "Reports Center": ["operations.reports.view", "analytics.reports.view"],
  "Activity Timeline": ["operations.timeline.view", "audit.view"],
  "System Health": ["operations.systemHealth.view", "settings.integrations.apiCenter.view"],
  "Advanced Search": ["operations.advancedSearch.view"],
  Jobs: ["jobs.view"],
  Providers: ["providers.view"],
  "Technician Performance": ["technicians.performance.view"],
  Customers: ["customers.view"],
  "Trust & safety": ["complaints.view"],
  Payments: ["payments.transactions.view", "payments.refunds.view", "payments.payouts.view", "payments.reports.view"],
  "Services & pricing": ["services.categories.view", "services.services.view", "services.pricing.view"],
  "Content & banners": ["content.banners.view"],
  "Support chats": ["support.liveChat.view", "support.tickets.view"],
  Promotions: ["promotions.view"],
  Analytics: ["analytics.overview.view", "analytics.reports.view"],
  "Admin & roles": ["adminUsers.view", "invitations.view", "roles.view", "audit.view"],
  Account: ["account.profile.view"],
  Settings: ["settings.company.view", "settings.branding.view", "settings.appearance.view", "settings.integrations.view", "settings.integrations.apiCenter.view", "settings.security.view", "settings.notifications.view", "settings.system.view"],
  "System Reset": ["system.reset"],
} as const satisfies Record<string, readonly Permission[]>;

export function canAccessAnySection(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  section: keyof typeof sectionPermissions,
) {
  return sectionPermissions[section].some((permission) =>
    hasPermission(roleName, permissions, permission),
  );
}

export function hasAnyPermission(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  required: readonly Permission[],
) {
  return required.some((permission) =>
    hasPermission(roleName, permissions, permission),
  );
}

export function hasAllPermissions(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  required: readonly Permission[],
) {
  return required.every((permission) =>
    hasPermission(roleName, permissions, permission),
  );
}

export function canAccessRoute(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  section: keyof typeof sectionPermissions,
) {
  return canAccessAnySection(roleName, permissions, section);
}

export function canRenderComponent(
  roleName: string | undefined,
  permissions: Permission[] | undefined,
  required: Permission | readonly Permission[],
) {
  return typeof required === "string"
    ? hasPermission(roleName, permissions, required)
    : hasAnyPermission(roleName, permissions, required);
}

export function filterNavigation<T extends { label: keyof typeof sectionPermissions }>(
  items: readonly T[],
  roleName: string | undefined,
  permissions: Permission[] | undefined,
) {
  return items.filter((item) => canAccessRoute(roleName, permissions, item.label));
}

export function moduleViewPermission(moduleId: string) {
  return `${moduleId}.view` as StructuredPermission;
}
