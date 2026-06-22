import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../assistant/ai_chat_screen.dart';

/// Bottom-nav shell. The four destinations (Home · My Jobs · Wallet · Profile)
/// sit in a frosted, floating pill that hovers over the content (Uber-style),
/// split around a raised AI-assistant button in the center.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const String homeRouteName = 'home';
  static const String homeRoutePath = '/home';
  static const String jobsRouteName = 'jobs';
  static const String jobsRoutePath = '/jobs';
  static const String messagesRouteName = 'messages';
  static const String messagesRoutePath = '/messages';
  static const String profileRouteName = 'profile';
  static const String profileRoutePath = '/profile';

  /// Space the floating bar occupies, so scroll content can clear it.
  static const double barClearance = 112;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _goBranch,
              onAi: () => context.push(AiChatScreen.routePath),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAi,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, bottomInset + AppSpacing.md),
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            // Frosted floating pill — adapts to light / dark.
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Builder(builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B2130).withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x26FFFFFF)
                          : const Color(0x18000000),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      _navItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _navItem(context, 1, Icons.handyman_outlined, Icons.handyman_rounded, 'My Jobs'),
                      const Spacer(), // gap for the raised AI button
                      _navItem(context, 2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages'),
                      _navItem(context, 3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                    ],
                  ),
                );
                }),
              ),
            ),
            // Raised center AI button.
            Positioned(
              top: -14,
              child: _AiButton(onTap: onAi),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon,
      IconData activeIcon, String label) {
    final bool active = index == currentIndex;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark: light-gray at 75% α on dark frosted pill ≈ 5:1.
    // Light: near-black secondary on white frosted pill ≈ 6.7:1.
    final Color inactiveColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.75)
        : AppColors.textSecondaryLight;
    return Expanded(
      child: InkResponse(
        onTap: () => onTap(index),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(active ? activeIcon : icon,
                size: 24,
                color: active ? AppColors.primary : inactiveColor),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : inactiveColor,
                )),
          ],
        ),
      ),
    );
  }
}

/// The raised AI-assistant button. Tiny sparkle particles drift upward around
/// the button like bubbles in sparkling water, with a subtle glow breathe.
/// Respects reduced-motion. The outer ring uses the scaffold background so the
/// button appears to float above the pill in both light and dark themes.
class _AiButton extends StatefulWidget {
  const _AiButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton>
    with TickerProviderStateMixin {
  // Ambient breathe + bubble particles (existing).
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  // Tap burst ring: 0 → 1 on each tap, then reset.
  late final AnimationController _tapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _anim.stop();
      _anim.value = 0;
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final bool reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduce) {
      setState(() => _pressed = true);
      // Burst ring expands while button springs back.
      unawaited(_tapCtrl.forward(from: 0).then((_) => _tapCtrl.reset()));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _pressed = false);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask the AI assistant',
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_anim, _tapCtrl]),
          builder: (context, child) {
            final double glow =
                Curves.easeInOut.transform(_anim.value * 2 % 1.0);
            final double burst = _tapCtrl.value; // 0 → 1

            return SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Ambient bubble particles.
                  CustomPaint(
                    size: const Size(74, 74),
                    painter: _BubblePainter(_anim.value),
                  ),
                  // Burst ring — expands and fades on each tap.
                  if (burst > 0)
                    Opacity(
                      opacity: (1 - burst).clamp(0, 1),
                      child: Transform.scale(
                        scale: 1.0 + burst * 0.72,
                        child: Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.85),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Main button with press-scale feedback.
                  AnimatedScale(
                    scale: _pressed ? 0.91 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeIn,
                    child: Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFF8B5CF6),
                            Color(0xFF6D28D9)
                          ],
                        ),
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 4),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(
                                alpha: 0.42 + 0.12 * glow),
                            blurRadius: 20 + 4 * glow,
                            spreadRadius: -2 + 2 * glow,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            );
          },
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

/// Paints 8 tiny dots that rise and fade like sparkling water bubbles.
/// Each bubble has a staggered phase so they don't move in unison.
class _BubblePainter extends CustomPainter {
  _BubblePainter(this.t);
  final double t; // 0..1 repeating

  static const int _count = 8;
  // Deterministic per-bubble offsets (angle around center, phase stagger).
  static const List<double> _angles = <double>[
    0.3, 1.1, 1.9, 2.5, 3.3, 4.0, 4.8, 5.6,
  ];
  static const List<double> _phases = <double>[
    0.0, 0.12, 0.28, 0.42, 0.55, 0.68, 0.78, 0.90,
  ];
  static const List<double> _sizes = <double>[
    2.0, 1.6, 2.2, 1.4, 1.8, 2.0, 1.5, 1.7,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double innerR = 27; // starts at button edge
    final double outerR = 37; // max drift distance

    for (int i = 0; i < _count; i++) {
      final double p = (t + _phases[i]) % 1.0;
      // Each bubble lives for 60% of the cycle, staggered by phase.
      final double life = (p / 0.6).clamp(0.0, 1.0);
      if (life >= 1.0) continue;

      final double r = innerR + (outerR - innerR) * Curves.easeOut.transform(life);
      final double angle = _angles[i];
      final double alpha = (1.0 - life) * 0.7;

      final Offset pos = center + Offset(
        r * math.cos(angle),
        r * math.sin(angle) - life * 6, // slight upward drift
      );

      canvas.drawCircle(
        pos,
        _sizes[i] * (0.6 + 0.4 * (1 - life)),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}
