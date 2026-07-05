import { loadEnvConfig } from "@next/env";

loadEnvConfig(process.cwd());

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
  const { fullAccessPermissions, isSuperAdminRole, normalizeRolePermissions } = permissionsExports;

  const now = new Date().toISOString();
  const rolesSnapshot = await firebaseAdminDb.collection("roles").get();
  const batch = firebaseAdminDb.batch();
  let migratedRoles = 0;

  for (const roleDoc of rolesSnapshot.docs) {
    const role = roleDoc.data() as {
      name?: string;
      permissions?: string[];
      version?: number;
    };
    const superAdmin = roleDoc.id === "super-admin" || isSuperAdminRole(role.name);
    const permissions = superAdmin
      ? [...fullAccessPermissions]
      : normalizeRolePermissions(Array.isArray(role.permissions) ? role.permissions : []);

    batch.set(
      roleDoc.ref,
      {
        permissions,
        version: Number(role.version ?? 0) + 1,
        updatedAt: now,
      },
      { merge: true },
    );
    migratedRoles += 1;
  }

  if (!rolesSnapshot.docs.some((doc) => doc.id === "super-admin")) {
    batch.set(
      firebaseAdminDb.collection("roles").doc("super-admin"),
      {
        id: "super-admin",
        name: "Super admin",
        description: "Full control over Task operations, configuration, and administrators.",
        permissions: [...fullAccessPermissions],
        version: 1,
        system: true,
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    migratedRoles += 1;
  }

  const adminsSnapshot = await firebaseAdminDb.collection("admins").get();
  let migratedAdmins = 0;
  for (const adminDoc of adminsSnapshot.docs) {
    const admin = adminDoc.data() as {
      role?: string;
      roleId?: string;
      tenantId?: string;
      permissions?: string[];
    };
    const roleId = String(
      admin.roleId || (isSuperAdminRole(admin.role) ? "super-admin" : "support-agent"),
    );
    const roleSnapshot = await firebaseAdminDb.collection("roles").doc(roleId).get();
    const role = roleSnapshot.exists
      ? (roleSnapshot.data() as { name?: string; permissions?: string[] })
      : undefined;
    const roleName = String(role?.name ?? admin.role ?? "Support Agent");
    const permissions = isSuperAdminRole(roleName)
      ? [...fullAccessPermissions]
      : normalizeRolePermissions(role?.permissions ?? admin.permissions ?? []);

    batch.set(
      adminDoc.ref,
      {
        role: roleName,
        roleId,
        permissions,
        updatedAt: now,
      },
      { merge: true },
    );

    await firebaseAdminAuth.setCustomUserClaims(
      adminDoc.id,
      smallDashboardClaims({
        role: roleName,
        roleId,
        tenantId: String(admin.tenantId ?? "task"),
      }),
    );
    migratedAdmins += 1;
  }

  batch.set(firebaseAdminDb.collection("auditLogs").doc(), {
    actorId: "system",
    actorName: "RBAC migration",
    action: "rbac.roles.migrated",
    entityType: "role",
    entityId: "all",
    detail: "Migrated roles to Firestore-backed hierarchical permissions and compact custom claims.",
    metadata: { migratedRoles, migratedAdmins },
    createdAt: now,
  });

  await batch.commit();
  await firebaseAdminDb.terminate();

  console.log(
    `RBAC migration complete. Roles: ${migratedRoles}. Admins: ${migratedAdmins}. Custom claims now contain roleId, tenantId, and isSuperAdmin only.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
