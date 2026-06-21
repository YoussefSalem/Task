import 'package:task_domain/task_domain.dart';

import 'assistant_service.dart';

/// Maps free text to a [JobCategory] by keyword, or null if nothing matches.
JobCategory? categoryFromKeywords(String text) {
  final String t = text.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(<String>['ac', 'air con', 'cooling', 'cool', 'compressor',
      'condition'])) {
    return JobCategory.ac;
  }
  if (has(<String>['leak', 'drip', 'sink', 'pipe', 'tap', 'faucet', 'toilet',
      'plumb'])) {
    return JobCategory.plumbing;
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
