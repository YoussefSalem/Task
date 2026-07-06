# Required Firestore/Storage rule changes (not applied — planning only)

> Per Phase C instructions, `firestore.rules` and `storage.rules` were **not modified**. This document records what will need to change once rules work is explicitly approved, based on the code-level fixes made in this pass and the `rules_storage_comparison` findings in [2026-07-06-unified-backend-architecture-plan.md](../../../docs/superpowers/plans/2026-07-06-unified-backend-architecture-plan.md).

## 1. `reviews` collection-group read (new in this pass)

`subscribeDashboard` now reads `collectionGroup(db, "reviews")` for non-demo admins. The backend's real `backend/firestore.rules` already has a `jobs/{jobId}/reviews/{reviewerId}` rule with `allow read: if isSignedIn()`, but **no collection-group rule** exists for it — Firestore requires an explicit `match /{path=**}/reviews/{reviewerId}` (or similar) collection-group rule for `collectionGroup()` queries to succeed, the same way the existing `threads` collection-group query already has one (`backend/firestore.rules:168-174`). **Required addition:** a collection-group rule for `reviews` scoped to admin/permission-holding accounts only (the existing per-job rule is `isSignedIn()`-only, which is broader than we'd want for a collection-group query spanning every job).

## 2. `payouts`/wallet writes from `createPayout` (fixed in this pass)

`createPayout`'s production branch now writes to `users/{uid}/wallet/summary` and `users/{uid}/wallet_transactions` for the technician. The backend's real rules make both paths **`allow write: if false`** (client-write-denied) — correct for the Customer App's own client, but this write comes from the *dashboard's* client-side Firestore SDK, not from a trusted server context. **Required change:** either (a) move this write server-side (a Next.js API route using `firebase-admin`, which bypasses rules entirely — the safer option, consistent with how `requireFirebaseAdmin` already works for other privileged routes), or (b) add a rules exception scoped to `admins/{uid}`-verified writers. Recommend (a); flagged for Phase D since it requires moving logic out of client-executed `repository.ts`, which is a design decision beyond "safe code alignment."

## 3. `users/{uid}/notifications` fan-out writes (new in this pass)

`createNotification`'s production branch now writes into `users/{uid}/notifications` for bounded recipients. The backend's real rule already allows this: `allow create: if isSignedIn();` on `users/{uid}/notifications` (no ownership check — flagged in the original Customer App audit as intentionally permissive-for-now). This means the new dashboard write will actually succeed once the two projects share one Firestore database, **without any rule change** — but it also means the existing security gap (any signed-in user can write into any other user's feed) applies here too. **Recommended tightening once unified:** scope `create` on this path to either the request's own uid, or a small allow-list of trusted server/admin identities, rather than leaving it open to any signed-in user.

## 4. `admins/{uid}` and `roles/{roleId}` collections do not exist in the real schema

The dashboard's entire rules file (`apps/admin-dashboard/firestore.rules`) depends on `get(/databases/.../admins/$(uid))` resolving. The real backend has no such collection. **Required addition:** the `admins`/`roles`/`adminInvites` collections and their rules need to be added to the unified ruleset — this is the single largest piece of rules work, and is exactly what Phase C item 6's `admin-identity.ts` helper defends against at the *code* layer in the meantime (refusing to treat a customer/technician uid as an admin even before rules exist to enforce it server-side).

## 5. Two conflicting catch-all/default-deny strategies

The dashboard's rules end in an explicit `match /{document=**} { allow read, write: if false; }`; the backend relies on Firestore's implicit default-deny. **Required decision:** pick one (recommend keeping the explicit catch-all, since it's more auditable) and remove the other before any merge.

## 6. `promotions` vs. `banners`/`promos` naming

Not a rules change per se, but the eventual merged ruleset needs one agreed name before write rules can be written for it — see the migration plan's Phase 2 decision item.

## Explicitly NOT included in this pass

- No changes to `apps/admin-dashboard/firestore.rules`, `storage.rules`, `firestore.indexes.json`, `backend/firestore.rules`, or `backend/storage.rules`.
- No `firebase deploy` of any kind was run.
- These are recommendations for a future, explicitly-approved rules-change phase (Phase 6 in the migration plan), reviewed here only so the code fixes in this pass have a documented path to actually working once rules catch up.
