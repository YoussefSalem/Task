import 'package:customer/features/marketplace/marketplace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  JobRequest pastJob() => JobRequest(
        id: 'job-1',
        category: JobCategory.electrical,
        title: 'Fix the porch light',
        description: 'Flickers at night.',
        fixedPrice: 350,
        urgency: Urgency.urgent,
        propertyType: PropertyType.villa,
        floor: '2',
        parking: true,
        photos: const <String>['/tmp/local-photo.jpg'],
        locationLabel: '12 Nile St',
        notes: 'Gate code 4321',
        status: JobStatus.completed,
        createdAt: DateTime(2026, 6, 1),
      );

  test('startFrom seeds the draft from a past job', () {
    container.read(jobDraftProvider.notifier).startFrom(pastJob());
    final JobRequestDraft draft = container.read(jobDraftProvider);

    expect(draft.category, JobCategory.electrical);
    expect(draft.title, 'Fix the porch light');
    expect(draft.description, 'Flickers at night.');
    expect(draft.fixedPrice, 350);
    expect(draft.urgency, Urgency.urgent);
    expect(draft.propertyType, PropertyType.villa);
    expect(draft.floor, '2');
    expect(draft.parking, isTrue);
    expect(draft.locationLabel, '12 Nile St');
    expect(draft.notes, 'Gate code 4321');
  });

  test('startFrom drops stale local photo paths', () {
    container.read(jobDraftProvider.notifier).startFrom(pastJob());
    expect(container.read(jobDraftProvider).photos, isEmpty);
  });

  test('the seeded draft is immediately valid for re-publishing', () {
    container.read(jobDraftProvider.notifier).startFrom(pastJob());
    expect(container.read(jobDraftProvider).isValid, isTrue);
  });
}
