import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';

/// The Bookings tab: live + upcoming jobs first, history below. Tapping an
/// active job returns to live tracking.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<JobRequest>> jobsAsync = ref.watch(myJobsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.1),
        SafeArea(
          bottom: false,
          child: jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, _) => Center(child: Text('Error: $e')),
            data: (List<JobRequest> jobs) {
              final List<JobRequest> active = jobs
                  .where((JobRequest j) =>
                      j.status != JobStatus.completed &&
                      j.status != JobStatus.cancelled)
                  .toList();
              final List<JobRequest> past = jobs
                  .where((JobRequest j) =>
                      j.status == JobStatus.completed ||
                      j.status == JobStatus.cancelled)
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 112),
                children: <Widget>[
                  Text(AppLocalizations.of(context).yourBookings,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xl),
                  if (active.isNotEmpty) ...<Widget>[
                    SectionHeader(title: AppLocalizations.of(context).activeAndUpcoming),
                    const SizedBox(height: AppSpacing.md),
                    ...active.map((JobRequest j) => _card(context, j, text,
                        onTap: () => context.push('/job/live'))),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SectionHeader(title: AppLocalizations.of(context).history),
                  const SizedBox(height: AppSpacing.md),
                  if (past.isEmpty)
                    _empty(text)
                  else
                    ...past.map((JobRequest j) => _card(context, j, text)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, JobRequest job, TextTheme text,
      {VoidCallback? onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color, IconData) badge = switch (job.status) {
      JobStatus.completed => (AppColors.success, Icons.check_circle),
      JobStatus.inProgress => (AppColors.primary, Icons.bolt),
      JobStatus.accepted => (AppColors.warning, Icons.event),
      _ => (AppColors.textSecondary, Icons.circle),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isDark ? null : Border.all(color: const Color(0x12000000)),
        ),
        child: Material(
          color: isDark ? AppColors.surface.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: categoryTint(job.category).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(categoryIcon(job.category),
                        color: categoryTint(job.category)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(job.title,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(job.category.displayLabel,
                            style: text.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                                  : AppColors.textSecondaryLight,
                            )),
                        const SizedBox(height: 6),
                        StatusPill(
                            label: job.status.name,
                            tint: badge.$1,
                            icon: badge.$2),
                      ],
                    ),
                  ),
                  Text('${job.settledPrice} EGP',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(TextTheme text) {
    return Builder(builder: (context) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Icon(Icons.receipt_long_rounded,
                size: 44,
                color: isDark
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('No past jobs yet',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    });
  }
}
