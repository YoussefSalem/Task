import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../job/job_tracking_screen.dart';

@immutable
class ActiveJob {
  const ActiveJob({
    required this.techName,
    required this.category,
    required this.status,
    required this.eta,
    this.photoUrl,
  });
  final String techName;
  final JobCategory category;
  final JobStatus status;
  final Duration eta;
  final String? photoUrl;

  String get statusLine => switch (status) {
        JobStatus.accepted => 'Confirmed — preparing to head out',
        JobStatus.enRoute =>
          '${categoryLabel(category)} arriving in ${eta.inMinutes} min',
        JobStatus.inProgress => '${categoryLabel(category)} is working',
        JobStatus.pausedForApproval => 'Waiting for your approval',
        _ => 'Job active',
      };

  double get progress => switch (status) {
        JobStatus.accepted => 0.15,
        JobStatus.enRoute => 0.40,
        JobStatus.inProgress => 0.70,
        JobStatus.pausedForApproval => 0.85,
        _ => 0.5,
      };

  IconData get statusIcon => switch (status) {
        JobStatus.accepted => Icons.check_circle_outline_rounded,
        JobStatus.enRoute => Icons.directions_car_rounded,
        JobStatus.inProgress => Icons.build_rounded,
        JobStatus.pausedForApproval => Icons.pause_circle_outline_rounded,
        _ => Icons.work_outline_rounded,
      };

  static String categoryLabel(JobCategory c) => switch (c) {
        JobCategory.plumbing => 'Plumber',
        JobCategory.electrical => 'Electrician',
        JobCategory.ac => 'AC Technician',
        JobCategory.cleaning => 'Cleaner',
        JobCategory.carpentry => 'Carpenter',
        JobCategory.painting => 'Painter',
        _ => 'Technician',
      };
}

/// Holds the currently active job, or null when idle.
/// For the prototype this is seeded with mock data; in production it would
/// listen to a Firestore stream.
final activeJobProvider = StateProvider<ActiveJob?>((ref) {
  return const ActiveJob(
    techName: 'Mohamed Ali',
    category: JobCategory.electrical,
    status: JobStatus.enRoute,
    eta: Duration(minutes: 15),
  );
});

/// Floating card shown on home when a job is active. Tapping opens the
/// full tracking screen. Includes a progress bar and live status line.
class ActiveJobCard extends ConsumerWidget {
  const ActiveJobCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(activeJobProvider);
    if (job == null) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final tint = categoryTint(job.category);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(JobTrackingScreen.routePath),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface.withValues(alpha: 0.55) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: tint.withValues(alpha: 0.30)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: tint.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(job.statusIcon, color: tint, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(job.statusLine,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(job.techName,
                          style: text.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondary.withValues(alpha: 0.65)
                                : AppColors.textSecondaryLight,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textSecondaryLight,
                    size: 22),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0x18000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: job.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              tint.withValues(alpha: 0.7),
                              tint,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: tint.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _StepDot(label: 'Confirmed', active: job.progress >= 0.15, tint: tint, isDark: isDark),
                _StepLine(filled: job.progress >= 0.40, tint: tint, isDark: isDark),
                _StepDot(label: 'En route', active: job.progress >= 0.40, tint: tint, isDark: isDark),
                _StepLine(filled: job.progress >= 0.70, tint: tint, isDark: isDark),
                _StepDot(label: 'Working', active: job.progress >= 0.70, tint: tint, isDark: isDark),
                _StepLine(filled: job.progress >= 1.0, tint: tint, isDark: isDark),
                _StepDot(label: 'Done', active: job.progress >= 1.0, tint: tint, isDark: isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.active,
    required this.tint,
    required this.isDark,
  });
  final String label;
  final bool active;
  final Color tint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? tint
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0x22000000)),
            boxShadow: active
                ? <BoxShadow>[BoxShadow(color: tint.withValues(alpha: 0.4), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                  : (isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textSecondaryLight),
            )),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.filled, required this.tint, required this.isDark});
  final bool filled;
  final Color tint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: filled
              ? tint.withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0x18000000)),
        ),
      ),
    );
  }
}
