import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import '../services/service_catalog.dart';

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

  void _submit() {
    ref.read(bookingProvider.notifier).reset();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Thanks for the feedback!')));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final BookingDraft draft = ref.watch(bookingProvider);
    final Service? service = draft.service;
    final TextTheme text = Theme.of(context).textTheme;
    final String pro = draft.selectedBid?.proName ?? 'Khaled Mansour';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).reset();
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
                Text('How was your ${service?.name.toLowerCase() ?? 'service'}?',
                    textAlign: TextAlign.center,
                    style:
                        text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Text('with $pro',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.65),
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
                        color: on ? AppColors.warning : AppColors.textSecondary,
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
                    return GestureDetector(
                      onTap: () => setState(() =>
                          on ? _tags.remove(tag) : _tags.add(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: 8),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : AppColors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: on
                                ? AppColors.primary
                                : const Color(0x18FFFFFF),
                          ),
                        ),
                        child: Text(tag,
                            style: text.labelLarge?.copyWith(
                              color: on
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
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
