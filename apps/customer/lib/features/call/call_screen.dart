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

    final callAsync = ref.watch(callControllerProvider(widget.args));

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
                  return _buildError(
                      l, text, state.errorMessage ?? l.callError);
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
          Text(
            l.callConnecting,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(callControllerProvider(widget.args)),
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
        // Back button — pops without hanging up (controller dispose handles disconnect)
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

        // Avatar with pulsing ring
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
                              : 0.15 + _pulseCtrl.value * 0.15,
                        ),
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

        // Technician name
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
            AppSpacing.xxl,
            0,
            AppSpacing.xxl,
            AppSpacing.xxl + mq.padding.bottom,
          ),
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight,
                ),
          ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
