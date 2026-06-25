# LiveKit VoIP Audio Calls — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the VoIP stub in `offers_screen.dart` with a real in-app audio call using LiveKit Cloud — full-screen call UI, Riverpod controller, and a Firebase Cloud Function for secure token generation.

**Architecture:** The customer app gets a `CallScreen` full-screen route and a `CallController` Riverpod notifier that owns the LiveKit `Room` lifecycle. A Firebase callable function (`generateCallToken`) issues signed JWTs; secrets live in Firebase Secret Manager. The `_CallSheet` stub is deleted.

**Tech Stack:** Flutter `livekit_client` ^2.x, Riverpod `AutoDisposeAsyncNotifier`, `firebase_functions` callable, `livekit-server-sdk` (npm), Firebase Secret Manager.

## Global Constraints

- Flutter SDK `>=3.44.0`, Dart SDK `^3.9.0`
- `flutter_riverpod: ^2.6.1` — no upgrade
- `go_router: ^14.6.2` — no upgrade
- `firebase_core: ^3.6.0`, `firebase_app_check: ^0.3.1`
- Node 20 for Cloud Functions
- All new strings must appear in both `app_en.arb` and `app_ar.arb`
- App Check enforcement on the Cloud Function (`enforceAppCheck: true`)
- `offerId` is the LiveKit room name — no Firestore lookup needed
- Technician-side call screen is **out of scope**

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `apps/customer/pubspec.yaml` | Modify | Add `livekit_client` dependency |
| `apps/customer/lib/features/call/call_controller.dart` | Create | `CallArgs`, `CallPhase`, `CallState`, `CallController`, `callControllerProvider` |
| `apps/customer/lib/features/call/call_screen.dart` | Create | Full-screen call UI, watches `callControllerProvider` |
| `apps/customer/lib/app/router.dart` | Modify | Add `/call` route |
| `apps/customer/lib/features/offers/offers_screen.dart` | Modify | Remove `_CallSheet`/`_CallSheetState`/`_showCallSheet`, wire Call button to `context.push('/call', extra: CallArgs(...))` |
| `apps/customer/lib/l10n/app_en.arb` | Modify | Add 9 call strings |
| `apps/customer/lib/l10n/app_ar.arb` | Modify | Add 9 call strings (Arabic) |
| `backend/functions/package.json` | Modify | Add `livekit-server-sdk` |
| `backend/functions/src/calls/generate_call_token.ts` | Create | Firebase callable — mint LiveKit JWT from Secret Manager secrets |
| `backend/functions/src/index.ts` | Modify | Export `generateCallToken` |

---

## Task 1: Add `livekit_client` to the Flutter app and localisation strings

**Files:**
- Modify: `apps/customer/pubspec.yaml`
- Modify: `apps/customer/lib/l10n/app_en.arb`
- Modify: `apps/customer/lib/l10n/app_ar.arb`

**Interfaces:**
- Produces: `livekit_client` package available to import; `AppLocalizations` fields `callConnecting`, `callRinging`, `callEnded`, `callMute`, `callUnmute`, `callSpeaker`, `callEarpiece`, `callRetry`, `callError`

- [ ] **Step 1: Add `livekit_client` to pubspec.yaml**

In `apps/customer/pubspec.yaml`, under `dependencies:`, add:

```yaml
  livekit_client: ^2.3.3
```

- [ ] **Step 2: Add English localisation strings**

In `apps/customer/lib/l10n/app_en.arb`, add before the final `}`:

```json
  "callConnecting": "Connecting…",
  "callRinging": "Ringing…",
  "callEnded": "Call ended",
  "callMute": "Mute",
  "callUnmute": "Unmute",
  "callSpeaker": "Speaker",
  "callEarpiece": "Earpiece",
  "callRetry": "Try again",
  "callError": "Could not connect."
```

- [ ] **Step 3: Add Arabic localisation strings**

In `apps/customer/lib/l10n/app_ar.arb`, add before the final `}`:

```json
  "callConnecting": "جاري الاتصال…",
  "callRinging": "يرن…",
  "callEnded": "انتهت المكالمة",
  "callMute": "كتم",
  "callUnmute": "إلغاء الكتم",
  "callSpeaker": "مكبر الصوت",
  "callEarpiece": "سماعة الأذن",
  "callRetry": "حاول مجدداً",
  "callError": "تعذّر الاتصال."
```

- [ ] **Step 4: Get packages and regenerate l10n**

```bash
cd "apps/customer"
flutter pub get
flutter gen-l10n
```

Expected: no errors, `lib/l10n/app_localizations_en.dart` now has `callConnecting` etc.

- [ ] **Step 5: Commit**

```bash
git add apps/customer/pubspec.yaml apps/customer/pubspec.lock \
        apps/customer/lib/l10n/app_en.arb apps/customer/lib/l10n/app_ar.arb \
        apps/customer/lib/l10n/
git commit -m "feat(call): add livekit_client dep and call localisation strings"
```

---

## Task 2: `CallController` — state model and LiveKit lifecycle

**Files:**
- Create: `apps/customer/lib/features/call/call_controller.dart`

**Interfaces:**
- Consumes: `livekit_client` (`Room`, `LocalParticipant`, `Hardware`), `firebase_functions` callable (`generateCallToken`)
- Produces:
  - `enum CallPhase { connecting, ringing, live, ended, error }`
  - `class CallArgs { final String offerId; final String technicianId; final String technicianName; }`
  - `class CallState { final CallPhase phase; final int secondsElapsed; final bool muted; final bool speakerOn; final String? errorMessage; }`
  - `final callControllerProvider = AsyncNotifierProvider.autoDispose.family<CallController, CallState, CallArgs>(CallController.new)`
  - `Future<void> hangUp()`
  - `Future<void> toggleMute()`
  - `Future<void> toggleSpeaker()`

- [ ] **Step 1: Create `call_controller.dart`**

Create `apps/customer/lib/features/call/call_controller.dart`:

```dart
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

enum CallPhase { connecting, ringing, live, ended, error }

@immutable
class CallArgs {
  const CallArgs({
    required this.offerId,
    required this.technicianId,
    required this.technicianName,
  });

  final String offerId;
  final String technicianId;
  final String technicianName;

  @override
  bool operator ==(Object other) =>
      other is CallArgs && other.offerId == offerId;

  @override
  int get hashCode => offerId.hashCode;
}

@immutable
class CallState {
  const CallState({
    required this.phase,
    this.secondsElapsed = 0,
    this.muted = false,
    this.speakerOn = false,
    this.errorMessage,
  });

  final CallPhase phase;
  final int secondsElapsed;
  final bool muted;
  final bool speakerOn;
  final String? errorMessage;

  CallState copyWith({
    CallPhase? phase,
    int? secondsElapsed,
    bool? muted,
    bool? speakerOn,
    String? errorMessage,
  }) =>
      CallState(
        phase: phase ?? this.phase,
        secondsElapsed: secondsElapsed ?? this.secondsElapsed,
        muted: muted ?? this.muted,
        speakerOn: speakerOn ?? this.speakerOn,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

final callControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CallController, CallState, CallArgs>(CallController.new);

class CallController
    extends AutoDisposeFamilyAsyncNotifier<CallState, CallArgs> {
  Room? _room;
  Timer? _ticker;

  @override
  Future<CallState> build(CallArgs arg) async {
    ref.onDispose(_cleanup);
    // Connect asynchronously; UI starts in connecting state.
    _connect(arg);
    return const CallState(phase: CallPhase.connecting);
  }

  Future<void> _connect(CallArgs arg) async {
    try {
      // 1. Get token from Cloud Function.
      final fn = FirebaseFunctions.instance.httpsCallable('generateCallToken');
      final result = await fn.call<Map<String, dynamic>>({
        'offerId': arg.offerId,
      });
      final token = result.data['token'] as String;
      final wsUrl = result.data['wsUrl'] as String;

      // 2. Create and connect room.
      _room = Room();

      _room!.addListener(_onRoomUpdate);

      await _room!.connect(
        wsUrl,
        token,
        roomOptions: const RoomOptions(
          defaultAudioPublishOptions: AudioPublishOptions(name: 'mic'),
        ),
      );

      // 3. Publish microphone.
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      state = const AsyncData(CallState(phase: CallPhase.ringing));
    } catch (e) {
      state = AsyncData(CallState(
        phase: CallPhase.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onRoomUpdate() {
    final room = _room;
    if (room == null) return;

    // Remote participant joined → live.
    if (room.remoteParticipants.isNotEmpty &&
        state.valueOrNull?.phase == CallPhase.ringing) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          final cur = state.valueOrNull;
          if (cur != null && cur.phase == CallPhase.live) {
            state = AsyncData(
                cur.copyWith(secondsElapsed: cur.secondsElapsed + 1));
          }
        },
      );
      state = AsyncData(state.valueOrNull!.copyWith(phase: CallPhase.live));
    }

    // All remote participants left or room disconnected → ended.
    if (room.remoteParticipants.isEmpty &&
        state.valueOrNull?.phase == CallPhase.live) {
      _setEnded();
    }
  }

  void _setEnded() {
    _ticker?.cancel();
    state = AsyncData(
        (state.valueOrNull ?? const CallState(phase: CallPhase.connecting))
            .copyWith(phase: CallPhase.ended));
  }

  Future<void> hangUp() async {
    await _room?.disconnect();
    _setEnded();
  }

  Future<void> toggleMute() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final next = !cur.muted;
    await _room?.localParticipant?.setMicrophoneEnabled(!next);
    state = AsyncData(cur.copyWith(muted: next));
  }

  Future<void> toggleSpeaker() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final next = !cur.speakerOn;
    await Hardware.instance.setSpeakerphoneOn(next);
    state = AsyncData(cur.copyWith(speakerOn: next));
  }

  void _cleanup() {
    _ticker?.cancel();
    _room?.removeListener(_onRoomUpdate);
    _room?.disconnect();
    _room?.dispose();
  }
}
```

- [ ] **Step 2: Verify the file compiles**

```bash
cd "apps/customer"
flutter analyze lib/features/call/call_controller.dart
```

Expected: no errors. (Warnings about missing `cloud_functions` import are resolved in the next step.)

- [ ] **Step 3: Add `cloud_functions` to pubspec if not present**

Check `apps/customer/pubspec.yaml` — if `cloud_functions` is not listed under `dependencies`, add:

```yaml
  cloud_functions: ^5.1.3
```

Then run:

```bash
flutter pub get
flutter analyze lib/features/call/call_controller.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add apps/customer/pubspec.yaml apps/customer/pubspec.lock \
        apps/customer/lib/features/call/call_controller.dart
git commit -m "feat(call): add CallController with LiveKit room lifecycle"
```

---

## Task 3: `CallScreen` — full-screen call UI

**Files:**
- Create: `apps/customer/lib/features/call/call_screen.dart`

**Interfaces:**
- Consumes: `callControllerProvider(CallArgs)`, `CallPhase`, `CallState`, `CallArgs` (all from `call_controller.dart`)
- Produces: `class CallScreen extends ConsumerStatefulWidget` with `static const String routePath = '/call'`

- [ ] **Step 1: Create `call_screen.dart`**

Create `apps/customer/lib/features/call/call_screen.dart`:

```dart
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import 'call_controller.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.args});

  static const String routePath = '/call';
  static const String routeName = 'call';

  final CallArgs args;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    final callAsync =
        ref.watch(callControllerProvider(widget.args));

    // Auto-pop when the call ends.
    ref.listen(callControllerProvider(widget.args), (_, next) {
      if (next.valueOrNull?.phase == CallPhase.ended && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBackground(intensity: 0.12),
          SafeArea(
            child: callAsync.when(
              loading: () => _buildConnecting(l, text),
              error: (e, _) => _buildError(l, text, e.toString()),
              data: (state) {
                if (state.phase == CallPhase.error) {
                  return _buildError(l, text, state.errorMessage ?? l.callError);
                }
                return _buildCall(context, l, text, mq, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting(AppLocalizations l, TextTheme text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(l.callConnecting,
              style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l, TextTheme text, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.invalidate(
                  callControllerProvider(widget.args)),
              child: Text(l.callRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCall(
    BuildContext context,
    AppLocalizations l,
    TextTheme text,
    MediaQueryData mq,
    CallState state,
  ) {
    final isLive = state.phase == CallPhase.live;

    return Column(
      children: [
        // Back button
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
        ),

        const Spacer(),

        // Avatar with pulse ring
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) => Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
              boxShadow: (state.phase == CallPhase.ringing || isLive)
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(
                            alpha: isLive
                                ? 0.30
                                : 0.15 + _pulseCtrl.value * 0.15),
                        blurRadius:
                            isLive ? 32 : 24 + _pulseCtrl.value * 16,
                        spreadRadius: isLive ? 4 : 2,
                      ),
                    ]
                  : [],
            ),
            child: child,
          ),
          child: _LargeAvatar(name: widget.args.technicianName),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Name
        Text(
          widget.args.technicianName,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Status / timer
        Text(
          isLive
              ? _formatTimer(state.secondsElapsed)
              : (state.phase == CallPhase.ringing
                  ? l.callRinging
                  : l.callConnecting),
          style: text.bodyMedium?.copyWith(
            color: isLive
                ? AppColors.success
                : AppColors.textSecondary.withValues(alpha: 0.6),
            fontWeight: isLive ? FontWeight.w600 : null,
            fontFeatures:
                isLive ? const [FontFeature.tabularFigures()] : null,
          ),
        ),

        const Spacer(),

        // Controls row
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl + mq.padding.bottom),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: state.muted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                label: state.muted ? l.callUnmute : l.callMute,
                onTap: () => ref
                    .read(callControllerProvider(widget.args).notifier)
                    .toggleMute(),
              ),
              _EndCallButton(
                onTap: () => ref
                    .read(callControllerProvider(widget.args).notifier)
                    .hangUp(),
              ),
              _ControlButton(
                icon: state.speakerOn
                    ? Icons.volume_up_rounded
                    : Icons.hearing_rounded,
                label: state.speakerOn ? l.callSpeaker : l.callEarpiece,
                onTap: () => ref
                    .read(callControllerProvider(widget.args).notifier)
                    .toggleSpeaker(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Large avatar (80 px initials circle)
// ---------------------------------------------------------------------------
class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((s) => s.isEmpty ? '' : s[0])
        .take(2)
        .join();
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Secondary control button (mute / speaker)
// ---------------------------------------------------------------------------
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// End-call button
// ---------------------------------------------------------------------------
class _EndCallButton extends StatelessWidget {
  const _EndCallButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.call_end_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).callEnded,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd "apps/customer"
flutter analyze lib/features/call/call_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add apps/customer/lib/features/call/call_screen.dart
git commit -m "feat(call): add CallScreen full-screen UI"
```

---

## Task 4: Wire router and update `OffersScreen`

**Files:**
- Modify: `apps/customer/lib/app/router.dart`
- Modify: `apps/customer/lib/features/offers/offers_screen.dart`

**Interfaces:**
- Consumes: `CallScreen.routePath` (`'/call'`), `CallScreen.routeName` (`'call'`), `CallArgs`
- Produces: `/call` route live; `_CallSheet`, `_CallSheetState`, `_showCallSheet` deleted; Call button pushes `/call`

- [ ] **Step 1: Add the `/call` route to the router**

In `apps/customer/lib/app/router.dart`, add the import at the top:

```dart
import 'package:customer/features/call/call_screen.dart';
import 'package:customer/features/call/call_controller.dart';
```

Then add this `GoRoute` alongside the other full-screen routes (after the `ChatScreen` route):

```dart
GoRoute(
  path: CallScreen.routePath,
  name: CallScreen.routeName,
  parentNavigatorKey: _rootKey,
  builder: (context, state) {
    final args = state.extra as CallArgs;
    return CallScreen(args: args);
  },
),
```

- [ ] **Step 2: Remove `_CallSheet` and `_CallSheetState` from `offers_screen.dart`**

In `apps/customer/lib/features/offers/offers_screen.dart`, delete the entire block from line 463 to the end of the `_CallSheet` widget (lines 463–630 — the comment `// Call bottom sheet (VoIP stub)` through the closing `}` of `_CallSheetState`).

- [ ] **Step 3: Replace `_showCallSheet` with `_callTechnician`**

In `_OfferCard` in `offers_screen.dart`, find the method:

```dart
void _showCallSheet(BuildContext context, Offer o) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _CallSheet(offer: o),
  );
}
```

Replace it with:

```dart
void _callTechnician(BuildContext context, Offer o) {
  context.push(
    CallScreen.routePath,
    extra: CallArgs(
      offerId: o.id,
      technicianId: o.technicianId,
      technicianName: o.technicianName,
    ),
  );
}
```

- [ ] **Step 4: Update the Call button tap handler**

In `_OfferCard.build`, find the Call `_ActionButton`:

```dart
_ActionButton(
  icon: Icons.call_rounded,
  label: l.call,
  color: AppColors.success,
  onTap: () => _showCallSheet(context, offer),
),
```

Change `_showCallSheet` to `_callTechnician`:

```dart
_ActionButton(
  icon: Icons.call_rounded,
  label: l.call,
  color: AppColors.success,
  onTap: () => _callTechnician(context, offer),
),
```

- [ ] **Step 5: Add the missing import to `offers_screen.dart`**

At the top of `offers_screen.dart`, add:

```dart
import '../call/call_screen.dart';
import '../call/call_controller.dart';
```

- [ ] **Step 6: Verify full app compiles**

```bash
cd "apps/customer"
flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add apps/customer/lib/app/router.dart \
        apps/customer/lib/features/offers/offers_screen.dart
git commit -m "feat(call): wire /call route and replace call sheet with full-screen"
```

---

## Task 5: Cloud Function — `generateCallToken`

**Files:**
- Create: `backend/functions/src/calls/generate_call_token.ts`
- Modify: `backend/functions/package.json`
- Modify: `backend/functions/src/index.ts`

**Interfaces:**
- Consumes: Firebase Secret Manager secrets `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_WS_URL`
- Produces: `export const generateCallToken` — Firebase v2 callable that accepts `{ offerId: string }` and returns `{ token: string, wsUrl: string }`

- [ ] **Step 1: Add `livekit-server-sdk` to `package.json`**

In `backend/functions/package.json`, add to `"dependencies"`:

```json
"livekit-server-sdk": "^2.6.0"
```

Also add the type definitions to `"devDependencies"`:

```json
"@livekit/server-sdk": "^2.6.0"
```

Then run:

```bash
cd "backend/functions"
npm install
```

Expected: `node_modules/livekit-server-sdk` present.

- [ ] **Step 2: Create `generate_call_token.ts`**

Create `backend/functions/src/calls/generate_call_token.ts`:

```typescript
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {AccessToken} from "livekit-server-sdk";

const livekitApiKey = defineSecret("LIVEKIT_API_KEY");
const livekitApiSecret = defineSecret("LIVEKIT_API_SECRET");
const livekitWsUrl = defineSecret("LIVEKIT_WS_URL");

export const generateCallToken = onCall(
  {
    enforceAppCheck: true,
    secrets: [livekitApiKey, livekitApiSecret, livekitWsUrl],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const offerId = (request.data as {offerId?: string}).offerId;
    if (!offerId || typeof offerId !== "string" || offerId.trim() === "") {
      throw new HttpsError("invalid-argument", "offerId is required.");
    }

    const identity = request.auth.uid;

    const token = new AccessToken(
      livekitApiKey.value(),
      livekitApiSecret.value(),
      {
        identity,
        ttl: 60 * 60 * 2, // 2 hours
      }
    );

    token.addGrant({
      roomJoin: true,
      room: offerId.trim(),
      canPublish: true,
      canSubscribe: true,
    });

    return {
      token: await token.toJwt(),
      wsUrl: livekitWsUrl.value(),
    };
  }
);
```

- [ ] **Step 3: Export from `index.ts`**

In `backend/functions/src/index.ts`, add after the existing `ping` export:

```typescript
export {generateCallToken} from "./calls/generate_call_token";
```

- [ ] **Step 4: Build the functions**

```bash
cd "backend/functions"
npm run build
```

Expected: `lib/calls/generate_call_token.js` generated, no TypeScript errors.

- [ ] **Step 5: Commit**

```bash
git add backend/functions/package.json backend/functions/package-lock.json \
        backend/functions/src/calls/generate_call_token.ts \
        backend/functions/src/index.ts backend/functions/lib/
git commit -m "feat(call): add generateCallToken Cloud Function"
```

---

## Task 6: Add LiveKit secrets to Firebase Secret Manager and deploy

> **Stop here and ask for the LiveKit API key, API secret, and WebSocket URL before running these commands.** These are sensitive credentials from your LiveKit Cloud dashboard (Settings → Keys).

**Files:** none (infra only)

- [ ] **Step 1: Set secrets in Firebase Secret Manager**

```bash
# Run from repo root — replace the values with your real LiveKit credentials
firebase functions:secrets:set LIVEKIT_API_KEY
# Enter your API key when prompted

firebase functions:secrets:set LIVEKIT_API_SECRET
# Enter your API secret when prompted

firebase functions:secrets:set LIVEKIT_WS_URL
# Enter your WebSocket URL, e.g.: wss://task-xxxx.livekit.cloud
```

- [ ] **Step 2: Verify secrets are set**

```bash
firebase functions:secrets:access LIVEKIT_API_KEY
```

Expected: prints your API key value.

- [ ] **Step 3: Deploy the function**

```bash
firebase deploy --only functions:generateCallToken
```

Expected output includes:
```
✔  functions[generateCallToken(europe-west1)] Successful create operation.
```

- [ ] **Step 4: Smoke-test the deployed function**

From the Firebase console → Functions → `generateCallToken` → Testing tab, or run:

```bash
firebase functions:shell
# In the shell:
generateCallToken({data: {offerId: 'test-offer-123'}, auth: {uid: 'test-user'}})
```

Expected: `{ token: 'eyJ...', wsUrl: 'wss://...' }`

- [ ] **Step 5: Final commit (no code change, tag the infra step)**

```bash
git commit --allow-empty -m "chore(call): LiveKit secrets set in Secret Manager, function deployed"
```

---

## Task 7: Platform permissions (iOS & Android)

**Files:**
- Modify: `apps/customer/ios/Runner/Info.plist`
- Modify: `apps/customer/android/app/src/main/AndroidManifest.xml`

**Interfaces:** none — platform config only.

- [ ] **Step 1: Add iOS microphone permission**

In `apps/customer/ios/Runner/Info.plist`, add inside the root `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Task needs microphone access to call technicians.</string>
```

- [ ] **Step 2: Add Android permissions**

In `apps/customer/android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` (before `<application>`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

- [ ] **Step 3: Verify the app still builds**

```bash
cd "apps/customer"
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add apps/customer/ios/Runner/Info.plist \
        apps/customer/android/app/src/main/AndroidManifest.xml
git commit -m "feat(call): add microphone permissions for iOS and Android"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ `CallArgs`, `CallPhase`, `CallState`, `CallController`, `callControllerProvider` — Task 2
- ✅ `CallScreen` with connecting/ringing/live/error states — Task 3
- ✅ Auto-pop on `phase == ended` — Task 3 (`ref.listen`)
- ✅ Mute toggle — Task 2 (`toggleMute`) + Task 3 (button)
- ✅ Speaker toggle — Task 2 (`toggleSpeaker`) + Task 3 (button)
- ✅ `hangUp()` — Task 2 + Task 3 (end call button)
- ✅ `ref.onDispose` cleanup — Task 2 (`_cleanup`)
- ✅ Error state with retry — Task 2 + Task 3 (`_buildError`)
- ✅ `/call` route — Task 4
- ✅ `_CallSheet` deleted — Task 4
- ✅ `generateCallToken` Cloud Function — Task 5
- ✅ App Check enforcement — Task 5
- ✅ Secret Manager secrets — Task 6
- ✅ Localisation strings (9 EN + 9 AR) — Task 1
- ✅ iOS/Android microphone permissions — Task 7

**Type consistency check:**
- `CallArgs` defined in Task 2, consumed in Tasks 3, 4 ✅
- `callControllerProvider(CallArgs)` defined Task 2, watched Task 3 ✅
- `CallScreen.routePath = '/call'` defined Task 3, used in router Task 4 ✅
- `generateCallToken` exported Task 5, called in controller Task 2 ✅
