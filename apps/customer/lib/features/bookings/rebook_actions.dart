import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/job_create_stub_screen.dart';
import '../marketplace/marketplace_providers.dart';

/// Footer actions on a past-booking card: re-book the same service in one tap,
/// or reschedule (same details, opened for editing first). Both seed the job
/// draft from [job] and land on the post-a-job screen — Re-book is emphasised.
class RebookActions extends ConsumerWidget {
  const RebookActions({super.key, required this.job});

  final JobRequest job;

  void _startFrom(BuildContext context, WidgetRef ref) {
    ref.read(jobDraftProvider.notifier).startFrom(job);
    context.push(JobCreateStubScreen.routePath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton.icon(
          onPressed: () => _startFrom(context, ref),
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: Text(l.reschedule),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: () => _startFrom(context, ref),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(l.rebook),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
