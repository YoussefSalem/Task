import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../../app/tech_colors.dart';
import 'call_controller.dart';

/// A voice call with the customer over LiveKit. The token is minted by the
/// `generateCallToken` function for the offer's room; both parties join it.
class CallScreen extends ConsumerWidget {
  const CallScreen({required this.args, super.key});

  final CallArgs args;

  static const String routeName = 'call';
  static const String routePath = '/call';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CallState> stateAsync =
        ref.watch(callControllerProvider(args));
    final CallController ctrl =
        ref.read(callControllerProvider(args).notifier);
    final CallState state =
        stateAsync.valueOrNull ?? const CallState(phase: CallPhase.connecting);

    // Leave the screen shortly after the call ends.
    ref.listen(callControllerProvider(args), (_, next) {
      if (next.valueOrNull?.phase == CallPhase.ended && context.mounted) {
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (context.mounted && Navigator.of(context).canPop()) context.pop();
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: TechColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: TechColors.accentBright.withValues(alpha: 0.6),
                      width: 2),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 60),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(args.peerName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: AppSpacing.sm),
              Text(_phaseLabel(state),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: state.phase == CallPhase.error
                            ? AppColors.error
                            : Colors.white.withValues(alpha: 0.7),
                      )),
              if (state.phase == CallPhase.error && state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          )),
                ),
              const Spacer(),
              if (state.phase == CallPhase.live ||
                  state.phase == CallPhase.ringing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _RoundControl(
                      icon: state.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      active: state.muted,
                      label: 'Mute',
                      onTap: ctrl.toggleMute,
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    _RoundControl(
                      icon: state.speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      active: state.speakerOn,
                      label: 'Speaker',
                      onTap: ctrl.toggleSpeaker,
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              _HangUpButton(onTap: () async {
                await ctrl.hangUp();
                if (context.mounted && Navigator.of(context).canPop()) {
                  context.pop();
                }
              }),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseLabel(CallState s) => switch (s.phase) {
        CallPhase.connecting => 'Connecting…',
        CallPhase.ringing => 'Ringing…',
        CallPhase.live => _fmt(s.secondsElapsed),
        CallPhase.ended => 'Call ended',
        CallPhase.error => 'Couldn’t connect',
      };

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: active
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              height: 62,
              width: 62,
              child: Icon(icon,
                  color: active ? const Color(0xFF0B1220) : Colors.white,
                  size: 26),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                )),
      ],
    );
  }
}

class _HangUpButton extends StatelessWidget {
  const _HangUpButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          height: 72,
          width: 72,
          child: Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
