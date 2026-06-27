import 'dart:async';
import 'dart:math' as math;

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
import 'package:task_domain/task_domain.dart';

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
  static const Duration _minDwell = Duration(milliseconds: 2000);
  static const Duration _reducedDwell = Duration(milliseconds: 600);

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
  // Slow, continuous orbit of the service glyphs around the mark.
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
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
  // Pointer parallax lives in its own notifier so hover never rebuilds the
  // (expensive) masked-logo tree — only the wrapping Transform listens.
  final ValueNotifier<Offset> _parallax = ValueNotifier<Offset>(Offset.zero);
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
      _orbit.repeat();
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
    _orbit.dispose();
    _exit.dispose();
    _parallax.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerHoverEvent event, Size size) {
    final dx = (event.localPosition.dx - size.width / 2) / size.width;
    final dy = (event.localPosition.dy - size.height / 2) / size.height;
    _parallax.value = Offset(dx * 14, dy * 14);
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
                        iconTheme: IconThemeData(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
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
                      _buildBrand(reduceMotion),
                      const SizedBox(height: AppSpacing.lg),
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: <Widget>[
                              Builder(builder: (context) {
                                final bool isDark = Theme.of(context).brightness == Brightness.dark;
                                return Column(
                                  children: <Widget>[
                                    Text(
                                      'Task',
                                      style: AppTypography.wordmark(
                                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                                      ).copyWith(
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: AppColors.primary.withValues(alpha: isDark ? 0.55 : 0.25),
                                            blurRadius: 28,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      l10n.tagline,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondary.withValues(alpha: 0.8)
                                            : AppColors.textSecondaryLight,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 6),
                      // Slim loading cue — replaces the old progress bar + CTA.
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: reduceMotion
                              ? const SizedBox.shrink()
                              : FadeTransition(
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

  // Signature: the service constellation. The category trades orbit the mark,
  // each settling into place on a staggered intro — "every home service, one
  // app." Under reduced motion the glyphs are simply placed, no orbit.
  static const List<JobCategory> _orbitCats = <JobCategory>[
    JobCategory.plumbing,
    JobCategory.electrical,
    JobCategory.ac,
    JobCategory.painting,
    JobCategory.cleaning,
    JobCategory.carpentry,
  ];

  Widget _buildBrand(bool reduceMotion) {
    const double field = 300;
    const double ringRadius = 124;
    // The masked logo (two nested ShaderMasks over a decoded JPG) is the most
    // expensive thing on screen. Build it once per build() and cache it behind a
    // RepaintBoundary so the breathing scale/glow just composite the cached
    // layer each frame instead of re-running the shaders.
    final Widget maskedLogo = RepaintBoundary(child: _maskedLogo(context));
    return ValueListenableBuilder<Offset>(
      valueListenable: _parallax,
      builder: (context, parallax, child) => Transform.translate(
        offset: parallax,
        child: child,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge(
            <Listenable>[_intro, _pulseCurve, _orbit]),
        builder: (context, _) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          return SizedBox(
            width: field,
            height: field,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Faint orbit guide ring.
                Opacity(
                  opacity: _logoFade.value * 0.5,
                  child: Container(
                    width: ringRadius * 2,
                    height: ringRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                // Orbiting service glyphs.
                for (int i = 0; i < _orbitCats.length; i++)
                  _orbitGlyph(i, ringRadius, reduceMotion, isDark),
                // Center mark — wraps the cached logo with the live glow/scale.
                _logoCore(maskedLogo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orbitGlyph(int i, double radius, bool reduceMotion, bool isDark) {
    final JobCategory cat = _orbitCats[i];
    final Color tint = categoryTint(cat);

    // Staggered settle-in: each glyph enters slightly after the previous.
    final double start = 0.2 + i * 0.09;
    final double raw = ((_intro.value - start) / 0.4).clamp(0.0, 1.0);
    final double t = Curves.easeOutBack.transform(raw);

    final double base = (math.pi * 2 / _orbitCats.length) * i - math.pi / 2;
    final double spin = reduceMotion ? 0 : _orbit.value * math.pi * 2;
    final double angle = base + spin;

    // Glyphs drift in from the center as they settle.
    final double r = radius * t;
    final Offset pos = Offset(math.cos(angle) * r, math.sin(angle) * r);

    return Transform.translate(
      offset: pos,
      child: Opacity(
        opacity: raw,
        child: Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF15102C).withValues(alpha: 0.85)
                  : AppColors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: tint.withValues(alpha: isDark ? 0.5 : 0.6)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: tint.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(categoryIcon(cat), color: tint, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _logoCore(Widget maskedLogo) {
    final double breathe = _pulseCurve.value; // 0 → 1
    final double scale = _logoScale.value * (1 + 0.03 * breathe);
    final double glowAlpha = 0.26 + 0.16 * breathe;
    return Opacity(
      opacity: _logoFade.value,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 188,
          height: 188,
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
              maskedLogo,
            ],
          ),
        ),
      ),
    );
  }

  /// The brand mark with all four edges dissolved into the page via two nested
  /// ShaderMasks (horizontal + vertical). The pixels never change, so this is
  /// built once per build() and cached by the caller — only the breathing
  /// scale/glow wrap it each frame.
  Widget _maskedLogo(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String asset = isDark
        ? 'assets/images/task_logo.jpg'
        : 'assets/images/task_logo_light.jpg';
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00FFFFFF),
          Colors.white,
          Colors.white,
          Color(0x00FFFFFF),
        ],
        stops: <double>[0.0, 0.20, 0.80, 1.0],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x00FFFFFF),
            Colors.white,
            Colors.white,
            Color(0x00FFFFFF),
          ],
          stops: <double>[0.0, 0.20, 0.80, 1.0],
        ).createShader(rect),
        child: Image.asset(
          asset,
          width: 150,
          height: 150,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'Task',
        ),
      ),
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
            child: Builder(builder: (context) {
              final bool isDark = Theme.of(context).brightness == Brightness.dark;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
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

/// Full-bleed background: adapts to light/dark.
/// Dark: diagonal violet→black identity with bloom and shadow pool.
/// Light: clean white→lavender gradient so the brand mark stays vivid.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
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
    // Light mode: white base with a soft lavender bloom at the top-left corner.
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(color: AppColors.backgroundLight),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.85, -1.0),
              radius: 1.4,
              colors: <Color>[Color(0x447C3AED), Color(0x00000000)],
            ),
          ),
        ),
      ],
    );
  }
}
