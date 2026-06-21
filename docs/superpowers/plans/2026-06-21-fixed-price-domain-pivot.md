# Fixed-Price Domain Pivot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the predefined-service / hourly-priced booking model with a shared, fixed-price `JobRequest` + per-technician `Offer` negotiation model, add the 8-category taxonomy (incl. two new categories), and tear out the legacy service catalog while keeping the monorepo compiling and `melos run test` green.

**Architecture:** The canonical model lives in pure-Dart `task_domain` (enums, entities, a `JobMarketplaceRepository` interface). The customer app provides an in-memory `MockJobMarketplaceRepository` (the single seam slice 4 swaps for Firestore) plus Riverpod providers. UI-only category icon/tint mapping lives in `task_design`. Legacy `Service`/`Bid`/`BookingMode` screens are migrated to read the new model; `service_detail` + `booking_configure` are replaced by a thin "describe → name your price" stub that slice 2 fleshes out.

**Tech Stack:** Flutter 3.44 / Dart 3.9, Melos workspace, Riverpod 2.6, go_router 14.6, `test` (pure Dart) + `flutter_test`.

## Global Constraints

- Currency is **EGP**, prices are whole integers (no decimals, no hourly math).
- `task_domain` and `task_core` are **pure Dart** — no `package:flutter`, no Firebase imports. Icons/colors never enter `task_domain`.
- Mock data only this slice; all live data flows through the `JobMarketplaceRepository` seam.
- Do **not** add the `font_awesome_flutter` dependency (breaks the build — use Material icons).
- Two new categories: **Satellite Installation & Repair** (`id: satellite`) and **Smart Home Installation & Automation** (`id: smart_home`).
- Keep migrated-but-deferred screens (`quote_bids_screen`, `asap_dispatch_screen`) compiling; do not delete them (slice 4 reshapes them).
- Each task ends green: run the stated test command and confirm PASS before committing.
- Run `dart test` from a package dir for pure-Dart packages; `flutter test` from `apps/customer` for the app.

---

### Task 1: JobCategory + supporting enums (task_domain)

**Files:**
- Create: `packages/task_domain/lib/src/entities/job_category.dart`
- Create: `packages/task_domain/lib/src/entities/job_enums.dart`
- Modify: `packages/task_domain/lib/task_domain.dart` (add exports)
- Test: `packages/task_domain/test/job_category_test.dart`

**Interfaces:**
- Produces: `enum JobCategory` with `final String id`, `final String displayLabel`, `static JobCategory fromId(String)`. `enum Urgency { flexible, soon, urgent, emergency }`, `enum PropertyType { apartment, villa, office, other }`, `enum ProposalAuthor { customer, technician }`, `enum OfferStatus { pending, countered, accepted, declined, withdrawn }`.

- [ ] **Step 1: Write the failing test**

```dart
// packages/task_domain/test/job_category_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

void main() {
  test('JobCategory has the 8 canonical categories incl. the 2 new ones', () {
    expect(JobCategory.values.length, 8);
    expect(JobCategory.satelliteInstallation.id, 'satellite');
    expect(JobCategory.satelliteInstallation.displayLabel,
        'Satellite Installation & Repair');
    expect(JobCategory.smartHome.id, 'smart_home');
    expect(JobCategory.smartHome.displayLabel,
        'Smart Home Installation & Automation');
  });

  test('fromId round-trips every category id', () {
    for (final JobCategory c in JobCategory.values) {
      expect(JobCategory.fromId(c.id), c);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/task_domain && dart test test/job_category_test.dart`
Expected: FAIL — `JobCategory` is not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// packages/task_domain/lib/src/entities/job_category.dart

/// Canonical service categories for the fixed-price marketplace. Pure data —
/// icons and tints live in the UI layer (`task_design`). The `id` is the stable
/// string persisted with a job; `displayLabel` is English copy.
enum JobCategory {
  plumbing('plumbing', 'Plumbing'),
  electrical('electrical', 'Electrical'),
  ac('ac', 'AC & Cooling'),
  cleaning('cleaning', 'Cleaning'),
  carpentry('carpentry', 'Carpentry'),
  painting('painting', 'Painting'),
  satelliteInstallation('satellite', 'Satellite Installation & Repair'),
  smartHome('smart_home', 'Smart Home Installation & Automation');

  const JobCategory(this.id, this.displayLabel);

  final String id;
  final String displayLabel;

  static JobCategory fromId(String id) =>
      JobCategory.values.firstWhere((JobCategory c) => c.id == id);
}
```

```dart
// packages/task_domain/lib/src/entities/job_enums.dart

/// How quickly the customer needs the job done.
enum Urgency { flexible, soon, urgent, emergency }

/// The kind of property the job is at (collected in the creation flow, slice 2).
enum PropertyType { apartment, villa, office, other }

/// Who made a given price proposal inside an [Offer] thread.
enum ProposalAuthor { customer, technician }

/// Lifecycle of a single technician's negotiation thread for a job.
enum OfferStatus { pending, countered, accepted, declined, withdrawn }
```

Add to `packages/task_domain/lib/task_domain.dart` after the existing `export 'src/entities/enums.dart';` line:

```dart
export 'src/entities/job_category.dart';
export 'src/entities/job_enums.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/task_domain && dart test test/job_category_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/task_domain/lib/src/entities/job_category.dart packages/task_domain/lib/src/entities/job_enums.dart packages/task_domain/lib/task_domain.dart packages/task_domain/test/job_category_test.dart
git commit -m "feat(domain): add JobCategory taxonomy and marketplace enums"
```

---

### Task 2: Offer + JobRequest entities (task_domain)

**Files:**
- Create: `packages/task_domain/lib/src/entities/offer.dart`
- Create: `packages/task_domain/lib/src/entities/job_request.dart`
- Modify: `packages/task_domain/lib/task_domain.dart` (add exports)
- Test: `packages/task_domain/test/offer_test.dart`, `packages/task_domain/test/job_request_test.dart`

**Interfaces:**
- Consumes: `JobCategory`, `Urgency`, `PropertyType`, `ProposalAuthor`, `OfferStatus` (Task 1); existing `JobStatus` from `enums.dart`.
- Produces:
  - `PriceProposal({required int amount, required ProposalAuthor by, required DateTime at})`.
  - `Offer({required String id, required String technicianId, required String technicianName, required double rating, required int jobsDone, required String etaLabel, required List<PriceProposal> proposals, required OfferStatus status})` with `int get currentPrice`, and `Offer copyWith({List<PriceProposal>? proposals, OfferStatus? status})`.
  - `JobRequest({required String id, required JobCategory category, required String title, required String description, required int fixedPrice, String currency = 'EGP', required Urgency urgency, required PropertyType propertyType, String? floor, bool? parking, List<String> photos = const [], required String locationLabel, String notes = '', required JobStatus status, List<Offer> offers = const [], required DateTime createdAt})` with `Offer? get acceptedOffer`, `int get settledPrice`, and `JobRequest copyWith({...})`.

- [ ] **Step 1: Write the failing tests**

```dart
// packages/task_domain/test/offer_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

Offer _offer(List<int> amounts, {OfferStatus status = OfferStatus.pending}) =>
    Offer(
      id: 'o1',
      technicianId: 't1',
      technicianName: 'Khaled',
      rating: 4.9,
      jobsDone: 1284,
      etaLabel: '40 min',
      status: status,
      proposals: <PriceProposal>[
        for (final int a in amounts)
          PriceProposal(amount: a, by: ProposalAuthor.technician, at: DateTime(2026)),
      ],
    );

void main() {
  test('currentPrice reflects the last proposal in the thread', () {
    expect(_offer(<int>[550, 480, 500]).currentPrice, 500);
  });

  test('copyWith appends a proposal and flips status', () {
    final Offer base = _offer(<int>[550]);
    final Offer countered = base.copyWith(
      proposals: <PriceProposal>[
        ...base.proposals,
        PriceProposal(amount: 480, by: ProposalAuthor.customer, at: DateTime(2026)),
      ],
      status: OfferStatus.countered,
    );
    expect(countered.currentPrice, 480);
    expect(countered.status, OfferStatus.countered);
    expect(base.currentPrice, 550); // original unchanged
  });
}
```

```dart
// packages/task_domain/test/job_request_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

JobRequest _job({List<Offer> offers = const <Offer>[]}) => JobRequest(
      id: 'j1',
      category: JobCategory.electrical,
      title: 'Flickering living-room lights',
      description: 'Lights flicker when the AC turns on.',
      fixedPrice: 400,
      urgency: Urgency.soon,
      propertyType: PropertyType.apartment,
      locationLabel: 'Maadi, Cairo',
      status: JobStatus.biddingActive,
      offers: offers,
      createdAt: DateTime(2026),
    );

void main() {
  test('settledPrice falls back to fixedPrice with no accepted offer', () {
    expect(_job().settledPrice, 400);
  });

  test('settledPrice uses the accepted offer current price', () {
    final Offer accepted = Offer(
      id: 'o1', technicianId: 't1', technicianName: 'K', rating: 4.9,
      jobsDone: 10, etaLabel: '40 min', status: OfferStatus.accepted,
      proposals: <PriceProposal>[
        PriceProposal(amount: 550, by: ProposalAuthor.technician, at: DateTime(2026)),
      ],
    );
    final JobRequest job = _job(offers: <Offer>[accepted]);
    expect(job.acceptedOffer, accepted);
    expect(job.settledPrice, 550);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/task_domain && dart test test/offer_test.dart test/job_request_test.dart`
Expected: FAIL — `Offer` / `JobRequest` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// packages/task_domain/lib/src/entities/offer.dart
import 'package:meta/meta.dart';

import 'job_enums.dart';

/// A single price point in a negotiation thread.
@immutable
class PriceProposal {
  const PriceProposal({required this.amount, required this.by, required this.at});

  final int amount; // EGP
  final ProposalAuthor by;
  final DateTime at;
}

/// One technician's negotiation thread for a job — the full price trail plus
/// the current status. There is exactly one [Offer] per interested technician.
@immutable
class Offer {
  const Offer({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.rating,
    required this.jobsDone,
    required this.etaLabel,
    required this.proposals,
    required this.status,
  });

  final String id;
  final String technicianId;
  final String technicianName;
  final double rating;
  final int jobsDone;
  final String etaLabel;
  final List<PriceProposal> proposals;
  final OfferStatus status;

  /// The latest proposed amount in the thread (EGP). Never empty by construction.
  int get currentPrice => proposals.last.amount;

  Offer copyWith({List<PriceProposal>? proposals, OfferStatus? status}) => Offer(
        id: id,
        technicianId: technicianId,
        technicianName: technicianName,
        rating: rating,
        jobsDone: jobsDone,
        etaLabel: etaLabel,
        proposals: proposals ?? this.proposals,
        status: status ?? this.status,
      );
}
```

```dart
// packages/task_domain/lib/src/entities/job_request.dart
import 'package:meta/meta.dart';

import 'enums.dart';
import 'job_category.dart';
import 'job_enums.dart';
import 'offer.dart';

/// A fixed-price job posted by a customer. The customer names one [fixedPrice];
/// technicians negotiate via [offers]. No hourly pricing exists in this model.
@immutable
class JobRequest {
  const JobRequest({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.fixedPrice,
    this.currency = 'EGP',
    required this.urgency,
    required this.propertyType,
    this.floor,
    this.parking,
    this.photos = const <String>[],
    required this.locationLabel,
    this.notes = '',
    required this.status,
    this.offers = const <Offer>[],
    required this.createdAt,
  });

  final String id;
  final JobCategory category;
  final String title;
  final String description;
  final int fixedPrice; // EGP — the customer's single offered amount
  final String currency;
  final Urgency urgency;
  final PropertyType propertyType;
  final String? floor;
  final bool? parking;
  final List<String> photos;
  final String locationLabel;
  final String notes;
  final JobStatus status;
  final List<Offer> offers;
  final DateTime createdAt;

  Offer? get acceptedOffer {
    for (final Offer o in offers) {
      if (o.status == OfferStatus.accepted) return o;
    }
    return null;
  }

  /// The agreed price if an offer was accepted, else the customer's fixed offer.
  int get settledPrice => acceptedOffer?.currentPrice ?? fixedPrice;

  JobRequest copyWith({
    JobStatus? status,
    List<Offer>? offers,
    int? fixedPrice,
  }) =>
      JobRequest(
        id: id,
        category: category,
        title: title,
        description: description,
        fixedPrice: fixedPrice ?? this.fixedPrice,
        currency: currency,
        urgency: urgency,
        propertyType: propertyType,
        floor: floor,
        parking: parking,
        photos: photos,
        locationLabel: locationLabel,
        notes: notes,
        status: status ?? this.status,
        offers: offers ?? this.offers,
        createdAt: createdAt,
      );
}
```

Add to `packages/task_domain/lib/task_domain.dart`:

```dart
export 'src/entities/offer.dart';
export 'src/entities/job_request.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/task_domain && dart test`
Expected: PASS (all domain tests).

- [ ] **Step 5: Commit**

```bash
git add packages/task_domain/lib/src/entities/offer.dart packages/task_domain/lib/src/entities/job_request.dart packages/task_domain/lib/task_domain.dart packages/task_domain/test/offer_test.dart packages/task_domain/test/job_request_test.dart
git commit -m "feat(domain): add fixed-price JobRequest and Offer entities"
```

---

### Task 3: JobRequestDraft + JobMarketplaceRepository interface (task_domain)

**Files:**
- Create: `packages/task_domain/lib/src/entities/job_request_draft.dart`
- Create: `packages/task_domain/lib/src/repositories/job_marketplace_repository.dart`
- Modify: `packages/task_domain/lib/task_domain.dart` (add exports)
- Test: `packages/task_domain/test/job_request_draft_test.dart`

**Interfaces:**
- Consumes: `JobCategory`, `Urgency`, `PropertyType` (Task 1); `JobRequest`, `Offer` (Task 2).
- Produces:
  - `JobRequestDraft({JobCategory? category, String title = '', String description = '', int fixedPrice = 0, Urgency urgency = Urgency.soon, PropertyType propertyType = PropertyType.apartment, String? floor, bool? parking, List<String> photos = const [], String locationLabel = '', String notes = ''})` with `bool get isValid` (category != null && title non-empty && fixedPrice > 0) and `JobRequestDraft copyWith({...})` covering every field plus `bool clearCategory`.
  - `abstract interface class JobMarketplaceRepository` with `Stream<List<JobRequest>> watchMyJobs()`, `Future<JobRequest> publish(JobRequestDraft draft)`, `Future<void> acceptOffer(String jobId, String offerId)`, `Future<void> counterOffer(String jobId, String offerId, int amount)`, `Future<void> cancelJob(String jobId)`.

- [ ] **Step 1: Write the failing test**

```dart
// packages/task_domain/test/job_request_draft_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

void main() {
  test('isValid requires a category, a title and a positive price', () {
    const JobRequestDraft empty = JobRequestDraft();
    expect(empty.isValid, isFalse);

    final JobRequestDraft full = const JobRequestDraft().copyWith(
      category: JobCategory.plumbing,
      title: 'Leaking sink',
      fixedPrice: 300,
    );
    expect(full.isValid, isTrue);
  });

  test('copyWith can clear the category', () {
    final JobRequestDraft d =
        const JobRequestDraft().copyWith(category: JobCategory.ac);
    expect(d.copyWith(clearCategory: true).category, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/task_domain && dart test test/job_request_draft_test.dart`
Expected: FAIL — `JobRequestDraft` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// packages/task_domain/lib/src/entities/job_request_draft.dart
import 'package:meta/meta.dart';

import 'job_category.dart';
import 'job_enums.dart';

/// The in-progress fixed-price job the customer assembles before publishing.
@immutable
class JobRequestDraft {
  const JobRequestDraft({
    this.category,
    this.title = '',
    this.description = '',
    this.fixedPrice = 0,
    this.urgency = Urgency.soon,
    this.propertyType = PropertyType.apartment,
    this.floor,
    this.parking,
    this.photos = const <String>[],
    this.locationLabel = '',
    this.notes = '',
  });

  final JobCategory? category;
  final String title;
  final String description;
  final int fixedPrice;
  final Urgency urgency;
  final PropertyType propertyType;
  final String? floor;
  final bool? parking;
  final List<String> photos;
  final String locationLabel;
  final String notes;

  bool get isValid =>
      category != null && title.trim().isNotEmpty && fixedPrice > 0;

  JobRequestDraft copyWith({
    JobCategory? category,
    bool clearCategory = false,
    String? title,
    String? description,
    int? fixedPrice,
    Urgency? urgency,
    PropertyType? propertyType,
    String? floor,
    bool? parking,
    List<String>? photos,
    String? locationLabel,
    String? notes,
  }) =>
      JobRequestDraft(
        category: clearCategory ? null : (category ?? this.category),
        title: title ?? this.title,
        description: description ?? this.description,
        fixedPrice: fixedPrice ?? this.fixedPrice,
        urgency: urgency ?? this.urgency,
        propertyType: propertyType ?? this.propertyType,
        floor: floor ?? this.floor,
        parking: parking ?? this.parking,
        photos: photos ?? this.photos,
        locationLabel: locationLabel ?? this.locationLabel,
        notes: notes ?? this.notes,
      );
}
```

```dart
// packages/task_domain/lib/src/repositories/job_marketplace_repository.dart
import '../entities/job_request.dart';
import '../entities/job_request_draft.dart';

/// The seam between the marketplace UI and its data source. The prototype binds
/// an in-memory mock; slice 4 swaps in a Firestore-backed implementation.
abstract interface class JobMarketplaceRepository {
  /// The customer's own posted jobs, newest first, re-emitting on every change.
  Stream<List<JobRequest>> watchMyJobs();

  /// Publishes a draft as a live [JobRequest] and returns the stored job.
  Future<JobRequest> publish(JobRequestDraft draft);

  /// Customer accepts a technician's current offer.
  Future<void> acceptOffer(String jobId, String offerId);

  /// Customer counters a technician's offer with [amount] EGP.
  Future<void> counterOffer(String jobId, String offerId, int amount);

  /// Customer cancels a posted job.
  Future<void> cancelJob(String jobId);
}
```

Add to `packages/task_domain/lib/task_domain.dart`:

```dart
export 'src/entities/job_request_draft.dart';
export 'src/repositories/job_marketplace_repository.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/task_domain && dart test`
Expected: PASS (all domain tests).

- [ ] **Step 5: Commit**

```bash
git add packages/task_domain/lib/src/entities/job_request_draft.dart packages/task_domain/lib/src/repositories/job_marketplace_repository.dart packages/task_domain/lib/task_domain.dart packages/task_domain/test/job_request_draft_test.dart
git commit -m "feat(domain): add JobRequestDraft and JobMarketplaceRepository interface"
```

---

### Task 4: Category visuals in task_design (icon + tint map)

**Files:**
- Create: `packages/task_design/lib/src/theme/category_visuals.dart`
- Modify: `packages/task_design/lib/task_design.dart` (add export)
- Test: `packages/task_design/test/category_visuals_test.dart`

**Interfaces:**
- Consumes: `JobCategory` (Task 1).
- Produces: `IconData categoryIcon(JobCategory)` and `Color categoryTint(JobCategory)` — total over all 8 categories.

Confirm `task_design/pubspec.yaml` declares `task_domain:` and a `flutter_test` dev dependency. If `task_domain:` is missing under `dependencies:`, add it (workspace ref, no version). If there is no `test/` dir, create it.

- [ ] **Step 1: Write the failing test**

```dart
// packages/task_design/test/category_visuals_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  test('every category has an icon and a tint', () {
    for (final JobCategory c in JobCategory.values) {
      expect(categoryIcon(c), isA<IconData>());
      expect(categoryTint(c), isA<Color>());
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/task_design && flutter test test/category_visuals_test.dart`
Expected: FAIL — `categoryIcon` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// packages/task_design/lib/src/theme/category_visuals.dart
import 'package:flutter/material.dart';
import 'package:task_domain/task_domain.dart';

/// Material icon for a job category. UI-only — the pure-Dart domain never holds
/// `IconData`, so this mapping is the single source of category iconography.
IconData categoryIcon(JobCategory category) => switch (category) {
      JobCategory.plumbing => Icons.plumbing_rounded,
      JobCategory.electrical => Icons.bolt_rounded,
      JobCategory.ac => Icons.ac_unit_rounded,
      JobCategory.cleaning => Icons.cleaning_services_rounded,
      JobCategory.carpentry => Icons.handyman_rounded,
      JobCategory.painting => Icons.format_paint_rounded,
      JobCategory.satelliteInstallation => Icons.satellite_alt_rounded,
      JobCategory.smartHome => Icons.home_max_rounded,
    };

/// Accent tint used for a category tile glow.
Color categoryTint(JobCategory category) => switch (category) {
      JobCategory.plumbing => const Color(0xFF38BDF8),
      JobCategory.electrical => const Color(0xFFFBBF24),
      JobCategory.ac => const Color(0xFF22D3EE),
      JobCategory.cleaning => const Color(0xFF34D399),
      JobCategory.carpentry => const Color(0xFFF472B6),
      JobCategory.painting => const Color(0xFFA78BFA),
      JobCategory.satelliteInstallation => const Color(0xFF818CF8),
      JobCategory.smartHome => const Color(0xFF2DD4BF),
    };
```

Add to `packages/task_design/lib/task_design.dart`:

```dart
export 'src/theme/category_visuals.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/task_design && flutter test test/category_visuals_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/task_design/lib/src/theme/category_visuals.dart packages/task_design/lib/task_design.dart packages/task_design/test/category_visuals_test.dart packages/task_design/pubspec.yaml
git commit -m "feat(design): add category icon and tint mapping"
```

---

### Task 5: Mock marketplace repository + providers (customer app)

**Files:**
- Create: `apps/customer/lib/features/marketplace/mock_job_marketplace_repository.dart`
- Create: `apps/customer/lib/features/marketplace/marketplace_providers.dart`
- Test: `apps/customer/test/mock_job_marketplace_repository_test.dart`

**Interfaces:**
- Consumes: `JobMarketplaceRepository`, `JobRequest`, `JobRequestDraft`, `Offer`, `PriceProposal`, `JobCategory`, `JobStatus`, `OfferStatus`, `ProposalAuthor`, `Urgency`, `PropertyType` (Tasks 1-3).
- Produces:
  - `class MockJobMarketplaceRepository implements JobMarketplaceRepository` seeded with 3 demo jobs (one with a live offer thread) using realistic Egyptian names + EGP prices. Seed the offer thread that today lives in `kBids` (Khaled 165, Sayed 140, Mostafa 190) onto the first job.
  - `final jobMarketplaceRepositoryProvider = Provider<JobMarketplaceRepository>((ref) => MockJobMarketplaceRepository());`
  - `final myJobsProvider = StreamProvider<List<JobRequest>>((ref) => ref.watch(jobMarketplaceRepositoryProvider).watchMyJobs());`
  - `final jobDraftProvider = NotifierProvider<JobDraftController, JobRequestDraft>(JobDraftController.new);` with methods `startCategory(JobCategory)`, `setTitle(String)`, `setDescription(String)`, `setPrice(int)`, `reset()`.

- [ ] **Step 1: Write the failing test**

```dart
// apps/customer/test/mock_job_marketplace_repository_test.dart
import 'package:customer/features/marketplace/mock_job_marketplace_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  test('publish adds a job to watchMyJobs newest-first', () async {
    final MockJobMarketplaceRepository repo = MockJobMarketplaceRepository();
    final int before = (await repo.watchMyJobs().first).length;

    final JobRequest job = await repo.publish(const JobRequestDraft().copyWith(
      category: JobCategory.electrical,
      title: 'Flickering lights',
      fixedPrice: 400,
    ));

    final List<JobRequest> jobs = await repo.watchMyJobs().first;
    expect(jobs.length, before + 1);
    expect(jobs.first.id, job.id);
    expect(jobs.first.fixedPrice, 400);
  });

  test('acceptOffer marks the offer accepted and fixes settledPrice', () async {
    final MockJobMarketplaceRepository repo = MockJobMarketplaceRepository();
    final JobRequest seeded =
        (await repo.watchMyJobs().first).firstWhere((j) => j.offers.isNotEmpty);
    final Offer target = seeded.offers.first;

    await repo.acceptOffer(seeded.id, target.id);

    final JobRequest updated =
        (await repo.watchMyJobs().first).firstWhere((j) => j.id == seeded.id);
    expect(updated.acceptedOffer?.id, target.id);
    expect(updated.settledPrice, target.currentPrice);
  });

  test('counterOffer appends a customer proposal and sets countered', () async {
    final MockJobMarketplaceRepository repo = MockJobMarketplaceRepository();
    final JobRequest seeded =
        (await repo.watchMyJobs().first).firstWhere((j) => j.offers.isNotEmpty);
    final Offer target = seeded.offers.first;

    await repo.counterOffer(seeded.id, target.id, 480);

    final Offer updated = (await repo.watchMyJobs().first)
        .firstWhere((j) => j.id == seeded.id)
        .offers
        .firstWhere((o) => o.id == target.id);
    expect(updated.currentPrice, 480);
    expect(updated.proposals.last.by, ProposalAuthor.customer);
    expect(updated.status, OfferStatus.countered);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/customer && flutter test test/mock_job_marketplace_repository_test.dart`
Expected: FAIL — `MockJobMarketplaceRepository` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// apps/customer/lib/features/marketplace/mock_job_marketplace_repository.dart
import 'dart:async';

import 'package:task_domain/task_domain.dart';

/// In-memory [JobMarketplaceRepository] for the prototype. Holds jobs in a list
/// and re-emits the whole list through a broadcast stream on every mutation.
class MockJobMarketplaceRepository implements JobMarketplaceRepository {
  MockJobMarketplaceRepository() {
    _jobs = _seed();
    _emit();
  }

  late List<JobRequest> _jobs;
  final StreamController<List<JobRequest>> _controller =
      StreamController<List<JobRequest>>.broadcast();
  int _counter = 0;

  void _emit() => _controller.add(List<JobRequest>.unmodifiable(_jobs));

  @override
  Stream<List<JobRequest>> watchMyJobs() async* {
    yield List<JobRequest>.unmodifiable(_jobs);
    yield* _controller.stream;
  }

  @override
  Future<JobRequest> publish(JobRequestDraft draft) async {
    final JobRequest job = JobRequest(
      id: 'JOB-${(_counter++).toString().padLeft(4, '0')}',
      category: draft.category ?? JobCategory.plumbing,
      title: draft.title,
      description: draft.description,
      fixedPrice: draft.fixedPrice,
      urgency: draft.urgency,
      propertyType: draft.propertyType,
      floor: draft.floor,
      parking: draft.parking,
      photos: draft.photos,
      locationLabel:
          draft.locationLabel.isEmpty ? 'Maadi, Cairo' : draft.locationLabel,
      notes: draft.notes,
      status: JobStatus.biddingActive,
      offers: const <Offer>[],
      createdAt: DateTime.now(),
    );
    _jobs = <JobRequest>[job, ..._jobs];
    _emit();
    return job;
  }

  @override
  Future<void> acceptOffer(String jobId, String offerId) async {
    _mutateJob(jobId, (JobRequest job) {
      final List<Offer> offers = job.offers
          .map((Offer o) => o.copyWith(
                status: o.id == offerId
                    ? OfferStatus.accepted
                    : OfferStatus.declined,
              ))
          .toList();
      return job.copyWith(status: JobStatus.accepted, offers: offers);
    });
  }

  @override
  Future<void> counterOffer(String jobId, String offerId, int amount) async {
    _mutateJob(jobId, (JobRequest job) {
      final List<Offer> offers = job.offers.map((Offer o) {
        if (o.id != offerId) return o;
        return o.copyWith(
          proposals: <PriceProposal>[
            ...o.proposals,
            PriceProposal(
                amount: amount,
                by: ProposalAuthor.customer,
                at: DateTime.now()),
          ],
          status: OfferStatus.countered,
        );
      }).toList();
      return job.copyWith(offers: offers);
    });
  }

  @override
  Future<void> cancelJob(String jobId) async {
    _mutateJob(jobId, (JobRequest job) => job.copyWith(status: JobStatus.cancelled));
  }

  void _mutateJob(String jobId, JobRequest Function(JobRequest) update) {
    _jobs = _jobs
        .map((JobRequest j) => j.id == jobId ? update(j) : j)
        .toList();
    _emit();
  }

  List<JobRequest> _seed() {
    final DateTime now = DateTime.now();
    PriceProposal tech(int amount) =>
        PriceProposal(amount: amount, by: ProposalAuthor.technician, at: now);
    return <JobRequest>[
      JobRequest(
        id: 'JOB-SEED1',
        category: JobCategory.plumbing,
        title: 'Leaking kitchen sink',
        description: 'Steady drip under the sink, water pooling in the cabinet.',
        fixedPrice: 180,
        urgency: Urgency.soon,
        propertyType: PropertyType.apartment,
        locationLabel: 'Maadi, Cairo',
        status: JobStatus.biddingActive,
        createdAt: now,
        offers: <Offer>[
          Offer(
            id: 'OF-1', technicianId: 'T-1', technicianName: 'Khaled Mansour',
            rating: 4.9, jobsDone: 1284, etaLabel: 'Can start in 40 min',
            status: OfferStatus.pending, proposals: <PriceProposal>[tech(165)],
          ),
          Offer(
            id: 'OF-2', technicianId: 'T-2', technicianName: 'Sayed Abdel-Rahman',
            rating: 4.7, jobsDone: 612, etaLabel: 'Available this evening',
            status: OfferStatus.pending, proposals: <PriceProposal>[tech(140)],
          ),
          Offer(
            id: 'OF-3', technicianId: 'T-3', technicianName: 'Mostafa Eid',
            rating: 4.8, jobsDone: 903, etaLabel: 'Can start in 25 min',
            status: OfferStatus.pending, proposals: <PriceProposal>[tech(190)],
          ),
        ],
      ),
      JobRequest(
        id: 'JOB-SEED2',
        category: JobCategory.ac,
        title: 'AC not cooling',
        description: 'Split unit runs but blows warm air.',
        fixedPrice: 240,
        urgency: Urgency.urgent,
        propertyType: PropertyType.apartment,
        locationLabel: 'Nasr City, Cairo',
        status: JobStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      JobRequest(
        id: 'JOB-SEED3',
        category: JobCategory.electrical,
        title: 'Replace tripping breaker',
        description: 'Main breaker trips when the heater runs.',
        fixedPrice: 150,
        urgency: Urgency.flexible,
        propertyType: PropertyType.villa,
        locationLabel: 'Sheikh Zayed, Giza',
        status: JobStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
```

```dart
// apps/customer/lib/features/marketplace/marketplace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_domain/task_domain.dart';

import 'mock_job_marketplace_repository.dart';

final jobMarketplaceRepositoryProvider = Provider<JobMarketplaceRepository>(
  (ref) => MockJobMarketplaceRepository(),
);

final myJobsProvider = StreamProvider<List<JobRequest>>(
  (ref) => ref.watch(jobMarketplaceRepositoryProvider).watchMyJobs(),
);

/// The in-progress draft the customer assembles before publishing.
class JobDraftController extends Notifier<JobRequestDraft> {
  @override
  JobRequestDraft build() => const JobRequestDraft();

  void startCategory(JobCategory category) =>
      state = JobRequestDraft(category: category);
  void setTitle(String title) => state = state.copyWith(title: title);
  void setDescription(String d) => state = state.copyWith(description: d);
  void setPrice(int price) => state = state.copyWith(fixedPrice: price);
  void reset() => state = const JobRequestDraft();
}

final jobDraftProvider =
    NotifierProvider<JobDraftController, JobRequestDraft>(JobDraftController.new);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/customer && flutter test test/mock_job_marketplace_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add apps/customer/lib/features/marketplace/ apps/customer/test/mock_job_marketplace_repository_test.dart
git commit -m "feat(customer): mock job marketplace repository and providers"
```

---

### Task 6: Rewrite booking_state.dart — drop Service/Bid/BookingMode

**Files:**
- Modify (rewrite): `apps/customer/lib/features/booking/booking_state.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: keeps `PaymentMethod` (+ `PaymentMethodX`), `SavedAddress` + `kSavedAddresses`, `JobStage` (+ `JobStageX`). **Removes** `Service`/`Bid`/`kBids`/`BookingMode`/`BookingModeX`/`BookingDraft`/`BookingController`/`bookingProvider`/`BookingRecord`/`BookingsController`/`bookingsProvider`. No `service_catalog.dart` import remains.

This task intentionally leaves the app **not compiling** until Task 10 finishes migrating consumers; run the build at the end of Task 10, not here. Commit anyway so the diff is reviewable per-file (the executing skill tolerates a red intermediate commit *within* a contiguous task group — but if your workflow forbids red commits, fold Tasks 6-10 into one commit at the end of Task 10).

- [ ] **Step 1: Rewrite the file**

Replace the entire contents of `apps/customer/lib/features/booking/booking_state.dart` with:

```dart
import 'package:flutter/material.dart';

/// How the customer pays (design spec §2 payments).
enum PaymentMethod { cash, card, wallet, instapay }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash on delivery',
        PaymentMethod.card => 'Card',
        PaymentMethod.wallet => 'Vodafone Cash',
        PaymentMethod.instapay => 'InstaPay',
      };

  String get sub => switch (this) {
        PaymentMethod.cash => 'Pay the pro directly when the job is done',
        PaymentMethod.card => 'Visa, Mastercard, Meeza · via Paymob',
        PaymentMethod.wallet => 'Pay from your mobile wallet',
        PaymentMethod.instapay => 'Bank transfer, confirmed by our team',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.wallet => Icons.account_balance_wallet_rounded,
        PaymentMethod.instapay => Icons.account_balance_rounded,
      };
}

@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line,
    required this.icon,
  });

  final String id;
  final String label;
  final String line;
  final IconData icon;
}

const List<SavedAddress> kSavedAddresses = <SavedAddress>[
  SavedAddress(
    id: 'home',
    label: 'Home',
    line: '14 Road 9, Maadi · Floor 3, Apt 6',
    icon: Icons.home_rounded,
  ),
  SavedAddress(
    id: 'work',
    label: 'Work',
    line: 'Smart Village, Building B12 · Reception',
    icon: Icons.work_rounded,
  ),
];

/// Live stages used by the tracking screen (subset of the job state machine).
enum JobStage { searching, accepted, enRoute, inProgress, completed }

extension JobStageX on JobStage {
  String get title => switch (this) {
        JobStage.searching => 'Finding your pro',
        JobStage.accepted => 'Pro assigned',
        JobStage.enRoute => 'On the way',
        JobStage.inProgress => 'Work in progress',
        JobStage.completed => 'Job complete',
      };
}
```

- [ ] **Step 2: Continue to Task 7** (no isolated test/build here — verified at end of Task 10)

---

### Task 7: Delete the legacy service catalog

**Files:**
- Delete: `apps/customer/lib/features/services/service_catalog.dart`
- Delete: `apps/customer/lib/features/services/service_detail_screen.dart`
- Delete: `apps/customer/lib/features/booking/booking_configure_screen.dart`

- [ ] **Step 1: Remove the files**

```bash
git rm apps/customer/lib/features/services/service_catalog.dart \
       apps/customer/lib/features/services/service_detail_screen.dart \
       apps/customer/lib/features/booking/booking_configure_screen.dart
```

- [ ] **Step 2: Continue to Task 8** (build verified at end of Task 10)

---

### Task 8: Job-create stub screen + router rewire

**Files:**
- Create: `apps/customer/lib/features/marketplace/job_create_stub_screen.dart`
- Modify: `apps/customer/lib/app/router.dart`

**Interfaces:**
- Consumes: `jobDraftProvider`, `jobMarketplaceRepositoryProvider` (Task 5); `JobCategory` + `categoryIcon`/`categoryTint`.
- Produces: `class JobCreateStubScreen` with `static const String routePath = '/job/create';` and `static const String routeName = 'job-create';`. Reads the seeded `jobDraftProvider.category`, lets the user type a title + price, calls `repository.publish`, and pushes the tracking route.

- [ ] **Step 1: Create the stub screen**

```dart
// apps/customer/lib/features/marketplace/job_create_stub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../job/job_tracking_screen.dart';
import 'marketplace_providers.dart';

/// Placeholder for the full "describe → details → name your price → publish"
/// flow (built out in slice 2). Collects the minimum — title + fixed price —
/// for the seeded category, publishes, and enters tracking.
class JobCreateStubScreen extends ConsumerStatefulWidget {
  const JobCreateStubScreen({super.key});

  static const String routePath = '/job/create';
  static const String routeName = 'job-create';

  @override
  ConsumerState<JobCreateStubScreen> createState() => _JobCreateStubScreenState();
}

class _JobCreateStubScreenState extends ConsumerState<JobCreateStubScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _price = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _publish(JobCategory category) async {
    final int price = int.tryParse(_price.text.trim()) ?? 0;
    ref.read(jobDraftProvider.notifier).setTitle(_title.text.trim());
    ref.read(jobDraftProvider.notifier).setPrice(price);
    final JobRequestDraft draft = ref.read(jobDraftProvider);
    if (!draft.isValid) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text('Add a short title and a price above 0.')));
      return;
    }
    await ref.read(jobMarketplaceRepositoryProvider).publish(draft);
    if (!mounted) return;
    ref.read(jobDraftProvider.notifier).reset();
    context.go(JobTrackingScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final JobCategory category =
        ref.watch(jobDraftProvider).category ?? JobCategory.plumbing;
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Post a job')),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.12),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(children: <Widget>[
                    Icon(categoryIcon(category), color: categoryTint(category)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(category.displayLabel,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  Text('What problem are you having?', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                        hintText: 'e.g. Living-room lights keep flickering'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('What will you pay for this job? (EGP)',
                      style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 400'),
                  ),
                  const Spacer(),
                  GlowButton(
                    label: 'Publish job',
                    onPressed: () => _publish(category),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

> If `GlowButton`'s constructor differs (check `packages/task_design/lib/src/widgets/glow_button.dart`), match its actual `label`/`onPressed` parameter names.

- [ ] **Step 2: Rewire the router**

In `apps/customer/lib/app/router.dart`:
1. Remove the imports for `service_detail_screen.dart` and `booking_configure_screen.dart`.
2. Add `import 'package:customer/features/marketplace/job_create_stub_screen.dart';`.
3. Delete the `GoRoute(path: '/service/:id', ...)` block and the `BookingConfigureScreen` route block.
4. Add this route in their place (under the root navigator, alongside the other full-screen journey routes):

```dart
GoRoute(
  path: JobCreateStubScreen.routePath,
  name: JobCreateStubScreen.routeName,
  parentNavigatorKey: _rootKey,
  builder: (context, state) => const JobCreateStubScreen(),
),
```

- [ ] **Step 3: Continue to Task 9** (build verified at end of Task 10)

---

### Task 9: Migrate home_screen to the JobCategory grid

**Files:**
- Modify: `apps/customer/lib/features/home/home_screen.dart`

- [ ] **Step 1: Replace catalog usage with categories**

1. Replace the import `import '../services/service_catalog.dart';` with:
   ```dart
   import 'package:task_domain/task_domain.dart';
   import '../marketplace/marketplace_providers.dart';
   import '../marketplace/job_create_stub_screen.dart';
   ```
   (Keep the `technician_catalog.dart` import.)
2. Change `_gridOrder` to a list of `JobCategory` (all 8, new ones last):
   ```dart
   static const List<JobCategory> _gridOrder = <JobCategory>[
     JobCategory.plumbing, JobCategory.electrical, JobCategory.ac,
     JobCategory.carpentry, JobCategory.painting, JobCategory.cleaning,
     JobCategory.satelliteInstallation, JobCategory.smartHome,
   ];
   ```
3. Rewrite `_categoryGrid` to render `JobCategory` tiles; tapping seeds the draft and opens the stub:
   ```dart
   Widget _categoryGrid(BuildContext context, WidgetRef ref) {
     return GridView.count(
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       crossAxisCount: 3,
       mainAxisSpacing: AppSpacing.md,
       crossAxisSpacing: AppSpacing.md,
       childAspectRatio: 0.92,
       children: _gridOrder.map((JobCategory c) {
         return _CategoryTile(
           label: c.displayLabel,
           icon: categoryIcon(c),
           tint: categoryTint(c),
           onTap: () {
             ref.read(jobDraftProvider.notifier).startCategory(c);
             context.push(JobCreateStubScreen.routePath);
           },
         );
       }).toList(),
     );
   }
   ```
4. Update the `_categoryGrid(context)` call site to `_categoryGrid(context, ref)`.
5. Update the `_CategoryTile` widget to accept `label` / `icon` / `tint` / `onTap` (replacing its `ServiceCategory category` field). Find its definition lower in the file and adjust its fields and `build` accordingly.
6. For the top-rated technician cards, replace `onTap: () => context.push('/service/${t.serviceId}')` with seeding a category from the technician's category and opening the stub. Map the technician to a `JobCategory` (e.g. add a `JobCategory category` getter in `technician_catalog.dart` derived from its existing `serviceId`, or default to `JobCategory.plumbing` if not present):
   ```dart
   onTap: () {
     ref.read(jobDraftProvider.notifier).startCategory(t.category);
     context.push(JobCreateStubScreen.routePath);
   },
   ```
   In `technician_catalog.dart`, add a `JobCategory get category` mapping from the existing `serviceId` strings (`plumb_leak → plumbing`, `elec_fault → electrical`, `ac_service → ac`). Keep the `serviceId` field or rename to `categoryId`; mapping is sufficient for this slice.

- [ ] **Step 2: Continue to Task 10** (build verified next)

---

### Task 10: Migrate remaining consumer screens + verify green

**Files:**
- Modify: `apps/customer/lib/features/payment/payment_screen.dart`
- Modify: `apps/customer/lib/features/bookings/bookings_screen.dart`
- Modify: `apps/customer/lib/features/booking/quote_bids_screen.dart`
- Modify: `apps/customer/lib/features/review/rating_screen.dart`
- Modify: `apps/customer/lib/features/job/job_tracking_screen.dart`
- Modify: `apps/customer/lib/features/booking/asap_dispatch_screen.dart`
- Modify: `apps/customer/lib/features/address/address_screen.dart`
- Modify: `apps/customer/lib/features/services/technician_catalog.dart` (if not already done in Task 9)

**Interfaces:**
- Consumes: `myJobsProvider`, `jobDraftProvider` (Task 5); `JobRequest`, `JobCategory`, `Offer` (Tasks 1-3).

Apply these concrete substitutions. After each file, the symbol `Service`, `BookingDraft`, `bookingProvider`, `BookingRecord`, `kBids`, `Bid`, `serviceById`, `basePrice`, `durationLabel` must no longer appear.

- [ ] **Step 1: payment_screen.dart**

- Replace `import '../booking/booking_state.dart';` usages of `bookingProvider`/`BookingDraft`/`Service` with the draft + repo. Replace `final BookingDraft draft = ref.read(bookingProvider);` → `final JobRequestDraft draft = ref.read(jobDraftProvider);` (add `import '../marketplace/marketplace_providers.dart';` and `import 'package:task_domain/task_domain.dart';`).
- Drop the `Service? service = draft.service;` lines. The summary now reads `draft.title`, `draft.category?.displayLabel ?? ''`, and the price `draft.fixedPrice`.
- Remove the `BookingRecord(...)` construction + `bookingsProvider` writes entirely (publishing already happened in the stub screen). On success just call `ref.read(jobDraftProvider.notifier).reset();`.
- `_summary(BookingDraft, Service, TextTheme)` → `_summary(JobRequestDraft draft, TextTheme text)`; render `draft.title` and `'${draft.fixedPrice} EGP'`. `_payBar(BookingDraft, TextTheme)` → `_payBar(JobRequestDraft draft, TextTheme text)`; total = `draft.fixedPrice`. Keep `setPayment` only if you reintroduce a payment field on the draft; for this slice replace the payment selector's `ref.read(bookingProvider.notifier).setPayment(m)` with local `setState` selection (the screen already manages a selected `PaymentMethod` for display).

> Keep `PaymentMethod`/`PaymentMethodX` import from `booking_state.dart` — they still exist there.

- [ ] **Step 2: bookings_screen.dart**

- Replace `final List<BookingRecord> records = ref.watch(bookingsProvider);` with reading jobs from the repo stream:
  ```dart
  final AsyncValue<List<JobRequest>> jobsAsync = ref.watch(myJobsProvider);
  ```
  (add `import '../marketplace/marketplace_providers.dart';` + `import 'package:task_domain/task_domain.dart';` + `import 'package:task_design/task_design.dart';` if not present.)
- Render with `jobsAsync.when(data: ..., loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => ...)`. Inside `data`, split active vs past by status: `active = jobs.where((j) => j.status != JobStatus.completed && j.status != JobStatus.cancelled)`, `past = jobs.where((j) => j.status == JobStatus.completed || j.status == JobStatus.cancelled)`.
- `_card(context, BookingRecord r, ...)` → `_card(context, JobRequest job, ...)`; show `job.title`, `categoryIcon(job.category)`, `'${job.settledPrice} EGP'`, and a status label from `job.status.name`.

- [ ] **Step 3: quote_bids_screen.dart**

- Replace `final BookingDraft draft = ref.watch(bookingProvider); final Service? service = draft.service;` with the first job that has offers from the repo:
  ```dart
  final List<JobRequest> jobs = ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
  final JobRequest? job = jobs.where((j) => j.offers.isNotEmpty).firstOrNull;
  final List<Offer> offers = job?.offers ?? const <Offer>[];
  ```
  (add marketplace + domain imports; `firstOrNull` comes from `dart:core` extension on Iterable in recent Dart — if unavailable, use `(list.isEmpty ? null : list.first)`).
- `_collectingState(TextTheme, Service?)` → `_collectingState(TextTheme text, JobRequest? job)`; show `job?.title`.
- `_bidsState(BookingDraft, TextTheme)` → `_bidsState(List<Offer> offers, TextTheme text)`. Replace `kBids` with `offers`, `b.price` with `o.currentPrice`, `b.proName` with `o.technicianName`, `b.id` with `o.id`. The cheapest line: `offers.map((o) => o.currentPrice).reduce((a, b) => a < b ? a : b)` (guard empty).
- Replace `ref.read(bookingProvider.notifier).selectBid(b.id)` on accept with:
  ```dart
  onTap: () => ref.read(jobMarketplaceRepositoryProvider).acceptOffer(job!.id, o.id),
  ```

- [ ] **Step 4: rating_screen.dart**

- Replace `ref.read(bookingProvider.notifier).reset();` → `ref.read(jobDraftProvider.notifier).reset();`.
- Replace `final BookingDraft draft = ref.watch(bookingProvider); final Service? service = draft.service;` with the most-recent job: `final JobRequest? job = ref.watch(myJobsProvider).valueOrNull?.firstOrNull;` and render `job?.title` / `job?.category.displayLabel` where the service name was shown. Add marketplace + domain imports.

- [ ] **Step 5: job_tracking_screen.dart**

- Wherever it reads `draft.service`/`basePrice`, read from the latest job: `final JobRequest? job = ref.watch(myJobsProvider).valueOrNull?.firstOrNull;` and use `job?.title`, `job?.settledPrice`. Keep `JobStage` (still in `booking_state.dart`). Add marketplace + domain imports.

- [ ] **Step 6: asap_dispatch_screen.dart**

- Remove any `Service`/`BookingMode`/`bookingProvider` references. If it shows a service name, switch to `ref.watch(jobDraftProvider).category?.displayLabel ?? 'your job'`. This screen is reshaped in slice 4 — keep it minimal but compiling. Add marketplace + domain imports as needed.

- [ ] **Step 7: address_screen.dart**

- Replace `final BookingDraft draft = ref.watch(bookingProvider);` and `ref.read(bookingProvider.notifier).setAddress(a.id);`. For this slice, address selection has no draft field yet (real location is slice 5), so make the address list selection local `setState` (track a selected `String addressId`) and drop the `bookingProvider` calls. `kSavedAddresses` still lives in `booking_state.dart`.

- [ ] **Step 8: technician_catalog.dart** (if not done in Task 9)

- Ensure a `JobCategory get category` getter exists mapping the legacy `serviceId` strings to categories, as described in Task 9 step 6.

- [ ] **Step 9: Run analyzer + full app tests**

Run: `cd apps/customer && flutter analyze && flutter test`
Expected: analyzer clean (no errors), all tests PASS. Fix any remaining references to removed symbols the analyzer flags.

- [ ] **Step 10: Run the whole workspace suite**

Run: `melos run test` (from repo root; or `dart test` in each package + `flutter test` in `apps/customer`).
Expected: all packages green.

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "refactor(customer): migrate screens to fixed-price JobRequest model"
```

---

### Task 11: Update widget_test for the new model

**Files:**
- Modify: `apps/customer/test/widget_test.dart`

The existing splash tests assert on `'Task'`, `'Sign in'`, `'Phone Number'` — none of which this slice changes, so they should still pass. Only touch this file if Task 10's `flutter test` surfaced a failure here (e.g. a removed import).

- [ ] **Step 1: Run the splash tests**

Run: `cd apps/customer && flutter test test/widget_test.dart`
Expected: PASS (2 tests). If they fail solely due to a removed-symbol import, fix the import; do not change the assertions.

- [ ] **Step 2: Commit (only if changed)**

```bash
git add apps/customer/test/widget_test.dart
git commit -m "test(customer): keep splash tests green after model pivot"
```

---

## Self-Review

**Spec coverage:**
- Fixed-price `JobRequest` + offer-thread negotiation → Tasks 2, 5. ✓
- `JobCategory` 8-category taxonomy incl. satellite + smart home → Task 1. ✓
- Model in shared `task_domain` → Tasks 1-3. ✓
- Mock repository seam → Task 5. ✓
- UI icon/tint map in `task_design` → Task 4. ✓
- Teardown of `Service`/`basePrice`/`durationLabel`/catalog → Tasks 6, 7, 9, 10. ✓
- Placeholder create entry + router rewire → Task 8. ✓
- Migrated-but-kept `quote_bids`/`asap_dispatch` → Task 10 (steps 3, 6). ✓
- Tests (domain unit, repo, splash) → Tasks 1-5, 10, 11. ✓
- Exit criterion `melos run test` green → Task 10 step 10. ✓

**Placeholder scan:** No "TBD"/"add error handling"/"similar to" steps; the only stub is the *product* placeholder screen (intentional, slice 2). ✓

**Type consistency:** `JobRequest`, `Offer`, `PriceProposal`, `JobRequestDraft`, `JobMarketplaceRepository`, `categoryIcon`/`categoryTint`, `jobMarketplaceRepositoryProvider`/`myJobsProvider`/`jobDraftProvider` are used with identical signatures across Tasks 5-10. `OfferStatus`/`ProposalAuthor`/`Urgency`/`PropertyType`/`JobCategory` match their Task 1 definitions. ✓

**Note on red intermediate state:** Tasks 6-9 leave the app uncompilable until Task 10 finishes. If executing with a workflow that forbids red commits, treat Tasks 6-10 as one commit group (commit once at Task 10 step 11) — Task 6's separate commit step is optional.
