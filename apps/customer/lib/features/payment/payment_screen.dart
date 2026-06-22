import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart' hide PaymentMethod;

import '../booking/booking_state.dart';
import '../marketplace/marketplace_providers.dart';

/// Payment & review. `settle == true` after a finished job (pay the pro); else
/// it authorizes a scheduled booking upfront. The summary and method picker are
/// live; the charge is stubbed for the prototype.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.settle, super.key});

  /// true = pay after the job; false = authorize a scheduled booking.
  final bool settle;

  static const String routePath = '/book/payment';

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _processing = false;
  PaymentMethod _selectedPayment = PaymentMethod.card;

  /// Returns how much wallet credit is applied toward [total].
  int _appliedCredit(int walletBalance, int total) =>
      walletBalance.clamp(0, total);

  Future<void> _confirm(int appliedCredit) async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    // Deduct the credit that was used from the wallet balance.
    if (appliedCredit > 0) {
      ref.read(walletCreditProvider.notifier).state -= appliedCredit;
    }

    if (widget.settle) {
      ref.read(jobDraftProvider.notifier).reset();
      context.pushReplacement('/job/live/rate');
    } else {
      ref.read(jobDraftProvider.notifier).reset();
      await _showConfirmed();
    }
  }

  Future<void> _showConfirmed() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: null, // uses theme surface
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final TextTheme text = Theme.of(context).textTheme;
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
              AppSpacing.xl, AppSpacing.xl + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Booking confirmed',
                  style:
                      text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Text("We've locked in your pro. You'll get a reminder before they arrive.",
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.7)
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  )),
              const SizedBox(height: AppSpacing.xl),
              GlowButton(
                label: 'Done',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final JobRequestDraft draft = ref.watch(jobDraftProvider);
    final int walletBalance = ref.watch(walletCreditProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final int total = draft.fixedPrice;
    final int applied = _appliedCredit(walletBalance, total);
    final int remaining = total - applied;
    final bool fullyCovered = remaining == 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.settle ? 'Pay & finish' : 'Review & pay'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 150),
              children: <Widget>[
                _summary(draft, text, applied: applied, remaining: remaining),
                const SizedBox(height: AppSpacing.xl),
                if (!fullyCovered) ...<Widget>[
                  Text('Payment method',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.md),
                  ...PaymentMethod.values.map((PaymentMethod m) => _methodTile(
                        m,
                        selected: _selectedPayment == m,
                        onTap: () => setState(() => _selectedPayment = m),
                        text: text,
                      )),
                ] else
                  _fullyCoveredNote(text),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _payBar(
              draft,
              text,
              applied: applied,
              remaining: remaining,
              fullyCovered: fullyCovered,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    JobRequestDraft draft,
    TextTheme text, {
    required int applied,
    required int remaining,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color divColor =
        isDark ? const Color(0x18FFFFFF) : const Color(0x12000000);
    final bool walletUsed = applied > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: divColor),
      ),
      child: Column(
        children: <Widget>[
          _row(text, 'Service', draft.category?.displayLabel ?? ''),
          _row(text, 'Title', draft.title),
          Divider(height: AppSpacing.xl, color: divColor),

          // Job total row
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Job total',
                    style: text.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.6)
                          : AppColors.textSecondaryLight,
                    )),
              ),
              Text('${draft.fixedPrice} EGP',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),

          // Wallet deduction row — only shown when credit is applied.
          if (walletUsed) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 15, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Task credit applied',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                Text('−$applied EGP',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: divColor),
            const SizedBox(height: AppSpacing.md),

            // You pay row
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('You pay',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(
                  remaining == 0 ? 'Free' : '$remaining EGP',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: remaining == 0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            // No wallet credit — show normal total.
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Total',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text('${draft.fixedPrice} EGP',
                    style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Shown below the summary when wallet credit covers the full amount.
  Widget _fullyCoveredNote(TextTheme text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Your Task credit fully covers this order — no additional payment needed.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.success,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(TextTheme text, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(label,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary.withValues(alpha: 0.6)
                      : AppColors.textSecondaryLight,
                )),
          ),
          Expanded(
            child: Text(value,
                style:
                    text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(PaymentMethod m,
      {required bool selected,
      required VoidCallback onTap,
      required TextTheme text}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: !selected && !isDark
              ? Border.all(color: const Color(0x12000000))
              : null,
        ),
        child: Material(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : (isDark ? AppColors.surface.withValues(alpha: 0.5) : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(m.icon, color: selected ? AppColors.primary : secondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(m.label,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(m.sub,
                            style: text.bodySmall?.copyWith(color: secondary)),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? AppColors.primary : secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _payBar(
    JobRequestDraft draft,
    TextTheme text, {
    required int applied,
    required int remaining,
    required bool fullyCovered,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String action;
    if (fullyCovered) {
      action = 'Confirm — credit only';
    } else if (widget.settle) {
      action = 'Pay $remaining EGP';
    } else {
      action = 'Authorize $remaining EGP';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x12000000),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Mini wallet reminder strip — visible when credit is partially used.
          if (applied > 0 && !fullyCovered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.account_balance_wallet_rounded,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 5),
                  Text(
                    '$applied EGP Task credit applied',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          GlowButton(
            label: action,
            loading: _processing,
            onPressed: () => _confirm(applied),
          ),
        ],
      ),
    );
  }
}
