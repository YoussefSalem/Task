import { z } from "zod";
import { firebaseAdminDb } from "@/lib/firebase/admin";
import { firebaseApiError, requireFirebaseAdmin } from "@/lib/firebase/server-auth";
import { hasPermission } from "@/lib/permissions";
import {
  decryptCredentials,
  encryptCredentials,
  integrationCatalog,
  integrationId,
  maskCredentials,
  type ApiIntegrationRecord,
  type IntegrationCredentialInput,
} from "@/lib/integrations/api-center";
import type { AdminUser } from "@/lib/types";

export const runtime = "nodejs";

const credentialSchema = z.object({
  apiKey: z.string().optional(),
  secretKey: z.string().optional(),
  webhookSecret: z.string().optional(),
  clientId: z.string().optional(),
  clientSecret: z.string().optional(),
});

const bodySchema = z.object({
  action: z.enum(["save", "test", "enable", "disable", "delete"]),
  provider: z.string().min(1),
  defaultModel: z.string().optional(),
  baseUrl: z.string().optional(),
  mode: z.enum(["sandbox", "live"]).default("sandbox"),
  credentials: credentialSchema.optional(),
});

function can(actor: AdminUser, permission: string) {
  return hasPermission(actor.role, actor.permissions, permission);
}

async function audit(actor: AdminUser, action: string, provider: string, detail: string, after?: unknown) {
  await firebaseAdminDb.collection("auditLogs").add({
    actorId: actor.id,
    actorName: actor.name,
    action,
    entityType: "apiIntegration",
    entityId: provider,
    detail,
    after: after ? JSON.stringify(after) : null,
    environment: actor.isDemoUser ? "demo" : "production",
    isDemoData: Boolean(actor.isDemoUser),
    ipAddress: "Firebase Auth",
    device: "Task Admin API",
    createdAt: new Date().toISOString(),
  });
}

function publicRecord(record: ApiIntegrationRecord) {
  const safe = { ...record };
  delete safe.encryptedCredentials;
  return safe;
}

function firstModel(item: (typeof integrationCatalog)[number]) {
  return "models" in item ? item.models[0] : "";
}

function demoRecords() {
  const now = new Date().toISOString();
  return integrationCatalog.map((item, index) => ({
    id: `demo-${item.provider}`,
    category: item.category,
    provider: item.provider,
    providerName: item.providerName,
    defaultModel: firstModel(item),
    baseUrl: item.provider.includes("google") ? "https://maps.googleapis.com" : "",
    mode: index % 2 ? "sandbox" : "live",
    enabled: item.provider === "gemini" || item.provider === "resend" || item.provider === "google-maps",
    status: item.provider === "gemini" || item.provider === "resend" ? "success" : "untested",
    maskedCredentials: item.provider === "gemini" ? { apiKey: "AI-****demo" } : {},
    lastSuccessfulTest: item.provider === "gemini" ? now : "",
    lastError: "",
    updatedAt: now,
    environment: "demo",
    isDemoData: true,
  }));
}

async function testProvider(provider: string, record: Partial<ApiIntegrationRecord>, credentials: IntegrationCredentialInput) {
  if (!credentials.apiKey && !credentials.secretKey && !credentials.clientId)
    throw new Error("At least one credential is required before testing.");
  if (provider === "gemini") {
    const response = await fetch("https://generativelanguage.googleapis.com/v1beta/models", {
      headers: { "x-goog-api-key": String(credentials.apiKey ?? "") },
    });
    if (!response.ok) throw new Error(`Gemini test failed with HTTP ${response.status}`);
  } else if (provider === "openai") {
    const response = await fetch("https://api.openai.com/v1/models", {
      headers: { authorization: `Bearer ${credentials.apiKey}` },
    });
    if (!response.ok) throw new Error(`OpenAI test failed with HTTP ${response.status}`);
  } else if (record.baseUrl) {
    const response = await fetch(record.baseUrl, { method: "HEAD" }).catch(() => null);
    if (!response) throw new Error("Base URL could not be reached.");
  }
  return true;
}

export async function GET(request: Request) {
  try {
    const actor = (await requireFirebaseAdmin(request)) as AdminUser;
    if (!can(actor, "settings.integrations.apiCenter.view"))
      throw new Response("Forbidden", { status: 403, statusText: "Forbidden" });
    if (actor.isDemoUser) return Response.json({ catalog: integrationCatalog, integrations: demoRecords() });
    const snapshot = await firebaseAdminDb
      .collection("apiIntegrations")
      .where("environment", "==", "production")
      .get();
    const stored = new Map(
      snapshot.docs.map((doc) => [String(doc.data().provider), publicRecord({ id: doc.id, ...(doc.data() as Omit<ApiIntegrationRecord, "id">) })]),
    );
    const now = new Date().toISOString();
    const integrations = integrationCatalog.map((item) =>
      stored.get(item.provider) ?? {
        id: integrationId(item.provider),
        category: item.category,
        provider: item.provider,
        providerName: item.providerName,
        defaultModel: firstModel(item),
        baseUrl: "",
        mode: "sandbox",
        enabled: false,
        status: "untested",
        maskedCredentials: {},
        lastSuccessfulTest: "",
        lastError: "",
        updatedAt: now,
        environment: "production",
      },
    );
    return Response.json({ catalog: integrationCatalog, integrations });
  } catch (error) {
    return firebaseApiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const actor = (await requireFirebaseAdmin(request)) as AdminUser;
    const body = bodySchema.parse(await request.json());
    if (actor.isDemoUser) {
      await audit(actor, `integration.demo.${body.action}`, body.provider, `Demo API Center action ${body.action}`);
      return Response.json({ ok: true, demo: true, message: "Demo integrations are simulated and do not use real credentials." });
    }
    const permission = {
      save: "settings.integrations.apiCenter.edit",
      test: "settings.integrations.apiCenter.test",
      enable: "settings.integrations.apiCenter.enable",
      disable: "settings.integrations.apiCenter.disable",
      delete: "settings.integrations.apiCenter.delete",
    }[body.action];
    if (!can(actor, permission) && !(body.action === "save" && can(actor, "settings.integrations.apiCenter.rotateKey")))
      throw new Response("Forbidden", { status: 403, statusText: "Forbidden" });

    const catalogItem = integrationCatalog.find((item) => item.provider === body.provider);
    if (!catalogItem) return Response.json({ error: "Unknown integration provider" }, { status: 404 });
    const ref = firebaseAdminDb.collection("apiIntegrations").doc(integrationId(body.provider));
    const existing = await ref.get();
    const existingData = existing.exists ? (existing.data() as ApiIntegrationRecord) : null;
    const now = new Date().toISOString();
    const credentials = body.credentials && Object.values(body.credentials).some(Boolean)
      ? body.credentials
      : decryptCredentials(existingData?.encryptedCredentials);

    if (body.action === "delete") {
      await ref.delete();
      await audit(actor, "integration.credentials_deleted", body.provider, `Deleted ${catalogItem.providerName} credentials`);
      return Response.json({ ok: true });
    }

    let status = existingData?.status ?? "untested";
    let lastSuccessfulTest = existingData?.lastSuccessfulTest ?? "";
    let lastError = "";
    if (body.action === "test") {
      try {
        await testProvider(body.provider, { ...existingData, ...body }, credentials);
        status = "success";
        lastSuccessfulTest = now;
        await audit(actor, "integration.test_succeeded", body.provider, `${catalogItem.providerName} connection test succeeded`);
      } catch (error) {
        status = "failed";
        lastError = error instanceof Error ? error.message : "Connection test failed";
        await audit(actor, "integration.test_failed", body.provider, `${catalogItem.providerName} connection test failed: ${lastError}`);
      }
    }

    const record: ApiIntegrationRecord = {
      id: ref.id,
      category: catalogItem.category,
      provider: catalogItem.provider,
      providerName: catalogItem.providerName,
      defaultModel: body.defaultModel ?? existingData?.defaultModel ?? firstModel(catalogItem),
      baseUrl: body.baseUrl ?? existingData?.baseUrl ?? "",
      mode: body.mode ?? existingData?.mode ?? "sandbox",
      enabled: body.action === "enable" ? true : body.action === "disable" ? false : existingData?.enabled ?? false,
      status: body.action === "disable" ? "disabled" : status,
      maskedCredentials: maskCredentials(credentials),
      encryptedCredentials: encryptCredentials(credentials),
      lastSuccessfulTest,
      lastError,
      updatedAt: now,
      updatedBy: actor.id,
      environment: "production",
    };
    await ref.set(record, { merge: true });
    await audit(
      actor,
      body.action === "enable" ? "integration.provider_enabled" : body.action === "disable" ? "integration.provider_disabled" : body.action === "save" ? "integration.credentials_updated" : "integration.provider_tested",
      body.provider,
      `${catalogItem.providerName} ${body.action} completed`,
      publicRecord(record),
    );
    return Response.json({ integration: publicRecord(record) });
  } catch (error) {
    return firebaseApiError(error);
  }
}
