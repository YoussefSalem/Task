# Uber-style splash with auth-based auto-routing

**Date:** 2026-06-21
**App:** `apps/customer` (Flutter)
**Status:** Approved for planning

## Goal

Replace the current onboarding-style splash (logo → 2.6s progress bar → "Get
Started" CTA → manual tap to sign-in) with a brief, Uber-style loading/transition
screen that **auto-routes by auth state** with zero user interaction.

- Authenticated → home shell (`/home`)
- Not authenticated → sign-in (`/sign-in`)

Implementation is **native Flutter/Dart**. Remotion only informs the motion
language (eased/spring interpolation, tight timing); no video asset is produced.

## Behavior

On app launch the splash mounts immediately and runs two things in parallel:

1. **Auth resolution** — read the current Firebase user.
2. **Minimum dwell** — a ~1200ms timer so the brand entrance never "flashes" by,
   even when auth resolves instantly.

When **both** complete, the splash calls `context.go(destination)` exactly once
(guarded by a `_navigated` flag so it can't fire twice):

- `FirebaseAuth.instance.currentUser != null` → `/home`
- otherwise → `/sign-in`

No buttons, no taps anywhere on the screen.

### Removed
- The "Get Started" CTA (`_GetStartedButton`).
- The progress-bar → CTA hand-off (`AnimatedSwitcher`, `_LaunchProgress`'s
  determinate fill + status label, the `_load` 2.6s controller, the `_ready`
  state, the `pushNamed(SignInScreen)` call).

### Reduced motion
Preserve the existing fast-path: when `MediaQuery.disableAnimations` is true,
skip the entrance animation. Auto-routing still applies; the min dwell is reduced
(~400ms) so reduced-motion users move on quickly but without a hard flash.

## Auth state source

The current splash never checks auth. Add an auth provider in
`auth_controller.dart`:

```dart
/// Current signed-in user, or null. Null whenever Firebase is unavailable
/// (mock mode) — so mock sessions always land on sign-in.
final authStateProvider = StreamProvider<User?>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream<User?>.value(null);
  return FirebaseAuth.instance.authStateChanges();
});
```

The splash reads the first resolved value of this provider. Because mock mode
(`firebaseReady == false`) yields `null`, mock sessions deterministically route
to sign-in, matching today's prototype behavior.

## Visual redesign (minimal / fast / polished)

Keep the established brand surface — the violet→black diagonal field, the ambient
top-corner bloom, the centered shadow pool, the glass logo with its breathing
violet halo, and the language switcher. These already read as premium and are
retained as-is (`_SplashBackground`, `_buildLogo`).

Changes:
- **Tighten the entrance** to ~800ms: logo fades/scales in, then wordmark +
  tagline rise. Eased curves (`Curves.easeOutCubic`), no long artificial wait.
- **Replace** the determinate progress bar + uppercase status label + CTA slot
  with a single **slim indeterminate shimmer line** beneath the wordmark — a thin
  violet highlight that sweeps left↔right on a repeating controller. Reads as
  "loading/transition," not "onboarding." Fixed small height so layout is stable.
- Keep the halo "breathing" pulse for ambient life.
- **Exit transition:** route into the destination with a quick fade-through
  (~300ms) so the hand-off feels like one continuous motion rather than a cut.

## Components

| Unit | Responsibility |
|------|----------------|
| `SplashScreen` (`ConsumerStatefulWidget`) | Mount visuals, run entrance + dwell timer, watch `authStateProvider`, navigate once both are ready. |
| `_SplashBackground` | Unchanged full-bleed brand field. |
| `_buildLogo` | Unchanged glass logo + breathing halo. |
| `_ShimmerLine` (new) | Slim indeterminate loading sweep replacing `_LaunchProgress`. |
| `authStateProvider` (new) | Auth state stream; null in mock mode. |

`SplashScreen` becomes a `ConsumerStatefulWidget` (it needs `ref` to read the
auth provider). It keeps `TickerProviderStateMixin` for the entrance/pulse/shimmer
controllers.

## Routing

`router.dart` keeps `initialLocation: '/'` (splash). Optionally add a custom
fade `pageBuilder`/transition on the destination so the exit fade-through is
smooth; if that adds complexity, a plain `context.go` is acceptable for v1.

## Files touched

- `apps/customer/lib/features/splash/splash_screen.dart` — rewrite per above.
- `apps/customer/lib/features/auth/auth_controller.dart` — add `authStateProvider`.
- `apps/customer/lib/app/router.dart` — (optional) destination fade transition.
- `apps/customer/lib/l10n/app_en.arb`, `app_ar.arb` — `getStarted` becomes unused
  (leave the key in place to avoid churn; `loading` is no longer shown but kept).

## Error handling / edge cases

- **Navigate-once guard:** a `bool _navigated` prevents double `go()` if both the
  dwell timer and the auth stream fire near-simultaneously, and prevents
  navigation after dispose (`if (!mounted) return;`).
- **Auth never resolves:** `authStateChanges()` emits its first value
  synchronously-ish on startup; if for some reason it stalls, the splash still
  shows (no crash). v1 does not add a hard timeout fallback — Firebase emits
  promptly, and mock mode resolves immediately to null.
- **Reduced motion:** entrance skipped, shorter dwell, still auto-routes.

## Testing

- `apps/customer/test/widget_test.dart`: update the existing splash test —
  pump `SplashScreen` with `firebaseReadyProvider` overridden false, advance time
  past the dwell, assert navigation toward `/sign-in` and that **no** "Get
  Started" CTA renders.
- Manual: run the customer app in the live web preview, confirm it lands on
  sign-in (mock mode) automatically with no tap, with the brief shimmer.

## Non-goals

- Persisting/remembering a "seen onboarding" flag (there is no onboarding now).
- Deep-link handling on cold start.
- Producing a Remotion video asset.
