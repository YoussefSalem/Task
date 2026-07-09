# Unified schema: Complaints, Conversations/Chat, Notifications

> Design + safe code-level scaffolding only. No Firestore rules deployed, no production data migrated, no production writes enabled.

## What was inspected first (per your instruction, before designing anything)

- **Customer App** (`apps/customer`): has a real, working chat system (`jobs/{jobId}/threads/{technicianId}(/messages)`) and a real per-user notification feed (`users/{uid}/notifications`). Has **no** complaints/disputes feature at all — confirmed again via fresh grep: the only "complaint" hit anywhere in the app is a colloquial word inside an AI assistant prompt example, unrelated to any real feature.
- **Technician App** (`apps/technician`): confirmed still a bare Phase-2 skeleton (`Text('Technician app — Phase 2')`) — no code to inspect, no existing model to conflict with or build on.
- **Admin Dashboard**: already has its own native `complaints`, `conversations`, `notifications` collections/types — but they're independently-designed dashboard concepts (ticket-style conversations, broadcast-style notifications), not bridges to the real per-job/per-user Customer App data.

## 1. Complaints — new real schema (didn't exist before)

**Decision: `jobs/{jobId}/complaints/{id}`**, a subcollection of the job — same convention already used for `reviews`, `tracking`, and `threads`, not a new top-level collection. A complaint is always about exactly one job, so this keeps it naturally scoped and queryable the same way reviews already are (dashboard reads via `collectionGroup('complaints')`).

| Field | Type | Notes |
|---|---|---|
| `job_id` | string | Denormalized for convenience; the document path is authoritative |
| `raised_by` | `"customer" \| "technician"` | Which side filed it |
| `reporter_id` | string (uid) | Who filed it |
| `subject_id` | string (uid), nullable | Who it's about |
| `category` | string | Free-text reason (e.g. `no_show`, `billing`) — open-ended by design, not a fixed enum, since reasons vary and app-side copy/localization can map them |
| `description` | string | |
| `status` | `"open" \| "investigating" \| "resolved" \| "closed"` | |
| `evidence` | array\<string\> | Storage download URLs |
| `created_at` | Timestamp | |
| `resolved_at` | Timestamp, nullable | |
| `resolution_note` | string, nullable | |

**Implemented:**
- `packages/task_domain/lib/src/entities/complaint.dart` — `Complaint`, `ComplaintDraft`, `ComplaintRaisedBy`, `ComplaintStatus`
- `packages/task_domain/lib/src/repositories/complaint_repository.dart` — abstract interface (`watchForJob`, `submit`)
- `packages/task_data/lib/src/complaints/firestore_complaint_repository.dart` — real Firestore implementation
- `packages/task_data/lib/src/mappers/enum_codecs.dart` — wire codecs for both new enums
- `packages/task_data/lib/src/firestore_paths.dart` — `FirestorePaths.jobComplaintsCollection(db, jobId)`
- Admin Dashboard: `mapJobComplaintToComplaint` (repository.ts) bridges the real subcollection into the dashboard's existing `Complaint` UI shape; `ADAPTER_REGISTRY.complaints` flipped from `native` to `bridged`; existing `trust.view`/`technicians.complaints.view` permissions reused (no new permission key needed)

**Not implemented (deliberately out of this scope):** no Customer/Technician App UI screens — this is the shared model + repository + dashboard-read layer only, per "safe code-level scaffolding."

## 2. Conversations / Chat — real schema already exists, kept separate on purpose

The Customer App's real chat (`jobs/{jobId}/threads/{technicianId}(/messages)`) and the Admin Dashboard's native `conversations` (a flat support-ticket list: subject/priority/assignedAdmin) are **two different concepts that happen to share the word "chat."** Force-mapping one onto the other would misrepresent both — a support ticket isn't a per-job customer↔technician thread, and vice versa. Per your "do not invent randomly" instruction, this pass does **not** merge them.

**What was added instead:** `lib/firebase/real-schema-types.ts` (`RealChatThread`, `RealChatMessage`, exact-field-name mappers) plus `readRealJobChat(jobId, technicianId, actor)` in `repository.ts` — a permission-gated, one-shot, read-only helper that lets a future admin UI (e.g. a "view real chat" panel inside a complaint's detail view) fetch a specific job's actual chat history for dispute investigation, without touching the `conversations` list at all.

## 3. Notifications — real schema already exists (and Phase C already writes to it); read side added now

Real: `users/{uid}/notifications` (per-user feed). Dashboard's native `notifications` is a broadcast/campaign list — again, a different concept, correctly kept separate. Phase C already added bounded write-side fan-out from the dashboard into the real feed (`notification-fanout.ts`).

**What was added now:** `RealNotification` type + mapper (`real-schema-types.ts`) and `readRealUserNotifications(uid, actor)` — a permission-gated, one-shot read of a specific user's real notification feed, for a future "customer detail" drill-down view.

## Ready now

- Complaints: fully bridged, real data flows into the dashboard's existing Complaints UI shape today (once you sign in against production).
- Chat and notifications: shared types + tested mappers + permission-gated read functions exist; no UI page consumes them yet (out of this pass's scope).

## Still needs approval/deploy before any of this touches real users

- **Firestore rules**: the real `backend/firestore.rules` has no rule for `jobs/{jobId}/complaints` yet — a production admin's `collectionGroup('complaints')` read would currently return empty (not an error) since no documents exist there today, but once the Customer/Technician App actually writes complaints, a rule allowing job participants + admins to read/write that subcollection needs to be added and deployed (not done in this pass).
- **Cloud Functions**: none required for read-only Phase D behavior; a future notification-on-complaint-filed fan-out would be a natural Cloud Function candidate, not built here.
- **Production data migration**: none needed — this is new data going forward, not a migration of existing data.
- **Customer/Technician App UI**: no complaints-filing screen exists yet in either Flutter app; the repository/entity layer is ready for one to be built on top of it.
