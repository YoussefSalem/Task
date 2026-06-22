import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';

/// Post-job rating. Stars, quick compliment chips, an optional note, then back
/// home. Submitting resets the draft so the next booking starts clean.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  static const String routePath = '/job/live/rate';

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 5;
  final Set<String> _tags = <String>{};
  final TextEditingController _note = TextEditingController();

  static const List<String> _options = <String>[
    'On time',
    'Tidy work',
    'Friendly',
    'Fair price',
    'Skilled',
    'Great communication',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(jobDraftProvider.notifier).reset();
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ReviewSuccessSheet(
        rating: _rating,
        proName: 'Khaled Mansour',
        onDone: () {
          Navigator.of(sheetCtx).pop();
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final JobRequest? job =
        ref.watch(myJobsProvider).valueOrNull?.isEmpty == false
            ? ref.watch(myJobsProvider).valueOrNull!.first
            : null;
    final TextTheme text = Theme.of(context).textTheme;
    const String pro = 'Khaled Mansour';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              ref.read(jobDraftProvider.notifier).reset();
              context.go('/home');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
              children: <Widget>[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      pro.split(' ').map((String s) => s[0]).take(2).join(),
                      style: text.headlineSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                    'How was your ${job?.title.toLowerCase() ?? job?.category.displayLabel.toLowerCase() ?? 'service'}?',
                    textAlign: TextAlign.center,
                    style:
                        text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Text('with $pro',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondary.withValues(alpha: 0.65)
                          : AppColors.textSecondaryLight,
                    )),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(5, (int i) {
                    final bool on = i < _rating;
                    return IconButton(
                      iconSize: 44,
                      onPressed: () => setState(() => _rating = i + 1),
                      icon: Icon(
                        on ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: on
                            ? AppColors.warning
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: _options.map((String tag) {
                    final bool on = _tags.contains(tag);
                    final bool isDark = Theme.of(context).brightness == Brightness.dark;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          on ? _tags.remove(tag) : _tags.add(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: 8),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : (isDark
                                  ? AppColors.surface.withValues(alpha: 0.5)
                                  : AppColors.primaryContainer),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: on
                                ? AppColors.primary
                                : (isDark
                                    ? const Color(0x18FFFFFF)
                                    : AppColors.primary.withValues(alpha: 0.2)),
                          ),
                        ),
                        child: Text(tag,
                            style: text.labelLarge?.copyWith(
                              color: on
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight),
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Add a note (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                GlowButton(label: 'Submit review', onPressed: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success confirmation sheet with auto-redirect countdown
// ---------------------------------------------------------------------------
class _ReviewSuccessSheet extends StatefulWidget {
  const _ReviewSuccessSheet({
    required this.rating,
    required this.proName,
    required this.onDone,
  });

  final int rating;
  final String proName;
  final VoidCallback onDone;

  @override
  State<_ReviewSuccessSheet> createState() => _ReviewSuccessSheetState();
}

class _ReviewSuccessSheetState extends State<_ReviewSuccessSheet>
    with SingleTickerProviderStateMixin {
  static const int _autoRedirectSeconds = 3;
  int _secondsLeft = _autoRedirectSeconds;
  Timer? _countdown;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Pop-in animation for the checkmark.
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();

    // Countdown → auto-redirect.
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _countdown?.cancel();
        widget.onDone();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme text = Theme.of(context).textTheme;
    final Color sheetColor =
        isDark ? AppColors.surface : AppColors.surfaceLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
          AppSpacing.xl + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0x22000000),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Animated checkmark circle
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 44),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Review submitted!',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Thanks for rating ${widget.proName}.\nYour feedback helps the whole community.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondary.withValues(alpha: 0.7)
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Star recap
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(5, (int i) {
              return Icon(
                i < widget.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < widget.rating
                    ? AppColors.warning
                    : (isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.35)
                        : AppColors.textSecondaryLight.withValues(alpha: 0.4)),
                size: 28,
              );
            }),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Back to home button
          GlowButton(
            label: 'Back to home',
            icon: Icons.home_rounded,
            onPressed: widget.onDone,
          ),

          const SizedBox(height: AppSpacing.md),

          // Countdown hint
          Text(
            'Redirecting in $_secondsLeft s…',
            style: text.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
