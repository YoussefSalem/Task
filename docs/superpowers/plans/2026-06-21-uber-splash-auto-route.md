# Uber-style Splash with Auth-Based Auto-Routing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the onboarding-style splash (logo → progress bar → "Get Started" tap) with a brief Uber-style transition screen that auto-routes by auth state with no user interaction.

**Architecture:** The splash mounts immediately, runs the brand entrance + a ~1.2s minimum-dwell timer, and watches a new `authStateProvider`. When both the dwell has elapsed and auth has resolved, it fades out and calls `context.go('/home')` (signed in) or `context.go('/sign-in')` (not). A slim indeterminate shimmer line replaces the determinate progress bar + CTA.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), go_router, firebase_auth.

## Global Constraints

- App under work: `apps/customer` (the Customer Flutter app). Run all commands from `apps/customer/`.
- Mock mode (`firebaseReadyProvider == false`) must always resolve to **not authenticated** → sign-in. This keeps the prototype navigable when the emulator is down. See [[customer-auth-setup]].
- Do **not** add new dependencies. No `font_awesome_flutter` (breaks the build). Use only packages already in `apps/customer/pubspec.yaml`.
- Routes: home shell = `HomeShell.homeRoutePath` (`/home`); sign-in = `SignInScreen.routePath` (`/sign-in`). Splash stays the router `initialLocation` (`/`).
- Tests with repeating animations MUST use `tester.pump(Duration(...))` — never `pumpAndSettle` (it times out on infinite animations).
- Preserve the reduced-motion fast-path (`MediaQuery.of(context).disableAnimations`).
- Keep the existing brand visuals: `_SplashBackground`, the glass logo + breathing halo, and the `LanguageSwitcher`.

---

### Task 1: Add `authStateProvider`

**Files:**
- Modify: `apps/customer/lib/features/auth/auth_controller.dart`
- Test: `apps/customer/test/auth_state_provider_test.dart` (create)

**Interfaces:**
- Consumes: `firebaseReadyProvider` (existing `Provider<bool>` in the same file).
- Produces: `final authStateProvider = StreamProvider<User?>(...)` — emits `null` when Firebase is not ready (mock mode), otherwise mirrors `FirebaseAuth.instance.authStateChanges()`.

- [ ] **Step 1: Write the failing test**

Create `apps/customer/test/auth_state_provider_test.dart`:

```dart
import 'package:customer/features/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authStateProvider yields null in mock mode (firebase not ready)', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        firebaseReadyProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    // First read is loading; await the resolved value.
    final user = await container.read(authStateProvider.future);
    expect(user, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/auth_state_provider_test.dart` (from `apps/customer/`)
Expected: FAIL — `authStateProvider` is not defined.

- [ ] **Step 3: Add the provider**

In `apps/customer/lib/features/auth/auth_controller.dart`, the imports already include `firebase_auth`, `foundation`, and `flutter_riverpod`. Add this provider directly below the existing `authControllerProvider` definition (after line ~12):

```dart
/// The current signed-in user, or null. Emits null whenever Firebase is
/// unavailable (mock mode) so mock sessions deterministically land on sign-in.
final authStateProvider = StreamProvider<User?>((ref) {
  final bool ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream<User?>.value(null);
  return FirebaseAuth.instance.authStateChanges();
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/auth_state_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/customer/lib/features/auth/auth_controller.dart apps/customer/test/auth_state_provider_test.dart
git commit -m "feat(customer): add authStateProvider for splash routing"
```

---

### Task 2: Rewrite the splash to auto-route (no CTA, shimmer line)

**Files:**
- Modify (full rewrite): `apps/customer/lib/features/splash/splash_screen.dart`

**Interfaces:**
- Consumes: `authStateProvider` (Task 1); `HomeShell.homeRoutePath`; `SignInScreen.routePath`; `LanguageSwitcher`; `AppLocalizations`; design tokens from `task_design`.
- Produces: `SplashScreen` (now a `ConsumerStatefulWidget`) keeping `static const routeName = 'splash'` and `static const routePath = '/'` so `router.dart` needs no change.

- [ ] **Step 1: Write the failing test**

Replace the entire contents of `apps/customer/test/widget_test.dart` with:

```dart
import 'package:customer/app/customer_app.dart';
import 'package:customer/app/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget fullApp() =>
      const ProviderScope(child: CustomerApp(flavor: Flavor.dev));

  testWidgets('Splash shows the Task wordmark and no Get Started CTA',
      (tester) async {
    await tester.pumpWidget(fullApp());
    await tester.pump(); // first frame

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('Splash auto-routes unauthenticated users to sign-in',
      (tester) async {
    await tester.pumpWidget(fullApp());
    await tester.pump(); // resolve providers + first frame

    // Advance past the minimum dwell and the exit fade.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(); // let go_router build the destination

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — old splash still renders "Get started" and never auto-routes, so both expectations fail.

- [ ] **Step 3: Rewrite the splash**

Replace the entire contents of `apps/customer/lib/features/splash/splash_screen.dart` with:

```dart
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
    ref.listen<AsyncValue<Object?>>(authStateProvider, (_, __) {
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widget_test.dart`
Expected: PASS — wordmark shows, no "Get started", and the app auto-routes to sign-in.

- [ ] **Step 5: Analyze for unused symbols**

Run: `flutter analyze lib/features/splash/splash_screen.dart`
Expected: No issues. (The old `_LaunchProgress` / `_GetStartedButton` are gone; `gestures.dart` is still used by parallax.)

- [ ] **Step 6: Commit**

```bash
git add apps/customer/lib/features/splash/splash_screen.dart apps/customer/test/widget_test.dart
git commit -m "feat(customer): Uber-style splash that auto-routes by auth state"
```

---

### Task 3: Full verification

**Files:** none (verification only).

- [ ] **Step 1: Run the customer app test suite**

Run: `flutter test` (from `apps/customer/`)
Expected: All tests pass, including `auth_state_provider_test.dart` and `widget_test.dart`.

- [ ] **Step 2: Static analysis across the app**

Run: `flutter analyze` (from `apps/customer/`)
Expected: No new issues.

- [ ] **Step 3: Manual check in the live web preview**

Launch the customer app in the live preview (see [[flutter-web-preview-navigation]] and [[task-app-dev-environment]]). On a cold load, confirm:
- The splash appears with the logo, wordmark, tagline, and a shimmer line.
- There is **no** "Get Started" button.
- After ~1.2s it fades and lands on the **sign-in** screen with no tap (mock mode → unauthenticated).

Note: routes reset on reload in the web preview; a hot restart recompiles. [[no-dead-stub-interactions]] — verify the real behavior, don't assume.

- [ ] **Step 4: Final commit (only if any fixes were needed above)**

```bash
git add -A
git commit -m "test(customer): verify Uber-style splash auto-routing"
```

---

## Self-Review

**Spec coverage:**
- Remove "Get Started" → Task 2 (rewrite drops `_GetStartedButton`; test asserts `findsNothing`). ✅
- Auto-route by auth on launch → Task 2 `_maybeNavigate` + Task 1 `authStateProvider`. ✅
- Authenticated → home, else sign-in → `_maybeNavigate` dest selection. ✅
- Brief loading/transition feel, no interaction → min dwell + shimmer + fade-out, no buttons. ✅
- Mock mode → sign-in → Task 1 provider returns null when not ready; test in Task 1. ✅
- Reduced-motion fast-path → `_start(reduceMotion)`. ✅
- Visual redesign (keep brand, shimmer replaces progress/CTA) → Task 2 `_ShimmerLine`, retained `_SplashBackground`/`_buildLogo`. ✅
- Tests updated → Task 2 Step 1. ✅
- `router.dart` unchanged → splash keeps `routeName`/`routePath` constants; confirmed no change needed. ✅
- arb files: `getStarted`/`loading` keys left in place (no longer shown, no churn) → per spec "leave the key in place". No task needed. ✅

**Placeholder scan:** No TBD/TODO; all code blocks complete. ✅

**Type consistency:** `authStateProvider` is `StreamProvider<User?>`; the splash reads it as `AsyncValue<Object?>` and uses `.isLoading`/`.value` (both available on `AsyncValue`), avoiding a `firebase_auth` import in the splash. `HomeShell.homeRoutePath` and `SignInScreen.routePath` match the source. ✅
