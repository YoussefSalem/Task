import { z } from "zod";
import {
  firebaseApiError,
  requireFirebaseAdmin,
} from "@/lib/firebase/server-auth";
import { firebaseAdminAuth, firebaseAdminDb } from "@/lib/firebase/admin";
import { requestId, serverLog } from "@/lib/server/logger";
import { DEMO_RESTRICTED_MESSAGE } from "@/lib/demo-mode";
import { hasPermission } from "@/lib/permissions";

export const runtime = "nodejs";

const schema = z.object({
  action: z.enum([
    "deleteCustomer",
    "deleteProvider",
    "toggleCustomer",
    "toggleProvider",
  ]),
  id: z.string().min(1),
});

type Actor = Awaited<ReturnType<typeof requireFirebaseAdmin>>;

function can(actor: Actor, permission: string) {
  return hasPermission(actor.role, actor.permissions, permission);
}

function assertCan(actor: Actor, permissions: string[]) {
  if (!permissions.some((permission) => can(actor, permission)))
    throw new Response("Forbidden", { status: 403 });
}

function recordEnvironment(data: FirebaseFirestore.DocumentData) {
  if (data.environment === "demo" || data.isDemoData === true) return "demo";
  return "production";
}

function assertProductionRecord(
  data: FirebaseFirestore.DocumentData,
  entityType: string,
  entityId: string,
) {
  if (recordEnvironment(data) !== "production") {
    serverLog("warn", "Blocked production API from mutating demo record", {
      entityType,
      entityId,
      environment: recordEnvironment(data),
    });
    throw new Response(
      "This record belongs to the demo workspace and cannot be modified from production.",
      { status: 403 },
    );
  }
}

function deleteRefOnce(
  batch: FirebaseFirestore.WriteBatch,
  seen: Set<string>,
  ref: FirebaseFirestore.DocumentReference,
) {
  if (seen.has(ref.path)) return;
  seen.add(ref.path);
  batch.delete(ref);
}

async function deleteQuery(
  batch: FirebaseFirestore.WriteBatch,
  seen: Set<string>,
  collectionName: string,
  field: string,
  value: string,
) {
  const snapshot = await firebaseAdminDb
    .collection(collectionName)
    .where(field, "==", value)
    .where("environment", "==", "production")
    .get();
  snapshot.docs.forEach((item) => deleteRefOnce(batch, seen, item.ref));
  return snapshot.size;
}

async function deleteKnownProfileDocuments(
  batch: FirebaseFirestore.WriteBatch,
  seen: Set<string>,
  id: string,
  collections: string[],
) {
  collections.forEach((collectionName) => {
    deleteRefOnce(batch, seen, firebaseAdminDb.collection(collectionName).doc(id));
  });
}

async function writeAudit(input: {
  actor: Actor;
  action: string;
  entityType: string;
  entityId: string;
  detail: string;
  before: unknown;
}) {
  await firebaseAdminDb.collection("auditLogs").add({
    actorId: input.actor.id,
    actorName: input.actor.name,
    action: input.action,
    entityType: input.entityType,
    entityId: input.entityId,
    detail: input.detail,
    environment: "production",
    isDemoData: false,
    before: JSON.stringify(input.before),
    after: null,
    ipAddress: "Firebase Auth",
    device: "Task Admin API",
    createdAt: new Date().toISOString(),
  });
}

async function findLinkedAuthUser(data: FirebaseFirestore.DocumentData) {
  const candidateIds = [
    data.id,
    data.authUid,
    data.firebaseUid,
    data.firebaseAuthUid,
    data.uid,
  ]
    .map((value) => (typeof value === "string" ? value.trim() : ""))
    .filter(Boolean);
  for (const uid of candidateIds) {
    try {
      return await firebaseAdminAuth.getUser(uid);
    } catch (error) {
      if ((error as { code?: string }).code !== "auth/user-not-found") throw error;
    }
  }
  const email = typeof data.email === "string" ? data.email.trim() : "";
  if (!email) return null;
  try {
    return await firebaseAdminAuth.getUserByEmail(email.toLowerCase());
  } catch (error) {
    if ((error as { code?: string }).code === "auth/user-not-found") return null;
    throw error;
  }
}

async function setLinkedAuthDisabled(
  data: FirebaseFirestore.DocumentData,
  disabled: boolean,
) {
  const user = await findLinkedAuthUser(data);
  if (!user) return null;
  await firebaseAdminAuth.updateUser(user.uid, { disabled });
  return user.uid;
}

async function deleteLinkedAuthUser(data: FirebaseFirestore.DocumentData) {
  const user = await findLinkedAuthUser(data);
  if (!user) return null;
  await firebaseAdminAuth.deleteUser(user.uid);
  return user.uid;
}

async function toggleCustomer(id: string, actor: Actor) {
  assertCan(actor, ["customers.edit", "customers.suspend", "payments.wallet", "customers.write", "payments.manage"]);
  const ref = firebaseAdminDb.collection("customers").doc(id);
  const snapshot = await ref.get();
  if (!snapshot.exists)
    return Response.json({ error: "Customer not found" }, { status: 404 });
  const record: FirebaseFirestore.DocumentData = {
    id: snapshot.id,
    ...(snapshot.data() ?? {}),
  };
  assertProductionRecord(record, "customer", id);
  const before = { ...record };
  const disabled = !Boolean(record.disabled);
  const authUid = await setLinkedAuthDisabled(record, disabled);
  await ref.update({
    status: disabled ? "Disabled" : "Active",
    disabled,
    updatedAt: new Date().toISOString(),
  });
  await writeAudit({
    actor,
    action: disabled ? "customer.disabled" : "customer.enabled",
    entityType: "customer",
    entityId: id,
    detail: `${disabled ? "Disabled" : "Enabled"} customer ${String(record.email ?? id)}${authUid ? ` and Firebase Auth user ${authUid}` : ""}`,
    before,
  });
  serverLog("info", "Customer account toggled", {
    customerId: id,
    disabled,
    authUid,
    actorId: actor.id,
  });
  return Response.json({ ok: true, id, disabled, authUid });
}

async function toggleProvider(id: string, actor: Actor) {
  assertCan(actor, ["providers.suspend", "providers.approve"]);
  const ref = firebaseAdminDb.collection("providers").doc(id);
  const snapshot = await ref.get();
  if (!snapshot.exists)
    return Response.json({ error: "Provider not found" }, { status: 404 });
  const record: FirebaseFirestore.DocumentData = {
    id: snapshot.id,
    ...(snapshot.data() ?? {}),
  };
  assertProductionRecord(record, "provider", id);
  const before = { ...record };
  const disabled = !Boolean(record.disabled);
  const authUid = await setLinkedAuthDisabled(record, disabled);
  const previousStatus = String(record.status ?? "Review");
  const statusBeforeDisable = String(
    record.statusBeforeDisable ?? "Active",
  );
  await ref.update({
    status: disabled
      ? "Disabled"
      : previousStatus === "Disabled"
        ? statusBeforeDisable
        : previousStatus,
    disabled,
    statusBeforeDisable: disabled
      ? previousStatus === "Disabled"
        ? statusBeforeDisable
        : previousStatus
      : null,
    available: false,
    updatedAt: new Date().toISOString(),
  });
  await writeAudit({
    actor,
    action: disabled ? "provider.disabled" : "provider.enabled",
    entityType: "provider",
    entityId: id,
    detail: `${disabled ? "Disabled" : "Enabled"} provider ${String(record.providerId ?? id)}${authUid ? ` and Firebase Auth user ${authUid}` : ""}`,
    before,
  });
  serverLog("info", "Provider account toggled", {
    providerId: id,
    disabled,
    authUid,
    actorId: actor.id,
  });
  return Response.json({ ok: true, id, disabled, authUid });
}

async function deleteCustomer(id: string, actor: Actor) {
  assertCan(actor, ["customers.delete", "customers.write", "payments.manage"]);
  const ref = firebaseAdminDb.collection("customers").doc(id);
  const snapshot = await ref.get();
  if (!snapshot.exists)
    return Response.json({ error: "Customer not found" }, { status: 404 });

  const batch = firebaseAdminDb.batch();
  const seen = new Set<string>();
  const record: FirebaseFirestore.DocumentData = {
    id: snapshot.id,
    ...(snapshot.data() ?? {}),
  };
  assertProductionRecord(record, "customer", id);
  const deletedAuthUid = await deleteLinkedAuthUser(record);
  deleteRefOnce(batch, seen, ref);
  await deleteKnownProfileDocuments(batch, seen, id, [
    "customerProfiles",
    "customerPrivate",
    "customerSettings",
    "customerDevices",
  ]);
  const deletedWallets = await deleteQuery(batch, seen, "wallets", "ownerId", id);
  deleteRefOnce(batch, seen, firebaseAdminDb.collection("wallets").doc(`wallet-${id}`));
  await batch.commit();
  await writeAudit({
    actor,
    action: "customer.deleted",
    entityType: "customer",
    entityId: id,
    detail: `Deleted customer ${String(record.email ?? id)} and ${deletedWallets} linked wallet record(s)`,
    before: record,
  });
  serverLog("info", "Customer account deleted", {
    customerId: id,
    deletedAuthUid,
    deletedWallets,
    actorId: actor.id,
  });
  return Response.json({ ok: true, id, deletedWallets, deletedAuthUid });
}

async function deleteProvider(id: string, actor: Actor) {
  assertCan(actor, ["providers.delete", "providers.approve", "providers.suspend"]);
  const ref = firebaseAdminDb.collection("providers").doc(id);
  const snapshot = await ref.get();
  if (!snapshot.exists)
    return Response.json({ error: "Provider not found" }, { status: 404 });

  const batch = firebaseAdminDb.batch();
  const seen = new Set<string>();
  const record: FirebaseFirestore.DocumentData = {
    id: snapshot.id,
    ...(snapshot.data() ?? {}),
  };
  assertProductionRecord(record, "provider", id);
  const deletedAuthUid = await deleteLinkedAuthUser(record);
  deleteRefOnce(batch, seen, ref);
  deleteRefOnce(batch, seen, firebaseAdminDb.collection("providerLocations").doc(id));
  deleteRefOnce(batch, seen, firebaseAdminDb.collection("wallets").doc(`wallet-${id}`));
  await deleteKnownProfileDocuments(batch, seen, id, [
    "providerProfiles",
    "providerPrivate",
    "providerSettings",
    "providerDevices",
    "providerAvailability",
  ]);
  const [deletedWallets, deletedProviderDocuments] = await Promise.all([
    deleteQuery(batch, seen, "wallets", "ownerId", id),
    deleteQuery(batch, seen, "providerDocuments", "providerId", id),
  ]);
  await batch.commit();
  await writeAudit({
    actor,
    action: "provider.deleted",
    entityType: "provider",
    entityId: id,
    detail: `Deleted provider ${String(record.providerId ?? id)}, ${deletedWallets} wallet record(s), and ${deletedProviderDocuments} document metadata record(s)`,
    before: record,
  });
  serverLog("info", "Provider account deleted", {
    providerId: id,
    deletedAuthUid,
    deletedWallets,
    deletedProviderDocuments,
    actorId: actor.id,
  });
  return Response.json({
    ok: true,
    id,
    deletedWallets,
    deletedProviderDocuments,
    deletedAuthUid,
  });
}

export async function POST(request: Request) {
  const id = requestId(request);
  try {
    const actor = await requireFirebaseAdmin(request);
    const parsed = schema.parse(await request.json());
    if (actor.isDemoUser) {
      await firebaseAdminDb.collection("auditLogs").add({
        actorId: actor.id,
        actorName: actor.name,
        action: "demo.restricted_action_attempted",
        entityType: "operations",
        entityId: parsed.id,
        detail: `Demo user attempted restricted operation ${parsed.action}`,
        createdAt: new Date().toISOString(),
      });
      return Response.json({ error: DEMO_RESTRICTED_MESSAGE }, { status: 403 });
    }
    if (parsed.action === "deleteCustomer")
      return await deleteCustomer(parsed.id, actor);
    if (parsed.action === "deleteProvider")
      return await deleteProvider(parsed.id, actor);
    if (parsed.action === "toggleCustomer")
      return await toggleCustomer(parsed.id, actor);
    return await toggleProvider(parsed.id, actor);
  } catch (error) {
    return firebaseApiError(error, {
      requestId: id,
      route: "/api/firebase/operations",
    });
  }
}
