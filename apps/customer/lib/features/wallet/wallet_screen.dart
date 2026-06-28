import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import 'wallet_providers.dart';

/// Wallet tab: real Firestore-backed Task-credit balance and ledger. Top-up and
/// payouts arrive with the payments phase, so those actions stay disabled and
/// surface an "arrives with payments" notice for now.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static const String routePath = '/wallet';
  static const String routeName = 'wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<WalletSummary> summary =
        ref.watch(walletSummaryProvider);
    final AsyncValue<List<WalletTransaction>> txns =
        ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l.walletTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.12),
          SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 32),
              children: <Widget>[
                _balanceCard(context, text, l, summary),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l.recentActivity),
                const SizedBox(height: AppSpacing.md),
                _ledger(context, text, l, txns),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledger(BuildContext context, TextTheme text, AppLocalizations l,
      AsyncValue<List<WalletTransaction>> txns) {
    return txns.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, _) => _LedgerMessage(
        icon: Icons.error_outline_rounded,
        title: l.walletLoadError,
      ),
      data: (List<WalletTransaction> items) {
        if (items.isEmpty) {
          return _LedgerMessage(
            icon: Icons.receipt_long_rounded,
            title: l.walletEmptyLedger,
            subtitle: l.walletEmptyLedgerHint,
          );
        }
        final Locale locale = Localizations.localeOf(context);
        return Column(
          children: items
              .map((WalletTransaction t) => _txnRow(text, t, l, locale))
              .toList(),
        );
      },
    );
  }

  Widget _balanceCard(BuildContext context, TextTheme text, AppLocalizations l,
      AsyncValue<WalletSummary> summary) {
    final Locale locale = Localizations.localeOf(context);
    final WalletSummary s = summary.valueOrNull ?? WalletSummary.empty;
    final bool loading = summary.isLoading && !summary.hasValue;
    final String balance = _money(s.balanceMajor, locale);

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
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            Text('$balance ${l.egp}',
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
                child:
                    _action(context, Icons.swap_horiz_rounded, l.sendAction, l),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Top-up and Send are disabled until the payments phase. Tapping explains why
  // rather than silently doing nothing.
  Widget _action(
      BuildContext context, IconData icon, String label, AppLocalizations l) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
                content: Text(l.featureArrivesWithPayments(label))));
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

  Widget _txnRow(TextTheme text, WalletTransaction t, AppLocalizations l,
      Locale locale) {
    final bool credit = t.isCredit;
    final ({IconData icon, Color color}) v = _visualFor(t.type);
    final String amount =
        '${credit ? '+' : '−'}${_money(t.amountMajorAbs, locale)} ${l.egp}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: v.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(v.icon, color: v.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(t.title,
                    style:
                        text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(_date(t.createdAt, locale),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ),
          Text(amount,
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: credit ? AppColors.success : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _visualFor(WalletTransactionType type) =>
      switch (type) {
        WalletTransactionType.referral => (
            icon: Icons.card_giftcard_rounded,
            color: AppColors.success
          ),
        WalletTransactionType.refund => (
            icon: Icons.replay_rounded,
            color: AppColors.success
          ),
        WalletTransactionType.credit => (
            icon: Icons.add_circle_rounded,
            color: AppColors.success
          ),
        WalletTransactionType.debit => (
            icon: Icons.remove_circle_rounded,
            color: AppColors.primary
          ),
      };

  String _money(double amount, Locale locale) =>
      intl.NumberFormat.decimalPattern(locale.toString()).format(amount);

  String _date(DateTime dt, Locale locale) =>
      intl.DateFormat.MMMd(locale.toString()).add_jm().format(dt);
}

class _LedgerMessage extends StatelessWidget {
  const _LedgerMessage({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon,
                size: 44, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style:
                    text.titleSmall?.copyWith(color: AppColors.textSecondary)),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.7))),
            ],
          ],
        ),
      ),
    );
  }
}
