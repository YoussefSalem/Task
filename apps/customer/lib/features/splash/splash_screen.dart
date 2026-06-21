import 'dart:async';

import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/auth/sign_in_screen.dart';
import 'package:customer/features/home/home_shell.dart';
import 'package:customer/features/localization/language_switcher.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

/// Uber-style entry: a brief, polished loading/transition screen. A violet→black
/// field flows to every edge; the glass Task logo sits in a pool of shadow ringed
/// by a breathing violet halo, with a slim shimmer line beneath the wordmark.
///
/// There is no user interaction. On launch the screen resolves auth state and,
/// after a short minimum dwell, fades out and routes: signed-in users to the
/// home shell, everyone else to sign-in.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Brief, deliberate dwell so the brand entrance never flashes by.
  static const Duration _minDwell = Duration(milliseconds: 1200);
  static const Duration _reducedDwell = Duration(milliseconds: 400);

  // Entrance: logo settles in, then the wordmark + tagline rise.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  // Ambient life: the logo glow and scale breathe slowly and forever.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  // Indeterminate loading sweep under the wordmark.
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  // Quick fade-through on exit, so the hand-off feels continuous.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.86, end: 1)
      .animate(CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  ));
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
  ));
  late final Animation<double> _pulseCurve = CurvedAnimation(
    parent: _pulse,
    curve: Curves.easeInOut,
  );

  bool _started = false; // one-time startup guard (reduced-motion known in build)
  bool _dwellDone = false;
  bool _navigated = false;
  Offset _parallax = Offset.zero;
  Timer? _dwellTimer;

  void _start(bool reduceMotion) {
    if (_started) return;
    _started = true;
    if (reduceMotion) {
      _intro.value = 1; // jump to resolved entrance, no breathing/shimmer
    } else {
      _intro.forward();
      _pulse.repeat(reverse: true);
      _shimmer.repeat();
    }
    _dwellTimer = Timer(reduceMotion ? _reducedDwell : _minDwell, () {
      _dwellDone = true;
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    if (_navigated || !mounted || !_dwellDone) return;
    final AsyncValue<Object?> auth = ref.read(authStateProvider);
    if (auth.isLoading) return; // wait until auth resolves
    _navigated = true;
    final bool signedIn = auth.value != null;
    final String dest =
        signedIn ? HomeShell.homeRoutePath : SignInScreen.routePath;
    _exit.forward().whenComplete(() {
      if (mounted) context.go(dest);
    });
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _intro.dispose();
    _pulse.dispose();
    _shimmer.dispose();
    _exit.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerHoverEvent event, Size size) {
    final dx = (event.localPosition.dx - size.width / 2) / size.width;
    final dy = (event.localPosition.dy - size.height / 2) / size.height;
    setState(() => _parallax = Offset(dx * 14, dy * 14));
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    _start(reduceMotion);

    // Navigate as soon as auth resolves (the dwell timer covers the other order).
    ref.listen<AsyncValue<Object?>>(authStateProvider, (previous, next) {
      _maybeNavigate();
    });

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _exit,
        builder: (context, child) =>
            Opacity(opacity: 1 - _exit.value, child: child),
        child: MouseRegion(
          onHover: reduceMotion
              ? null
              : (e) => _onPointerHover(e, MediaQuery.of(context).size),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _SplashBackground(),
              SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        iconTheme: const IconThemeData(
                            color: AppColors.textSecondary),
                      ),
                      child: const LanguageSwitcher(),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: <Widget>[
                      const Spacer(flex: 5),
                      _buildLogo(),
                      const SizedBox(height: AppSpacing.lg),
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: <Widget>[
                              Text(
                                'Task',
                                style: AppTypography.wordmark(
                                  color: AppColors.textPrimary,
                                ).copyWith(
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.55),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.tagline,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.8),
                                      letterSpacing: 0.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 6),
                      // Slim loading cue — replaces the old progress bar + CTA.
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: FadeTransition(
                            opacity: _textFade,
                            child: _ShimmerLine(animation: _shimmer),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_intro, _pulseCurve]),
      builder: (context, _) {
        final breathe = _pulseCurve.value; // 0 → 1
        final scale = _logoScale.value * (1 + 0.03 * breathe);
        final glowAlpha = 0.26 + 0.16 * breathe;
        return Transform.translate(
          offset: _parallax,
          child: Opacity(
            opacity: _logoFade.value,
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              AppColors.primary.withValues(alpha: glowAlpha),
                              const Color(0x00000000),
                            ],
                            stops: const <double>[0.32, 0.72],
                          ),
                        ),
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect rect) => const RadialGradient(
                        radius: 0.72,
                        colors: <Color>[
                          Colors.white,
                          Colors.white,
                          Color(0x00FFFFFF),
                        ],
                        stops: <double>[0.0, 0.56, 1.0],
                      ).createShader(rect),
                      child: Image.asset(
                        'assets/images/task_logo.jpg',
                        width: 232,
                        height: 232,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'Task',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A slim, indeterminate loading sweep: a faint static track with a violet
/// highlight that travels across it on a repeating controller.
class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.animation});

  final Animation<double> animation; // 0..1, repeating

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 2,
      child: Stack(
        children: <Widget>[
          // Faint static track.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Travelling highlight.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final double dx = animation.value * 3 - 1.5; // -1.5 → 1.5
                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect rect) => LinearGradient(
                    begin: Alignment(dx - 0.5, 0),
                    end: Alignment(dx + 0.5, 0),
                    colors: <Color>[
                      AppColors.primary.withValues(alpha: 0.0),
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.5, 1.0],
                  ).createShader(rect),
                  child: const ColoredBox(color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed background: a diagonal violet identity that settles into black,
/// an ambient top-corner bloom, and a large, softly-faded pool of pure shadow
/// centered on the logo.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF2A1257),
                Color(0xFF15102C),
                Color(0xFF09080F),
              ],
              stops: <double>[0.0, 0.5, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.85, -1.0),
              radius: 1.25,
              colors: <Color>[Color(0x557C3AED), Color(0x00000000)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.18),
              radius: 1.5,
              colors: <Color>[
                Color(0xFF000000),
                Color(0xFF000000),
                Color(0x00000000),
              ],
              stops: <double>[0.0, 0.32, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
