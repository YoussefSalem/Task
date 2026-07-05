import { loadEnvConfig } from "@next/env";

loadEnvConfig(process.cwd());

const email = process.env.FIREBASE_SEED_ADMIN_EMAIL?.trim().toLowerCase() || '';
const password = process.env.FIREBASE_SEED_ADMIN_PASSWORD || '';
const name = process.env.FIREBASE_SEED_ADMIN_NAME?.trim() || "Task Super Admin";

if (!email || !password) {
  throw new Error(
    "Set FIREBASE_SEED_ADMIN_EMAIL and FIREBASE_SEED_ADMIN_PASSWORD in .env.local before running npm run seed.",
  );
}
if (password.length < 12) {
  throw new Error("FIREBASE_SEED_ADMIN_PASSWORD must contain at least 12 characters.");
}

async function main() {
  const firebaseAdminModule = await import("../lib/firebase/admin");
  const claimsModule = await import("../lib/firebase/rbac-claims");
  const permissionsModule = await import("../lib/permissions");
  const firebaseAdminExports = (
    "default" in firebaseAdminModule ? firebaseAdminModule.default : firebaseAdminModule
  ) as typeof import("../lib/firebase/admin");
  const claimsExports = (
    "default" in claimsModule ? claimsModule.default : claimsModule
  ) as typeof import("../lib/firebase/rbac-claims");
  const permissionsExports = (
    "default" in permissionsModule ? permissionsModule.default : permissionsModule
  ) as typeof import("../lib/permissions");
  const { firebaseAdminAuth, firebaseAdminDb } = firebaseAdminExports;
  const { smallDashboardClaims } = claimsExports;
  const { fullAccessPermissions, normalizeRolePermissions } = permissionsExports;

  const operationsPermissions = normalizeRolePermissions([
    "operations.view",
    "operations.assign",
    "customers.read",
    "customers.write",
    "providers.read",
    "providers.approve",
    "providers.suspend",
    "jobs.read",
    "jobs.write",
    "services.manage",
  ]);

  const financePermissions = normalizeRolePermissions([
    "customers.read",
    "providers.read",
    "jobs.read",
    "payments.read",
    "payments.manage",
    "payments.refund",
    "payments.payout",
    "audit.read",
  ]);

  const supportPermissions = normalizeRolePermissions([
    "customers.read",
    "customers.write",
    "providers.read",
    "jobs.read",
    "jobs.write",
    "trust.manage",
    "support.view",
    "support.reply",
  ]);

  const verificationPermissions = normalizeRolePermissions([
    "providers.read",
    "providers.approve",
    "providers.suspend",
    "providers.documents",
    "audit.read",
  ]);

  const roles = [
    {
      id: "super-admin",
      name: "Super admin",
      description: "Full control over Task operations, configuration, and administrators.",
      permissions: [...fullAccessPermissions],
      version: 2,
      system: true,
    },
    {
      id: "operations-manager",
      name: "Operations Manager",
      description: "Dispatch, orders, providers, customers, and service catalog.",
      permissions: operationsPermissions,
      version: 2,
      system: true,
    },
    {
      id: "finance-manager",
      name: "Finance Manager",
      description: "Payments, wallets, payouts, refunds, and financial audit visibility.",
      permissions: financePermissions,
      version: 2,
      system: true,
    },
    {
      id: "support-agent",
      name: "Support Agent",
      description: "Customer support, order visibility, communication, and complaints.",
      permissions: supportPermissions,
      version: 2,
      system: true,
    },
    {
      id: "verification-officer",
      name: "Verification Officer",
      description: "Provider onboarding, documents, background checks, and suspensions.",
      permissions: verificationPermissions,
      version: 2,
      system: true,
    },
  ];

const verificationRequirements = [
  ["national-id-front", "National ID (Front)", true],
  ["national-id-back", "National ID (Back)", true],
  ["criminal-record", "Criminal Record", true],
  ["provider-contract", "Signed Provider Agreement / Contract", true],
  ["id-selfie", "Selfie holding National ID", true],
  ["personal-photo", "Personal photo", true],
  ["professional-license", "Professional license", false],
  ["trade-license", "Trade license", false],
  ["tax-card", "Tax card", false],
  ["commercial-register", "Commercial register", false],
  ["insurance", "Insurance documents", false],
  ["vehicle-documents", "Vehicle documents", false],
  ["iban-proof", "Bank account / IBAN proof", true],
  ["instapay-details", "Instapay account details", false],
  ["custom-document", "Custom document", false],
] as const;

let authUser;
try {
  authUser = await firebaseAdminAuth.getUserByEmail(email);
  authUser = await firebaseAdminAuth.updateUser(authUser.uid, {
    password,
    displayName: name,
    disabled: false,
  });
} catch (error) {
  if ((error as { code?: string }).code !== "auth/user-not-found") throw error;
  authUser = await firebaseAdminAuth.createUser({
    email,
    password,
    displayName: name,
    emailVerified: true,
    disabled: false,
  });
}

await firebaseAdminAuth.setCustomUserClaims(authUser.uid, {
  ...smallDashboardClaims({
    role: "Super admin",
    roleId: "super-admin",
  }),
});

const now = new Date().toISOString();
const batch = firebaseAdminDb.batch();

for (const role of roles) {
  batch.set(firebaseAdminDb.collection("roles").doc(role.id), role, { merge: true });
}

verificationRequirements.forEach(([id, type, required], sortOrder) => {
  batch.set(firebaseAdminDb.collection("verificationRequirements").doc(id), { id, type, required, enabled: true, sortOrder }, { merge: true });
});

batch.set(
  firebaseAdminDb.collection("admins").doc(authUser.uid),
  {
    id: authUser.uid,
    uid: authUser.uid,
    name,
    email,
    phone: "",
    department: "Executive Operations",
    jobTitle: "Super Administrator",
    role: "Super admin",
    roleId: "super-admin",
    permissions: [...fullAccessPermissions],
    status: "Active",
    enabled: true,
    authDisabled: false,
    lastSeen: "Never",
    twoFactorEnabled: false,
    theme: "system",
    locale: "en",
    createdAt: now,
    updatedAt: now,
  },
  { merge: true },
);

batch.set(
  firebaseAdminDb.collection("settings").doc("dashboard"),
  {
    general: {
      companyName: "Task",
      companyEmail: email,
      companyPhone: "",
      companyAddress: "Cairo, Egypt",
      timezone: "Africa/Cairo",
      currency: "EGP",
      language: "English",
      dateFormat: "DD/MM/YYYY",
    },
    branding: {
      companyLogo: "/task-logo.svg",
      dashboardLogo: "/task-logo.svg",
      favicon: "/task-logo.svg",
      loginLogo: "/task-logo.svg",
      sidebarLogo: "/task-logo.svg",
    },
    appearance: { accentColor: "#6366f1", sidebarCollapsed: false },
    notifications: {
      email: true,
      push: true,
      jobs: true,
      complaints: true,
      finance: true,
      system: true,
    },
    integrations: {
      firebase: { enabled: true, value: "Configured through environment variables", updatedAt: now },
      googleMaps: { enabled: Boolean(process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY), value: "Environment managed", updatedAt: now },
      resend: { enabled: false, value: "Firebase Auth email actions are active", updatedAt: now },
      gemini: { enabled: Boolean(process.env.GEMINI_API_KEY), value: "Server-side Gemini API", updatedAt: now },
      twilio: { enabled: false, value: "", updatedAt: now },
      stripe: { enabled: false, value: "", updatedAt: now },
      instapay: { enabled: false, value: "", updatedAt: now },
      supabase: { enabled: false, value: "", updatedAt: now },
    },
  },
  { merge: true },
);

batch.set(firebaseAdminDb.collection("system").doc("counters"), { provider: 0 }, { merge: true });
batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
  actorId: authUser.uid,
  actorName: name,
  action: "firebase.seed",
  entityType: "system",
  entityId: "bootstrap",
  detail: "Firebase Auth, RBAC roles, dashboard settings, and provider counter initialized.",
  createdAt: now,
});

await batch.commit();
await firebaseAdminDb.terminate();

console.log(`Firebase bootstrap completed for ${email}.`);

}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
