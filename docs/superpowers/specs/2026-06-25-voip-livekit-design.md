# VoIP Integration — LiveKit Audio Calls
**Date:** 2026-06-25  
**Scope:** Customer app only (technician app is an empty shell)  
**Status:** Approved — ready for implementation planning

---

## Goal

Replace the VoIP stub in `offers_screen.dart` with a real in-app audio call backed by LiveKit Cloud. The customer can call a technician before hiring, from the offer comparison screen.

---

## Architecture

```
Customer taps "Call" on an offer
  → navigates to CallScreen(offerId, technicianId, technicianName)
  → CallController.joinCall()
      → Firebase Callable: generateCallToken(offerId, identity)
          → LiveKit Cloud issues a JWT scoped to room=offerId
      → livekit_client connects to wss://your-project.livekit.cloud
      → publishes microphone AudioTrack
  → UI: connecting → ringing → live (timer, mute, speaker)
  → End Call → CallController.leaveCall() → pop to Offers
```

**Three new pieces:**
1. `CallScreen` — full-screen Flutter UI at `/call` route
2. `CallController` — Riverpod `AutoDisposeAsyncNotifier`, owns `Room` lifecycle
3. `generateCallToken` — Firebase Cloud Function (TS), returns a signed LiveKit JWT

The `Offer` entity is unchanged. `offerId` is used as the LiveKit room name.

---

## New Files

```
apps/customer/lib/features/call/
  call_screen.dart          — full-screen UI
  call_controller.dart      — Riverpod notifier + CallState/CallPhase/CallArgs
backend/functions/src/calls/
  generate_call_token.ts    — Firebase callable function
```

**Modified files:**
- `apps/customer/pubspec.yaml` — add `livekit_client`
- `apps/customer/lib/app/router.dart` — add `/call` route
- `apps/customer/lib/features/offers/offers_screen.dart` — remove `_CallSheet`, wire "Call" button to push `/call`
- `backend/functions/package.json` — add `livekit-server-sdk`
- `backend/functions/src/index.ts` — export `generateCallToken`
- `apps/customer/lib/l10n/app_en.arb` + `app_ar.arb` — new call strings

---

## CallScreen UI

Three visual states:

| State | Status text | Animation |
|-------|-------------|-----------|
| `connecting` | "Connecting…" | spinner |
| `ringing` | "Ringing…" | pulsing green ring |
| `live` | `MM:SS` timer | solid green ring |

**Layout (top → bottom):**
- Dark scaffold with `AmbientBackground(intensity: 0.12)`
- Back/X button (top-left, pops immediately — hangup happens in controller dispose)
- Technician avatar — large initials circle (80 px, gradient, same pattern as `_Avatar` in offers)
- Technician name (`titleLarge`, bold)
- Status text / timer (`bodyMedium`, green when live)

**Controls row (bottom):**
- Mute toggle: `Icons.mic_rounded` / `Icons.mic_off_rounded` — grey circle button
- End call: large red circle, `Icons.call_end_rounded` — always centre
- Speaker toggle: `Icons.volume_up_rounded` / `Icons.hearing_rounded` — grey circle button

**Error state:** full-screen message + "Try again" button that calls `ref.invalidateSelf()`.

**Auto-pop:** `CallScreen` watches `phase == CallPhase.ended` and calls `context.pop()` automatically.

---

## CallController

```dart
enum CallPhase { connecting, ringing, live, ended, error }

@immutable
class CallArgs {
  final String offerId;
  final String technicianId;
  final String technicianName;
}

@immutable
class CallState {
  final CallPhase phase;
  final int secondsElapsed;   // meaningful only in live
  final bool muted;
  final bool speakerOn;
  final String? errorMessage;
}

// Provider
final callControllerProvider = AsyncNotifierProvider
  .autoDispose
  .family<CallController, CallState, CallArgs>(CallController.new);
```

**Lifecycle:**
1. `build()` → `CallState(phase: connecting)`, triggers `_connect()`
2. `_connect()` → calls `generateCallToken` Firebase function → `Room.connect()` → publish mic track → phase = `ringing`
3. `room.onParticipantConnected` → phase = `live`, start seconds ticker
4. `room.onParticipantDisconnected` / `room.onDisconnected` → phase = `ended`
5. `CallScreen` listens: `phase == ended` → `context.pop()`
6. `toggleMute()` → flip `muted`, call `localParticipant.setMicrophoneEnabled(!muted)`
7. `toggleSpeaker()` → flip `speakerOn`, call `Hardware.instance.setSpeakerphoneOn(speakerOn)`
8. `hangUp()` → `room.disconnect()` → phase = `ended`
9. `ref.onDispose` → always `room.disconnect()` (prevents leaked connections)

**Error handling:** any exception in `_connect()` → `phase = error, errorMessage = e.toString()`. Screen shows retry button → `ref.invalidateSelf()`.

---

## Cloud Function — `generateCallToken`

**File:** `backend/functions/src/calls/generate_call_token.ts`

```typescript
// Input
{ offerId: string, identity: string }  // identity = Firebase UID

// Output  
{ token: string, wsUrl: string }
```

**Logic:**
1. App Check enforced (matches existing pattern)
2. Validate `offerId` non-empty; `identity` comes from `request.auth.uid`
3. Read secrets from Firebase Secret Manager: `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_WS_URL`
4. Create `AccessToken` via `livekit-server-sdk`:
   - `roomName = offerId`
   - `participantIdentity = identity`
   - grants: `roomJoin: true`, `canPublish: true`, `canSubscribe: true`
   - TTL: 2 hours
5. Return `{ token: token.toJwt(), wsUrl }`

**Secrets (Firebase Secret Manager):**
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`
- `LIVEKIT_WS_URL` (e.g. `wss://task-xxxx.livekit.cloud`)

**Dependencies:** `livekit-server-sdk` added to `backend/functions/package.json`.

---

## New Localisation Strings

| Key | English | Arabic |
|-----|---------|--------|
| `callConnecting` | Connecting… | جاري الاتصال… |
| `callRinging` | Ringing… | يرن… |
| `callEnded` | Call ended | انتهت المكالمة |
| `callMute` | Mute | كتم |
| `callUnmute` | Unmute | إلغاء الكتم |
| `callSpeaker` | Speaker | مكبر الصوت |
| `callEarpiece` | Earpiece | سماعة الأذن |
| `callRetry` | Try again | حاول مجدداً |
| `callError` | Could not connect. | تعذّر الاتصال. |

---

## Router Change

```dart
GoRoute(
  path: '/call',
  name: 'call',
  parentNavigatorKey: _rootKey,
  builder: (context, state) {
    final args = state.extra as CallArgs;
    return CallScreen(args: args);
  },
),
```

`_showCallSheet` in `OffersScreen` is replaced by:
```dart
void _callTechnician(BuildContext context, Offer o) {
  context.push('/call', extra: CallArgs(
    offerId: o.id,
    technicianId: o.technicianId,
    technicianName: o.technicianName,
  ));
}
```

The `_CallSheet` class and `_CallSheetState` are deleted entirely.

---

## Out of Scope

- Technician-side call screen (technician app is an empty shell)
- Push notification for incoming calls
- Call history / duration logging to Firestore
- Video
- Recording
