import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../util/money.dart';
import '../../widgets/tech_ambient.dart';
import '../chat/chat_screen.dart';
import '../home/tech_shell.dart';
import 'active_job_screen.dart';
import 'job_card.dart';
import 'job_detail_screen.dart';
import 'jobs_providers.dart';
import 'map/jobs_map_screen.dart';

/// The job board. Two lenses: the pro's own work ("My work" — active jobs and
/// pending bids, each opening the customer conversation) and the open market
/// ("Available"). A trade filter narrows the open market to the pro's lane.
class JobFeedScreen extends ConsumerStatefulWidget {
  const JobFeedScreen({super.key});

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen> {
  int _tab = 0; // 0 = My work (active + bids), 1 = Available
  JobCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final String? uid = ref.watch(currentUidProvider);
    final AsyncValue<List<JobRequest>> openAsync = ref.watch(openJobsProvider);
    final List<JobRequest> nearby = ref.watch(nearbyJobsProvider);
    final List<JobRequest> myBids = ref.watch(myBidsProvider);
    final List<JobRequest> active = ref.watch(myActiveJobsProvider);
    final int workCount = active.length + myBids.length;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient(intensity: 0.12)),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      Text('Jobs',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_tab == 1) ...<Widget>[
                        IconButton(
                          tooltip: 'Map view',
                          icon: const Icon(Icons.map_rounded),
                          onPressed: () =>
                              context.pushNamed(JobsMapScreen.routeName),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _TradeFilterButton(
                          selected: _filter,
                          onSelected: (c) => setState(() => _filter = c),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _Segmented(
                    labels: <String>[
                      'My work${workCount > 0 ? ' ($workCount)' : ''}',
                      'Available',
                    ],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _tab == 0
                      ? _MyWorkList(active: active, bids: myBids, uid: uid)
                      : _AvailableList(
                          openAsync: openAsync,
                          jobs: nearby,
                          uid: uid,
                          filter: _filter,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// The pro's own work: the jobs they're hired on and the bids awaiting a
/// customer decision. Every row opens the customer conversation so the pro can
/// message quickly; active jobs also expose an "Open" shortcut to the workspace.
class _MyWorkList extends StatelessWidget {
  const _MyWorkList({
    required this.active,
    required this.bids,
    required this.uid,
  });

  final List<JobRequest> active;
  final List<JobRequest> bids;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (active.isEmpty && bids.isEmpty) {
      return const _FeedEmpty(
        icon: Icons.work_history_rounded,
        title: 'No active jobs or bids',
        body: 'Jobs you’re hired on and bids you’ve placed show up here, '
            'ready to message the customer.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, TechShell.barClearance),
      children: <Widget>[
        if (active.isNotEmpty) ...<Widget>[
          const _WorkSectionHeader(label: 'Active jobs'),
          const SizedBox(height: AppSpacing.sm),
          ...active.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _WorkRow(job: j, uid: uid, isActive: true),
              )),
        ],
        if (bids.isNotEmpty) ...<Widget>[
          if (active.isNotEmpty) const SizedBox(height: AppSpacing.md),
          const _WorkSectionHeader(label: 'Pending bids'),
          const SizedBox(height: AppSpacing.sm),
          ...bids.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _WorkRow(job: j, uid: uid, isActive: false),
              )),
        ],
      ],
    );
  }
}

class _WorkSectionHeader extends StatelessWidget {
  const _WorkSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ));
  }
}

/// One active job or pending bid. Tapping opens the customer conversation; a
/// trailing "Open" affordance on active jobs jumps to the active-job workspace.
class _WorkRow extends StatelessWidget {
  const _WorkRow({
    required this.job,
    required this.uid,
    required this.isActive,
  });

  final JobRequest job;
  final String? uid;
  final bool isActive;

  void _openChat(BuildContext context) {
    context.pushNamed(
      ChatScreen.routeName,
      pathParameters: <String, String>{'jobId': job.id},
      extra: ChatArgs(
        jobId: job.id,
        technicianId: uid ?? '',
        customerId: job.customerId,
        customerName: 'Customer',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = categoryTint(job.category);
    final int? myBid = uid == null
        ? null
        : job.offers
            .where((o) => o.technicianId == uid)
            .firstOrNull
            ?.currentPrice;
    final String subtitle = isActive
        ? _activeStatusLabel(job.status)
        : 'Your bid: ${egpLabel(myBid ?? job.fixedPrice)} · awaiting reply';

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => _openChat(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(categoryIcon(job.category), color: tint),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      job.title.isEmpty ? job.category.displayLabel : job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Primary affordance is chat (the whole row taps to it); this
              // icon reinforces it.
              Icon(Icons.chat_bubble_rounded, size: 20, color: scheme.primary),
              if (isActive) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: 'Open job',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.open_in_full_rounded,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                  onPressed: () => context.pushNamed(
                    ActiveJobScreen.routeName,
                    pathParameters: <String, String>{'jobId': job.id},
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _activeStatusLabel(JobStatus s) => switch (s) {
      JobStatus.accepted => 'Hired — head over when ready',
      JobStatus.enRoute => 'On your way',
      JobStatus.inProgress => 'Work in progress',
      JobStatus.pausedForApproval => 'Waiting on customer approval',
      _ => 'Active',
    };

class _AvailableList extends StatelessWidget {
  const _AvailableList({
    required this.openAsync,
    required this.jobs,
    required this.uid,
    required this.filter,
  });

  /// Only carries the load/error state; the data comes from [jobs] (already
  /// filtered to customers actively looking).
  final AsyncValue<List<JobRequest>> openAsync;
  final List<JobRequest> jobs;
  final String? uid;
  final JobCategory? filter;

  @override
  Widget build(BuildContext context) {
    if (openAsync.isLoading && jobs.isEmpty) return const _FeedLoading();
    if (openAsync.hasError && jobs.isEmpty) {
      return _FeedError(message: '${openAsync.error}');
    }
    final List<JobRequest> shown = filter == null
        ? jobs
        : jobs.where((j) => j.category == filter).toList();
    if (shown.isEmpty) {
      return _FeedEmpty(
        icon: Icons.travel_explore_rounded,
        title: filter == null ? 'No customers looking right now' : 'No matching jobs',
        body: filter == null
            ? 'When a customer nearby is looking for a technician, their job '
                'shows up here.'
            : 'No open ${filter!.displayLabel} jobs right now. Try clearing the '
                'filter.',
      );
    }
    return _JobListView(jobs: shown, uid: uid);
  }
}

class _JobListView extends StatelessWidget {
  const _JobListView({required this.jobs, required this.uid});
  final List<JobRequest> jobs;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, TechShell.barClearance),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final JobRequest job = jobs[i];
        final myOffer =
            job.offers.where((o) => o.technicianId == uid).firstOrNull;
        return EntranceReveal(
          index: i.clamp(0, 8),
          child: JobCard(
            job: job,
            myOfferAmount: myOffer?.currentPrice,
            onTap: () => context.pushNamed(
              JobDetailScreen.routeName,
              pathParameters: <String, String>{'jobId': job.id},
            ),
          ),
        );
      },
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (i) {
          final bool active = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active
                            ? scheme.onPrimary
                            : scheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TradeFilterButton extends StatelessWidget {
  const _TradeFilterButton({required this.selected, required this.onSelected});
  final JobCategory? selected;
  final ValueChanged<JobCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool on = selected != null;
    return ActionChip(
      avatar: Icon(
        on ? categoryIcon(selected!) : Icons.tune_rounded,
        size: 18,
        color: on ? categoryTint(selected!) : scheme.onSurface,
      ),
      label: Text(on ? selected!.displayLabel : 'Filter'),
      onPressed: () async {
        // Result: a JobCategory (pick), the string 'all' (clear), or null
        // (dismissed — leave the current filter untouched).
        final Object? picked = await showModalBottomSheet<Object?>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _TradePickerSheet(selected: selected),
        );
        if (picked == 'all') {
          onSelected(null);
        } else if (picked is JobCategory) {
          onSelected(picked);
        }
      },
    );
  }
}

class _TradePickerSheet extends StatelessWidget {
  const _TradePickerSheet({required this.selected});
  final JobCategory? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Filter by trade',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.clear_all_rounded),
            title: const Text('All trades'),
            selected: selected == null,
            onTap: () => Navigator.of(context).pop('all'),
          ),
          ...JobCategory.values.map((c) => ListTile(
                leading: Icon(categoryIcon(c), color: categoryTint(c)),
                title: Text(c.displayLabel),
                selected: selected == c,
                onTap: () => Navigator.of(context).pop(c),
              )),
        ],
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text('Could not load jobs.\n$message',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: scheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    )),
          ],
        ),
      ),
    );
  }
}
