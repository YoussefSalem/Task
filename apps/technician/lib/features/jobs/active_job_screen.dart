import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/tech_colors.dart';
import '../../util/location_service.dart';
import '../../util/maps_launcher.dart';
import '../../util/money.dart';
import '../call/call_controller.dart';
import '../call/call_screen.dart';
import '../chat/chat_providers.dart';
import '../chat/chat_screen.dart';
import '../home/tech_shell.dart';
import '../profile/technician_profile.dart';
import 'jobs_providers.dart';

/// The on-site workspace for a job this pro is hired on. It owns the two things
/// a technician does after being hired: advance the job through its stages
/// (heading over → working → done) and broadcast a live location so the
/// customer can watch them approach.
class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({required this.jobId, super.key});

  final String jobId;

  static const String routeName = 'active-job';
  static const String routePath = '/active/:jobId';

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  static const LocationService _location = LocationService();
  static const Duration _interval = Duration(seconds: 15);

  Timer? _timer;
  bool _sharing = false;
  DateTime? _lastShared;
  bool _advancing = false;
  bool _assignmentSynced = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleSharing(bool on) async {
    if (!on) {
      _timer?.cancel();
      setState(() => _sharing = false);
      return;
    }
    final bool ok = await _location.ensurePermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location is off. Enable location access to share your arrival.'),
        ),
      );
      return;
    }
    setState(() => _sharing = true);
    await _sampleAndPublish();
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _sampleAndPublish());
  }

  Future<void> _sampleAndPublish() async {
    final fix = await _location.current();
    if (fix == null) return;
    final repo = ref.read(jobTrackingRepositoryProvider);
    try {
      await repo.publish(
        widget.jobId,
        TrackingPoint(lat: fix.lat, lng: fix.lng, at: DateTime.now()),
      );
      if (mounted) setState(() => _lastShared = DateTime.now());
    } catch (_) {/* best-effort; next tick retries */}
  }

  Future<void> _advance(JobRequest job) async {
    final JobStatus? next = _nextStatus(job.status);
    if (next == null || _advancing) return;

    if (next == JobStatus.completed) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Mark job complete?'),
          content: Text(
              'Confirm the work is done and ${egpLabel(job.settledPrice)} is settled with the customer.'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not yet')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Complete')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _advancing = true);
    final repo = ref.read(technicianJobsRepositoryProvider);
    try {
      await repo?.advanceStatus(job.id, next);
      // Keep the assignment join-table row in step with the job status.
      await _syncAssignment(job, next);
      // Tell the customer's in-app feed the job moved.
      if (job.customerId.isNotEmpty) {
        await ref.read(notificationRepositoryProvider).notify(
              recipientUid: job.customerId,
              draft: NotificationDraft(
                type: NotificationType.jobStatus,
                title: _notifyTitle(next),
                body: _notifyBody(next, job),
                actorId: ref.read(currentUidProvider),
                jobId: job.id,
              ),
            );
      }
      // Heading over → hand off to Google Maps navigation automatically.
      if (next == JobStatus.enRoute) {
        await _navigate(job);
      }
      // Stop broadcasting and credit the completed job once done.
      if (next == JobStatus.completed) {
        _timer?.cancel();
        if (mounted) setState(() => _sharing = false);
        await ref.read(techProfileRepositoryProvider)?.incrementJobsDone();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update the job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  /// Records/refreshes this job in the `job_assignments` join table. Called once
  /// when the workspace opens (so a freshly-hired job is linked) and again on
  /// each status change.
  Future<void> _syncAssignment(JobRequest job, JobStatus status) async {
    final repo = ref.read(technicianJobsRepositoryProvider);
    final profile = ref.read(techProfileProvider).valueOrNull;
    if (repo == null) return;
    try {
      await repo.upsertAssignment(
        job,
        technicianName:
            (profile?.fullName ?? '').isEmpty ? 'Technician' : profile!.fullName,
        status: status,
      );
    } catch (_) {/* best-effort link write */}
  }

  /// Opens Google Maps navigation to the customer's location. Surfaces a message
  /// only when there's nothing to route to.
  Future<void> _navigate(JobRequest job) async {
    final bool ok = await openDirections(
      lat: job.lat,
      lng: job.lng,
      address: job.locationLabel,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location on file for this job yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final JobRequest? job = ref.watch(jobByIdProvider(widget.jobId));

    if (job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Link this job into the assignments join table the first time we see it.
    if (!_assignmentSynced) {
      _assignmentSynced = true;
      final JobRequest linked = job;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _syncAssignment(linked, linked.status));
    }

    if (job.status == JobStatus.completed) {
      return _CompletedView(job: job);
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = categoryTint(job.category);
    final JobStatus? next = _nextStatus(job.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active job'),
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          IconButton(
            tooltip: 'Call customer',
            icon: const Icon(Icons.call_rounded),
            onPressed: () {
              final String room = job.acceptedOffer?.id ??
                  ref.read(currentUidProvider) ??
                  '';
              if (room.isEmpty) return;
              context.pushNamed(
                CallScreen.routeName,
                extra: CallArgs(roomId: room, peerName: 'Customer'),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          _JobSummary(job: job, tint: tint),
          const SizedBox(height: AppSpacing.xl),
          _StatusStepper(current: job.status),
          const SizedBox(height: AppSpacing.xl),
          _LocationCard(
            sharing: _sharing,
            lastShared: _lastShared,
            onChanged: _toggleSharing,
          ),
          Consumer(builder: (context, ref, _) {
            final TrackingPoint? point =
                ref.watch(jobTrackingProvider(widget.jobId)).valueOrNull;
            if (point == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _MiniMap(lat: point.lat, lng: point.lng),
            );
          }),
          if (job.hasCoordinates || job.locationLabel.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _navigate(job),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Navigate to customer'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _ContactCard(job: job),
        ],
      ),
      bottomNavigationBar: next == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              child: FilledButton.icon(
                onPressed: _advancing ? null : () => _advance(job),
                icon: Icon(_advanceIcon(job.status)),
                label: Text(_advanceLabel(job.status)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: job.status == JobStatus.inProgress
                      ? TechColors.online
                      : scheme.primary,
                ),
              ),
            ),
    );
  }
}

JobStatus? _nextStatus(JobStatus s) => switch (s) {
      JobStatus.accepted => JobStatus.enRoute,
      JobStatus.enRoute => JobStatus.inProgress,
      JobStatus.inProgress => JobStatus.completed,
      _ => null,
    };

String _notifyTitle(JobStatus s) => switch (s) {
      JobStatus.enRoute => 'Your pro is on the way',
      JobStatus.inProgress => 'Work has started',
      JobStatus.completed => 'Job completed',
      _ => 'Job update',
    };

String _notifyBody(JobStatus s, JobRequest job) => switch (s) {
      JobStatus.enRoute => 'Heading to ${job.category.displayLabel} now.',
      JobStatus.inProgress => 'Your ${job.category.displayLabel} job is underway.',
      JobStatus.completed =>
        'Marked complete · ${egpLabel(job.settledPrice)}. Please confirm & rate.',
      _ => job.category.displayLabel,
    };

IconData _advanceIcon(JobStatus s) => switch (s) {
      JobStatus.accepted => Icons.directions_car_rounded,
      JobStatus.enRoute => Icons.login_rounded,
      JobStatus.inProgress => Icons.check_circle_rounded,
      _ => Icons.check_rounded,
    };

String _advanceLabel(JobStatus s) => switch (s) {
      JobStatus.accepted => 'Start heading over',
      JobStatus.enRoute => "I've arrived — start work",
      JobStatus.inProgress => 'Mark job complete',
      _ => 'Continue',
    };

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.job, required this.tint});
  final JobRequest job;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon(job.category), color: tint),
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
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(job.category.displayLabel,
                        style: text.bodySmall?.copyWith(color: tint)),
                  ],
                ),
              ),
              Text(egpLabel(job.settledPrice),
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  )),
            ],
          ),
          if (job.locationLabel.isNotEmpty) ...<Widget>[
            const Divider(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                Icon(Icons.location_on_rounded,
                    size: 18, color: scheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(job.locationLabel, style: text.bodyMedium),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.current});
  final JobStatus current;

  static const List<(JobStatus, String, IconData)> _steps =
      <(JobStatus, String, IconData)>[
    (JobStatus.accepted, 'Hired', Icons.handshake_rounded),
    (JobStatus.enRoute, 'En route', Icons.directions_car_rounded),
    (JobStatus.inProgress, 'Working', Icons.build_rounded),
    (JobStatus.completed, 'Done', Icons.check_circle_rounded),
  ];

  int get _currentIndex {
    final int i = _steps.indexWhere((s) => s.$1 == current);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: List<Widget>.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final bool done = (i ~/ 2) < _currentIndex;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: done
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final int idx = i ~/ 2;
        final bool active = idx <= _currentIndex;
        final bool isCurrent = idx == _currentIndex;
        final (JobStatus, String, IconData) step = _steps[idx];
        return Column(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: active
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? <BoxShadow>[
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(step.$3,
                  size: 20,
                  color: active
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 6),
            Text(step.$2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: active
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.5),
                    )),
          ],
        );
      }),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.sharing,
    required this.lastShared,
    required this.onChanged,
  });

  final bool sharing;
  final DateTime? lastShared;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: sharing
            ? TechColors.online.withValues(alpha: 0.12)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: sharing
              ? TechColors.online.withValues(alpha: 0.4)
              : scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            sharing ? Icons.my_location_rounded : Icons.location_searching_rounded,
            color: sharing ? TechColors.online : scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(sharing ? 'Sharing your location' : 'Share live location',
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  sharing
                      ? (lastShared != null
                          ? 'Customer can track you · updated ${_secs(lastShared!)}'
                          : 'Getting your first position…')
                      : 'Let the customer watch you approach.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: sharing, onChanged: onChanged),
        ],
      ),
    );
  }

  String _secs(DateTime t) {
    final int s = DateTime.now().difference(t).inSeconds;
    if (s < 5) return 'just now';
    if (s < 60) return '${s}s ago';
    return '${s ~/ 60}m ago';
  }
}

/// A static Google map of the pro's last broadcast position. Read-only preview;
/// a full interactive map is a platform-split feature deferred for v1.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.lat, required this.lng});
  final double lat;
  final double lng;

  // Static Maps API key (the shared Maps key; Static Maps API is enabled).
  static const String _key = 'AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA';

  String get _url =>
      'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng'
      '&zoom=15&size=640x260&scale=2'
      '&markers=color:0x14B8A6%7C$lat,$lng&key=$_key';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AspectRatio(
        aspectRatio: 640 / 260,
        child: Image.network(
          _url,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => Container(
            color: scheme.surface,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.map_outlined,
                    color: scheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: AppSpacing.sm),
                Text('Location shared',
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  color: scheme.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.pushNamed(
          ChatScreen.routeName,
          pathParameters: <String, String>{'jobId': job.id},
          extra: ChatArgs(
            jobId: job.id,
            technicianId: ref.read(currentUidProvider) ?? '',
            customerId: job.customerId,
            customerName: 'Customer',
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Icon(Icons.chat_bubble_rounded, color: scheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Message the customer',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
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

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: TechColors.online.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: TechColors.online, size: 56),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Job complete',
                  style:
                      text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nice work. ${egpLabel(job.settledPrice)} is settled for this job.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      context.goNamed(TechShell.dashboardRouteName),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54)),
                  child: const Text('Back to dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
