import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../job/job_tracking_screen.dart';
import 'marketplace_providers.dart';

/// Placeholder for the full "describe → details → name your price → publish"
/// flow (built out in slice 2). Collects the minimum — title + fixed price —
/// for the seeded category, publishes, and enters tracking.
class JobCreateStubScreen extends ConsumerStatefulWidget {
  const JobCreateStubScreen({super.key});

  static const String routePath = '/job/create';
  static const String routeName = 'job-create';

  @override
  ConsumerState<JobCreateStubScreen> createState() => _JobCreateStubScreenState();
}

class _JobCreateStubScreenState extends ConsumerState<JobCreateStubScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _price = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _publish(JobCategory category) async {
    final int price = int.tryParse(_price.text.trim()) ?? 0;
    ref.read(jobDraftProvider.notifier).setTitle(_title.text.trim());
    ref.read(jobDraftProvider.notifier).setPrice(price);
    final JobRequestDraft draft = ref.read(jobDraftProvider);
    if (!draft.isValid) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text('Add a short title and a price above 0.')));
      return;
    }
    await ref.read(jobMarketplaceRepositoryProvider).publish(draft);
    if (!mounted) return;
    ref.read(jobDraftProvider.notifier).reset();
    context.go(JobTrackingScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final JobCategory category =
        ref.watch(jobDraftProvider).category ?? JobCategory.plumbing;
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Post a job')),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.12),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(children: <Widget>[
                    Icon(categoryIcon(category), color: categoryTint(category)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(category.displayLabel,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  Text('What problem are you having?', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                        hintText: 'e.g. Living-room lights keep flickering'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('What will you pay for this job? (EGP)',
                      style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 400'),
                  ),
                  const Spacer(),
                  GlowButton(
                    label: 'Publish job',
                    onPressed: () => _publish(category),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
