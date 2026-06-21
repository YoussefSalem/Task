# Groq AI Booking Assistant — Design

**Date:** 2026-06-21
**Status:** Approved (pending spec review)

## Goal

Turn the existing stubbed `AiChatScreen` (Task Assistant) into a real,
Groq-backed conversational assistant whose job is to **gather all relevant
details about the customer's issue** and write a **concise problem summary
for technicians**. The AI never sets or asks for a price — the **customer
sets the fixed price and stays in control of the quote**. When the details
are complete the AI produces the summary; the customer then enters the price
and, on explicit confirmation, the `JobRequest` is published to the
marketplace seam so technicians can read the summary and decide whether to
respond. No hourly pricing; currency is EGP whole integers.

## Division of responsibility

- **AI gathers:** category, a concise `title` (the technician-facing problem
  summary), a fuller `description`, `urgency`, and `propertyType`.
- **AI never touches:** price. It must not propose, ask for, or mention a
  number for the price.
- **Customer controls:** the `fixedPrice`, entered in the confirmation step,
  and the final decision to publish.

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
  smart_home`), the `Urgency` and `PropertyType` values, an explicit
  instruction that **the assistant must never ask about, suggest, or state a
  price** (the customer sets it later), guidance to ask focused follow-up
  questions until it can write a clear technician-facing summary, and the
  required JSON response schema:
  ```json
  { "reply": "string to show the user",
    "draft": { "category": "<id|null>",
               "title": "concise technician-facing summary",
               "description": "fuller problem detail",
               "urgency": "flexible|soon|urgent|emergency",
               "property_type": "apartment|villa|office|other" },
    "ready": false }
  ```
  Plus the mapped chat history as `messages`. The `draft` carries **no
  price field** at all.
- Parses the JSON reply into `AssistantTurn`, mapping `category` id →
  `JobCategory.fromId` (null/unknown → null draft category), `urgency`
  string → `Urgency`, and `property_type` → `PropertyType`. The draft's
  `fixedPrice` stays at its default `0` here — it is the customer's to set.
  `ready` is honored when the gathered draft has a category and a non-empty
  title/description (price is intentionally *not* required for `ready`).
- On any network or parse error, returns an `AssistantTurn` with a friendly
  error `reply`, `draft: null`, `ready: false` (never throws to the UI).

### `mock_assistant_service.dart`
- `class MockAssistantService implements AssistantService` — keyword
  heuristic (leak/drip→plumbing, trip/power→electrical, AC/cooling→ac,
  clean→cleaning, etc.) that infers a category and writes a title +
  description from the user's text, marking `ready` once it has category +
  title (never asks about price). Used with no key and in unit tests.

### `assistant_providers.dart`
- `final assistantServiceProvider = Provider<AssistantService>((ref) { ... })`
  — returns `GroqAssistantService` when `GROQ_API_KEY` is non-empty, else
  `MockAssistantService`.
- `class BookingChatController extends Notifier<ChatState>` where
  `ChatState { List<ChatMessage> messages; JobRequestDraft? pendingDraft;
  bool typing; }`. Methods: `send(String)`, `setPrice(int)`,
  `publishPending()`, `reset()`. `send` appends the user message, sets
  `typing`, calls the service, appends the reply, and stores the gathered
  `pendingDraft` (price still 0) when `ready`. `setPrice` updates
  `pendingDraft` via `copyWith(fixedPrice:)` as the customer types.
  `publishPending` requires `pendingDraft.isValid` (i.e. the customer-set
  price > 0), calls `jobMarketplaceRepositoryProvider.publish`, and clears
  the pending draft.
- `final bookingChatProvider =
  NotifierProvider<BookingChatController, ChatState>(...)`.

### `AiChatScreen` rewiring
- Replace the local `_messages`/`_typing`/`_replyTimer` stub with
  `ref.watch(bookingChatProvider)`; the composer calls
  `controller.send(...)`.
- Keep the existing bubble, typing indicator, suggestion chips, and
  composer widgets unchanged.
- Add a **confirmation-card bubble**: when `pendingDraft != null`, render a
  card showing `categoryIcon`/`categoryTint`, the AI-written title +
  description (the technician-facing summary), and a **price `TextField`
  the customer fills** ("What will you pay for this job? (EGP)") wired to
  `controller.setPrice`. The **Confirm & publish** button is enabled only
  when the entered price > 0 → `controller.publishPending()` →
  `context.go(JobTrackingScreen.routePath)`.

## Data flow

```
user types → BookingChatController.send
  → AssistantService.respond(history)        (Groq or mock; price never asked)
  → append reply bubble
  → if ready (category + title/description gathered):
       set pendingDraft (price = 0) → render summary + price-entry card
customer enters price → controller.setPrice
customer taps Confirm & publish (enabled when price > 0)
  → jobMarketplaceRepositoryProvider.publish(draft with customer price)
  → reset draft → navigate to JobTrackingScreen
```

The customer can keep chatting to add detail; each new `ready` turn updates
the gathered summary while preserving any price already entered.

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
  category/urgency/property_type, `ready` gated on category + title, draft
  `fixedPrice == 0`); assert a 500/garbage body yields a safe error turn.
- `mock_assistant_service_test.dart` — a known phrase yields a ready draft
  with a category + title and `fixedPrice == 0` (price never set by the AI).
- `booking_chat_controller_test.dart` — with a fake `AssistantService` and a
  `MockJobMarketplaceRepository`: `send` produces a pending draft with price
  0; `publishPending` before `setPrice` is a no-op (invalid); after
  `setPrice(400)`, `publishPending` publishes one job at 400 EGP to
  `watchMyJobs`.

## Out of scope (later slices)

- Streaming responses, tool-calling, photo upload, address/location capture,
  multi-language replies, persisting chat history.
