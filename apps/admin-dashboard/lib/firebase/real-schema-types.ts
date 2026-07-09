/**
 * Read-only, additive types + pure mappers for two real Customer App
 * concepts the dashboard does NOT force into its own native shapes:
 *
 * - Chat: real per-job chat threads at jobs/{jobId}/threads/{technicianId}
 *   (+/messages), structurally different from the dashboard's own
 *   `conversations` (a flat support-ticket list) - see entity-routing.ts's
 *   ADAPTER_REGISTRY, which correctly keeps `conversations` native rather
 *   than force-mapping these two different concepts onto one shape.
 * - Notifications: the real per-user feed at users/{uid}/notifications,
 *   structurally different from the dashboard's own `notifications` (a
 *   broadcast/campaign list) - same reasoning, kept native.
 *
 * These types/mappers exist so an admin-facing "inspect this job's real chat
 * history" or "inspect this customer's real notification feed" view (e.g. for
 * dispute/complaint investigation) can be built later without inventing a new
 * schema at that point - the exact real field names are captured once, here,
 * matching packages/task_domain/lib/src/entities/message.dart and
 * app_notification.dart. No UI page consumes these yet; this is data-layer
 * scaffolding only, per the "safe code-level scaffolding" scope.
 */

export interface RealChatThread {
  jobId: string;
  technicianId: string;
  customerId: string;
  technicianName: string;
  lastMessage: string;
  lastMessageAt: string | null;
}

export interface RealChatMessage {
  id: string;
  senderId: string;
  senderRole: "customer" | "technician";
  text: string;
  createdAt: string | null;
}

export interface RealNotification {
  id: string;
  type: "message" | "offer" | "hired" | "job_status";
  title: string;
  body: string;
  actorId: string | null;
  jobId: string | null;
  threadId: string | null;
  read: boolean;
  createdAt: string | null;
}

/**
 * One real technician location sample under jobs/{jobId}/tracking/{id}
 * (packages/task_data/lib/src/tracking/firestore_job_tracking_repository.dart:
 * fields lat/lng/at/eta_minutes). Keyed by job, not provider - the real schema
 * has no per-provider "current location" doc, so this is the honest granularity
 * the dashboard's live map can consume.
 */
export interface RealTrackingPoint {
  id: string;
  lat: number | null;
  lng: number | null;
  at: string | null;
  etaMinutes: number | null;
}

function toIsoOrNull(value: unknown): string | null {
  if (!value) return null;
  if (typeof value === "string") return value;
  if (value instanceof Date) return value.toISOString();
  const maybeTimestamp = value as { toDate?: () => Date };
  if (typeof maybeTimestamp.toDate === "function") return maybeTimestamp.toDate().toISOString();
  return null;
}

export function mapRealChatThread(
  jobId: string,
  technicianId: string,
  data: Record<string, unknown>,
): RealChatThread {
  return {
    jobId,
    technicianId,
    customerId: String(data.customer_id ?? ""),
    technicianName: String(data.technician_name ?? ""),
    lastMessage: String(data.last_message ?? ""),
    lastMessageAt: toIsoOrNull(data.last_message_at),
  };
}

const SENDER_ROLES = new Set(["customer", "technician"]);

export function mapRealChatMessage(id: string, data: Record<string, unknown>): RealChatMessage {
  const rawRole = String(data.sender_role ?? "customer");
  return {
    id,
    senderId: String(data.sender_id ?? ""),
    senderRole: (SENDER_ROLES.has(rawRole) ? rawRole : "customer") as "customer" | "technician",
    text: String(data.text ?? ""),
    createdAt: toIsoOrNull(data.created_at),
  };
}

const NOTIFICATION_TYPES = new Set(["message", "offer", "hired", "job_status"]);

export function mapRealNotification(id: string, data: Record<string, unknown>): RealNotification {
  const rawType = String(data.type ?? "job_status");
  return {
    id,
    type: (NOTIFICATION_TYPES.has(rawType) ? rawType : "job_status") as RealNotification["type"],
    title: String(data.title ?? ""),
    body: String(data.body ?? ""),
    actorId: data.actor_id ? String(data.actor_id) : null,
    jobId: data.job_id ? String(data.job_id) : null,
    threadId: data.thread_id ? String(data.thread_id) : null,
    read: Boolean(data.read ?? false),
    createdAt: toIsoOrNull(data.created_at),
  };
}

export function mapRealTrackingPoint(id: string, data: Record<string, unknown>): RealTrackingPoint {
  const lat = typeof data.lat === "number" ? data.lat : null;
  const lng = typeof data.lng === "number" ? data.lng : null;
  const eta = typeof data.eta_minutes === "number" ? data.eta_minutes : null;
  return {
    id,
    lat,
    lng,
    at: toIsoOrNull(data.at),
    etaMinutes: eta,
  };
}
