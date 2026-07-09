import { firebaseAdminAuth, firebaseAdminDb } from "@/lib/firebase/admin";
import { firebaseProjectId, firebaseStorageBucket } from "@/lib/firebase/config";
import { requestId, serverLog } from "@/lib/server/logger";

export const runtime = "nodejs";

const has = (name: string) => Boolean(process.env[name]?.trim());

export async function GET(request: Request) {
  const id = requestId(request);
  const startedAt = Date.now();
  const checks = {
    firebaseProject: Boolean(firebaseProjectId()),
    firestore: false,
    auth: false,
    storageBucket: Boolean(firebaseStorageBucket()),
    resend: has("RESEND_API_KEY") && has("RESEND_FROM_EMAIL") && has("RESEND_FROM_NAME"),
    maps: has("NEXT_PUBLIC_GOOGLE_MAPS_API_KEY"),
    gemini: has("GEMINI_API_KEY"),
  };
  try {
    await firebaseAdminDb.collection("healthChecks").limit(1).get();
    checks.firestore = true;
  } catch (error) {
    serverLog("error", "Health check Firestore probe failed", {
      requestId: id,
      error,
    });
  }
  try {
    await firebaseAdminAuth.listUsers(1);
    checks.auth = true;
  } catch (error) {
    serverLog("error", "Health check Firebase Auth probe failed", {
      requestId: id,
      error,
    });
  }
  const healthy = checks.firebaseProject && checks.firestore && checks.auth;
  serverLog(healthy ? "info" : "warn", "Health check completed", {
    requestId: id,
    healthy,
    checks,
    durationMs: Date.now() - startedAt,
  });
  return Response.json(
    {
      ok: healthy,
      service: "task-admin-dashboard",
      timestamp: new Date().toISOString(),
      checks,
    },
    { status: healthy ? 200 : 503 },
  );
}
