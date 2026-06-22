import 'package:customer/l10n/app_localizations.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Full-screen celebratory animation shown once a job request has been posted
/// to the technician marketplace. Plays an expanding ring burst, a stroke-drawn
/// checkmark, radiating sparkles and a rising headline, then calls [onDone] so
/// the caller can route the customer home.
class PostedSuccessOverlay extends StatefulWidget {
  const PostedSuccessOverlay({required this.onDone, super.key});

  /// Invoked once, when the animation has finished playing.
  final VoidCallback onDone;

  @override
  State<PostedSuccessOverlay> createState() => _PostedSuccessOverlayState();
}

class _PostedSuccessOverlayState extends State<PostedSuccessOverlay>
    with TickerProviderStateMixin {
  // One-shot timeline for the whole sequence.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // Continuous gentle pulse behind the badge.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  late final Animation<double> _badge = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.30, curve: Curves.easeOutBack),
  );
  late final Animation<double> _check = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.22, 0.50, curve: Curves.easeInOut),
  );
  late final Animation<double> _sparks = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
  );
  late final Animation<double> _hint = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.62, 0.85, curve: Curves.easeOut),
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _c.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(
            intensity: 0.18,
            alignment: Alignment(0, -0.35),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                _badgeStack(),
                const SizedBox(height: AppSpacing.xxl),
                _risingText(
                  'All set! 🎉',
                  text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  _text,
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: _risingText(
                    'Your request is live — technicians are reviewing it now '
                    'and will send you offers shortly.',
                    text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    _text,
                    align: TextAlign.center,
                  ),
                ),
                const Spacer(),
                _takingHome(text),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStack() {
    const double badge = 132;
    return SizedBox(
      width: badge * 2.2,
      height: badge * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Continuous soft pulse rings.
          AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, _) {
              return CustomPaint(
                size: const Size.square(badge * 2.2),
                painter: _PulsePainter(_pulse.value),
              );
            },
          ),
          // Radiating sparkles on the one-shot timeline.
          AnimatedBuilder(
            animation: _sparks,
            builder: (BuildContext context, _) {
              return CustomPaint(
                size: const Size.square(badge * 2.2),
                painter: _SparkPainter(_sparks.value),
              );
            },
          ),
          // The badge: scales in, with the checkmark stroking on.
          AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_badge, _check]),
            builder: (BuildContext context, _) {
              return Transform.scale(
                scale: _badge.value.clamp(0.0, 1.0),
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF34D399), AppColors.success],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.45),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _CheckPainter(_check.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _risingText(
    String value,
    TextStyle? style,
    Animation<double> anim, {
    TextAlign align = TextAlign.center,
  }) {
    return AnimatedBuilder(
      animation: anim,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - anim.value)),
            child: child,
          ),
        );
      },
      child: Text(value, textAlign: align, style: style),
    );
  }

  Widget _takingHome(TextTheme text) {
    return AnimatedBuilder(
      animation: _hint,
      builder: (BuildContext context, Widget? child) {
        return Opacity(opacity: _hint.value.clamp(0.0, 1.0), child: child);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Taking you home…',
            style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Two staggered expanding rings that fade as they grow.
class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double base = size.width * 0.30;
    for (int i = 0; i < 2; i++) {
      final double p = (t + i * 0.5) % 1.0;
      final double radius = base + base * 1.2 * p;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.success.withValues(alpha: (1 - p) * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}

/// Eight small dots flung outward from the badge, fading as they travel.
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final Offset center = size.center(Offset.zero);
    final double start = size.width * 0.26;
    final double travel = size.width * 0.22;
    final Paint paint = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: (1 - t) * 0.9);
    for (int i = 0; i < 8; i++) {
      final double angle = (math.pi * 2 / 8) * i - math.pi / 2;
      final double r = start + travel * Curves.easeOut.transform(t);
      final Offset p = center +
          Offset(math.cos(angle) * r, math.sin(angle) * r);
      canvas.drawCircle(p, 3.5 * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.t != t;
}

/// Draws the checkmark progressively from 0 → 1.
class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final double w = size.width;
    final double h = size.height;
    final Offset a = Offset(w * 0.30, h * 0.52);
    final Offset b = Offset(w * 0.44, h * 0.66);
    final Offset c = Offset(w * 0.72, h * 0.36);

    final double firstLen = (b - a).distance;
    final double secondLen = (c - b).distance;
    final double total = firstLen + secondLen;
    final double drawn = total * progress;

    final Path path = Path()..moveTo(a.dx, a.dy);
    if (drawn <= firstLen) {
      final double t = firstLen == 0 ? 1 : drawn / firstLen;
      path.lineTo(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
    } else {
      path.lineTo(b.dx, b.dy);
      final double t = (drawn - firstLen) / secondLen;
      path.lineTo(b.dx + (c.dx - b.dx) * t, b.dy + (c.dy - b.dy) * t);
    }

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
