# Groq AI Booking Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the in-app Task Assistant gather a customer's issue over chat (via Groq), write a concise technician-facing summary, let the customer set the price, and publish it as a `JobRequest`.

**Architecture:** A small `AssistantService` seam under `apps/customer/lib/features/assistant/` has two implementations — `GroqAssistantService` (real, OpenAI-compatible Groq JSON-mode call over `http`) and `MockAssistantService` (keyword fallback, no network). A Riverpod `BookingChatController` drives the conversation, holds the AI-gathered `JobRequestDraft` (price left at 0), accepts a customer-entered price, and publishes through the existing `jobMarketplaceRepositoryProvider`. The existing `AiChatScreen` is rewired from its stubbed timer to this controller and gains a summary + price confirmation card.

**Tech Stack:** Flutter 3.44 / Dart 3.9, Riverpod 2.6, go_router 14.8, `http`, `package:http/testing.dart` (MockClient), `flutter_test`. Groq model `llama-3.3-70b-versatile`.

## Global Constraints

- Currency is **EGP**, prices are whole integers (no decimals, no hourly math).
- The AI must **never ask about, suggest, or state a price** — the customer sets `fixedPrice`.
- `ready` is gated on **category + non-empty title/description only**, never on price.
- The Groq API key is read via `String.fromEnvironment('GROQ_API_KEY')` and supplied with `--dart-define-from-file=groq.env.json`; the key is **never** written into a committed file.
- Do **not** add `font_awesome_flutter` (breaks the build — use Material icons).
- The 8 `JobCategory` ids: `plumbing, electrical, ac, cleaning, carpentry, painting, satellite, smart_home`.
- `JobRequestDraft.isValid` = `category != null && title non-empty && fixedPrice > 0`.
- Each task ends green: run the stated test command and confirm PASS before committing.
- Run `flutter test` from `apps/customer`; prepend `export PATH="$PATH:/c/Users/youss/flutter/bin"` in the Bash tool.

---

### Task 1: AssistantService seam + MockAssistantService

**Files:**
- Create: `apps/customer/lib/features/assistant/assistant_service.dart`
- Create: `apps/customer/lib/features/assistant/mock_assistant_service.dart`
- Test: `apps/customer/test/assistant/mock_assistant_service_test.dart`

**Interfaces:**
- Consumes: `JobCategory`, `JobRequestDraft`, `Urgency`, `PropertyType` from `package:task_domain/task_domain.dart`.
- Produces:
  - `class ChatMessage { final String text; final bool fromUser; const ChatMessage(this.text, {required this.fromUser}); }`
  - `class AssistantTurn { final String reply; final JobRequestDraft? draft; final bool ready; const AssistantTurn({required this.reply, this.draft, this.ready = false}); }`
  - `abstract interface class AssistantService { Future<AssistantTurn> respond(List<ChatMessage> history); }`
  - `JobCategory? categoryFromKeywords(String text)` (top-level helper in `mock_assistant_service.dart`).
  - `class MockAssistantService implements AssistantService`.

- [ ] **Step 1: Write the failing test**

```dart
// apps/customer/test/assistant/mock_assistant_service_test.dart
import 'package:customer/features/assistant/assistant_service.dart';
import 'package:customer/features/assistant/mock_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  final MockAssistantService svc = MockAssistantService();

  test('infers a category and is ready, with no price set', () async {
    final AssistantTurn turn = await svc.respond(<ChatMessage>[
      const ChatMessage('My AC is leaking water and not cooling',
          fromUser: true),
    ]);
    expect(turn.ready, isTrue);
    expect(turn.draft, isNotNull);
    expect(turn.draft!.category, JobCategory.ac);
    expect(turn.draft!.title.trim(), isNotEmpty);
    expect(turn.draft!.fixedPrice, 0); // AI never sets price
    expect(turn.reply, isNotEmpty);
  });

  test('unknown issue asks a follow-up and is not ready', () async {
    final AssistantTurn turn = await svc.respond(<ChatMessage>[
      const ChatMessage('hello', fromUser: true),
    ]);
    expect(turn.ready, isFalse);
    expect(turn.draft?.category, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/customer && flutter test test/assistant/mock_assistant_service_test.dart`
Expected: FAIL — `assistant_service.dart` / `MockAssistantService` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// apps/customer/lib/features/assistant/assistant_service.dart
import 'package:task_domain/task_domain.dart';

/// One line in the assistant conversation.
class ChatMessage {
  const ChatMessage(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
}

/// The assistant's response for one turn: a reply to show, an optionally
/// gathered [draft] (price always left at 0 — the customer sets it), and
/// whether enough has been gathered to summarise for technicians.
class AssistantTurn {
  const AssistantTurn({required this.reply, this.draft, this.ready = false});
  final String reply;
  final JobRequestDraft? draft;
  final bool ready;
}

/// Seam between the chat UI and the model. Bound to [GroqAssistantService]
/// when a key is present, else [MockAssistantService].
abstract interface class AssistantService {
  Future<AssistantTurn> respond(List<ChatMessage> history);
}
```

```dart
// apps/customer/lib/features/assistant/mock_assistant_service.dart
import 'package:task_domain/task_domain.dart';

import 'assistant_service.dart';

/// Maps free text to a [JobCategory] by keyword, or null if nothing matches.
JobCategory? categoryFromKeywords(String text) {
  final String t = text.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(<String>['leak', 'drip', 'sink', 'pipe', 'tap', 'faucet', 'toilet',
      'plumb'])) {
    return JobCategory.plumbing;
  }
  if (has(<String>['ac', 'air con', 'cooling', 'cool', 'compressor',
      'condition'])) {
    return JobCategory.ac;
  }
  if (has(<String>['power', 'trip', 'breaker', 'wiring', 'socket', 'outlet',
      'electric', 'light'])) {
    return JobCategory.electrical;
  }
  if (has(<String>['clean', 'deep clean', 'dust', 'tidy'])) {
    return JobCategory.cleaning;
  }
  if (has(<String>['wood', 'door', 'cabinet', 'furniture', 'carpent'])) {
    return JobCategory.carpentry;
  }
  if (has(<String>['paint', 'wall colour', 'wall color'])) {
    return JobCategory.painting;
  }
  if (has(<String>['satellite', 'dish', 'receiver', 'antenna'])) {
    return JobCategory.satelliteInstallation;
  }
  if (has(<String>['smart home', 'automation', 'smart light', 'alexa',
      'smart switch'])) {
    return JobCategory.smartHome;
  }
  return null;
}

/// Offline fallback assistant. Infers a category from the latest user message
/// and writes a title/description, never asking about price.
class MockAssistantService implements AssistantService {
  @override
  Future<AssistantTurn> respond(List<ChatMessage> history) async {
    final ChatMessage? lastUser =
        history.where((ChatMessage m) => m.fromUser).isEmpty
            ? null
            : history.lastWhere((ChatMessage m) => m.fromUser);
    final String text = lastUser?.text.trim() ?? '';
    final JobCategory? category = categoryFromKeywords(text);

    if (category == null) {
      return const AssistantTurn(
        reply:
            "Tell me what's going wrong — for example a leak, an AC that "
            "won't cool, or power that keeps tripping — and where in your "
            'home it is.',
        ready: false,
      );
    }

    final String title = text.length <= 60 ? text : '${text.substring(0, 57)}…';
    final JobRequestDraft draft = JobRequestDraft(
      category: category,
      title: title,
      description: text,
    );
    return AssistantTurn(
      reply:
          "Got it — this looks like a ${category.displayLabel} job. I've put "
          'together a summary for technicians below. Set the price you want '
          'to pay and publish when you are ready.',
      draft: draft,
      ready: true,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/customer && flutter test test/assistant/mock_assistant_service_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add apps/customer/lib/features/assistant/assistant_service.dart apps/customer/lib/features/assistant/mock_assistant_service.dart apps/customer/test/assistant/mock_assistant_service_test.dart
git commit -m "feat(assistant): AssistantService seam + mock fallback"
```

---

### Task 2: GroqAssistantService (real Groq JSON-mode call)

**Files:**
- Modify: `apps/customer/pubspec.yaml` (add `http: ^1.2.0`)
- Create: `apps/customer/lib/features/assistant/groq_assistant_service.dart`
- Test: `apps/customer/test/assistant/groq_assistant_service_test.dart`

**Interfaces:**
- Consumes: `AssistantService`, `ChatMessage`, `AssistantTurn` (Task 1); `JobCategory`, `JobRequestDraft`, `Urgency`, `PropertyType` (task_domain); `package:http/http.dart`.
- Produces: `class GroqAssistantService implements AssistantService` with constructor `GroqAssistantService({required http.Client client, required String apiKey, String model = 'llama-3.3-70b-versatile'})`.

- [ ] **Step 1: Add the http dependency**

In `apps/customer/pubspec.yaml`, under `dependencies:` after `shared_preferences: ^2.3.2`, add:

```yaml
  # AI assistant (Groq, OpenAI-compatible)
  http: ^1.2.0
```

Run: `cd apps/customer && export PATH="$PATH:/c/Users/youss/flutter/bin" && flutter pub get`
Expected: resolves with `http` added.

- [ ] **Step 2: Write the failing test**

```dart
// apps/customer/test/assistant/groq_assistant_service_test.dart
import 'dart:convert';

import 'package:customer/features/assistant/assistant_service.dart';
import 'package:customer/features/assistant/groq_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_domain/task_domain.dart';

http.Client _clientReturning(String content, {int status = 200}) {
  return MockClient((http.Request req) async {
    return http.Response(
      jsonEncode(<String, dynamic>{
        'choices': <dynamic>[
          <String, dynamic>{
            'message': <String, dynamic>{'content': content},
          },
        ],
      }),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
}

void main() {
  test('parses a ready turn and maps enums, leaving price at 0', () async {
    final String content = jsonEncode(<String, dynamic>{
      'reply': 'Thanks, I have what I need.',
      'draft': <String, dynamic>{
        'category': 'electrical',
        'title': 'Breaker trips when heater runs',
        'description': 'Main breaker trips whenever the water heater starts.',
        'urgency': 'urgent',
        'property_type': 'villa',
      },
      'ready': true,
    });
    final GroqAssistantService svc = GroqAssistantService(
      client: _clientReturning(content),
      apiKey: 'test-key',
    );

    final AssistantTurn turn = await svc.respond(<ChatMessage>[
      const ChatMessage('breaker keeps tripping', fromUser: true),
    ]);

    expect(turn.ready, isTrue);
    expect(turn.reply, 'Thanks, I have what I need.');
    expect(turn.draft!.category, JobCategory.electrical);
    expect(turn.draft!.urgency, Urgency.urgent);
    expect(turn.draft!.propertyType, PropertyType.villa);
    expect(turn.draft!.fixedPrice, 0);
  });

  test('not ready when category missing even if model says ready', () async {
    final String content = jsonEncode(<String, dynamic>{
      'reply': 'Where is the problem?',
      'draft': <String, dynamic>{
        'category': null,
        'title': '',
        'description': '',
      },
      'ready': true,
    });
    final GroqAssistantService svc = GroqAssistantService(
      client: _clientReturning(content),
      apiKey: 'test-key',
    );
    final AssistantTurn turn =
        await svc.respond(<ChatMessage>[const ChatMessage('hi', fromUser: true)]);
    expect(turn.ready, isFalse);
    expect(turn.draft?.category, isNull);
  });

  test('http error yields a safe non-throwing turn', () async {
    final GroqAssistantService svc = GroqAssistantService(
      client: _clientReturning('nonsense', status: 500),
      apiKey: 'test-key',
    );
    final AssistantTurn turn = await svc
        .respond(<ChatMessage>[const ChatMessage('hi', fromUser: true)]);
    expect(turn.ready, isFalse);
    expect(turn.draft, isNull);
    expect(turn.reply, contains('trouble'));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/customer && flutter test test/assistant/groq_assistant_service_test.dart`
Expected: FAIL — `GroqAssistantService` not defined.

- [ ] **Step 4: Write minimal implementation**

```dart
// apps/customer/lib/features/assistant/groq_assistant_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:task_domain/task_domain.dart';

import 'assistant_service.dart';

/// Real assistant backed by Groq's OpenAI-compatible chat completions API in
/// JSON mode. The system prompt forbids any mention of price; the customer
/// sets that later.
class GroqAssistantService implements AssistantService {
  GroqAssistantService({
    required http.Client client,
    required String apiKey,
    this.model = 'llama-3.3-70b-versatile',
  })  : _client = client,
        _apiKey = apiKey;

  final http.Client _client;
  final String _apiKey;
  final String model;

  static final Uri _endpoint =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  static const String _systemPrompt = '''
You are Task Assistant, helping a customer in Egypt describe a home-services
problem so a technician can decide whether to take the job.

Your ONLY goals:
1. Ask short, focused follow-up questions until you understand the issue.
2. Classify it into exactly one category id from:
   plumbing, electrical, ac, cleaning, carpentry, painting, satellite,
   smart_home.
3. Write a concise, technician-facing summary (a short "title" and a fuller
   "description").

STRICT RULES:
- NEVER ask about, suggest, mention, or estimate a price or cost. The customer
  sets the price themselves afterwards.
- Currency, money, hourly rates: do not bring them up.
- Reply ONLY with a single JSON object, no markdown, in this exact shape:
{
  "reply": "what you say to the customer",
  "draft": {
    "category": "<one id above, or null if unsure>",
    "title": "concise technician-facing summary",
    "description": "fuller problem detail",
    "urgency": "flexible|soon|urgent|emergency",
    "property_type": "apartment|villa|office|other"
  },
  "ready": false
}
Set "ready" to true only once you have a category and a clear title and
description. Until then keep "ready" false and ask another question.''';

  @override
  Future<AssistantTurn> respond(List<ChatMessage> history) async {
    try {
      final List<Map<String, String>> messages = <Map<String, String>>[
        <String, String>{'role': 'system', 'content': _systemPrompt},
        for (final ChatMessage m in history)
          <String, String>{
            'role': m.fromUser ? 'user' : 'assistant',
            'content': m.text,
          },
      ];

      final http.Response res = await _client.post(
        _endpoint,
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'model': model,
          'messages': messages,
          'temperature': 0.3,
          'response_format': <String, String>{'type': 'json_object'},
        }),
      );

      if (res.statusCode != 200) {
        return _errorTurn();
      }

      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      final String content = (body['choices'] as List<dynamic>).first
          ['message']['content'] as String;
      final Map<String, dynamic> parsed =
          jsonDecode(content) as Map<String, dynamic>;
      return _toTurn(parsed);
    } catch (_) {
      return _errorTurn();
    }
  }

  AssistantTurn _toTurn(Map<String, dynamic> parsed) {
    final String reply = (parsed['reply'] as String?)?.trim() ??
        'Could you tell me a bit more about the problem?';
    final Map<String, dynamic>? d =
        parsed['draft'] as Map<String, dynamic>?;
    if (d == null) {
      return AssistantTurn(reply: reply, ready: false);
    }

    final JobCategory? category = _categoryFromId(d['category'] as String?);
    final String title = (d['title'] as String?)?.trim() ?? '';
    final String description = (d['description'] as String?)?.trim() ?? '';
    final bool ready = (parsed['ready'] as bool? ?? false) &&
        category != null &&
        title.isNotEmpty;

    final JobRequestDraft draft = JobRequestDraft(
      category: category,
      title: title,
      description: description,
      urgency: _urgencyFromName(d['urgency'] as String?),
      propertyType: _propertyFromName(d['property_type'] as String?),
    );
    return AssistantTurn(reply: reply, draft: draft, ready: ready);
  }

  AssistantTurn _errorTurn() => const AssistantTurn(
        reply:
            'I had trouble reaching the assistant just now — please try '
            'sending that again.',
        ready: false,
      );

  JobCategory? _categoryFromId(String? id) {
    if (id == null) return null;
    for (final JobCategory c in JobCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }

  Urgency _urgencyFromName(String? name) {
    for (final Urgency u in Urgency.values) {
      if (u.name == name) return u;
    }
    return Urgency.soon;
  }

  PropertyType _propertyFromName(String? name) {
    for (final PropertyType p in PropertyType.values) {
      if (p.name == name) return p;
    }
    return PropertyType.apartment;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd apps/customer && flutter test test/assistant/groq_assistant_service_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add apps/customer/pubspec.yaml apps/customer/lib/features/assistant/groq_assistant_service.dart apps/customer/test/assistant/groq_assistant_service_test.dart
git commit -m "feat(assistant): Groq JSON-mode assistant service"
```

---

### Task 3: Providers + BookingChatController

**Files:**
- Create: `apps/customer/lib/features/assistant/assistant_providers.dart`
- Test: `apps/customer/test/assistant/booking_chat_controller_test.dart`

**Interfaces:**
- Consumes: `AssistantService`, `ChatMessage`, `AssistantTurn`, `MockAssistantService` (Tasks 1-2); `GroqAssistantService` (Task 2); `jobMarketplaceRepositoryProvider` from `../marketplace/marketplace_providers.dart`; `JobRequestDraft` (task_domain); `package:http/http.dart`.
- Produces:
  - `final httpClientProvider = Provider<http.Client>((ref) => http.Client());`
  - `final assistantServiceProvider = Provider<AssistantService>(...)` — Groq when `String.fromEnvironment('GROQ_API_KEY')` is non-empty, else mock.
  - `class ChatState { final List<ChatMessage> messages; final JobRequestDraft? pendingDraft; final bool typing; }` with `ChatState copyWith({...})`.
  - `class BookingChatController extends Notifier<ChatState>` with `Future<void> send(String text)`, `void setPrice(int price)`, `Future<void> publishPending()`, `void reset()`.
  - `final bookingChatProvider = NotifierProvider<BookingChatController, ChatState>(BookingChatController.new);`

- [ ] **Step 1: Write the failing test**

```dart
// apps/customer/test/assistant/booking_chat_controller_test.dart
import 'package:customer/features/assistant/assistant_providers.dart';
import 'package:customer/features/assistant/assistant_service.dart';
import 'package:customer/features/marketplace/marketplace_providers.dart';
import 'package:customer/features/marketplace/mock_job_marketplace_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';

/// Always returns a ready draft (price 0), like a finished gathering turn.
class _ReadyService implements AssistantService {
  @override
  Future<AssistantTurn> respond(List<ChatMessage> history) async {
    return AssistantTurn(
      reply: 'Summary ready.',
      ready: true,
      draft: const JobRequestDraft(
        category: JobCategory.plumbing,
        title: 'Leaking sink',
        description: 'Drip under the kitchen sink.',
      ),
    );
  }
}

void main() {
  late ProviderContainer container;
  late MockJobMarketplaceRepository repo;

  setUp(() {
    repo = MockJobMarketplaceRepository();
    container = ProviderContainer(overrides: <Override>[
      assistantServiceProvider.overrideWithValue(_ReadyService()),
      jobMarketplaceRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  test('send stores a pending draft with price 0', () async {
    await container.read(bookingChatProvider.notifier).send('sink leaks');
    final ChatState s = container.read(bookingChatProvider);
    expect(s.pendingDraft, isNotNull);
    expect(s.pendingDraft!.fixedPrice, 0);
    expect(s.messages.where((ChatMessage m) => m.fromUser).length, 1);
  });

  test('publishPending is a no-op until the customer sets a price', () async {
    final BookingChatController c =
        container.read(bookingChatProvider.notifier);
    await c.send('sink leaks');
    final int before = (await repo.watchMyJobs().first).length;

    await c.publishPending(); // price still 0 → invalid → nothing published
    expect((await repo.watchMyJobs().first).length, before);

    c.setPrice(400);
    await c.publishPending();
    final List<JobRequest> jobs = await repo.watchMyJobs().first;
    expect(jobs.length, before + 1);
    expect(jobs.first.fixedPrice, 400);
    expect(container.read(bookingChatProvider).pendingDraft, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/customer && flutter test test/assistant/booking_chat_controller_test.dart`
Expected: FAIL — `assistant_providers.dart` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// apps/customer/lib/features/assistant/assistant_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';
import 'assistant_service.dart';
import 'groq_assistant_service.dart';
import 'mock_assistant_service.dart';

/// Compile-time key, supplied via --dart-define-from-file=groq.env.json.
const String _kGroqKey = String.fromEnvironment('GROQ_API_KEY');

final httpClientProvider = Provider<http.Client>((Ref ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Real Groq service when a key is configured; offline mock otherwise.
final assistantServiceProvider = Provider<AssistantService>((Ref ref) {
  if (_kGroqKey.isEmpty) return MockAssistantService();
  return GroqAssistantService(
    client: ref.watch(httpClientProvider),
    apiKey: _kGroqKey,
  );
});

/// Immutable chat state: the visible conversation, the AI-gathered draft
/// awaiting a price + publish, and whether the assistant is "typing".
class ChatState {
  const ChatState({
    required this.messages,
    this.pendingDraft,
    this.typing = false,
  });

  final List<ChatMessage> messages;
  final JobRequestDraft? pendingDraft;
  final bool typing;

  ChatState copyWith({
    List<ChatMessage>? messages,
    JobRequestDraft? pendingDraft,
    bool clearPending = false,
    bool? typing,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        pendingDraft: clearPending ? null : (pendingDraft ?? this.pendingDraft),
        typing: typing ?? this.typing,
      );
}

const ChatMessage _greeting = ChatMessage(
  "Hi! I'm your Task assistant. Tell me what needs fixing and I'll write a "
  'clear summary for the right pro. You decide the price.',
  fromUser: false,
);

/// Drives the assistant conversation and the gather → price → publish flow.
class BookingChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState(messages: <ChatMessage>[_greeting]);

  Future<void> send(String text) async {
    final String value = text.trim();
    if (value.isEmpty || state.typing) return;

    final List<ChatMessage> withUser = <ChatMessage>[
      ...state.messages,
      ChatMessage(value, fromUser: true),
    ];
    state = state.copyWith(messages: withUser, typing: true);

    final AssistantTurn turn =
        await ref.read(assistantServiceProvider).respond(withUser);

    state = ChatState(
      messages: <ChatMessage>[
        ...withUser,
        ChatMessage(turn.reply, fromUser: false),
      ],
      pendingDraft: turn.ready ? turn.draft : state.pendingDraft,
      typing: false,
    );
  }

  void setPrice(int price) {
    final JobRequestDraft? draft = state.pendingDraft;
    if (draft == null) return;
    state = state.copyWith(pendingDraft: draft.copyWith(fixedPrice: price));
  }

  Future<void> publishPending() async {
    final JobRequestDraft? draft = state.pendingDraft;
    if (draft == null || !draft.isValid) return;
    await ref.read(jobMarketplaceRepositoryProvider).publish(draft);
    state = state.copyWith(clearPending: true);
  }

  void reset() => state = build();
}

final bookingChatProvider =
    NotifierProvider<BookingChatController, ChatState>(BookingChatController.new);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/customer && flutter test test/assistant/booking_chat_controller_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add apps/customer/lib/features/assistant/assistant_providers.dart apps/customer/test/assistant/booking_chat_controller_test.dart
git commit -m "feat(assistant): providers + booking chat controller"
```

---

### Task 4: Rewire AiChatScreen to the controller + summary/price card

**Files:**
- Modify (rewrite): `apps/customer/lib/features/assistant/ai_chat_screen.dart`

**Interfaces:**
- Consumes: `bookingChatProvider`, `ChatState`, `BookingChatController` (Task 3); `ChatMessage` (Task 1); `JobRequestDraft`, `JobCategory` (task_domain); `categoryIcon`/`categoryTint`, `GlowButton`, `AmbientBackground`, `AppColors`, `AppSpacing` (task_design); `JobTrackingScreen.routePath` from `../job/job_tracking_screen.dart`; `go_router`.

This task replaces the stubbed `_messages`/`_typing`/`_replyTimer` state with the controller, and adds a confirmation card. Keep the existing bubble / typing-dot / composer / suggestion visuals.

- [ ] **Step 1: Rewrite the screen**

Replace the entire contents of `apps/customer/lib/features/assistant/ai_chat_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../job/job_tracking_screen.dart';
import 'assistant_providers.dart';
import 'assistant_service.dart';

/// Task Assistant — gathers the customer's issue via Groq, writes a
/// technician-facing summary, then lets the customer set a price and publish.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  static const String routePath = '/ai-chat';

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const List<String> _suggestions = <String>[
    'My AC is leaking water',
    'Power keeps tripping',
    'Need a deep clean this weekend',
  ];

  @override
  void dispose() {
    _input.dispose();
    _price.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String raw) {
    if (raw.trim().isEmpty) return;
    _input.clear();
    ref.read(bookingChatProvider.notifier).send(raw);
    _scrollToEnd();
  }

  Future<void> _publish() async {
    await ref.read(bookingChatProvider.notifier).publishPending();
    if (!mounted) return;
    if (ref.read(bookingChatProvider).pendingDraft == null) {
      _price.clear();
      context.go(JobTrackingScreen.routePath);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ChatState chat = ref.watch(bookingChatProvider);
    ref.listen<ChatState>(bookingChatProvider, (_, _) => _scrollToEnd());

    final int messageCount = chat.messages.length +
        (chat.typing ? 1 : 0) +
        (chat.pendingDraft != null ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Task Assistant',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('AI · always on',
                    style: text.labelSmall?.copyWith(color: AppColors.success)),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.12),
          SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: messageCount,
                    itemBuilder: (BuildContext context, int i) {
                      if (i < chat.messages.length) {
                        return _bubble(chat.messages[i], text);
                      }
                      if (chat.typing && i == chat.messages.length) {
                        return _typingBubble();
                      }
                      return _summaryCard(chat.pendingDraft!, text);
                    },
                  ),
                ),
                if (chat.messages.length == 1 && chat.pendingDraft == null)
                  _suggestionRow(text),
                _composer(text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, TextTheme text) {
    final bool user = m.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color:
              user ? AppColors.primary : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
        ),
        child: Text(m.text,
            style: text.bodyMedium?.copyWith(color: Colors.white, height: 1.35)),
      ),
    );
  }

  Widget _summaryCard(JobRequestDraft draft, TextTheme text) {
    final JobCategory category = draft.category ?? JobCategory.plumbing;
    final bool canPublish = draft.fixedPrice > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: categoryTint(category).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(categoryIcon(category), color: categoryTint(category)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(draft.title,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(draft.description,
              style: text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary, height: 1.35)),
          const SizedBox(height: AppSpacing.lg),
          Text('What will you pay for this job? (EGP)',
              style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 400'),
            onChanged: (String v) => ref
                .read(bookingChatProvider.notifier)
                .setPrice(int.tryParse(v.trim()) ?? 0),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlowButton(
            label: 'Confirm & publish',
            icon: Icons.send_rounded,
            onPressed: canPublish ? _publish : null,
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                child: const _Dot(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(TextTheme text) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) {
          return GestureDetector(
            onTap: () => _send(_suggestions[i]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(_suggestions[i],
                  style: text.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _composer(TextTheme text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              minLines: 1,
              maxLines: 4,
              decoration:
                  const InputDecoration(hintText: 'Message the assistant…'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _send(_input.text),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
        child: SizedBox(height: 7, width: 7),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze + run the whole app test suite**

Run: `cd apps/customer && export PATH="$PATH:/c/Users/youss/flutter/bin" && flutter analyze && flutter test`
Expected: analyzer clean; all tests PASS (Task 1-3 tests + existing splash/marketplace tests).

- [ ] **Step 3: Commit**

```bash
git add apps/customer/lib/features/assistant/ai_chat_screen.dart
git commit -m "feat(assistant): wire chat screen to Groq controller + summary card"
```

---

### Task 5: Wire the Groq key into the run config + verify live

**Files:**
- Modify: `.claude/launch.json`

**Interfaces:** none (config + manual verification only). `apps/customer/groq.env.json` already exists and is git-ignored.

- [ ] **Step 1: Add the dart-define-from-file flag**

In `.claude/launch.json`, in the `"Customer App (Flutter Web)"` config's `runtimeArgs`, add `"--dart-define-from-file"` and `"groq.env.json"` immediately before `"-t"`. The array becomes:

```json
"runtimeArgs": [
  "run",
  "-d",
  "web-server",
  "--web-hostname",
  "127.0.0.1",
  "--web-port",
  "5000",
  "--dart-define-from-file",
  "groq.env.json",
  "-t",
  "lib/main_dev.dart"
],
```

(The path is relative to the config `cwd`, `apps/customer`, where `groq.env.json` lives.)

- [ ] **Step 2: Confirm the key file is present and ignored**

Run: `git check-ignore apps/customer/groq.env.json && test -f apps/customer/groq.env.json && echo OK`
Expected: prints the path and `OK`. If the file is missing, recreate it with `{ "GROQ_API_KEY": "<your key>" }`.

- [ ] **Step 3: Restart the preview and verify the assistant end-to-end**

Restart the "Customer App (Flutter Web)" dev server (stop then start) so the new `--dart-define-from-file` takes effect. In the running app: open the AI chat (`/ai-chat`), send "My AC is leaking water and won't cool", confirm a real assistant reply + a summary card appear, type a price (e.g. `350`), confirm **Confirm & publish** enables, tap it, and confirm navigation to the live-job screen and the new job showing under Bookings.

Expected: a Groq-generated summary (not the mock greeting), price gating works, and publishing creates a job.

- [ ] **Step 4: Commit**

```bash
git add .claude/launch.json
git commit -m "chore(assistant): pass GROQ_API_KEY via dart-define-from-file"
```

---

## Self-Review

**Spec coverage:**
- AI gathers issue, writes technician-facing summary, never prices → Tasks 1 (mock), 2 (Groq system prompt + parse). ✓
- Customer sets price, stays in control → Task 3 (`setPrice`, `publishPending` gated on `isValid`), Task 4 (price field + enable gate). ✓
- Confirm-first publish via marketplace seam → Task 3 + Task 4. ✓
- Groq JSON-mode, model `llama-3.3-70b-versatile`, OpenAI-compatible endpoint → Task 2. ✓
- Key via `String.fromEnvironment` + `--dart-define-from-file`, never committed → Task 3 (read), Task 5 (wire), git-ignored file. ✓
- Mock fallback when no key → Task 1 + Task 3 provider branch. ✓
- Reuse existing chat UI → Task 4 keeps bubble/typing/composer/suggestions. ✓
- `http` dependency → Task 2 Step 1. ✓
- Tests: parse, mock, controller publish-gating → Tasks 1-3. ✓

**Placeholder scan:** No TBD/TODO/"add error handling"/"similar to" steps; all code blocks are complete. Error handling is concrete (`_errorTurn`, try/catch, `isValid` gate). ✓

**Type consistency:** `AssistantTurn{reply,draft,ready}`, `ChatMessage{text,fromUser}`, `AssistantService.respond(List<ChatMessage>)`, `ChatState{messages,pendingDraft,typing}`, `BookingChatController.{send,setPrice,publishPending,reset}`, `assistantServiceProvider`/`bookingChatProvider`/`httpClientProvider`, `categoryFromKeywords`, `GroqAssistantService({client,apiKey,model})` are used identically across Tasks 1-4. `JobRequestDraft.copyWith(fixedPrice:)` and `.isValid` match the task_domain definitions. `JobTrackingScreen.routePath` = `/job/live` (verified). `GlowButton({label, onPressed, icon})` matches the real widget. ✓
