# Required Firestore rule: `jobs/{jobId}/complaints`

> Documentation only. Nothing in this file has been deployed. `backend/firestore.rules`
> is unchanged by this pass — this describes the exact diff needed once complaint
> writes from the Customer/Technician App are approved for production.

## Why a rule is needed now

[2026-07-07-complaints-chat-notifications-schema.md](2026-07-07-complaints-chat-notifications-schema.md)
added `FirestoreComplaintRepository` (`packages/task_data/lib/src/complaints/firestore_complaint_repository.dart`),
which writes to `jobs/{jobId}/complaints`, and this sprint wired a real UI entry
point (`apps/customer/lib/features/complaints/report_problem_sheet.dart`) that
calls it. `backend/firestore.rules` currently has no `match` block for that
subcollection at all, so with the default-deny rules root, every real write
from the app will fail with `permission-denied` until this rule is added and
deployed. The admin dashboard's `collectionGroup('complaints')` read
(`resolveReadSource` in `lib/firebase/entity-routing.ts`) will similarly return
nothing for real data until a collection-group rule exists.

## Exact fields written (from `firestore_complaint_repository.dart`)

`job_id`, `raised_by` (`'customer' | 'technician'`), `reporter_id` (uid of
whoever filed it), `subject_id` (uid of the other party, may be absent),
`category`, `description`, `status` (`'open'` on create), `evidence`,
`created_at`.

## Rule to add inside `match /jobs/{jobId} { ... }`

Placed alongside the existing `threads` and `reviews` subcollection rules
(`backend/firestore.rules:121-162`), following the same
resource-data-not-a-`get()` convention used by `isThreadParticipant()` (a
`get()` on the parent job fails for collection-group queries because the
`{jobId}` wildcard is unresolved at evaluation time):

```
// Problem reports filed by a job's customer or assigned technician against
// the other party. Mirrors the threads subcollection's participant check.
match /complaints/{complaintId} {
  function isComplaintParticipant() {
    return isSignedIn() && (
      resource.data.reporter_id == request.auth.uid
      || resource.data.subject_id == request.auth.uid
      || isAdmin()
    );
  }

  function canCreateComplaint() {
    return isSignedIn() && (
      request.resource.data.reporter_id == request.auth.uid
      && request.resource.data.job_id == jobId
      && request.resource.data.status == 'open'
    );
  }

  allow read: if isComplaintParticipant();
  allow create: if canCreateComplaint();
  // Only admins change status (investigating/resolved/closed) or add
  // resolution notes; reporters cannot edit or withdraw after filing.
  allow update, delete: if isAdmin();
}
```

## Rule to add for the dashboard's collection-group read

The admin dashboard reads via `collectionGroup("complaints")`
(`lib/firebase/entity-routing.ts`'s `resolveReadSource` case for
`"complaints"`), which needs its own top-level recursive-wildcard rule —
scoped to admins only, since this is an operational triage view, not a path
any customer/technician-facing feature queries across jobs:

```
// --- complaints inbox (collection-group query, admin dashboard only) ---
match /{path=**}/complaints/{complaintId} {
  allow read: if isAdmin();
}
```

Place this near the existing `match /{path=**}/threads/{technicianId}`
collection-group rule (`backend/firestore.rules:174-179`) for consistency.

## What is NOT covered by this doc

- No Cloud Function fan-out (e.g. notifying an admin queue on complaint
  create) is proposed here — out of scope for this rule change.
- No composite Firestore index is required: the dashboard's
  `readRealJobChat`/complaint reads do not filter/sort the collection-group
  query, so no `firestore.indexes.json` change accompanies this.
- Deployment itself (`firebase deploy --only firestore:rules`) requires
  explicit approval and is not part of this pass.
