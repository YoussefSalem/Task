import 'package:customer/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../booking/booking_state.dart';
import '../marketplace/marketplace_providers.dart';
import '../services/category_l10n.dart';
import 'tracking_providers.dart';

/// Google Static Maps key (Maps Static API must be enabled on it). Shared with
/// the matching + location screens; duplicated as a const to keep features
/// self-contained.
const String _mapsKey = 'AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA';

/// Live job tracking. A real map shows the technician's last reported position;
/// the stage timeline advances en route → in progress → complete. On completion
/// the customer pays and rates. All data is read from Firestore — no mock seed.
class JobTrackingScreen extends ConsumerWidget {
  const JobTrackingScreen({super.key});

  static const String routePath = '/job/live';

  /// The job the tracking screen follows: the hired job in progress, else the
  /// most recently completed one (so the pay/rate step is still reachable).
  JobRequest? _trackedJob(List<JobRequest> jobs) {
    const Set<JobStatus> live = <JobStatus>{
      JobStatus.accepted,
      JobStatus.enRoute,
      JobStatus.inProgress,
      JobStatus.pausedForApproval,
    };
    for (final JobRequest j in jobs) {
      if (live.contains(j.status)) return j;
    }
    for (final JobRequest j in jobs) {
      if (j.status == JobStatus.completed) return j;
    }
    return null;
  }

  int _stageIndexFromStatus(JobStatus? status) => switch (status) {
        JobStatus.enRoute => 0,
        JobStatus.inProgress => 1,
        JobStatus.completed => 2,
        _ => 0,
      };

  JobStage _stageFromStatus(JobStatus? status) => switch (status) {
        JobStatus.enRoute => JobStage.enRoute,
        JobStatus.inProgress => JobStage.inProgress,
        JobStatus.completed => JobStage.completed,
        _ => JobStage.enRoute,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<JobRequest> jobs =
        ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
    final JobRequest? job = _trackedJob(jobs);
    final TextTheme text = Theme.of(context).textTheme;

    if (job == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Text(l.noActiveJob,
              style: text.titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
        ),
      );
    }

    final TrackingPoint? point =
        ref.watch(jobTrackingProvider(job.id)).valueOrNull;
    final int stageIndex = _stageIndexFromStatus(job.status);
    final JobStage stage = _stageFromStatus(job.status);
    final bool done = stage == JobStage.completed;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: _LiveMap(point: point)),
          if (point == null && !done)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _MapChip(label: l.awaitingLiveLocation),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: CircleAvatar(
                  backgroundColor: AppColors.background.withValues(alpha: 0.7),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/home'),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _sheet(context, l, job, text, done, stage, stageIndex, point),
          ),
        ],
      ),
    );
  }

  Widget _sheet(BuildContext context, AppLocalizations l, JobRequest job,
      TextTheme text, bool done, JobStage stage, int stageIndex,
      TrackingPoint? point) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String etaLabel = done
        ? l.done
        : (point?.etaMinutes != null
            ? l.etaMinutes(point!.etaMinutes!)
            : jobStatusLabel(job.status, l));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x12000000),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33FFFFFF) : const Color(0x22000000),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(stage.title(l),
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              StatusPill(
                label: etaLabel,
                tint: done ? AppColors.success : AppColors.primary,
                icon: done ? Icons.check_circle : Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _proRow(context, l, job, text),
          const SizedBox(height: AppSpacing.lg),
          _timeline(context, l, text, stageIndex),
          const SizedBox(height: AppSpacing.lg),
          if (done)
            GlowButton(
              label: l.payAndFinish,
              icon: Icons.check_rounded,
              onPressed: () => context.push('/book/payment?stage=settle'),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _ghostAction(
                      context, l, Icons.chat_bubble_outline_rounded, l.chat),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ghostAction(context, l, Icons.call_rounded, l.call),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _proRow(BuildContext context, AppLocalizations l, JobRequest job,
      TextTheme text) {
    final Offer? offer = job.acceptedOffer;
    final String pro = (offer?.technicianName.isNotEmpty ?? false)
        ? offer!.technicianName
        : categoryLabel(job.category, l);
    final String initials = pro
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .map((String s) => s[0])
        .take(2)
        .join();
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary,
          child: Text(
            initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(pro,
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(job.title,
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary.withValues(alpha: 0.65)
                        : AppColors.textSecondaryLight,
                  )),
            ],
          ),
        ),
        if (offer != null && offer.rating > 0)
          Row(
            children: <Widget>[
              const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 3),
              Text(offer.rating.toStringAsFixed(1)),
            ],
          ),
      ],
    );
  }

  Widget _timeline(BuildContext context, AppLocalizations l, TextTheme text,
      int stageIndex) {
    final List<(JobStage, String)> steps = <(JobStage, String)>[
      (JobStage.enRoute, l.headingToAddress),
      (JobStage.inProgress, l.workingOnJob),
      (JobStage.completed, l.jobCompleted),
    ];
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _timelineRow(
            context,
            steps[i].$2,
            done: i < stageIndex,
            active: i == stageIndex,
            last: i == steps.length - 1,
            text: text,
          ),
      ],
    );
  }

  Widget _timelineRow(BuildContext context, String label,
      {required bool done,
      required bool active,
      required bool last,
      required TextTheme text}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = done || active
        ? AppColors.primary
        : (isDark ? const Color(0x33FFFFFF) : const Color(0x33000000));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!last)
              Container(
                width: 2,
                height: 22,
                color: done
                    ? AppColors.primary
                    : (isDark ? const Color(0x22FFFFFF) : const Color(0x22000000)),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(label,
              style: text.bodyMedium?.copyWith(
                color: active || done
                    ? Theme.of(context).colorScheme.onSurface
                    : (isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textSecondaryLight),
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              )),
        ),
      ],
    );
  }

  Widget _ghostAction(
      BuildContext context, AppLocalizations l, IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l.featureOpensComms(label))));
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x33FFFFFF)
              : const Color(0x33000000),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

/// Small frosted chip overlaid on the map for status text.
class _MapChip extends StatelessWidget {
  const _MapChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// The map layer. When the technician has reported a position, a Google Static
/// Maps image centred on it (with a marker) renders over a plain backdrop. With
/// no position yet, only the backdrop shows — no invented route or marker.
class _LiveMap extends StatelessWidget {
  const _LiveMap({required this.point});
  final TrackingPoint? point;

  @override
  Widget build(BuildContext context) {
    final TrackingPoint? p = point;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF161E2E), Color(0xFF0E1320)],
            ),
          ),
        ),
        if (p != null)
          Image.network(
            'https://maps.googleapis.com/maps/api/staticmap'
            '?center=${p.lat},${p.lng}'
            '&zoom=15'
            '&size=640x640'
            '&scale=2'
            '&maptype=roadmap'
            '&markers=color:0x7C3AED%7C${p.lat},${p.lng}'
            '&key=$_mapsKey',
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            frameBuilder: (context, child, frame, wasSync) =>
                (wasSync || frame != null) ? child : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
