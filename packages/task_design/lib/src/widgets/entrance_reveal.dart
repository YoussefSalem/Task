import 'package:flutter/material.dart';

/// A one-shot entrance animation: the child fades up into place on first build.
///
/// Drop it around the sections of a screen and pass an increasing [index] to
/// stagger them, so the page assembles itself top-to-bottom instead of snapping
/// in all at once. The motion plays exactly once per mount and never rebuilds
/// the child, so it is cheap to scatter across a list.
///
/// Respects the platform "reduce motion" setting — when animations are disabled
/// the child is shown immediately with no transform.
class EntranceReveal extends StatefulWidget {
  const EntranceReveal({
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 460),
    this.offset = 18,
    super.key,
  });

  final Widget child;

  /// Position in the stagger sequence; later items start later.
  final int index;

  /// Delay added per [index] step.
  final Duration stagger;

  /// Length of each item's fade-up.
  final Duration duration;

  /// Vertical travel, in logical pixels, the child rises through.
  final double offset;

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );
  late final Animation<double> _rise = Tween<double>(begin: widget.offset, end: 0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _c.value = 1;
    } else {
      // Stagger the start; the per-item curve handles the rest.
      Future<void>.delayed(widget.stagger * widget.index, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _rise.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
