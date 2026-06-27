import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';
import '../services/category_l10n.dart';

/// Read-only history of the user's past (completed or cancelled) bookings,
/// pulled per-user from Firestore via [myJobsProvider].
class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  static const String routePath = '/profile/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<List<JobRequest>> jobsAsync = ref.watch(myJobsProvider);

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent, title: Text(l.bookingHistory)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text(l.error(e.toString()))),
              data: (List<JobRequest> jobs) {
                final List<JobRequest> past = jobs
                    .where((JobRequest j) =>
                        j.status == JobStatus.completed ||
                        j.status == JobStatus.cancelled)
                    .toList();
                if (past.isEmpty) return _empty(context, text, l);
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: <Widget>[
                    for (final JobRequest j in past) _card(context, j, text, l),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, JobRequest job, TextTheme text,
      AppLocalizations l) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color, IconData) badge = switch (job.status) {
      JobStatus.completed => (AppColors.success, Icons.check_circle),
      JobStatus.cancelled => (AppColors.error, Icons.cancel),
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
          color:
              isDark ? AppColors.surface.withValues(alpha: 0.5) : Colors.white,
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
                      Text(categoryLabel(job.category, l),
                          style: text.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                    .withValues(alpha: 0.6)
                                : AppColors.textSecondaryLight,
                          )),
                      const SizedBox(height: 6),
                      StatusPill(
                          label: jobStatusLabel(job.status, l),
                          tint: badge.$1,
                          icon: badge.$2),
                    ],
                  ),
                ),
                Text('${job.settledPrice} ${l.egp}',
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, TextTheme text, AppLocalizations l) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.receipt_long_rounded,
              size: 44,
              color: isDark
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(l.noPastJobs,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
