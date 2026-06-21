import 'package:customer/features/auth/sign_in_screen.dart';
import 'package:customer/features/localization/language_switcher.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

/// Branded splash / entry screen. A violet→black field flows smoothly to every
/// edge; the glass Task logo sits in a pool of pure shadow (so its baked black
/// backdrop dissolves) ringed by a breathing violet halo. A glowing progress
/// bar fills on launch and then hands off to the single "Get started" CTA,
/// which animates in — a deliberately futuristic, system-coming-to-life entry.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Entrance: logo settles in, then the wordmark + tagline rise.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // Launch progress: fills the bar, then reveals the CTA.
  late final AnimationController _load = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // Ambient life: the logo glow and scale breathe slowly and forever.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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

  bool _ready = false;
  bool _resolved = false; // reduced-motion fast-path guard
  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _pulse.repeat(reverse: true);
    _load.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _ready = true);
      }
    });
    _load.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _load.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerHoverEvent event, Size size) {
    // Subtle parallax drift toward the pointer (web/desktop only — no-op where
    // there is no hover device).
    final dx = (event.localPosition.dx - size.width / 2) / size.width;
    final dy = (event.localPosition.dy - size.height / 2) / size.height;
    setState(() => _parallax = Offset(dx * 14, dy * 14));
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && !_resolved) {
      // Jump straight to the resolved state — no progress wait, no breathing.
      _resolved = true;
      _intro.value = 1;
      _load.value = 1;
      _pulse.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _ready = true);
      });
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: MouseRegion(
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
                      iconTheme:
                          const IconThemeData(color: AppColors.textSecondary),
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
                    // Bottom slot: progress bar → CTA, fixed height so the
                    // hand-off doesn't shift the layout.
                    SizedBox(
                      height: 64,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 520),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.35),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _ready
                            ? _GetStartedButton(
                                key: const ValueKey<String>('cta'),
                                label: l10n.getStarted,
                                onPressed: () => context
                                    .pushNamed(SignInScreen.routeName),
                              )
                            : _LaunchProgress(
                                key: const ValueKey<String>('progress'),
                                progress: _load,
                                pulse: _pulseCurve,
                                label: l10n.loading,
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
                    // Breathing violet halo — the "ring" around the dark logo.
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
                    // Feather the logo's square edges so they melt into the
                    // shadow pool behind it.
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

/// The launch progress bar with its status label. A glowing fill sweeps left to
/// right; the label breathes to signal a live system.
class _LaunchProgress extends StatelessWidget {
  const _LaunchProgress({
    required this.progress,
    required this.pulse,
    required this.label,
    super.key,
  });

  final Animation<double> progress;
  final Animation<double> pulse;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: <Widget>[
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x33FFFFFF)),
                ),
                AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) {
                    return FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: progress.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 0.9).animate(pulse),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

/// The primary CTA, wrapped in a soft violet glow so it reads as the lit,
/// arrived endpoint of the launch sequence.
class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed background: a diagonal violet identity that settles into black,
/// an ambient top-corner bloom, and a large, softly-faded pool of pure shadow
/// centered on the logo. The pool's fade runs all the way to the edges, so the
/// logo's black backdrop dissolves with no visible disc — just one smooth field.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Base diagonal gradient: violet identity settling into near-black.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF2A1257), // deep violet
                Color(0xFF15102C), // indigo
                Color(0xFF09080F), // near-black
              ],
              stops: <double>[0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Ambient violet bloom from the top corner for life.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.85, -1.0),
              radius: 1.25,
              colors: <Color>[Color(0x557C3AED), Color(0x00000000)],
            ),
          ),
        ),
        // Pure-black pool centered on the logo. Opaque past the logo's corners,
        // then a long, gradual fade to transparent that reaches the screen
        // edges — no perceptible circle, just a smooth darkening toward center.
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
