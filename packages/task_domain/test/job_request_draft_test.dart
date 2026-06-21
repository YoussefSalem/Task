// packages/task_domain/test/job_request_draft_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

void main() {
  test('isValid requires a category, a title and a positive price', () {
    const JobRequestDraft empty = JobRequestDraft();
    expect(empty.isValid, isFalse);

    final JobRequestDraft full = const JobRequestDraft().copyWith(
      category: JobCategory.plumbing,
      title: 'Leaking sink',
      fixedPrice: 300,
    );
    expect(full.isValid, isTrue);
  });

  test('copyWith can clear the category', () {
    final JobRequestDraft d =
        const JobRequestDraft().copyWith(category: JobCategory.ac);
    expect(d.copyWith(clearCategory: true).category, isNull);
  });
}
