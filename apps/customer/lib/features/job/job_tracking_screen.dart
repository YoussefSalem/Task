import 'package:customer/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../booking/booking_state.dart';
import '../marketplace/marketplace_providers.dart';

/// Live job tracking. A stylized map shows the pro approaching; the stage
/// timeline advances en route → in progress → complete. On completion the
/// customer pays and rates. Progression is timed for the prototype.
class JobTrackingScreen extends ConsumerStatefulWidget {
  const JobTrackingScreen({super.key});

  static const String routePath = '/job/live';

  @override
  ConsumerState<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends ConsumerState<JobTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    final bool reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduce) _move.forward();
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final List<JobRequest> jobs =
        ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
    final JobRequest? job = jobs.where((j) =>
        j.status == JobStatus.accepted ||
        j.status == JobStatus.enRoute ||
        j.status == JobStatus.inProgress ||
        j.status == JobStatus.completed).isEmpty
        ? (jobs.isNotEmpty ? jobs.first : null)
        : jobs.where((j) =>
            j.status == JobStatus.accepted ||
            j.status == JobStatus.enRoute ||
            j.status == JobStatus.inProgress ||
            j.status == JobStatus.completed).first;
    final int stageIndex = _stageIndexFromStatus(job?.status);
    final JobStage stage = _stageFromStatus(job?.status);
    final TextTheme text = Theme.of(context).textTheme;
    final bool done = stage == JobStage.completed;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: _Map(progress: _move, arrived: stageIndex > 0),
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
            child: _sheet(job, text, done, stage, stageIndex),
          ),
        ],
      ),
    );
  }

  Widget _sheet(JobRequest? job, TextTheme text, bool done, JobStage stage, int stageIndex) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);
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
                label: done ? l.done : l.etaMinutes(8),
                tint: done ? AppColors.success : AppColors.primary,
                icon: done ? Icons.check_circle : Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _proRow(job, text),
          const SizedBox(height: AppSpacing.lg),
          _timeline(text, stageIndex),
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
                  child: _ghostAction(Icons.chat_bubble_outline_rounded, l.chat),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ghostAction(Icons.call_rounded, l.call),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _proRow(JobRequest? job, TextTheme text) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String pro = job?.acceptedOffer?.technicianName ?? l.techNameKhaled;
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary,
          child: Text(
            pro.split(' ').map((String s) => s[0]).take(2).join(),
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
              Text(job?.title ?? l.homeService,
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary.withValues(alpha: 0.65)
                        : AppColors.textSecondaryLight,
                  )),
            ],
          ),
        ),
        const Row(
          children: <Widget>[
            Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 3),
            Text('4.9'),
          ],
        ),
      ],
    );
  }

  Widget _timeline(TextTheme text, int stageIndex) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<(JobStage, String)> steps = <(JobStage, String)>[
      (JobStage.enRoute, l.headingToAddress),
      (JobStage.inProgress, l.workingOnJob),
      (JobStage.completed, l.jobCompleted),
    ];
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _timelineRow(
            steps[i].$2,
            done: i < stageIndex,
            active: i == stageIndex,
            last: i == steps.length - 1,
            text: text,
          ),
      ],
    );
  }

  Widget _timelineRow(String label,
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

  Widget _ghostAction(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).featureOpensComms(label))));
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

/// Stylized dark map: grid streets, a route line, and the pro marker gliding
/// toward the destination pin.
class _Map extends StatelessWidget {
  const _Map({required this.progress, required this.arrived});
  final Animation<double> progress;
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF161E2E), Color(0xFF0E1320)],
        ),
      ),
      child: AnimatedBuilder(
        animation: progress,
        builder: (BuildContext context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _MapPainter(arrived ? 1.0 : progress.value),
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = const Color(0x10FFFFFF)
      ..strokeWidth = 1;
    const double step = 44;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final Offset start = Offset(size.width * 0.2, size.height * 0.28);
    final Offset end = Offset(size.width * 0.78, size.height * 0.5);
    final Path route = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(start.dx, end.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.5)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Destination pin.
    canvas.drawCircle(end, 9,
        Paint()..color = const Color(0xFF34D399));
    canvas.drawCircle(end, 9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Moving pro marker along the L-shaped route.
    final double vLen = (end.dy - start.dy).abs();
    final double hLen = (end.dx - start.dx).abs();
    final double total = vLen + hLen;
    final double travelled = t * total;
    Offset pos;
    if (travelled <= vLen) {
      pos = Offset(start.dx, start.dy + travelled);
    } else {
      pos = Offset(start.dx + (travelled - vLen), end.dy);
    }
    canvas.drawCircle(pos, 16,
        Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.35));
    canvas.drawCircle(pos, 9, Paint()..color = const Color(0xFF7C3AED));
    canvas.drawCircle(pos, 9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.t != t;
}
