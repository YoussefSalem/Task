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
