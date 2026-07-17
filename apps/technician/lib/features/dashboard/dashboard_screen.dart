import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/tech_colors.dart';
import '../../util/money.dart';
import '../../widgets/tech_ambient.dart';
import '../home/tech_shell.dart';
import '../jobs/active_job_screen.dart';
import '../jobs/job_card.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/jobs_providers.dart';
import '../notifications/notification_providers.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/technician_profile.dart';

/// The pro's home base. The single most important control — the availability
/// toggle — leads, because everything downstream (dispatch, new jobs) depends on
/// it. Below it: today's money, the job in progress, and the freshest openings.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(techProfileProvider).valueOrNull;
    final List<JobRequest> history = ref.watch(myHistoryProvider);
    final JobRequest? active = ref.watch(primaryActiveJobProvider);
    final int bidCount = ref.watch(myBidsProvider).length;
    // Only customers actively looking near this pro — never phantom/stale demand.
    final List<JobRequest> open = ref.watch(nearbyJobsProvider);

    final int totalEarned =
        history.fold<int>(0, (sum, j) => sum + j.settledPrice);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient(intensity: 0.14)),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(openJobsProvider);
                ref.invalidate(myEngagementsProvider);
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                    AppSpacing.lg, TechShell.barClearance),
                children: <Widget>[
                  _Header(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  EntranceReveal(child: _AvailabilityCard(profile: profile)),
                  const SizedBox(height: AppSpacing.lg),
                  EntranceReveal(
                    index: 1,
                    child: _EarningsRow(
                      totalEarned: totalEarned,
                      jobsDone: profile?.jobsDone ?? history.length,
                      rating: profile?.rating ?? 0,
                    ),
                  ),
                  if (active != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'On the job'),
                    const SizedBox(height: AppSpacing.md),
                    EntranceReveal(
                      index: 2,
                      child: _ActiveJobBanner(job: active),
                    ),
                  ],
                  Builder(builder: (context) {
                    final List<JobRequest> scheduled =
                        ref.watch(myScheduledJobsProvider);
                    if (scheduled.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader(title: 'Upcoming schedule'),
                        const SizedBox(height: AppSpacing.md),
                        ...scheduled.map((j) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _ScheduledRow(job: j),
                            )),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'New jobs nearby',
                    actionLabel: open.isEmpty ? null : 'See all',
                    onAction: open.isEmpty
                        ? null
                        : () => context.goNamed(TechShell.jobsRouteName),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (bidCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _BidsHint(
                        count: bidCount,
                        onTap: () => context.goNamed(TechShell.jobsRouteName),
                      ),
                    ),
                  if (open.isEmpty)
                    _EmptyJobs(online: profile?.available ?? false)
                  else
                    ...open.take(4).toList().asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: EntranceReveal(
                              index: 3 + e.key,
                              child: JobCard(
                                job: e.value,
                                onTap: () => context.pushNamed(
                                  JobDetailScreen.routeName,
                                  pathParameters: <String, String>{
                                    'jobId': e.value.id
                                  },
                                ),
                              ),
                            ),
                          ),
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

class _Header extends ConsumerWidget {
  const _Header({required this.profile});
  final TechProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    final String name = (profile?.firstName ?? '').isEmpty
        ? 'there'
        : profile!.firstName;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Welcome back',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  )),
              Text(name,
                  style: text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        _BellButton(unread: unread),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => context.pushNamed(ProfileScreen.routeName),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary.withValues(alpha: 0.16),
            backgroundImage: profile?.photoUrl != null
                ? NetworkImage(profile!.photoUrl!)
                : null,
            child: profile?.photoUrl == null
                ? Text(profile?.initials ?? '?',
                    style: TextStyle(
                        color: scheme.primary, fontWeight: FontWeight.w800))
                : null,
          ),
        ),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconButton(
          onPressed: () => context.pushNamed(NotificationsScreen.routeName),
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
          style: IconButton.styleFrom(
            backgroundColor: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The lead control: go online to start receiving jobs.
class _AvailabilityCard extends ConsumerWidget {
  const _AvailabilityCard({required this.profile});
  final TechProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool online = profile?.available ?? false;
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = online ? TechColors.online : TechColors.offline;

    Future<void> toggle() async {
      final repo = ref.read(techProfileRepositoryProvider);
      if (repo == null) return;
      await repo.setAvailability(!online);
    }

    return GestureDetector(
      onTap: toggle,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: online
                ? <Color>[const Color(0xFF0F766E), const Color(0xFF10B981)]
                : <Color>[const Color(0xFF334155), const Color(0xFF475569)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: tint.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _PulseDot(active: online),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    online ? "You're online" : "You're offline",
                    style: text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    online
                        ? 'Accepting jobs and visible to customers.'
                        : 'Tap to go online and start receiving jobs.',
                    style: text.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Switch(
              value: online,
              onChanged: (_) => toggle(),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        active ? Icons.bolt_rounded : Icons.power_settings_new_rounded,
        color: Colors.white,
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  const _EarningsRow({
    required this.totalEarned,
    required this.jobsDone,
    required this.rating,
  });

  final int totalEarned;
  final int jobsDone;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: _StatCard(
            label: 'Earned',
            value: egpLabel(totalEarned),
            icon: Icons.payments_rounded,
            tint: TechColors.earnings,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: _StatCard(
            label: 'Jobs',
            value: '$jobsDone',
            icon: Icons.check_circle_rounded,
            tint: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: _StatCard(
            label: 'Rating',
            value: rating > 0 ? rating.toStringAsFixed(1) : '—',
            icon: Icons.star_rounded,
            tint: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: tint, size: 20),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  )),
        ],
      ),
    );
  }
}

class _ActiveJobBanner extends StatelessWidget {
  const _ActiveJobBanner({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.pushNamed(
          ActiveJobScreen.routeName,
          pathParameters: <String, String>{'jobId': job.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon(job.category), color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      job.title.isEmpty
                          ? job.category.displayLabel
                          : job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _statusLabel(job.status),
                      style: text.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(egpLabel(job.settledPrice),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  )),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledRow extends StatelessWidget {
  const _ScheduledRow({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime at = job.scheduledAt!;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.pushNamed(
          ActiveJobScreen.routeName,
          pathParameters: <String, String>{'jobId': job.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(DateFormat('MMM').format(at),
                        style: text.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(DateFormat('d').format(at),
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        job.title.isEmpty
                            ? job.category.displayLabel
                            : job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(DateFormat('EEE · h:mm a').format(at),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BidsHint extends StatelessWidget {
  const _BidsHint({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(Icons.gavel_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '$count active ${count == 1 ? 'bid' : 'bids'} — waiting on customers',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.inbox_rounded,
              size: 40, color: scheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(
            online ? 'No customers looking right now' : "You're offline",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            online
                ? 'When a customer nearby is looking for a technician, their job appears here.'
                : 'Go online above to see jobs customers are posting nearby.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(JobStatus s) => switch (s) {
      JobStatus.accepted => 'Hired — head over when ready',
      JobStatus.enRoute => 'On your way',
      JobStatus.inProgress => 'Work in progress',
      JobStatus.pausedForApproval => 'Waiting on customer approval',
      _ => 'Active',
    };
