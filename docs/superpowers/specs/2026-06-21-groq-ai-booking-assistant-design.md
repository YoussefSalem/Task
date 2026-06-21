# Groq AI Booking Assistant — Design

**Date:** 2026-06-21
**Status:** Approved (pending spec review)

## Goal

Turn the existing stubbed `AiChatScreen` (Task Assistant) into a real,
Groq-backed conversational assistant that helps a customer assemble a
fixed-price `JobRequestDraft` through natural chat and, on explicit user
confirmation, publishes it as a `JobRequest` via the existing marketplace
seam. No hourly pricing; currency is EGP whole integers.

## Decisions (from brainstorming)

- **Interaction:** chat screen (reuse `AiChatScreen` UI).
- **Publish:** confirm-first — the AI proposes a draft; the user taps
  **Confirm & publish** before anything is committed.
- **LLM:** Groq, model `llama-3.3-70b-versatile`, OpenAI-compatible
  endpoint `https://api.groq.com/openai/v1/chat/completions`, JSON mode
  (`response_format: {type: json_object}`).
- **Structured-reply approach (A):** each turn the model returns a JSON
  object the app maps to a draft — chosen over tool-calling (less plumbing)
  and over a separate extraction call (less latency).

## Key handling

- Read at compile/run time via `String.fromEnvironment('GROQ_API_KEY')`.
- Provided through `--dart-define-from-file=groq.env.json`
  (`apps/customer/groq.env.json`, **git-ignored**, never committed).
- If the key is empty, `assistantServiceProvider` returns
  `MockAssistantService` so the screen still works offline and in tests.

## Architecture

All new code under `apps/customer/lib/features/assistant/`.

### `assistant_service.dart`
- `class ChatMessage { final String text; final bool fromUser; }`
- `class AssistantTurn { final String reply; final JobRequestDraft? draft;
  final bool ready; }`
- `abstract interface class AssistantService {
  Future<AssistantTurn> respond(List<ChatMessage> history); }`

### `groq_assistant_service.dart`
- `class GroqAssistantService implements AssistantService` taking an
  injected `http.Client` and the API key.
- Builds the request: a system prompt enumerating the 8 `JobCategory` ids
  (`plumbing, electrical, ac, cleaning, carpentry, painting, satellite,
  smart_home`), the EGP whole-integer pricing rule, the `Urgency` values,
  and the required JSON response schema:
  ```json
  { "reply": "string to show the user",
    "draft": { "category": "<id|null>", "title": "string",
               "description": "string", "fixed_price": 0,
               "urgency": "flexible|soon|urgent|emergency" },
    "ready": false }
  ```
  Plus the mapped chat history as `messages`.
- Parses the JSON reply into `AssistantTurn`, mapping `category` id →
  `JobCategory.fromId` (null/unknown → null draft category) and `urgency`
  string → `Urgency`. `ready` is only honored when the resulting draft is
  `isValid`.
- On any network or parse error, returns an `AssistantTurn` with a friendly
  error `reply`, `draft: null`, `ready: false` (never throws to the UI).

### `mock_assistant_service.dart`
- `class MockAssistantService implements AssistantService` — keyword
  heuristic (leak/drip→plumbing, trip/power→electrical, AC/cooling→ac,
  clean→cleaning, etc.) that fills a draft and asks for a price if missing,
  marking `ready` once it has category + title + price. Used with no key
  and in unit tests.

### `assistant_providers.dart`
- `final assistantServiceProvider = Provider<AssistantService>((ref) { ... })`
  — returns `GroqAssistantService` when `GROQ_API_KEY` is non-empty, else
  `MockAssistantService`.
- `class BookingChatController extends Notifier<ChatState>` where
  `ChatState { List<ChatMessage> messages; JobRequestDraft? pendingDraft;
  bool typing; }`. Methods: `send(String)`, `confirmPending()`,
  `reset()`. `send` appends the user message, sets `typing`, calls the
  service, appends the reply, and stores `pendingDraft` when `ready`.
  `confirmPending` calls `jobMarketplaceRepositoryProvider.publish` and
  clears the pending draft.
- `final bookingChatProvider =
  NotifierProvider<BookingChatController, ChatState>(...)`.

### `AiChatScreen` rewiring
- Replace the local `_messages`/`_typing`/`_replyTimer` stub with
  `ref.watch(bookingChatProvider)`; the composer calls
  `controller.send(...)`.
- Keep the existing bubble, typing indicator, suggestion chips, and
  composer widgets unchanged.
- Add a **confirmation-card bubble**: when `pendingDraft != null`, render a
  card showing `categoryIcon`/`categoryTint`, the title, and
  `'${draft.fixedPrice} EGP'`, with a **Confirm & publish** button →
  `controller.confirmPending()` → `context.go(JobTrackingScreen.routePath)`.

## Data flow

```
user types → BookingChatController.send
  → AssistantService.respond(history)        (Groq or mock)
  → append reply bubble
  → if ready && draft.isValid: set pendingDraft → render confirm card
user taps Confirm & publish
  → jobMarketplaceRepositoryProvider.publish(draft)
  → reset draft → navigate to JobTrackingScreen
```

The user can keep chatting to revise; each new `ready` turn replaces the
pending draft.

## Error handling

- Network/timeout/parse failure → friendly assistant bubble, no crash.
- Empty/missing key → mock service (no network).
- Invalid model output (missing fields) → treated as `ready: false`; the
  assistant keeps the conversation going.

## Dependency

- Add `http: ^1.2.0` to `apps/customer/pubspec.yaml`.

## Run / launch config

- `apps/customer/groq.env.json` (git-ignored) holds the key.
- `.claude/launch.json` Customer config gains
  `--dart-define-from-file=groq.env.json` in `runtimeArgs` (the file path is
  relative to the config `cwd` = `apps/customer`). The launch config itself
  holds **no** secret.

## Testing

- `groq_assistant_service_test.dart` — inject a fake `http.Client` returning
  a canned JSON body; assert the parsed `AssistantTurn` (reply, mapped
  category/urgency, `ready` gated on `isValid`); assert a 500/garbage body
  yields a safe error turn.
- `mock_assistant_service_test.dart` — a known phrase + price yields a valid
  ready draft.
- `booking_chat_controller_test.dart` — with a fake `AssistantService` and a
  `MockJobMarketplaceRepository`, `send` then `confirmPending` publishes one
  job to `watchMyJobs`.

## Out of scope (later slices)

- Streaming responses, tool-calling, photo upload, address/location capture,
  multi-language replies, persisting chat history.
