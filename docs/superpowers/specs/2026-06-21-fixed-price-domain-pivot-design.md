# Fixed-Price Domain Pivot — Design Spec

**Date:** 2026-06-21
**Status:** Approved
**Slice:** 1 of 6 (Core UX & Marketplace Refactor)
**Fidelity:** Polished prototype — mock data behind a swappable repository

## Context

The Task App is a Flutter Melos monorepo (`apps/customer`, `apps/technician`,
`apps/admin`) with shared packages (`task_core`, `task_domain`, `task_data`,
`task_design`) and a Firebase Cloud Functions backend. Today the customer app
models work as a **predefined service catalog**: hardcoded `Service` objects
carry a `basePrice` and a `durationLabel` ("45-90 min", "2-4 hrs"), and the
booking flow picks one of three engines (ASAP / Scheduled / Quote).

The product is pivoting to a **fixed-price job marketplace** (Uber / inDrive /
TaskRabbit style): users describe a problem, name a single price for the whole
job, and nearby technicians accept, decline, or counter-offer until one party
accepts or cancels. There is no hourly pricing and no predefined-service
selection.

This spec covers **slice 1 only**: the domain/data pivot plus the start of the
teardown of the hourly/predefined-service model. Later slices (job-creation UX,
AI dispatcher, technician marketplace + live negotiation, real GPS/location,
navigation & animation polish) each get their own spec → plan → build cycle.

## Goals

- A canonical, hourly-free fixed-price job model shared across all three apps.
- An offer/negotiation model that preserves the full price trail per technician.
- The two new categories (Satellite Installation & Repair, Smart Home
  Installation & Automation) defined in the canonical taxonomy.
- Excise the predefined-service / `basePrice` / `durationLabel` model from the
  customer app, replacing it with the new model plus a thin placeholder entry
  point for the real creation flow (slice 2).
- The monorepo compiles and `melos run test` is green at the end of the slice.

## Non-Goals (explicitly deferred)

- Real GPS, permissions, map pin/search (slice 5).
- The full multi-step "describe → details → price → publish" creation UX and
  photo capture (slice 2).
- The AI dispatcher assistant (slice 3).
- Technician-side accept/decline/counter UI and live customer↔technician sync;
  radius routing (slice 4). The two new categories are *defined* here but only
  wired into technician registration / admin filters in slice 4 and later.
- Navigation, transitions, hero, loading/empty/pull-to-refresh polish (slice 6).

## Architecture

### Decisions locked during brainstorming

1. **Fidelity:** polished prototype against mock/in-memory data.
2. **Negotiation model:** *offer thread per technician* — each interested
   technician has one `Offer` holding the full list of price proposals.
3. **Model home:** the canonical model lives in the shared `task_domain`
   package so all three apps import one source of truth. Mock data lives behind
   a repository the customer app provides.
4. **Categories:** a `JobCategory` enum in pure-Dart `task_domain`
   (id + display label); icon + tint mapping lives in the UI layer.
5. **Slice boundary:** foundation **plus** the start of the teardown, while
   keeping the tree compiling and tests green.

### New domain model (`packages/task_domain`, pure Dart — no Flutter imports)

```text
JobCategory (enum)
    plumbing, electrical, ac, cleaning, carpentry, painting,
    satelliteInstallation, smartHome
    → id (stable string), displayLabel (English)

Urgency (enum)        flexible | soon | urgent | emergency
PropertyType (enum)   apartment | villa | office | other

PriceProposal
    amount      int    // EGP, whole pounds
    by          ProposalAuthor   // customer | technician
    at          DateTime

Offer                 // one per interested technician — the negotiation thread
    id              String
    technicianId    String
    technicianName  String
    rating          double
    jobsDone        int
    etaLabel        String
    proposals       List<PriceProposal>   // chronological; never empty
    status          OfferStatus           // pending | countered | accepted
                                          //  | declined | withdrawn
    // derived:
    currentPrice => proposals.last.amount

JobRequest
    id            String
    category      JobCategory
    title         String
    description   String
    fixedPrice    int            // EGP — the customer's single offered amount
    currency      String = 'EGP'
    urgency       Urgency
    propertyType  PropertyType
    floor         String?        // free text ("3", "Ground")
    parking       bool?          // parking available at the location
    photos        List<String>   // local paths / ids in prototype
    locationLabel String         // human-readable; real geo lands in slice 5
    notes         String
    status        JobStatus      // reuse existing enum
    offers        List<Offer>
    createdAt     DateTime
    // derived:
    acceptedOffer => offers.firstWhereOrNull(o => o.status == accepted)
    settledPrice  => acceptedOffer?.currentPrice ?? fixedPrice
```

`JobStatus` reuses the existing enum in `enums.dart`. New enums
(`JobCategory`, `Urgency`, `PropertyType`, `ProposalAuthor`, `OfferStatus`) are
added there or in a sibling file under `task_domain/src/entities/`.

### Repository seam

```text
abstract interface JobMarketplaceRepository {
    Stream<List<JobRequest>> watchMyJobs();      // customer's posted jobs
    Future<JobRequest> publish(JobRequestDraft draft);
    Future<void> acceptOffer(String jobId, String offerId);
    Future<void> counterOffer(String jobId, String offerId, int amount);
    Future<void> cancelJob(String jobId);
}
```

- Interface lives in `task_domain`.
- A `MockJobMarketplaceRepository` in the customer app seeds realistic jobs and
  offer threads (replacing today's `kBids` const list) and serves them via an
  in-memory store / `StateNotifier`-friendly stream. This is the single seam
  slice 4 swaps for a Firestore-backed implementation.

### `JobRequestDraft`

The in-progress request the customer assembles (replaces `BookingDraft`):
`category`, `title`, `description`, `fixedPrice`, `urgency`, `propertyType`,
`floor`, `parking`, `photos`, `locationLabel`, `notes`. Provided to
`publish()`. Held by a Riverpod notifier in the customer app.

## Teardown / migration (keeps the app green)

| File | Action |
|------|--------|
| `features/services/service_catalog.dart` | **Delete** `Service`, `kServices`, `basePrice`, `durationLabel`, `serviceById`, `servicesForCategory`, `serviceGlow`. Keep a UI-only `categoryIcon(JobCategory)` + `categoryTint(JobCategory)` map (move here or into `task_design`). |
| `features/booking/booking_state.dart` | Replace `BookingDraft` / `BookingMode` with `JobRequestDraft`. `BookingsController` reads `JobRequest`s from the mock repo instead of the `BookingRecord` const list. Remove `kBids` (moves into the repo seed). |
| `features/services/service_detail_screen.dart` + `features/booking/booking_configure_screen.dart` | Replace with a **thin placeholder** "Describe your problem → name your price" entry that builds a `JobRequestDraft` and calls `publish()`. The full multi-step UX is slice 2. (May collapse to a single new `job_create_stub_screen.dart`.) |
| `features/home/home_screen.dart` | Category grid renders the new 8 `JobCategory` values via the UI icon map; tapping a category seeds a draft and opens the placeholder create entry. Remove `servicesForCategory` usage and any `Service` references. |
| `features/bookings/bookings_screen.dart` | Render `JobRequest`s (title, category, `settledPrice`, status) instead of `BookingRecord` + `Service`. |
| `features/job/job_tracking_screen.dart` | Read price/labels from `JobRequest` / `acceptedOffer` rather than `Service.basePrice`. |
| `features/payment/payment_screen.dart` | Totals come from `JobRequest.settledPrice`. |
| `features/review/rating_screen.dart` | Reference `JobRequest` instead of `Service`. |
| `features/booking/quote_bids_screen.dart` | Re-point from `kBids` to the job's `Offer` threads (read-only render is fine here; full accept/counter interactions are slice 4). |
| `features/booking/asap_dispatch_screen.dart` | Migrate off `Service`/`BookingMode`; keep as a kept-but-reshaped-later screen (slice 4). |
| `features/services/technician_catalog.dart` | Update any `Service`/category references to `JobCategory`. |
| `app/router.dart` | Drop `/service/:id` and `/book/configure` engine routes; add the placeholder job-create route. |
| `features/auth/sign_in_screen.dart` | Adjust only if it references the removed model (audit during implementation). |

"Migrated-but-kept" screens (`quote_bids_screen`, `asap_dispatch_screen`) are
intentionally **not deleted** now — they are reshaped in slice 4 when the live
technician marketplace lands.

## Data flow

1. Home category tap → seeds `JobRequestDraft(category)` → placeholder create
   entry collects title/description/price → `repository.publish(draft)`.
2. `publish` stores a `JobRequest` (status `searching`/`biddingActive`) with a
   seeded set of incoming `Offer`s (mock technicians) for demo realism.
3. Bookings tab + tracking + quote-bids read from `watchMyJobs()`.
4. Accept/counter calls mutate the in-memory store; the stream re-emits.

## Error handling

- Repository methods return/throw via the existing `Result` / `Failure` types
  in `task_core` where the surrounding code already uses them; otherwise keep
  prototype-simple (the mock cannot realistically fail). Validate that
  `fixedPrice > 0` and required draft fields are present before `publish`.

## Testing

- **Domain unit tests** (`task_domain`): `Offer.currentPrice` reflects the last
  proposal; threading a counter appends a proposal and flips status to
  `countered`; `JobCategory` id/label round-trip and exhaustiveness;
  `JobRequest.settledPrice` falls back to `fixedPrice` with no accepted offer.
- **Mock repository tests** (customer app): `publish` adds a job to
  `watchMyJobs`; `acceptOffer` sets `OfferStatus.accepted` and `settledPrice`;
  `counterOffer` appends a customer proposal.
- Update existing splash/widget tests that reference the removed model so the
  suite stays green.
- Slice exit criterion: `melos run test` passes.

## Open items / audit-during-implementation

- Confirm whether `categoryIcon`/`categoryTint` belong in `task_design`
  (shared) vs. the customer feature folder — prefer `task_design` if the
  technician/admin apps will need the same mapping in later slices.
- Audit `sign_in_screen.dart` and `technician_catalog.dart` for stray `Service`
  references during the teardown.
