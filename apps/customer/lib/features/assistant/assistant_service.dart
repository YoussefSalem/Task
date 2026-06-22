import 'package:customer/l10n/app_localizations.dart';
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
