import "server-only";

import { createCipheriv, createDecipheriv, createHash, randomBytes } from "node:crypto";
import { firebaseAdminDb } from "@/lib/firebase/admin";

export type IntegrationMode = "sandbox" | "live";
export type IntegrationStatus = "untested" | "success" | "failed" | "disabled";

export type IntegrationCredentialInput = {
  apiKey?: string;
  secretKey?: string;
  webhookSecret?: string;
  clientId?: string;
  clientSecret?: string;
};

export type ApiIntegrationRecord = {
  id: string;
  category: string;
  provider: string;
  providerName: string;
  defaultModel?: string;
  baseUrl?: string;
  mode: IntegrationMode;
  enabled: boolean;
  status: IntegrationStatus;
  maskedCredentials: Record<string, string>;
  encryptedCredentials?: string;
  lastSuccessfulTest?: string;
  lastError?: string;
  updatedAt: string;
  updatedBy?: string;
  environment: "production" | "demo";
};

export const integrationCatalog = [
  { category: "AI Providers", provider: "openai", providerName: "OpenAI", models: ["gpt-4.1-mini", "gpt-4.1", "gpt-4o-mini"] },
  { category: "AI Providers", provider: "gemini", providerName: "Gemini", models: ["gemini-3.5-flash", "gemini-2.5-flash", "gemini-1.5-pro"] },
  { category: "Payments", provider: "fawry", providerName: "Fawry" },
  { category: "Payments", provider: "paymob", providerName: "Paymob" },
  { category: "Payments", provider: "stripe", providerName: "Stripe" },
  { category: "Payments", provider: "myfatoorah", providerName: "MyFatoorah" },
  { category: "SMS / WhatsApp", provider: "twilio", providerName: "Twilio" },
  { category: "SMS / WhatsApp", provider: "whatsapp-cloud", providerName: "WhatsApp Cloud API" },
  { category: "SMS / WhatsApp", provider: "local-sms", providerName: "Local SMS Provider" },
  { category: "Email", provider: "resend", providerName: "Resend" },
  { category: "Email", provider: "sendgrid", providerName: "SendGrid" },
  { category: "Email", provider: "smtp", providerName: "SMTP" },
  { category: "Maps / Location", provider: "google-maps", providerName: "Google Maps" },
  { category: "Maps / Location", provider: "mapbox", providerName: "Mapbox" },
  { category: "Push Notifications", provider: "firebase-cloud-messaging", providerName: "Firebase Cloud Messaging" },
  { category: "Storage / CDN", provider: "firebase-storage", providerName: "Firebase Storage" },
  { category: "Storage / CDN", provider: "cloudinary", providerName: "Cloudinary" },
  { category: "Shipping / Delivery", provider: "bosta", providerName: "Bosta" },
  { category: "Shipping / Delivery", provider: "aramex", providerName: "Aramex" },
  { category: "Shipping / Delivery", provider: "dhl", providerName: "DHL" },
] as const;

export function integrationId(provider: string) {
  return `production-${provider}`;
}

function encryptionMaterial() {
  const value =
    process.env.API_CENTER_ENCRYPTION_KEY ||
    process.env.FIREBASE_PRIVATE_KEY ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON ||
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
  if (!value?.trim())
    throw new Error("API Center encryption key is not configured. Set API_CENTER_ENCRYPTION_KEY.");
  return createHash("sha256").update(value).digest();
}

export function encryptCredentials(credentials: IntegrationCredentialInput) {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", encryptionMaterial(), iv);
  const encrypted = Buffer.concat([
    cipher.update(JSON.stringify(credentials), "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return `${iv.toString("base64")}.${tag.toString("base64")}.${encrypted.toString("base64")}`;
}

export function decryptCredentials(payload?: string): IntegrationCredentialInput {
  if (!payload) return {};
  const [ivRaw, tagRaw, encryptedRaw] = payload.split(".");
  if (!ivRaw || !tagRaw || !encryptedRaw) return {};
  const decipher = createDecipheriv("aes-256-gcm", encryptionMaterial(), Buffer.from(ivRaw, "base64"));
  decipher.setAuthTag(Buffer.from(tagRaw, "base64"));
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(encryptedRaw, "base64")),
    decipher.final(),
  ]).toString("utf8");
  return JSON.parse(decrypted) as IntegrationCredentialInput;
}

export function maskSecret(value?: string) {
  if (!value) return "";
  if (value.length <= 8) return "****";
  return `${value.slice(0, 3)}-****${value.slice(-4)}`;
}

export function maskCredentials(input: IntegrationCredentialInput) {
  return Object.fromEntries(
    Object.entries(input)
      .filter(([, value]) => Boolean(value))
      .map(([key, value]) => [key, maskSecret(String(value))]),
  );
}

export async function loadProductionIntegration(provider: string) {
  const snapshot = await firebaseAdminDb.collection("apiIntegrations").doc(integrationId(provider)).get();
  if (!snapshot.exists) return null;
  return { id: snapshot.id, ...(snapshot.data() as Omit<ApiIntegrationRecord, "id">) } as ApiIntegrationRecord;
}

export async function activeAiProvider() {
  const docs = await firebaseAdminDb
    .collection("apiIntegrations")
    .where("environment", "==", "production")
    .where("category", "==", "AI Providers")
    .where("enabled", "==", true)
    .limit(1)
    .get();
  if (!docs.empty) {
    const record = {
      id: docs.docs[0].id,
      ...(docs.docs[0].data() as Omit<ApiIntegrationRecord, "id">),
    } as ApiIntegrationRecord;
    const credentials = decryptCredentials(record.encryptedCredentials);
    return { source: "dashboard" as const, record, credentials };
  }
  const envProvider = (process.env.AI_PROVIDER || (process.env.GEMINI_API_KEY ? "gemini" : process.env.OPENAI_API_KEY ? "openai" : "disabled")).toLowerCase();
  if (envProvider === "disabled") return { source: "env" as const, record: null, credentials: {}, provider: "disabled" };
  if (envProvider === "openai" && process.env.OPENAI_API_KEY)
    return { source: "env" as const, record: null, credentials: { apiKey: process.env.OPENAI_API_KEY }, provider: "openai", defaultModel: process.env.OPENAI_MODEL || "gpt-4.1-mini" };
  if (envProvider === "gemini" && process.env.GEMINI_API_KEY)
    return { source: "env" as const, record: null, credentials: { apiKey: process.env.GEMINI_API_KEY }, provider: "gemini", defaultModel: process.env.GEMINI_MODEL || "gemini-3.5-flash" };
  return { source: "env" as const, record: null, credentials: {}, provider: "disabled" };
}
