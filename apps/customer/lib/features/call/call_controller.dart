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
  EventsListener<RoomEvent>? _listener;

  @override
  Future<CallState> build(CallArgs arg) async {
    ref.onDispose(_cleanup);
    unawaited(_connect(arg));
    return const CallState(phase: CallPhase.connecting);
  }

  Future<void> _connect(CallArgs arg) async {
    try {
      // 1. Get token from Cloud Function.
      final fn =
          FirebaseFunctions.instance.httpsCallable('generateCallToken');
      final result = await fn.call<Map<Object?, Object?>>({
        'offerId': arg.offerId,
      });
      final token = result.data['token'] as String;
      final wsUrl = result.data['wsUrl'] as String;

      // 2. Create room and attach event listeners before connecting.
      _room = Room(
        roomOptions: const RoomOptions(
          defaultAudioPublishOptions: AudioPublishOptions(name: 'mic'),
        ),
      );
      _listener = _room!.createListener();

      _listener!
        ..on<ParticipantConnectedEvent>((_) {
          final cur = state.valueOrNull;
          if (cur == null || cur.phase != CallPhase.ringing) return;
          _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
            final s = state.valueOrNull;
            if (s != null && s.phase == CallPhase.live) {
              state = AsyncData(s.copyWith(secondsElapsed: s.secondsElapsed + 1));
            }
          });
          state = AsyncData(cur.copyWith(phase: CallPhase.live));
        })
        ..on<ParticipantDisconnectedEvent>((_) {
          final cur = state.valueOrNull;
          if (cur != null && cur.phase == CallPhase.live) _setEnded();
        })
        ..on<RoomDisconnectedEvent>((_) => _setEnded());

      // 3. Connect to room.
      await _room!.connect(wsUrl, token);

      // 4. Publish microphone.
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      state = const AsyncData(CallState(phase: CallPhase.ringing));
    } catch (e) {
      state = AsyncData(CallState(
        phase: CallPhase.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _setEnded() {
    _ticker?.cancel();
    final cur = state.valueOrNull ?? const CallState(phase: CallPhase.connecting);
    state = AsyncData(cur.copyWith(phase: CallPhase.ended));
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
    _listener?.dispose();
    _room?.disconnect();
    _room?.dispose();
  }
}
