import { firebaseAdminAuth, firebaseAdminDb } from "@/lib/firebase/admin";
import { hasPermission } from "@/lib/permissions";
import { errorMessage, requestId, serverLog } from "@/lib/server/logger";

async function loadRolePermissions(roleId: string | undefined, fallback: string[] = []) {
  if (!roleId) return fallback;
  const snapshot = await firebaseAdminDb.collection("roles").doc(roleId).get();
  if (!snapshot.exists) return fallback;
  const data = snapshot.data() as { permissions?: unknown };
  return Array.isArray(data.permissions)
    ? data.permissions.filter((item): item is string => typeof item === "string")
    : fallback;
}

export async function requireFirebaseAdmin(request: Request, permission?: string) {
  const id = requestId(request);
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) {
    serverLog("warn", "Missing Firebase bearer token", {
      requestId: id,
      path: new URL(request.url).pathname,
    });
    throw new Response("Unauthorized", {
      status: 401,
      statusText: "Unauthorized",
    });
  }
  let token;
  try {
    token = await firebaseAdminAuth.verifyIdToken(header.slice(7), true);
  } catch (error) {
    const code = (error as { code?: string }).code;
    const status = code === "auth/id-token-revoked" || code === "auth/user-disabled"
      ? 401
      : 401;
    serverLog("warn", "Firebase token rejected", {
      requestId: id,
      path: new URL(request.url).pathname,
      code,
      error: errorMessage(error),
    });
    throw new Response(
      code === "auth/user-disabled"
        ? "This account is disabled"
        : "Unauthorized",
      {
        status,
        statusText:
          code === "auth/user-disabled" ? "This account is disabled" : "Unauthorized",
      },
    );
  }
  const snapshot = await firebaseAdminDb.collection("admins").doc(token.uid).get();
  if (!snapshot.exists) {
    serverLog("warn", "Admin profile missing for authenticated user", {
      requestId: id,
      uid: token.uid,
      path: new URL(request.url).pathname,
    });
    throw new Response("Unauthorized", {
      status: 401,
      statusText: "Unauthorized",
    });
  }
  const admin = snapshot.data() as {
    name: string;
    status: string;
    role: string;
    roleId?: string;
    permissions?: string[];
    disabled?: boolean;
    enabled?: boolean;
    authDisabled?: boolean;
    isDemoUser?: boolean;
    demoExpiresAt?: string;
  };
  const demoExpiresAt = admin.demoExpiresAt ? new Date(admin.demoExpiresAt).getTime() : 0;
  if (
    admin.status !== "Active" ||
    admin.disabled ||
    admin.enabled === false ||
    admin.authDisabled === true ||
    (admin.isDemoUser && Number.isFinite(demoExpiresAt) && demoExpiresAt > 0 && demoExpiresAt <= Date.now())
  ) {
    serverLog("warn", "Inactive admin blocked from API", {
      requestId: id,
      uid: token.uid,
      status: admin.status,
      disabled: Boolean(admin.disabled),
      enabled: admin.enabled,
      authDisabled: admin.authDisabled,
      path: new URL(request.url).pathname,
    });
    throw new Response("This administrator account is disabled", {
      status: 401,
      statusText:
        admin.isDemoUser && Number.isFinite(demoExpiresAt) && demoExpiresAt > 0 && demoExpiresAt <= Date.now()
          ? "Demo access expired."
          : "This administrator account is disabled",
    });
  }
  if (
    permission &&
    !hasPermission(
      admin.role,
      await loadRolePermissions(admin.roleId, admin.permissions),
      permission,
    )
  ) {
    serverLog("warn", "Admin permission denied", {
      requestId: id,
      uid: token.uid,
      permission,
      path: new URL(request.url).pathname,
    });
    throw new Response("Forbidden", { status: 403, statusText: "Forbidden" });
  }
  const permissions = await loadRolePermissions(admin.roleId, admin.permissions);
  return { id: token.uid, email: token.email ?? "", ...admin, permissions };
}

export function firebaseApiError(error: unknown, context: Record<string, unknown> = {}) {
  if (error instanceof Response) {
    return Response.json(
      { error: error.statusText || errorMessage(error) },
      { status: error.status },
    );
  }
  serverLog("error", "Firebase API operation failed", {
    ...context,
    error: errorMessage(error),
    code: (error as { code?: string }).code,
  });
  return Response.json(
    { error: error instanceof Error ? error.message : "Firebase operation failed" },
    { status: 500 },
  );
}
