// apps/customer/test/assistant/booking_chat_controller_test.dart
import 'package:customer/features/assistant/assistant_providers.dart';
import 'package:customer/features/assistant/assistant_service.dart';
import 'package:customer/features/marketplace/marketplace_providers.dart';
import 'package:customer/features/marketplace/mock_job_marketplace_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';

/// Always returns a ready draft (price 0), like a finished gathering turn.
class _ReadyService implements AssistantService {
  @override
  Future<AssistantTurn> respond(List<ChatMessage> history) async {
    return AssistantTurn(
      reply: 'Summary ready.',
      ready: true,
      draft: const JobRequestDraft(
        category: JobCategory.plumbing,
        title: 'Leaking sink',
        description: 'Drip under the kitchen sink.',
      ),
    );
  }
}

void main() {
  late ProviderContainer container;
  late MockJobMarketplaceRepository repo;

  setUp(() {
    repo = MockJobMarketplaceRepository();
    container = ProviderContainer(overrides: <Override>[
      assistantServiceProvider.overrideWithValue(_ReadyService()),
      jobMarketplaceRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  test('send stores a pending draft with price 0', () async {
    await container.read(bookingChatProvider.notifier).send('sink leaks');
    final ChatState s = container.read(bookingChatProvider);
    expect(s.pendingDraft, isNotNull);
    expect(s.pendingDraft!.fixedPrice, 0);
    expect(s.messages.where((ChatMessage m) => m.fromUser).length, 1);
  });

  test('publishPending is a no-op until the customer sets a price', () async {
    final BookingChatController c =
        container.read(bookingChatProvider.notifier);
    await c.send('sink leaks');
    final int before = (await repo.watchMyJobs().first).length;

    await c.publishPending(); // price still 0 → invalid → nothing published
    expect((await repo.watchMyJobs().first).length, before);

    c.setPrice(400);
    await c.publishPending();
    final List<JobRequest> jobs = await repo.watchMyJobs().first;
    expect(jobs.length, before + 1);
    expect(jobs.first.fixedPrice, 400);
    expect(container.read(bookingChatProvider).pendingDraft, isNull);
  });

  test('in-chat flow: gather → price → confirm → posts to marketplace',
      () async {
    final BookingChatController c =
        container.read(bookingChatProvider.notifier);
    final int before = (await repo.watchMyJobs().first).length;

    // 1. Gathering — the ready service hands back a draft, we ask for a price.
    await c.send('sink leaks');
    expect(container.read(bookingChatProvider).phase, ChatPhase.awaitingPrice);

    // 2. Customer states a price in chat → moves to confirmation.
    await c.send('I can pay 350 EGP');
    ChatState s = container.read(bookingChatProvider);
    expect(s.phase, ChatPhase.awaitingConfirm);
    expect(s.pendingDraft!.fixedPrice, 350);

    // 3. Customer confirms → job is published and chat is in posted state.
    await c.send('yes');
    s = container.read(bookingChatProvider);
    expect(s.phase, ChatPhase.posted);
    expect(s.pendingDraft, isNull);

    final List<JobRequest> jobs = await repo.watchMyJobs().first;
    expect(jobs.length, before + 1);
    expect(jobs.first.fixedPrice, 350);
  });

  test('in-chat flow: unparseable price re-asks without advancing', () async {
    final BookingChatController c =
        container.read(bookingChatProvider.notifier);
    await c.send('sink leaks');
    await c.send('not sure yet');
    expect(container.read(bookingChatProvider).phase, ChatPhase.awaitingPrice);
  });
}
