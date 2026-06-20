import 'package:customer/features/auth/sign_in_screen.dart';
import 'package:customer/features/localization/language_switcher.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

/// Branded splash / entry screen. Deep violet→black gradient with the glass
/// Task logo pooled on a dark radial center (so its black backdrop blends and
/// the purple check appears lit), the wordmark below, and a single CTA.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.86, end: 1)
      .animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  ));
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
  ));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion: jump straight to the resolved state.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _SplashBackground(),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Theme(
                  // Ensure switcher icon reads on the dark gradient.
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(color: AppColors.textSecondary),
                  ),
                  child: const LanguageSwitcher(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 5),
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 72,
                              spreadRadius: -14,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: Image.asset(
                            'assets/images/task_logo.jpg',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'Task',
                          ),
                        ),
                      ),
                    ),
                  ),
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
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 6),
                  FadeTransition(
                    opacity: _textFade,
                    child: FilledButton(
                      onPressed: () =>
                          context.pushNamed(SignInScreen.routeName),
                      child: Text(l10n.getStarted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layered background: diagonal brand gradient, an off-center purple bloom for
/// life, and a dark radial pool centered behind the logo.
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
                Color(0xFF2E1065), // deep violet
                Color(0xFF14102E), // indigo
                Color(0xFF0A0A12), // near-black
              ],
              stops: <double>[0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Ambient purple bloom, kept away from the logo center.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.9, -1.0),
              radius: 1.1,
              colors: <Color>[Color(0x4D7C3AED), Color(0x00000000)],
            ),
          ),
        ),
        // Dark pool so the logo's black JPG backdrop blends seamlessly.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.18),
              radius: 0.62,
              colors: <Color>[Color(0xE6000000), Color(0x00000000)],
            ),
          ),
        ),
      ],
    );
  }
}
