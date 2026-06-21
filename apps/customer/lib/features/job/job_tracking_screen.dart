import 'dart:async';

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

  static const List<JobStage> _flow = <JobStage>[
    JobStage.enRoute,
    JobStage.inProgress,
    JobStage.completed,
  ];
  int _stageIndex = 0;
  final List<Timer> _timers = <Timer>[];

  JobStage get _stage => _flow[_stageIndex];

  @override
  void initState() {
    super.initState();
    final bool reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduce) _move.forward();
    _timers.add(Timer(Duration(milliseconds: reduce ? 200 : 6000), () {
      if (mounted) setState(() => _stageIndex = 1);
    }));
    _timers.add(Timer(Duration(milliseconds: reduce ? 400 : 11000), () {
      if (mounted) setState(() => _stageIndex = 2);
    }));
  }

  @override
  void dispose() {
    _move.dispose();
    for (final Timer t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final JobRequest? job =
        ref.watch(myJobsProvider).valueOrNull?.isEmpty == false
            ? ref.watch(myJobsProvider).valueOrNull!.first
            : null;
    final TextTheme text = Theme.of(context).textTheme;
    final bool done = _stage == JobStage.completed;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: _Map(progress: _move, arrived: _stageIndex > 0),
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
            child: _sheet(job, text, done),
          ),
        ],
      ),
    );
  }

  Widget _sheet(JobRequest? job, TextTheme text, bool done) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
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
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(_stage.title,
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              StatusPill(
                label: done ? 'Done' : 'ETA 8 min',
                tint: done ? AppColors.success : AppColors.primary,
                icon: done ? Icons.check_circle : Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _proRow(job, text),
          const SizedBox(height: AppSpacing.lg),
          _timeline(text),
          const SizedBox(height: AppSpacing.lg),
          if (done)
            GlowButton(
              label: 'Pay & finish',
              icon: Icons.check_rounded,
              onPressed: () => context.push('/book/payment?stage=settle'),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _ghostAction(Icons.chat_bubble_outline_rounded, 'Chat'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ghostAction(Icons.call_rounded, 'Call'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _proRow(JobRequest? job, TextTheme text) {
    const String pro = 'Khaled Mansour';
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
              Text(job?.title ?? 'Home service',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
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

  Widget _timeline(TextTheme text) {
    const List<(JobStage, String)> steps = <(JobStage, String)>[
      (JobStage.enRoute, 'Heading to your address'),
      (JobStage.inProgress, 'Working on the job'),
      (JobStage.completed, 'Job completed'),
    ];
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _timelineRow(
            steps[i].$2,
            done: i < _stageIndex,
            active: i == _stageIndex,
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
    final Color color = done || active ? AppColors.primary : const Color(0x33FFFFFF);
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
                color: done ? AppColors.primary : const Color(0x22FFFFFF),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(label,
              style: text.bodyMedium?.copyWith(
                color: active || done
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
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
          ..showSnackBar(SnackBar(content: Text('$label opens in the comms phase.')));
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: Color(0x33FFFFFF)),
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
