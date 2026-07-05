import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const read = (file) => readFileSync(join(root, file), "utf8");
const walk = (directory) => readdirSync(join(root, directory)).flatMap((entry) => {
  const relative = join(directory, entry);
  return statSync(join(root, relative)).isDirectory() ? walk(relative) : [relative];
});

const provider = read("components/admin-data-provider.tsx");
const repository = read("lib/firebase/repository.ts");
const adminRoute = read("app/api/firebase/admin-users/route.ts");
const authSessionRoute = read("app/api/firebase/auth/session/route.ts");
const aiPage = read("components/ai-executive-page.tsx");
const aiRoute = read("app/api/firebase/ai/route.ts");
const operationsRoute = read("app/api/firebase/operations/route.ts");
const passwordResetRoute = read("app/api/firebase/password-reset/route.ts");
const forgotPasswordPage = read("app/forgot-password/page.tsx");
const runtimeFiles = [...walk("app"), ...walk("components"), ...walk("lib")]
  .filter((file) => /\.(ts|tsx)$/.test(file))
  .map(read)
  .join("\n");

for (const forbidden of ["next-auth", "@prisma/client", "DATABASE_URL", "/api/state", "/api/operations", "mock-data", "sampleData"]) {
  assert.ok(!runtimeFiles.includes(forbidden), `Runtime still contains forbidden legacy dependency: ${forbidden}`);
}
assert.ok(!runtimeFiles.includes(".sessionStorage.setItem"), "Runtime must not persist dashboard data with sessionStorage");
const localStorageWrites = [...runtimeFiles.matchAll(/localStorage\.setItem\(([^)]+)\)/g)].map((match) => match[0]);
for (const write of localStorageWrites) {
  assert.ok(
    write.includes("task-admin-invite-token"),
    `Runtime must not persist dashboard data with browser localStorage: ${write}`,
  );
}

for (const required of ["firebase/auth", "firebase/firestore", "firebase/storage", "subscribeDashboard", "performFirestoreOperation", "/api/firebase/admin-users"]) {
  assert.ok(runtimeFiles.includes(required), `Firebase production wiring is missing ${required}`);
}

const firestoreActions = [
  "createAiExecution", "updateAiExecution", "acceptAiRecommendation", "rememberAiContext", "createAiReport",
  "createCustomer", "updateCustomer", "adjustWallet",
  "createProvider", "updateProvider", "updateProviderLocation", "setProviderDecision",
  "uploadProviderDocument", "replaceProviderDocument", "reviewProviderDocument", "deleteProviderDocument",
  "assignVerificationOfficer", "addProviderVerificationNote", "updateProviderBackgroundCheck",
  "createCategory", "updateCategory", "deleteCategory", "createService", "updateService", "deleteService", "toggleService",
  "createBanner", "updateBanner", "deleteBanner", "createConversation", "updateConversation", "addConversationMessage", "deleteConversation",
  "createJob", "updateJob", "assignProvider", "changeJobStatus", "refundJob", "addJobNote", "updateCancellation",
  "flagMessage", "reviewCall", "reviewInstapay", "setWalletFrozen", "deleteJob",
  "createComplaint", "updateComplaint", "setCaseOwner", "setCaseSeverity", "addCaseNote", "closeCase", "reopenCase", "deleteComplaint",
  "createPayout", "verifyPayout", "createTransaction", "updateTransaction",
  "createPromo", "updatePromo", "deletePromo", "createNotification",
];

for (const action of firestoreActions) {
  assert.ok(provider.includes(`execute("${action}"`), `${action} is not connected from the UI data layer`);
  assert.ok(repository.includes(`"${action}"`), `${action} has no Firestore implementation`);
}

for (const destructiveAction of ["deleteCustomer", "deleteProvider", "toggleCustomer", "toggleProvider"]) {
  assert.ok(provider.includes(`operationsRequest({action:"${destructiveAction}"`), `${destructiveAction} must go through the server-side operations API`);
  assert.ok(operationsRoute.includes(destructiveAction), `${destructiveAction} is missing from the server-side operations API`);
}

assert.ok(provider.includes('adminRequest({action:"update"'), "Administrator edits must update Firebase Auth and Firestore through the Admin SDK route");
assert.ok(provider.includes('adminRequest({action:"delete"'), "Administrator deletion must delete through the Admin SDK route");
assert.ok(provider.includes('adminRequest({action:"sync-auth-users"'), "Firebase Console-created Auth users must be syncable into Firestore admin profiles");
assert.ok(provider.includes('adminRequest<Role>({action:"role-create"'), "Role creation must update Firestore roles through the Admin SDK route");
assert.ok(provider.includes('adminRequest({action:"role-update"'), "Role edits must update Firestore roles through the Admin SDK route");
assert.ok(provider.includes('adminRequest({action:"role-delete"'), "Role deletion must update Firestore roles through the Admin SDK route");
assert.ok(runtimeFiles.includes("/api/firebase/auth/session"), "Login must verify Firebase Auth users through the server session route");
assert.ok(authSessionRoute.includes("verifyIdToken"), "Session route must verify Firebase ID tokens server-side");
assert.ok(authSessionRoute.includes("admins"), "Session route must verify or create the Firestore admin profile");
assert.ok(authSessionRoute.includes("smallDashboardClaims"), "Session route must write only small dashboard claims");
assert.ok(!authSessionRoute.includes("claims.permissions"), "Session route must not read permission arrays from custom claims");
assert.ok(!authSessionRoute.includes("permissions: normalized.permissions"), "Session route must not write permission arrays to custom claims");
assert.ok(!provider.includes("sendPasswordResetEmail"), "Invitation emails must not be sent from the browser");
assert.ok(!forgotPasswordPage.includes("firebase/auth"), "Reset password page must not use the Firebase client email sender");
assert.ok(!forgotPasswordPage.includes("sendPasswordResetEmail"), "Reset password page must call the server Resend route, not Firebase client email");
assert.ok(forgotPasswordPage.includes("/api/firebase/password-reset"), "Reset password page must post to the server Resend route");
assert.ok(adminRoute.includes("generatePasswordResetLink"), "Admin invitations must generate setup links with the Firebase Admin SDK");
assert.ok(adminRoute.includes("sendInvitationEmail"), "Admin invitations must send through the server-side email provider");
assert.ok(passwordResetRoute.includes("generatePasswordResetLink"), "Password reset must generate secure reset links with the Firebase Admin SDK");
assert.ok(passwordResetRoute.includes("sendPasswordResetEmail"), "Password reset must send through the server-side Resend provider");
assert.ok(existsSync(join(root, "app/api/firebase/health/route.ts")), "Health API route is missing");
assert.ok(!aiPage.includes("routeAiRequest"), "AI responses must not be generated in the browser");
assert.ok(aiPage.includes("/api/firebase/ai"), "AI page must call the server-side Gemini route");
assert.ok(aiRoute.includes("runGeminiAiExecution"), "AI route must execute through Gemini server-side");
assert.ok(runtimeFiles.includes("GEMINI_API_KEY"), "Gemini server environment variable is missing");
assert.ok(runtimeFiles.includes("OPENAI_API_KEY"), "OpenAI server fallback environment variable is missing");
assert.ok(runtimeFiles.includes("API_CENTER_ENCRYPTION_KEY"), "API Center encryption environment variable is missing");
assert.ok(runtimeFiles.includes("RESEND_FROM_NAME"), "Resend sender display name environment variable is missing");
assert.ok(runtimeFiles.includes("/api/firebase/integrations"), "API Center must call the secure Firebase integrations route");

for (const requiredFile of ["firebase.json", "firestore.rules", "storage.rules", "scripts/seed-firebase.ts", ".env.example"]) {
  assert.ok(existsSync(join(root, requiredFile)), `${requiredFile} is missing`);
}

const apiRoutes = walk("app/api").filter((file) => file.endsWith("route.ts")).sort();
assert.deepEqual(apiRoutes, [
  "app/api/firebase/admin-users/route.ts",
  "app/api/firebase/ai/route.ts",
  "app/api/firebase/auth/session/route.ts",
  "app/api/firebase/demo/reset/route.ts",
  "app/api/firebase/health/route.ts",
  "app/api/firebase/integration-status/route.ts",
  "app/api/firebase/integrations/route.ts",
  "app/api/firebase/operations/route.ts",
  "app/api/firebase/password-reset/route.ts",
  "app/api/firebase/system-reset/route.ts",
], "A legacy non-Firebase API route still ships");

const packageJson = read("package.json");
for (const legacy of ["prisma", "next-auth", "@aws-sdk/client-s3"]) {
  assert.ok(!packageJson.includes(legacy), `package.json still contains ${legacy}`);
}

console.log(`Firebase wiring verified: ${firestoreActions.length} dashboard mutations and all runtime reads are Firebase-backed.`);
