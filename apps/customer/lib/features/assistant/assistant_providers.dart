// apps/customer/lib/features/assistant/assistant_providers.dart
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:task_domain/task_domain.dart';

import '../chat/chat_providers.dart';
import '../localization/locale_controller.dart';
import '../marketplace/marketplace_providers.dart';
import '../services/category_l10n.dart';
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
  final AppLocalizations l =
      lookupAppLocalizations(ref.watch(localeControllerProvider));
  if (_kGroqKey.isEmpty) return MockAssistantService(l);
  return GroqAssistantService(
    client: ref.watch(httpClientProvider),
    apiKey: _kGroqKey,
    l: l,
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

/// Drives the assistant conversation and the gather → price → confirm → post
/// flow. Information gathering is delegated to the AI; the deterministic price,
/// confirmation and publish steps are handled here so they cannot misfire.
class BookingChatController extends Notifier<ChatState> {
  /// Localized strings in the active locale, for the deterministic copy this
  /// controller generates (greeting, price/confirm prompts, post messages).
  AppLocalizations get _l =>
      lookupAppLocalizations(ref.read(localeControllerProvider));

  @override
  ChatState build() => ChatState(
      messages: <ChatMessage>[ChatMessage(_l.assistantGreeting, fromUser: false)]);

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
        _appendAssistant(_l.assistantAlreadyLive);
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
        if (ready) ChatMessage(_l.assistantPriceAsk, fromUser: false),
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
      _appendAssistant(_l.assistantNoPriceCaught);
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
        _appendAssistant(_l.assistantSomethingMissing);
        return;
      }
      state = state.copyWith(typing: true);
      try {
        await ref
            .read(jobMarketplaceRepositoryProvider)
            .publish(draft)
            .timeout(const Duration(seconds: 15));
        await _notifyPosted();
      } catch (e, st) {
        // Publish threw (e.g. rejected write, signed out) or never reached the
        // backend (timeout). Recover: drop the typing indicator, keep the draft
        // and stay on confirm so the customer can reply "yes" to retry.
        debugPrint('[assistant] publish failed: $e\n$st');
        state = state.copyWith(typing: false);
        _appendAssistant(_l.assistantPostFailed);
        return;
      }
      state = state.copyWith(
        typing: false,
        clearPending: true,
        phase: ChatPhase.posted,
        messages: <ChatMessage>[
          ...state.messages,
          ChatMessage(_l.assistantPosted, fromUser: false),
        ],
      );
      return;
    }
    if (_isNo(value)) {
      state = state.copyWith(phase: ChatPhase.awaitingPrice);
      _appendAssistant(_l.assistantWhatToChange);
      return;
    }
    _appendAssistant(_l.assistantJustConfirm);
  }

  /// Drop a "request posted" entry into the customer's own feed so the bell
  /// badge and notifications screen light up the moment a job goes live.
  Future<void> _notifyPosted() async {
    final String? uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(notificationRepositoryProvider).notify(
          recipientUid: uid,
          draft: NotificationDraft(
            type: NotificationType.jobStatus,
            title: _l.notifPostedTitle,
            body: _l.notifPostedBody,
          ),
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

  String _confirmText(JobRequestDraft d) {
    final String cat =
        d.category != null ? categoryLabel(d.category!, _l) : _l.serviceWord;
    // gen-l10n orders these positional params alphabetically by placeholder
    // name — (cat, price, title) — not in template order. Pass price then title
    // to match, or the summary shows the price and description swapped.
    return _l.assistantConfirm(cat, d.fixedPrice, d.title);
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

final bookingChatProvider =
    NotifierProvider<BookingChatController, ChatState>(BookingChatController.new);
