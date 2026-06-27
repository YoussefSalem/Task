import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

/// Wallet tab: Task credit balance and a recent transaction history. Top-up and
/// payouts arrive with the payments phase, so those actions are stubbed.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static List<(IconData, String, String, int)> _txnsFor(AppLocalizations l) =>
      <(IconData, String, String, int)>[
        (Icons.ac_unit_rounded, l.acServiceAndGasRefill, l.txnToday240, -240),
        (Icons.add_circle_rounded, l.walletTopUp, l.txnYesterday, 300),
        (Icons.bolt_rounded, l.electricalFault, l.txnMar18, -150),
        (Icons.card_giftcard_rounded, l.referralCredit, l.txnMar15, 50),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.12),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 112),
            children: <Widget>[
              Text(l.walletTitle,
                  style:
                      text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xl),
              _balanceCard(context, text, l),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l.recentActivity),
              const SizedBox(height: AppSpacing.md),
              ..._txnsFor(l).map((t) => _txnRow(text, t, l)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(BuildContext context, TextTheme text, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF5B21B6), Color(0xFF7C3AED)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.taskCredit,
              style: text.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              )),
          const SizedBox(height: 4),
          Text('125 ${l.egp}',
              style: text.displaySmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _action(context, Icons.add_rounded, l.topUp, l),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _action(context, Icons.swap_horiz_rounded, l.sendAction, l),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, AppLocalizations l) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(l.featureArrivesWithPayments(label))));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _txnRow(TextTheme text, (IconData, String, String, int) t, AppLocalizations l) {
    final bool credit = t.$4 > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: (credit ? AppColors.success : AppColors.primary)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(t.$1,
                color: credit ? AppColors.success : AppColors.primary,
                size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(t.$2,
                    style:
                        text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(t.$3,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ),
          Text('${credit ? '+' : ''}${t.$4} ${l.egp}',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: credit ? AppColors.success : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
