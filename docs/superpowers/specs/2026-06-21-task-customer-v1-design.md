# Task — Customer v1 + Shared Foundation + Backend — Design Spec

**Date:** 2026-06-21
**Status:** Approved
**Scope:** Customer app (v1), shared Melos packages, and the Firebase backend contract built in lockstep.
**Source docs:** `Task_App_PRD.md` (v1.0.0, authoritative), `Task_App_Discovery_Document_Updated.md`, `V.1 Task_App_Discovery_Document.md`.

---

## 1. Product summary

**Task** is an Uber-style, on-demand **home-services marketplace** for Egypt/MENA. Dark-theme, RTL-first (Arabic), built on Flutter + a fully serverless Firebase backend. Three surfaces share one ecosystem: **Customer app**, **Technician app**, **Web Admin dashboard**. The defining complexity is operational: a cash-dominant market, unreliable street addressing, frequent loss of connectivity (basements), and unpredictable job scope creep.

This spec covers **the Customer app as the first surface**, the **shared business-logic packages**, and the **backend contract** (Firestore + Cloud Functions + Cloud Tasks) built alongside it. Technician and Admin apps are later phases and are scaffolded as skeletons only.

---

## 2. Locked decisions

| Decision | Choice | Rationale |
|---|---|---|
| First surface | **Customer app** | Fastest path to a visible, testable product; exercises the full backend. |
| Backend | **We build it** (Firestore rules, Cloud Functions TS, Cloud Tasks) | PRD §2–§3 schemas/functions ARE the contract. |
| Packaging | **Monorepo + flavors** (Melos) | Tech + Admin reuse domain/data; avoids a future refactor. |
| Platforms | **Mobile + Web** (Android, iOS, tablets, Flutter Web for Admin) | PRD targets iOS/Android/Web. |
| Offline DB | **Drift** | SQL, testable, dev-instruction-preferred over Hive/sqflite. |
| State mgmt | **Riverpod** | Dev instructions override PRD's "Riverpod or BLoC". |
| Booking engines (v1) | **ASAP + Scheduled + Quote/sealed-bid** | All three in v1. |
| Payments (v1) | **COD** (state-synced) + **Card & Vodafone Cash** (Paymob) + **InstaPay** (admin-approved) | Full payment surface. |
| Comms (v1) | **In-app chat + VoIP** (provider abstracted; Agora recommended) | |
| Deferred | Promos, referrals, loyalty, subscription, AI bot, WhatsApp | Out of v1. |

---

## 3. Roles

- **Customer** — books (ASAP/Scheduled/Quote), tracks, pays (Cash/Card/Wallet/InstaPay), approves scope changes, disputes, reviews. Blocked from booking while `debt_balance > 0`.
- **Technician** — KYC-gated; sandbox while `under_review`; availability toggle (hard-locked by wallet/suspension); receives dispatch; executes job; manages wallet (can go negative to −500); subject to no-show penalty matrix. *(Phase 2.)*
- **Admin** — KYC/payout approval, polygon zone management, pricing/commission overrides, dispute resolution, emergency blackout, **InstaPay transaction approval**. *(Phase 3; minimal InstaPay-approval path enters in v1.)*
- **System** (Cloud Functions + Cloud Tasks) — dispatch cascade, bid cap, scope-threshold routing, penalty automation, chat TTL cleanup, payment webhooks.

---

## 4. Architecture

Clean Architecture, three layers. **Shared business logic lives in Melos packages from day one** — Technician/Admin reuse jobs, wallet, payments, addresses, auth, so this is justified rather than premature.

Stack: **Riverpod** (state) · **GoRouter** (routing) · **Dio** (Paymob HTTP) · **Freezed + json_serializable** (models) · **Drift** (offline queue) · **Material 3** dark-only · **RTL-first** localization (ar/en) · **Firebase App Check** mandatory on all DB/API calls.

### 4.1 Monorepo layout (Melos-managed)

```
task/
├─ melos.yaml
├─ pubspec.yaml                  # workspace root
├─ packages/
│  ├─ task_core/                 # pure Dart: Result/Failure, value objects, constants, utils, App Check hooks
│  ├─ task_design/               # M3 theme, color tokens, Cairo typography, RTL, l10n (ar/en), shared widgets
│  ├─ task_domain/               # Freezed entities + repository INTERFACES + use cases (no Flutter/Firebase)
│  └─ task_data/                 # Firebase/Dio/Drift IMPLEMENTATIONS, DTOs, mappers, offline sync
├─ apps/
│  ├─ customer/                  # v1 — feature-first presentation, Riverpod providers, GoRouter, DI wiring
│  ├─ technician/                # Phase 2 (skeleton only)
│  └─ admin/                     # Phase 3, Flutter Web (skeleton only)
└─ backend/
   ├─ functions/                 # TS Cloud Functions + Cloud Tasks
   ├─ firestore.rules            # sealed-bid blinding, role gates, App Check enforcement
   ├─ firestore.indexes.json
   └─ storage.rules
```

Presentation lives in `apps/customer/lib/features/<feature>/` (auth, address, booking, job, payment, chat, profile, disputes) — each feature owns its screens/widgets/controllers. **Domain & data are shared packages**, so promotion to the Technician app is zero-cost.

### 4.2 Layer dependency rule

`presentation → domain ← data`. Domain depends on nothing Flutter/Firebase. Data implements domain interfaces. Presentation depends on domain (+ design/core). No layer skips inward.

---

## 5. Data flow

```
UI (widget)
  → Riverpod controller (AsyncNotifier)
    → Use case (domain)
      → Repository interface (domain)
        → Repository impl (data): Firestore snapshots() | Dio→Paymob | Drift
```

Real-time job/tracking/chat surfaces are Firestore `snapshots()` exposed as `Stream` providers. Offline writes hit **Drift first** and are reconciled by a sync service on connectivity restore.

---

## 6. Backend contract (built in lockstep)

Firestore collections per PRD §2 — `users`, `addresses`, `jobs` with `quotes` / `tracking` / `chat` subcollections (sub-collections over unbounded arrays). Cloud Functions per PRD §3:

- **ASAP dispatch** — Cloud Tasks cascade 3→6→…→20 km, +30 s per tier, sequential closest-N FCM, timeout → `cancelled`.
- **Sealed bid** — quotes blinded by security rules; cap at 5; losers → `expired` on selection.
- **Scope creep** — pause → line item + photo evidence → threshold routing (<30% customer OTP · 30–50% admin override + OTP · >50% admin review + re-auth).
- **Penalties** — customer flake → `debt_balance`; technician no-show 4-strike matrix (rank hit → 24 h → 72 h → ban + 50 EGP).
- **Wallet** — COD 20% platform fee deducted to `wallet_balance`; −300 warning; −500 hard lock.
- **Payments** — Paymob webhooks (card + Vodafone Cash); **InstaPay → `pending_admin_approval`** until admin confirms.
- **Maintenance** — chat 30-day active TTL, 12-month archive, then cron delete.

Rules enforce sealed bids, role separation, and App Check. **No invented fields** — any addition beyond the PRD schema is flagged in the PR.

---

## 7. Job state machine

`searching → pending_scheduled → bidding_active → accepted → en_route → in_progress → paused_for_approval → completed | disputed | cancelled`

Completion validation: `before_images` (min 1) and `after_images` (min 1, max 10 total). Geo-tracking: 10 s writes while `en_route`; distance-filtered (>20 m) or 2-min idle while online; **foreground service killed on `completed`/`cancelled`**.

---

## 8. Error handling

`Result<Success, Failure>` across domain boundaries — exceptions never leak to UI. Typed `Failure` hierarchy: `network` · `auth` · `validation` · `permission` · `payment` · `offline`. Every async provider renders explicit loading / error / empty states. Firebase Crashlytics captures non-fatals.

---

## 9. Testing strategy

- Pure domain + use cases → unit tests.
- Repositories → tested against fake data sources.
- Riverpod controllers → tested with `ProviderContainer` overrides.
- Key Customer screens → golden tests (RTL + dark theme).
- `flutter analyze` clean is a merge gate (zero warnings).

---

## 10. Offline & media constraints (PRD §5)

- Offline queue in **Drift**; high-res photo paths stored locally; 7-day TTL.
- "Saved Offline — Syncing when connected" UX; tech can leave premises.
- Background worker (`workmanager`): on reconnect, compress images (1080p, 80% JPEG, ≤800 KB), upload to Storage, write URLs to the job doc.

---

## 11. Known unknowns (abstracted, not assumed)

| Item | Handling |
|---|---|
| VoIP provider | Interface now; **Agora** recommended; confirm later. |
| Scheduled-booking availability mutation | Backend concern; data model supports it; rule TBD before Scheduled goes live. |
| Tier-threshold math (Bronze→Platinum) | Phase 2 (Technician). |
| Payout cadence + compliance fields | Phase 2. |
| Commission override precedence (flat 20% vs per-zone vs per-tier) | Define before Admin zone tooling (Phase 3). |
| Customer-flake tech compensation on COD | Define before penalties go live. |

None block Customer v1.

---

## 12. Phasing

1. **Foundation** — Melos monorepo, packages skeleton, App Check, theme/RTL/l10n, routing, DI, Firebase project config, emulator suite, `launch.json`.
2. **Auth & profile** — Phone OTP, user model, App Check enforcement.
3. **Addresses** — hybrid address book.
4. **Booking engines** — ASAP (Cloud Tasks), Scheduled, Quote/sealed-bid.
5. **Job execution** — tracking, invoicing, scope-approval OTP, reviews.
6. **Payments** — COD state-sync, Paymob (card + wallet), InstaPay admin-approval.
7. **Comms** — chat (TTL) + VoIP.
8. **Disputes** — customer-side dispute creation.

Each phase: explain → build → self-review → verify (`flutter analyze` + tests) before complete.
