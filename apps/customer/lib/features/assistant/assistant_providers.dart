import 'package:customer/l10n/app_localizations.dart';
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

final httpClientProvider = Provider<http.Client>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Real Groq service when a key is configured; offline mock otherwise.
final assistantServiceProvider = Provider<AssistantService>((ref) {
  if (_kGroqKey.isEmpty) return MockAssistantService();
  return GroqAssistantService(
    client: ref.watch(httpClientProvider),
    apiKey: _kGroqKey,
  );
});

/// Where the conversation is in the gather → price → confirm → post flow.
enum ChatPhase {
  /// The assistant is still asking questions to understand the job.
  gathering,

  /// The job is understood; we are waiting for the customer's price.
  awaitingPrice,

  /// Price set; waiting for the customer to confirm before publishing.
  awaitingConfirm,

  /// The job has been published to the technician marketplace.
  posted,
}

/// Immutable chat state: the visible conversation, the AI-gathered draft
/// awaiting a price + publish, the flow [phase], and whether the assistant is
/// "typing".
class ChatState {
  const ChatState({
    required this.messages,
    this.pendingDraft,
    this.typing = false,
    this.phase = ChatPhase.gathering,
  });

  final List<ChatMessage> messages;
  final JobRequestDraft? pendingDraft;
  final bool typing;
  final ChatPhase phase;

  ChatState copyWith({
    List<ChatMessage>? messages,
    JobRequestDraft? pendingDraft,
    bool clearPending = false,
    bool? typing,
    ChatPhase? phase,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        pendingDraft: clearPending ? null : (pendingDraft ?? this.pendingDraft),
        typing: typing ?? this.typing,
        phase: phase ?? this.phase,
      );
}

const ChatMessage _greeting = ChatMessage(
  "Hi! I'm your Task assistant. Tell me what needs fixing and I'll write a "
  'clear summary for the right pro. You decide the price.',
  fromUser: false,
);

/// Drives the assistant conversation and the gather → price → confirm → post
/// flow. Information gathering is delegated to the AI; the deterministic price,
/// confirmation and publish steps are handled here so they cannot misfire.
class BookingChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState(messages: <ChatMessage>[_greeting]);

  Future<void> send(String text) async {
    final String value = text.trim();
    if (value.isEmpty || state.typing) return;

    switch (state.phase) {
      case ChatPhase.awaitingPrice:
        _handlePriceReply(value);
      case ChatPhase.awaitingConfirm:
        await _handleConfirmReply(value);
      case ChatPhase.posted:
        _appendUser(value);
        _appendAssistant(
          'Your request is already live with technicians. Tap "New request" '
          'below to start another one.',
        );
      case ChatPhase.gathering:
        await _handleGatherReply(value);
    }
  }

  // ── Gathering: the AI asks questions until it has a usable draft ──────────
  Future<void> _handleGatherReply(String value) async {
    final List<ChatMessage> withUser = <ChatMessage>[
      ...state.messages,
      ChatMessage(value, fromUser: true),
    ];
    state = state.copyWith(messages: withUser, typing: true);

    final AssistantTurn turn =
        await ref.read(assistantServiceProvider).respond(withUser);

    final bool ready = turn.ready && turn.draft != null;
    state = ChatState(
      messages: <ChatMessage>[
        ...withUser,
        ChatMessage(turn.reply, fromUser: false),
        if (ready) const ChatMessage(_priceAsk, fromUser: false),
      ],
      pendingDraft: ready ? turn.draft : state.pendingDraft,
      typing: false,
      phase: ready ? ChatPhase.awaitingPrice : ChatPhase.gathering,
    );
  }

  // ── Price: parse the amount the customer is willing to pay ───────────────
  void _handlePriceReply(String value) {
    _appendUser(value);
    final int? price = _parsePrice(value);
    final JobRequestDraft? draft = state.pendingDraft;
    if (price == null || price <= 0 || draft == null) {
      _appendAssistant(
        "I didn't catch a price there. About how much would you like to pay, "
        'in EGP? For example "400".',
      );
      return;
    }
    final JobRequestDraft priced = draft.copyWith(fixedPrice: price);
    state = state.copyWith(
      pendingDraft: priced,
      phase: ChatPhase.awaitingConfirm,
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(_confirmText(priced), fromUser: false),
      ],
    );
  }

  // ── Confirm: publish to the technician marketplace, or reopen ────────────
  Future<void> _handleConfirmReply(String value) async {
    _appendUser(value);
    if (_isYes(value)) {
      final JobRequestDraft? draft = state.pendingDraft;
      if (draft == null || !draft.isValid) {
        state = state.copyWith(phase: ChatPhase.gathering);
        _appendAssistant(
          "Something's missing from the request — let's go over it again. "
          "What's the problem?",
        );
        return;
      }
      state = state.copyWith(typing: true);
      await ref.read(jobMarketplaceRepositoryProvider).publish(draft);
      state = state.copyWith(
        typing: false,
        clearPending: true,
        phase: ChatPhase.posted,
        messages: <ChatMessage>[
          ...state.messages,
          const ChatMessage(
            "Done — your request is now live for technicians to review. "
            "You'll start getting offers shortly.",
            fromUser: false,
          ),
        ],
      );
      return;
    }
    if (_isNo(value)) {
      state = state.copyWith(phase: ChatPhase.awaitingPrice);
      _appendAssistant(
        'No problem. What would you like to change? Tell me a new price, or '
        'describe anything about the job you want to adjust.',
      );
      return;
    }
    _appendAssistant(
      'Just to confirm — should I post this for technicians? Reply "yes" to '
      'post, or "no" to change something.',
    );
  }

  // ── Public hooks kept for the price-card UI / tests ──────────────────────
  void setPrice(int price) {
    final JobRequestDraft? draft = state.pendingDraft;
    if (draft == null) return;
    state = state.copyWith(pendingDraft: draft.copyWith(fixedPrice: price));
  }

  Future<void> publishPending() async {
    final JobRequestDraft? draft = state.pendingDraft;
    if (draft == null || !draft.isValid) return;
    await ref.read(jobMarketplaceRepositoryProvider).publish(draft);
    state = state.copyWith(clearPending: true, phase: ChatPhase.posted);
  }

  void reset() => state = build();

  // ── Helpers ──────────────────────────────────────────────────────────────
  void _appendUser(String value) => state = state.copyWith(
        messages: <ChatMessage>[
          ...state.messages,
          ChatMessage(value, fromUser: true),
        ],
      );

  void _appendAssistant(String value) => state = state.copyWith(
        messages: <ChatMessage>[
          ...state.messages,
          ChatMessage(value, fromUser: false),
        ],
      );

  static int? _parsePrice(String value) {
    final RegExpMatch? m = RegExp(r'\d[\d,]*').firstMatch(value);
    if (m == null) return null;
    return int.tryParse(m.group(0)!.replaceAll(',', ''));
  }

  static String _confirmText(JobRequestDraft d) {
    final String cat = d.category?.displayLabel ?? 'service';
    return 'Here\'s your request:\n\n• $cat — ${d.title}\n• You pay: '
        'EGP ${d.fixedPrice}\n\nShall I post this for technicians to review? '
        'Reply "yes" to post, or "no" to change something.';
  }

  static bool _isYes(String v) {
    final String t = v.toLowerCase().trim();
    const List<String> yes = <String>[
      'yes', 'yeah', 'yep', 'yup', 'sure', 'ok', 'okay', 'confirm', 'post',
      'go ahead', 'publish', 'do it', 'نعم', 'اه', 'تمام', 'انشر',
    ];
    return yes.any((String w) => t == w || t.contains(w));
  }

  static bool _isNo(String v) {
    final String t = v.toLowerCase().trim();
    const List<String> no = <String>[
      'no', 'nope', 'cancel', 'change', 'edit', 'wait', 'لا', 'الغاء', 'غير',
    ];
    return no.any((String w) => t == w || t.contains(w));
  }
}

const String _priceAsk =
    "Great — I've got everything I need. What would you like to pay for this "
    'service, in EGP?';

final bookingChatProvider =
    NotifierProvider<BookingChatController, ChatState>(BookingChatController.new);
