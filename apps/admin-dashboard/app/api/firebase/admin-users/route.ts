import { z } from "zod";
import { createHash, randomBytes } from "node:crypto";
import { firebaseAdminAuth, firebaseAdminDb } from "@/lib/firebase/admin";
import {
  firebaseApiError,
  requireFirebaseAdmin,
} from "@/lib/firebase/server-auth";
import {
  dashboardUrl,
  sendInvitationEmail,
} from "@/lib/email/invitations";
import {
  fullAccessPermissions,
  hasPermission,
  normalizeRolePermissions,
} from "@/lib/permissions";
import { DEMO_RESTRICTED_MESSAGE } from "@/lib/demo-mode";
import { requestId, serverLog } from "@/lib/server/logger";
import { smallDashboardClaims } from "@/lib/firebase/rbac-claims";

const adminCreateSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().optional(),
  department: z.string().optional(),
  roleId: z.string(),
  isDemoUser: z.boolean().optional().default(false),
  demoExpiresAt: z.string().optional(),
  demoCompanyName: z.string().optional(),
  demoContactName: z.string().optional(),
  demoNotes: z.string().optional(),
});

const roleInputSchema = z.object({
  name: z.string().trim().min(1, "Role name is required"),
  description: z.string().trim().optional().default(""),
  permissions: z.array(z.string()).default([]),
});

const patchSchema = z.object({
  name: z.string().min(2).optional(),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  department: z.string().optional(),
  jobTitle: z.string().optional(),
  roleId: z.string().optional(),
  twoFactorEnabled: z.boolean().optional(),
  avatar: z.string().optional(),
  isDemoUser: z.boolean().optional(),
  demoExpiresAt: z.string().optional(),
  demoCompanyName: z.string().optional(),
  demoContactName: z.string().optional(),
  demoNotes: z.string().optional(),
});

const schema = z.object({
  action: z.enum([
    "create",
    "resend",
    "revoke",
    "disable",
    "delete",
    "toggle",
    "update",
    "update-profile",
    "sync-auth-users",
    "role-create",
    "role-update",
    "role-delete",
  ]),
  id: z.string().optional(),
  input: z.unknown().optional(),
  patch: patchSchema.optional(),
});

const INVITATION_TTL_MS = 7 * 86_400_000;

class InvitationDeliveryError extends Error {
  setupLink: string;
  expiresAt: string;
  constructor(message: string, setupLink: string, expiresAt: string) {
    super(message);
    this.name = "InvitationDeliveryError";
    this.setupLink = setupLink;
    this.expiresAt = expiresAt;
  }
}

function invitationExpiresAt() {
  return new Date(Date.now() + INVITATION_TTL_MS).toISOString();
}

function createInvitationToken() {
  return randomBytes(32).toString("base64url");
}

function hashInvitationToken(token: string) {
  return createHash("sha256").update(token).digest("hex");
}

async function recordInvitationEmailFailure(input: {
  adminId: string;
  email: string;
  actorId: string;
  actorName: string;
  error: unknown;
}) {
  const message =
    input.error instanceof Error ? input.error.message : "Invitation email failed";
  const now = new Date().toISOString();
  const batch = firebaseAdminDb.batch();
  batch.set(
    firebaseAdminDb.collection("adminInvites").doc(input.adminId),
    {
      emailDeliveryStatus: "Failed",
      lastEmailError: message,
      lastEmailAttemptAt: now,
    },
    { merge: true },
  );
  batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
    actorId: input.actorId,
    actorName: input.actorName,
    action: "admin.invitation_email_failed",
    entityType: "admin",
    entityId: input.adminId,
    detail: `Invitation email failed for ${input.email}: ${message}`,
    createdAt: now,
  });
  await batch.commit();
  return message;
}

async function sendAdminInvitation(input: {
  adminId: string;
  email: string;
  name: string;
  roleName: string;
  roleId?: string;
  permissions?: string[];
  invitedBy: string;
  actorId: string;
  actorName: string;
  resend?: boolean;
}) {
  const url = dashboardUrl();
  const now = new Date().toISOString();
  const token = createInvitationToken();
  const expiresAt = invitationExpiresAt();
  const tokenHash = hashInvitationToken(token);
  const inviteRef = firebaseAdminDb.collection("adminInvites").doc(input.adminId);
  const existingInvite = await inviteRef.get();
  const existingData = existingInvite.exists ? existingInvite.data() ?? {} : {};
  const resendCount = input.resend
    ? Number(existingData.resendCount ?? 0) + 1
    : Number(existingData.resendCount ?? 0);
  const setupLink = await firebaseAdminAuth.generatePasswordResetLink(
    input.email,
    {
      url: `${url}/login?invite=${encodeURIComponent(token)}`,
      handleCodeInApp: false,
    },
  );
  await inviteRef.set(
    {
      adminId: input.adminId,
      email: input.email,
      roleId: input.roleId ?? null,
      roleName: input.roleName,
      assignedPermissions: input.permissions ?? [],
      invitedBy: existingData.invitedBy ?? input.invitedBy,
      status: "Pending",
      tokenHash,
      tokenCreatedAt: now,
      tokenUsedAt: null,
      expiresAt,
      dashboardUrl: url,
      resendCount,
      ...(input.resend
        ? {
            lastResentAt: now,
            lastResentBy: input.actorName,
          }
        : {}),
      updatedAt: now,
    },
    { merge: true },
  );
  let sent;
  try {
    sent = await sendInvitationEmail({
      to: input.email,
      name: input.name,
      roleName: input.roleName,
      invitedBy: input.invitedBy,
      dashboardUrl: url,
      setupLink,
      expiresAt,
    });
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Invitation email provider failed.";
    throw new InvitationDeliveryError(message, setupLink, expiresAt);
  }
  const batch = firebaseAdminDb.batch();
  batch.set(
    inviteRef,
    {
      emailDeliveryStatus: "Sent",
      emailProvider: sent.provider,
      emailMessageId: sent.messageId,
      emailSentAt: sent.sentAt,
      lastEmailError: null,
      dashboardUrl: url,
      resentAt: input.resend ? sent.sentAt : existingData.resentAt ?? null,
      ...(input.resend
        ? {
            lastResentAt: sent.sentAt,
            lastResentBy: input.actorName,
          }
        : {}),
      resendCount,
      expiresAt,
    },
    { merge: true },
  );
  batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
    actorId: input.actorId,
    actorName: input.actorName,
    action: input.resend ? "admin.invitation_resent" : "admin.invitation_email_sent",
    entityType: "admin",
    entityId: input.adminId,
    detail: `${input.resend ? "Resent" : "Sent"} invitation email to ${input.email}`,
    createdAt: sent.sentAt,
  });
  await batch.commit();
  return { ...sent, setupLink, expiresAt, resendCount };
}

export async function POST(request: Request) {
  const logId = requestId(request);
  try {
    const actor = await requireFirebaseAdmin(request);
    const parsed = schema.parse(await request.json());
    if (
      actor.isDemoUser &&
      parsed.action !== "update-profile"
    ) {
      await firebaseAdminDb.collection("auditLogs").add({
        actorId: actor.id,
        actorName: actor.name,
        action: "demo.restricted_action_attempted",
        entityType: "admin",
        entityId: parsed.id ?? "admin-users",
        detail: `Demo user attempted restricted admin action ${parsed.action}`,
        createdAt: new Date().toISOString(),
      });
      return Response.json({ error: DEMO_RESTRICTED_MESSAGE }, { status: 403 });
    }
    const actorCan = (permission: string) =>
      hasPermission(actor.role, actor.permissions, permission);
    const canManageUsers =
      actorCan("users.create") ||
      actorCan("users.edit") ||
      actorCan("users.delete") ||
      actorCan("users.change_status") ||
      actorCan("users.invite") ||
      actorCan("users.sync") ||
      actorCan("admins.manage");
    const canManageRoles =
      actorCan("roles.create") ||
      actorCan("roles.edit") ||
      actorCan("roles.delete") ||
      actorCan("admins.manage");
    const roleActions = new Set(["role-create", "role-update", "role-delete"]);
    const canManage = roleActions.has(parsed.action)
      ? canManageRoles
      : canManageUsers;
    if (parsed.action !== "update-profile" && !canManage)
      throw new Response("Forbidden", { status: 403 });

    if (parsed.action === "sync-auth-users") {
      const now = new Date().toISOString();
      const created: string[] = [];
      let pageToken: string | undefined;
      do {
        const page = await firebaseAdminAuth.listUsers(1000, pageToken);
        for (const user of page.users) {
          if (!user.email) continue;
          const email = user.email.trim().toLowerCase();
          const direct = await firebaseAdminDb.collection("admins").doc(user.uid).get();
          if (direct.exists) continue;
          const byEmail = await firebaseAdminDb
            .collection("admins")
            .where("email", "==", email)
            .limit(1)
            .get();
          if (!byEmail.empty) continue;
          const profile = {
            id: user.uid,
            uid: user.uid,
            name: user.displayName || email.split("@")[0],
            email,
            phone: "",
            department: "",
            jobTitle: "",
            role: "Support",
            roleId: "support",
            permissions: [],
            status: "Disabled",
            enabled: false,
            authDisabled: user.disabled,
            lastSeen: "Never",
            twoFactorEnabled: false,
            createdAt: user.metadata.creationTime || now,
            updatedAt: now,
          };
          await firebaseAdminDb.collection("admins").doc(user.uid).set(profile, {
            merge: true,
          });
          created.push(user.uid);
        }
        pageToken = page.pageToken;
      } while (pageToken);
      await firebaseAdminDb.collection("auditLogs").add({
        actorId: actor.id,
        actorName: actor.name,
        action: "admin.auth_users_synced",
        entityType: "admin",
        entityId: "firebase-auth",
        detail: `Synced ${created.length} Firebase Auth user(s) into disabled admin profiles`,
        createdAt: now,
      });
      return Response.json({ ok: true, created });
    }

    if (parsed.action === "create") {
      const input = adminCreateSchema.parse(parsed.input);
      if (!input)
        return Response.json(
          { error: "Administrator details are required" },
          { status: 400 },
        );
      const roleSnapshot = await firebaseAdminDb
        .collection("roles")
        .doc(input.roleId)
        .get();
      if (!roleSnapshot.exists)
        return Response.json({ error: "Role not found" }, { status: 404 });
      const role = roleSnapshot.data() as {
        name: string;
        permissions: string[];
      };
      const email = input.email.trim().toLowerCase();
      let authUser;
      try {
        authUser = await firebaseAdminAuth.getUserByEmail(email);
        authUser = await firebaseAdminAuth.updateUser(authUser.uid, {
          displayName: input.name,
          disabled: false,
        });
      } catch (error) {
        if ((error as { code?: string }).code !== "auth/user-not-found")
          throw error;
        authUser = await firebaseAdminAuth.createUser({
          email,
          displayName: input.name,
          emailVerified: false,
          disabled: false,
        });
      }
      await firebaseAdminAuth.setCustomUserClaims(authUser.uid, {
        ...smallDashboardClaims({
          role: role.name,
          roleId: input.roleId,
        }),
      });
      const createdAt = new Date().toISOString();
      const adminRef = firebaseAdminDb.collection("admins").doc(authUser.uid);
      const existingAdmin = await adminRef.get();
      const existingData = existingAdmin.exists ? existingAdmin.data() ?? {} : {};
      const admin = {
        ...existingData,
        id: authUser.uid,
        uid: authUser.uid,
        name: input.name,
        email,
        phone: input.phone ?? "",
        department: input.department ?? "",
        jobTitle: String(existingData.jobTitle ?? ""),
        role: role.name,
        roleId: input.roleId,
        permissions: role.permissions,
        status: "Invited",
        enabled: true,
        authDisabled: false,
        lastSeen: String(existingData.lastSeen ?? "Never"),
        twoFactorEnabled: Boolean(existingData.twoFactorEnabled),
        isDemoUser: Boolean(input.isDemoUser),
        demoExpiresAt: input.demoExpiresAt ?? "",
        demoCompanyName: input.demoCompanyName ?? "",
        demoContactName: input.demoContactName ?? "",
        demoNotes: input.demoNotes ?? "",
        createdAt: String(existingData.createdAt ?? createdAt),
        updatedAt: createdAt,
      };
      const invitation = {
        id: authUser.uid,
        adminId: authUser.uid,
        email: admin.email,
        roleId: input.roleId,
        roleName: role.name,
        assignedPermissions: role.permissions,
        invitedBy: actor.name,
        status: "Pending",
        emailDeliveryStatus: "Pending",
        emailProvider: "resend",
        dashboardUrl: dashboardUrl(),
        createdAt,
        expiresAt: invitationExpiresAt(),
        resendCount: 0,
      };
      const batch = firebaseAdminDb.batch();
      batch.set(adminRef, admin, { merge: true });
      batch.set(
        firebaseAdminDb.collection("adminInvites").doc(authUser.uid),
        invitation,
        { merge: true },
      );
      batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
        actorId: actor.id,
        actorName: actor.name,
        action: "admin.created",
        entityType: "admin",
        entityId: authUser.uid,
        detail: `Created Firebase Auth administrator ${admin.email}`,
        createdAt,
      });
      await batch.commit();
      try {
        const emailResult = await sendAdminInvitation({
          adminId: authUser.uid,
          email: admin.email,
          name: admin.name,
          roleName: role.name,
          roleId: input.roleId,
          permissions: role.permissions,
          invitedBy: actor.name,
          actorId: actor.id,
          actorName: actor.name,
        });
        return Response.json(
          { ...admin, invitationEmail: emailResult },
          { status: 201 },
        );
      } catch (error) {
        const message = await recordInvitationEmailFailure({
          adminId: authUser.uid,
          email: admin.email,
          actorId: actor.id,
          actorName: actor.name,
          error,
        });
        if (error instanceof InvitationDeliveryError) {
          return Response.json(
            {
              error: `Administrator was created, but the invitation email was not sent: ${message}`,
              invitationEmail: {
                status: "Failed",
                expiresAt: error.expiresAt,
              },
            },
            { status: 502 },
          );
        }
        return Response.json(
          {
            error: `Administrator was created, but the invitation email was not sent: ${message}`,
          },
          { status: 502 },
        );
      }
    }

    if (parsed.action === "role-create") {
      if (!actorCan("roles.create") && !actorCan("admins.manage"))
        throw new Response("Forbidden", { status: 403 });
      const input = roleInputSchema.parse(parsed.input);
      const normalizedName = input.name.trim();
      const existing = await firebaseAdminDb
        .collection("roles")
        .where("name", "==", normalizedName)
        .limit(1)
        .get();
      if (!existing.empty)
        return Response.json({ error: "A role with this name already exists" }, { status: 409 });
      const now = new Date().toISOString();
      const isSuperAdmin = normalizedName.toLowerCase() === "super admin";
      const roleRef = isSuperAdmin
        ? firebaseAdminDb.collection("roles").doc("super-admin")
        : firebaseAdminDb.collection("roles").doc();
      const role = {
        id: roleRef.id,
        name: normalizedName,
        description: input.description,
        permissions: isSuperAdmin
          ? fullAccessPermissions
          : normalizeRolePermissions(input.permissions),
        system: isSuperAdmin,
        version: 1,
        createdAt: now,
        updatedAt: now,
      };
      const batch = firebaseAdminDb.batch();
      batch.set(roleRef, role);
      batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
        actorId: actor.id,
        actorName: actor.name,
        action: "role.created",
        entityType: "role",
        entityId: role.id,
        detail: `Created role ${role.name}`,
        after: JSON.stringify(role),
        createdAt: now,
      });
      await batch.commit();
      return Response.json(role, { status: 201 });
    }

    const id = parsed.id;
    if (!id)
      return Response.json(
        { error: parsed.action.startsWith("role-") ? "Role ID is required" : "Administrator ID is required" },
        { status: 400 },
      );

    if (parsed.action === "role-update" || parsed.action === "role-delete") {
      const roleSnapshot = await firebaseAdminDb.collection("roles").doc(id).get();
      if (!roleSnapshot.exists)
        return Response.json({ error: "Role not found" }, { status: 404 });
      const currentRole = {
        id,
        ...(roleSnapshot.data() as Record<string, unknown>),
      } as {
        id: string;
        name?: string;
        description?: string;
        permissions?: string[];
        system?: boolean;
      };
      const isSuperAdminRole =
        currentRole.system === true || currentRole.name === "Super admin" || id === "super-admin";

      if (parsed.action === "role-delete") {
        if (!actorCan("roles.delete") && !actorCan("admins.manage"))
          throw new Response("Forbidden", { status: 403 });
        if (isSuperAdminRole)
          return Response.json(
            { error: "The Super Admin role is protected and cannot be deleted" },
            { status: 400 },
          );
        const assigned = await firebaseAdminDb
          .collection("admins")
          .where("roleId", "==", id)
          .limit(1)
          .get();
        if (!assigned.empty)
          return Response.json(
            { error: "This role is assigned to active admins. Reassign them before deleting it." },
            { status: 409 },
          );
        const now = new Date().toISOString();
        const batch = firebaseAdminDb.batch();
        batch.delete(roleSnapshot.ref);
        batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
          actorId: actor.id,
          actorName: actor.name,
          action: "role.deleted",
          entityType: "role",
          entityId: id,
          detail: `Deleted role ${currentRole.name ?? id}`,
          before: JSON.stringify(currentRole),
          after: null,
          createdAt: now,
        });
        await batch.commit();
        return Response.json({ ok: true, id });
      }

      if (!actorCan("roles.edit") && !actorCan("admins.manage"))
        throw new Response("Forbidden", { status: 403 });
      const patch = roleInputSchema.partial().parse(parsed.input ?? parsed.patch ?? {});
      if (!patch.name && patch.description === undefined && patch.permissions === undefined)
        return Response.json({ error: "Role changes are required" }, { status: 400 });
      const now = new Date().toISOString();
      const nextName = isSuperAdminRole ? "Super admin" : patch.name?.trim() || currentRole.name || "";
      if (!nextName)
        return Response.json({ error: "Role name is required" }, { status: 400 });
      if (patch.name && patch.name.trim() !== currentRole.name) {
        const duplicate = await firebaseAdminDb
          .collection("roles")
          .where("name", "==", patch.name.trim())
          .limit(1)
          .get();
        if (!duplicate.empty && duplicate.docs[0].id !== id)
          return Response.json({ error: "A role with this name already exists" }, { status: 409 });
      }
      const nextPermissions = isSuperAdminRole
        ? fullAccessPermissions
        : patch.permissions
          ? normalizeRolePermissions(patch.permissions)
          : currentRole.permissions ?? [];
      const update = {
        name: nextName,
        description: patch.description ?? currentRole.description ?? "",
        permissions: nextPermissions,
        system: isSuperAdminRole,
        version: Number((currentRole as { version?: number }).version ?? 1) + 1,
        updatedAt: now,
      };
      const assigned = await firebaseAdminDb
        .collection("admins")
        .where("roleId", "==", id)
        .get();
      const batch = firebaseAdminDb.batch();
      batch.update(roleSnapshot.ref, update);
      assigned.docs.forEach((adminDoc) => {
        batch.update(adminDoc.ref, {
          role: update.name,
          permissions: update.permissions,
          updatedAt: now,
        });
      });
      batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
        actorId: actor.id,
        actorName: actor.name,
        action: "role.updated",
        entityType: "role",
        entityId: id,
        detail: `Updated role ${update.name}`,
        before: JSON.stringify(currentRole),
        after: JSON.stringify({ ...currentRole, ...update, id }),
        createdAt: now,
      });
      await batch.commit();
      await Promise.allSettled(
        assigned.docs.map((adminDoc) =>
          firebaseAdminAuth.setCustomUserClaims(adminDoc.id, {
            ...smallDashboardClaims({
              role: update.name,
              roleId: id,
            }),
          }),
        ),
      );
      return Response.json({ ...currentRole, ...update, id });
    }

    if (parsed.action === "update-profile" && id !== actor.id && !canManage)
      throw new Response("Forbidden", { status: 403 });
    const adminSnapshot = await firebaseAdminDb
      .collection("admins")
      .doc(id)
      .get();
    if (!adminSnapshot.exists)
      return Response.json(
        { error: "Administrator not found" },
        { status: 404 },
      );
    const admin = adminSnapshot.data() as Record<string, unknown>;

    if (parsed.action === "resend") {
      const inviteRef = firebaseAdminDb.collection("adminInvites").doc(id);
      const inviteSnapshot = await inviteRef.get();
      const invite = inviteSnapshot.exists ? inviteSnapshot.data() ?? {} : {};
      const status = String(invite.status ?? "Pending");
      if (status === "Accepted" || invite.acceptedAt || invite.tokenUsedAt)
        return Response.json(
          { error: "This invitation has already been accepted and cannot be resent." },
          { status: 409 },
        );
      if (status === "Revoked")
        return Response.json(
          { error: "This invitation has been revoked. Create a new invitation instead." },
          { status: 409 },
        );
      try {
        const emailResult = await sendAdminInvitation({
          adminId: id,
          email: String(admin.email),
          name: String(admin.name),
          roleName: String(admin.role),
          roleId: String(admin.roleId ?? ""),
          permissions: Array.isArray(admin.permissions) ? admin.permissions as string[] : [],
          invitedBy: actor.name,
          actorId: actor.id,
          actorName: actor.name,
          resend: true,
        });
        return Response.json({
          ok: true,
          email: admin.email,
          invitationEmail: emailResult,
        });
      } catch (error) {
        const message = await recordInvitationEmailFailure({
          adminId: id,
          email: String(admin.email),
          actorId: actor.id,
          actorName: actor.name,
          error,
        });
        if (error instanceof InvitationDeliveryError) {
          return Response.json(
            {
              error: `Invitation email was not sent: ${message}`,
              invitationEmail: {
                status: "Failed",
                expiresAt: error.expiresAt,
                resendCount: Number(invite.resendCount ?? 0) + 1,
              },
            },
            { status: 502 },
          );
        }
        return Response.json(
          { error: `Invitation email was not sent: ${message}` },
          { status: 502 },
        );
      }
    }

    if (parsed.action === "update" || parsed.action === "update-profile") {
      const patch = parsed.patch;
      if (!patch)
        return Response.json(
          { error: "Profile changes are required" },
          { status: 400 },
        );
      let roleName = String(admin.role);
      let permissions = (admin.permissions as string[] | undefined) ?? [];
      if (parsed.action === "update" && patch.roleId) {
        const roleSnapshot = await firebaseAdminDb
          .collection("roles")
          .doc(patch.roleId)
          .get();
        if (!roleSnapshot.exists)
          return Response.json({ error: "Role not found" }, { status: 404 });
        const role = roleSnapshot.data() as {
          name: string;
          permissions: string[];
        };
        roleName = role.name;
        permissions = role.permissions;
      }
      const nextIsDemoUser = Boolean(patch.isDemoUser ?? admin.isDemoUser);
      const nextDemoExpiry = patch.demoExpiresAt ?? String(admin.demoExpiresAt ?? "");
      const demoExtendedActive =
        nextIsDemoUser &&
        nextDemoExpiry &&
        Number.isFinite(new Date(nextDemoExpiry).getTime()) &&
        new Date(nextDemoExpiry).getTime() > Date.now();
      await firebaseAdminAuth.updateUser(id, {
        email: patch.email,
        displayName: patch.name,
        disabled: demoExtendedActive ? false : undefined,
      });
      await firebaseAdminAuth.setCustomUserClaims(id, {
        ...smallDashboardClaims({
          role: roleName,
          roleId: String(patch.roleId ?? admin.roleId ?? "support"),
        }),
      });
      const update = {
        ...patch,
        ...(demoExtendedActive ? { status: "Active", enabled: true, authDisabled: false } : {}),
        role: roleName,
        permissions,
        updatedAt: new Date().toISOString(),
      };
      await adminSnapshot.ref.update(update);
      await firebaseAdminDb
        .collection("auditLogs")
        .add({
          actorId: actor.id,
          actorName: actor.name,
          action:
            parsed.action === "update" ? "admin.updated" : "account.updated",
          entityType: "admin",
          entityId: id,
          detail: `Updated ${Object.keys(patch).join(", ")}`,
          createdAt: new Date().toISOString(),
        });
      return Response.json({ id, ...admin, ...update });
    }

    if (parsed.action === "delete") {
      if (id === actor.id)
        return Response.json(
          { error: "You cannot delete your own active admin account" },
          { status: 400 },
        );
      try {
        await firebaseAdminAuth.deleteUser(id);
      } catch (error) {
        if ((error as { code?: string }).code !== "auth/user-not-found") {
          serverLog("error", "Failed to delete Firebase Auth admin user", {
            requestId: logId,
            adminId: parsed.id,
            error,
          });
          throw error;
        }
      }
      const sessions = await adminSnapshot.ref.collection("sessions").get();
      const batch = firebaseAdminDb.batch();
      sessions.docs.forEach((session) => batch.delete(session.ref));
      batch.delete(firebaseAdminDb.collection("adminInvites").doc(id));
      batch.delete(adminSnapshot.ref);
      batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
        actorId: actor.id,
        actorName: actor.name,
        action: "admin.deleted",
        entityType: "admin",
        entityId: id,
        detail: `Deleted Firebase Auth administrator ${String(admin.email)}`,
        before: JSON.stringify({ id, ...admin }),
        after: null,
        createdAt: new Date().toISOString(),
      });
      await batch.commit();
      serverLog("info", "Admin account deleted", {
        requestId: logId,
        adminId: id,
        actorId: actor.id,
      });
      return Response.json({ ok: true, id });
    }

    const disabled =
      parsed.action === "toggle"
        ? admin.status !== "Disabled"
        : parsed.action === "disable" || parsed.action === "revoke";
    await firebaseAdminAuth.updateUser(id, { disabled });
    const batch = firebaseAdminDb.batch();
    batch.update(adminSnapshot.ref, {
      status: disabled ? "Disabled" : "Active",
      disabled,
      enabled: !disabled,
      authDisabled: disabled,
      updatedAt: new Date().toISOString(),
    });
    if (parsed.action === "revoke")
      batch.set(
        firebaseAdminDb.collection("adminInvites").doc(id),
        { status: "Revoked", revokedAt: new Date().toISOString() },
        { merge: true },
      );
    batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
      actorId: actor.id,
      actorName: actor.name,
      action: `admin.${parsed.action}`,
      entityType: "admin",
      entityId: id,
      detail: `${parsed.action} ${String(admin.email)}`,
      createdAt: new Date().toISOString(),
    });
    await batch.commit();
    serverLog("info", "Admin account toggled", {
      requestId: logId,
      adminId: id,
      disabled,
      actorId: actor.id,
      action: parsed.action,
    });
    return Response.json({ ok: true, id, disabled });
  } catch (error) {
    return firebaseApiError(error, {
      requestId: logId,
      route: "/api/firebase/admin-users",
    });
  }
}
