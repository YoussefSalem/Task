# Technician job-status Firestore rule fix (Phase C.1, item 1)

## The bug

`backend/firestore.rules`, the `jobs/{jobId}` `update` rule, allowed a technician to advance a job's status only if:

```
request.resource.data.status in ['enRoute', 'inProgress', 'completed']
```

Those are the **Dart enum member names** (`JobStatus.enRoute`, `JobStatus.inProgress`). The real wire values the app actually writes to Firestore are snake_case, per `packages/task_data/lib/src/mappers/enum_codecs.dart` (`JobStatusCodec`):

```dart
JobStatus.enRoute => 'en_route',
JobStatus.inProgress => 'in_progress',
```

`'completed'` happens to be identical in both forms, which is likely why this went unnoticed — two of the three values were silently broken, one wasn't.

**Impact:** as written, a technician client can never legally write `status: 'en_route'` or `status: 'in_progress'` to a job — those writes would always be rejected by the `update` rule (falling through to deny, since no other branch of the `allow update` disjunction covers a technician's own status advance). This would have blocked the core booking lifecycle the moment a real Technician App exists and tries to advance a job past acceptance.

## The fix (code change made, not deployed)

`backend/firestore.rules`:

```diff
       allow update: if isAdmin()
         || isSelf(resource.data.customer_id)
         || (isSignedIn() && role() == 'technician' &&
-            request.resource.data.status in ['enRoute', 'inProgress', 'completed']);
+            request.resource.data.status in ['en_route', 'in_progress', 'completed']);
```

A comment was added at the rule site pointing back to `enum_codecs.dart` as the source of truth for wire values, so this doesn't regress again.

## What this fix does NOT do

- **Not deployed.** `backend/firestore.rules` is a local file edit only; no `firebase deploy` command was run, and the live rules protecting `task-app-20c5f` are unchanged until you explicitly approve a deploy.
- **Does not merge** the Customer App's rules with the Admin Dashboard's rules — that remains a separate, larger, not-yet-approved piece of work (see `docs/required-firestore-rule-changes.md` in the admin-dashboard app and the migration-plan docs).
- **Does not change any other rule** in the file.

## What still requires your approval/deploy later

- Actually deploying this one-line fix to `task-app-20c5f` (`firebase deploy --only firestore:rules`) — needs your explicit approval, per your standing instruction not to deploy.
- Everything else already tracked in `docs/required-firestore-rule-changes.md` and the Phase B migration plan (the two rule sets still cannot be merged by concatenation; RBAC/admin-identity model still needs a decision).
