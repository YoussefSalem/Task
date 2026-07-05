import { firebaseAdminAuth, firebaseAdminDb } from "@/lib/firebase/admin";
import { requestId, serverLog, errorMessage } from "@/lib/server/logger";
import { createHash } from "node:crypto";
import { smallDashboardClaims } from "@/lib/firebase/rbac-claims";

export const runtime = "nodejs";

type AdminProfile = {
  id: string;
  uid: string;
  email: string;
  name: string;
  role: string;
  roleId: string;
  permissions: string[];
  status: "Active" | "Disabled" | "Invited";
  enabled: boolean;
  authDisabled: boolean;
  lastSeen: string;
  createdAt: string;
  updatedAt: string;
  [key: string]: unknown;
};

type AdminInvite = {
  id: string;
  email?: string;
  roleId?: string;
  roleName?: string;
  status?: string;
  expiresAt?: string;
};

function normalizeEmail(value: unknown) {
  return String(value ?? "").trim().toLowerCase();
}

function hashInvitationToken(token: string) {
  return createHash("sha256").update(token).digest("hex");
}

function allowedEmails() {
  return new Set(
    [
      process.env.FIREBASE_SEED_ADMIN_EMAIL,
      ...(process.env.ADMIN_ALLOWED_EMAILS ?? "").split(","),
    ]
      .map(normalizeEmail)
      .filter(Boolean),
  );
}

async function roleFor(roleId?: string, roleName?: string) {
  if (roleId) {
    const snapshot = await firebaseAdminDb.collection("roles").doc(roleId).get();
    if (snapshot.exists) {
      const role = snapshot.data() as { name?: string; permissions?: string[] };
      return {
        roleId,
        role: role.name ?? roleName ?? "Support",
        permissions: role.permissions ?? [],
      };
    }
  }
  return {
    roleId: roleId ?? "support",
    role: roleName ?? "Support",
    permissions: [],
  };
}

async function findInvite(uid: string, email: string): Promise<AdminInvite | null> {
  const direct = await firebaseAdminDb.collection("adminInvites").doc(uid).get();
  if (direct.exists)
    return { id: direct.id, ...(direct.data() as Omit<AdminInvite, "id">) };
  const byEmail = await firebaseAdminDb
    .collection("adminInvites")
    .where("email", "==", email)
    .limit(1)
    .get();
  if (byEmail.empty) return null;
  return {
    id: byEmail.docs[0].id,
    ...(byEmail.docs[0].data() as Omit<AdminInvite, "id">),
  };
}

async function findAdminByEmail(email: string) {
  const direct = await firebaseAdminDb
    .collection("admins")
    .where("email", "==", email)
    .limit(1)
    .get();
  if (!direct.empty) return direct.docs[0];
  return null;
}

function toClientProfile(data: AdminProfile) {
  return {
    id: data.uid,
    uid: data.uid,
    name: data.name,
    email: data.email,
    role: data.role,
    roleId: data.roleId,
    permissions: data.permissions,
    status: data.status,
    enabled: data.enabled,
    authDisabled: data.authDisabled,
    lastSeen: data.lastSeen,
    createdAt: data.createdAt,
    updatedAt: data.updatedAt,
    phone: String(data.phone ?? ""),
    department: String(data.department ?? ""),
    jobTitle: String(data.jobTitle ?? ""),
    avatar: String(data.avatar ?? ""),
    twoFactorEnabled: Boolean(data.twoFactorEnabled),
    isDemoUser: Boolean(data.isDemoUser),
    demoExpiresAt: data.demoExpiresAt ? String(data.demoExpiresAt) : "",
    demoCompanyName: String(data.demoCompanyName ?? ""),
    demoContactName: String(data.demoContactName ?? ""),
    demoNotes: String(data.demoNotes ?? ""),
  };
}

export async function POST(request: Request) {
  const logId = requestId(request);
  try {
    const header = request.headers.get("authorization");
    if (!header?.startsWith("Bearer "))
      return Response.json({ error: "Unauthorized" }, { status: 401 });
    const body = (await request.json().catch(() => ({}))) as {
      inviteToken?: unknown;
    };
    const inviteToken = String(body.inviteToken ?? "").trim();

    const token = await firebaseAdminAuth.verifyIdToken(header.slice(7), true);
    const authUser = await firebaseAdminAuth.getUser(token.uid);
    const email = normalizeEmail(authUser.email ?? token.email);
    if (!email)
      return Response.json(
        { error: "This Firebase user has no email address." },
        { status: 403 },
      );

    const now = new Date().toISOString();
    const adminRef = firebaseAdminDb.collection("admins").doc(authUser.uid);
    let snapshot = await adminRef.get();
    let data = snapshot.exists
      ? ({ id: authUser.uid, uid: authUser.uid, ...snapshot.data() } as AdminProfile)
      : null;

    if (!data) {
      const emailMatch = await findAdminByEmail(email);
      if (emailMatch) {
        const legacy = emailMatch.data() as Record<string, unknown>;
        data = {
          ...(legacy as AdminProfile),
          id: authUser.uid,
          uid: authUser.uid,
          email,
          updatedAt: now,
        };
        const batch = firebaseAdminDb.batch();
        batch.set(adminRef, data, { merge: true });
        if (emailMatch.id !== authUser.uid) batch.delete(emailMatch.ref);
        batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
          actorId: "system",
          actorName: "Auth sync",
          action: "admin.profile_migrated_to_auth_uid",
          entityType: "admin",
          entityId: authUser.uid,
          detail: `Migrated admin profile for ${email} from ${emailMatch.id} to Firebase Auth UID`,
          createdAt: now,
        });
        await batch.commit();
        snapshot = await adminRef.get();
      }
    }

    if (!data) {
      const invite = await findInvite(authUser.uid, email);
      const claims = (authUser.customClaims ?? {}) as {
        roleId?: string;
        tenantId?: string;
        isSuperAdmin?: boolean;
      };
      const canCreateActive =
        Boolean(invite && !["Revoked", "Expired"].includes(String(invite.status))) ||
        allowedEmails().has(email) ||
        claims.isSuperAdmin === true;
      const role = await roleFor(
        invite?.roleId ?? claims.roleId ?? "",
        invite?.roleName || "",
      );
      data = {
        id: authUser.uid,
        uid: authUser.uid,
        email,
        name: authUser.displayName || email.split("@")[0],
        phone: "",
        department: "",
        jobTitle: "",
        role: role.role,
        roleId: role.roleId,
        permissions: role.permissions,
        status: canCreateActive ? "Active" : "Disabled",
        enabled: canCreateActive,
        authDisabled: authUser.disabled || !canCreateActive,
        lastSeen: "Never",
        twoFactorEnabled: false,
        createdAt: now,
        updatedAt: now,
      };
      await adminRef.set(data, { merge: true });
      if (invite) {
        await firebaseAdminDb.collection("adminInvites").doc(String(invite.id)).set(
          {
            adminId: authUser.uid,
            status: canCreateActive ? "Accepted" : invite.status,
            acceptedAt: canCreateActive ? now : null,
            updatedAt: now,
          },
          { merge: true },
        );
      }
      await firebaseAdminDb.collection("auditLogs").add({
        actorId: "system",
        actorName: "Auth sync",
        action: "admin.profile_created_from_auth",
        entityType: "admin",
        entityId: authUser.uid,
        detail: `Created ${canCreateActive ? "active" : "disabled"} admin profile for ${email}`,
        createdAt: now,
      });
    }

    const status = String(data.status ?? "").toLowerCase();
    const invite = await findInvite(authUser.uid, email);
    const inviteStatus = String(invite?.status ?? "").toLowerCase();
    const inviteExpiresAt = invite?.expiresAt ? new Date(String(invite.expiresAt)).getTime() : 0;
    const inviteTokenMatches =
      Boolean(inviteToken) &&
      Boolean((invite as Record<string, unknown> | null)?.tokenHash) &&
      hashInvitationToken(inviteToken) === String((invite as Record<string, unknown>).tokenHash);
    const inviteTokenUnused = !((invite as Record<string, unknown> | null)?.tokenUsedAt);
    const inviteExpired =
      inviteStatus === "pending" &&
      Number.isFinite(inviteExpiresAt) &&
      inviteExpiresAt > 0 &&
      inviteExpiresAt <= Date.now();
    if (inviteExpired) {
      await firebaseAdminDb.collection("adminInvites").doc(String(invite?.id)).set(
        {
          status: "Expired",
          expiredAt: now,
          updatedAt: now,
        },
        { merge: true },
      );
    }
    const invitedPending =
      status === "invited" &&
      Boolean(invite) &&
      inviteStatus === "pending" &&
      !inviteExpired &&
      inviteTokenMatches &&
      inviteTokenUnused;
    const invitedBlockedByToken =
      status === "invited" &&
      Boolean(invite) &&
      inviteStatus === "pending" &&
      !inviteExpired &&
      (!inviteTokenMatches || !inviteTokenUnused);
    const demoExpiresAt = data.demoExpiresAt ? new Date(String(data.demoExpiresAt)).getTime() : 0;
    const demoExpired = Boolean(data.isDemoUser) && Number.isFinite(demoExpiresAt) && demoExpiresAt > 0 && demoExpiresAt <= Date.now();
    const enabled = data.enabled !== false && (status === "active" || invitedPending);
    const authDisabled = authUser.disabled || data.authDisabled === true || !enabled || demoExpired;
    if (status === "invited" && (inviteExpired || inviteStatus === "expired")) {
      serverLog("warn", "Expired invitation blocked during auth sync", {
        requestId: logId,
        uid: authUser.uid,
        email,
      });
      return Response.json(
        { error: "This invitation has expired. Ask a Super Admin to resend it." },
        { status: 403 },
      );
    }
    if (status === "invited" && inviteStatus === "revoked") {
      serverLog("warn", "Revoked invitation blocked during auth sync", {
        requestId: logId,
        uid: authUser.uid,
        email,
      });
      return Response.json(
        { error: "This invitation has been revoked." },
        { status: 403 },
      );
    }
    if (invitedBlockedByToken) {
      serverLog("warn", "Invited admin blocked by missing or used invitation token", {
        requestId: logId,
        uid: authUser.uid,
        email,
      });
      return Response.json(
        { error: "This invitation link is invalid or has already been used." },
        { status: 403 },
      );
    }
    const normalized: AdminProfile = {
      ...data,
      id: authUser.uid,
      uid: authUser.uid,
      email,
      name: String(data.name ?? authUser.displayName ?? email.split("@")[0]),
      role: String(data.role ?? "Support"),
      roleId: String(data.roleId ?? "support"),
      permissions: (await roleFor(String(data.roleId ?? "support"), String(data.role ?? "Support"))).permissions,
      status: authDisabled ? "Disabled" : "Active",
      enabled: !authDisabled,
      authDisabled,
      lastSeen: now,
      createdAt: String(data.createdAt ?? now),
      updatedAt: now,
    };

    if (authDisabled) {
      if (!authUser.disabled)
        await firebaseAdminAuth.updateUser(authUser.uid, { disabled: true });
      await adminRef.set(normalized, { merge: true });
      serverLog("warn", "Disabled admin blocked during auth sync", {
        requestId: logId,
        uid: authUser.uid,
        email,
      });
      return Response.json(
        { error: demoExpired ? "This demo account has expired. Please contact Task to continue." : "This administrator account is disabled." },
        { status: 403 },
      );
    }

    await firebaseAdminAuth.setCustomUserClaims(authUser.uid, {
      ...smallDashboardClaims({
        role: normalized.role,
        roleId: normalized.roleId,
        tenantId: String(normalized.tenantId ?? "task"),
      }),
    });
    const batch = firebaseAdminDb.batch();
    batch.set(adminRef, normalized, { merge: true });
    if (invitedPending && invite) {
      batch.set(
        firebaseAdminDb.collection("adminInvites").doc(String(invite.id)),
        {
          status: "Accepted",
          acceptedAt: now,
          tokenUsedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );
    }
    await batch.commit();
    await firebaseAdminDb.collection("auditLogs").add({
      actorId: authUser.uid,
      actorName: normalized.name,
      action: Boolean(normalized.isDemoUser) ? "demo.login" : "admin.login",
      entityType: "admin",
      entityId: authUser.uid,
      detail: `${Boolean(normalized.isDemoUser) ? "Demo" : "Admin"} login for ${email}`,
      createdAt: now,
    });

    serverLog("info", "Admin session synchronized", {
      requestId: logId,
      uid: authUser.uid,
      email,
      role: normalized.role,
    });
    return Response.json({ admin: toClientProfile(normalized) });
  } catch (error) {
    const code = (error as { code?: string }).code;
    const message =
      code === "auth/user-disabled"
        ? "This administrator account is disabled."
        : errorMessage(error);
    serverLog("error", "Admin auth session sync failed", {
      requestId: logId,
      code,
      error: message,
    });
    return Response.json({ error: message }, { status: 401 });
  }
}
