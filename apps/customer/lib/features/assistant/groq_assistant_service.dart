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
