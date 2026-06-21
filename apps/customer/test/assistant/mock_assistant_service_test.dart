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
