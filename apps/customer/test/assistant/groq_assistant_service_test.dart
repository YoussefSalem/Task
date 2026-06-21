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
