# Phase C Final Verification Report

> Audit-only pass over the Phase C work, per your request. **One issue was found and fixed** (a code-duplication gap in the routing layer I introduced); everything else is a finding to report, not a bug to fix, per the "do not modify unless a real issue is found" instruction. No Firebase config, rules, deploys, or data were touched.

## 1. Remaining hardcoded collection names that should route through the adapter layer

**Found and fixed:** `entity-routing.ts` (created in Phase C) was only wired into one call site (`createPayout`). 22 other places in `repository.ts` still had the identical inline ternaries (`actor.isDemoUser ? "providers" : "users"`, `... "customers" : "users"`, `... "orders" : "jobs"`) — correct in behavior, but duplicating logic the shared module already existed to centralize. **Fixed:** all 22 replaced with `providerSourceCollection()`/`customerSourceCollection()`/`jobSourceCollection()` calls. Re-verified with `tsc --noEmit`, `npm test` (21/21 pass), `npm run lint` (clean), and `npm run build` (succeeds) after the change.

## 2. Every production write goes through the correct routing path

Verified all `setDoc`/`updateDoc`/`deleteDoc`/`batch.*`/`transaction.*` call sites (60 total) in `repository.ts`. Every one that targets a real Customer App collection (`users`, `jobs`, `users/{uid}/wallet(_transactions)`, `users/{uid}/notifications`) is correctly gated by `!actor.isDemoUser` or routed through the new shared helpers. No unguarded production write was found reaching a demo-only collection, or vice versa.

## 3. Production reads never accidentally read demo collections

`subscribeDashboard`'s real-collection branches (`customers`, `providers`, `jobs`, `wallets`, `transactions`, `reviews`) are each explicitly gated by `!actor.isDemoUser` before touching `users`/`jobs`/`collectionGroup(wallet|wallet_transactions|reviews)`. Every other (dashboard-only) collection read is filtered by `where("environment", "==", environmentForActor(actor))`, so demo and production admins structurally cannot see each other's documents in those collections. No gap found.

## 4. No remaining dashboard-only notification paths

`createNotification` writes its dashboard broadcast record (unchanged, all modes) and, for non-demo actors, fans out to real `users/{uid}/notifications` for bounded recipients (confirmed via the two updated call sites: `technician-performance-center.tsx` now passes `targetUserId`, `provider-management.tsx` now passes `targetUserIds: selected`). No other notification-write code path exists anywhere in the repo.

## 5. Payout/refund legacy collection names

`createPayout`/`verifyPayout` correctly branch to `users`/real `wallet_transactions` for production (fixed in Phase C). The dashboard-only `payouts` and `transactions` collections are still written unconditionally by design — there is no real "provider payout" or generic "transaction ledger" concept in the Customer App to bridge to, so these remain dashboard-native audit/UI records, not a bug.

**Found, not fixed (pre-existing, outside Phase C's original scope):** `flagMessage`, `reviewCall`, and `reviewInstapay` still read/write the demo-only `"orders"`/`"transactions"` collections unconditionally, with no `isDemoUser` branch at all. These were already flagged in the original audit report and were **not** among the 9 priority items you approved for Phase C (chat-message flagging, call review, and Instapay verification specifically). Flagging here for your decision on whether to include them in a follow-up pass — not fixed in this audit to avoid unrequested scope expansion.

## 6. Status conversions — no silent fallback

`job-status-mapping.ts`'s `adminJobStatusFromWire` (the one this phase targeted) now explicitly maps every declared Customer App `JobStatus` value, including `disputed`/`pausedForApproval`, and logs a warning for genuinely unrecognized input instead of silently defaulting. Confirmed via `tests/job-status-mapping.test.ts`.

**Found, not fixed (pre-existing, outside Phase C's original scope):** three other status-conversion functions in `repository.ts` also have silent defaults: `adminStatusFromUser` (unrecognized customer status → `"Active"` — arguably the riskiest of the three, since it defaults an unknown state to the *most permissive* one rather than a neutral one), `bookingTypeFromWire` (→ `"Scheduled"`), and `paymentStatusFromWire` (→ `"Pending"`). None of these were in the original Phase C priority list (which named "job status mapping" specifically), so none were changed. Flagging `adminStatusFromUser`'s default in particular as worth a decision on whether to fix in a follow-up.

## 7. TODO/FIXME related to migration

**None found.** A full grep of `lib/`, `components/`, `app/`, and `scripts/` for `TODO`/`FIXME` returned zero matches.

## 8. Duplicate/dead code scan

- **Duplicate Firestore path constants:** found and fixed (see #1 above).
- **Duplicate models/enums/status definitions:** none found — no other file redefines `JobStatus` or any other type from `lib/types.ts`; no naming collisions among exported interfaces/types.
- **Dead code:** none found in the four new Phase C modules — every exported symbol from `job-status-mapping.ts`, `notification-fanout.ts`, `admin-identity.ts`, and `entity-routing.ts` is referenced either by `repository.ts`/`server-auth.ts` or by its own test file (the latter is intentional — `BroadcastFanoutNotImplementedError` and `MAX_BOUNDED_FANOUT_RECIPIENTS` are exported specifically so tests can assert against them, not consumed directly by `repository.ts`). `lib/permissions 2.ts` was already confirmed dead and deleted in Phase C.
- **Duplicate/dead code elsewhere in the app:** out of scope for this pass (the instruction was to verify Phase C's own work); a full-app dead-code sweep would be a separate, larger audit.

## Final verification (fresh, this session)

- `npm test`: **21/21 pass**
- `npx tsc --noEmit`: **0 errors**
- `npm run lint`: **0 warnings/errors**
- `npm run build`: **succeeds**, all 17 routes generate

## Confirmation

One fix applied (the routing-helper consolidation, #1) — a safe, behavior-preserving refactor, re-verified with the full test/lint/build suite. No Firebase config, Firestore rules, or Storage rules were touched. No deploy ran. No data was migrated. All changes remain uncommitted on the isolated `phase-c-safe-code-alignment` branch/worktree.

The repository is internally consistent for the 9 items Phase C was chartered to fix. Three genuine, pre-existing gaps were found outside that charter (`flagMessage`/`reviewCall`/`reviewInstapay` collection routing; `adminStatusFromUser`'s risky default) — recommend a decision on these before or during Phase D, but they are not blockers to proceeding.
