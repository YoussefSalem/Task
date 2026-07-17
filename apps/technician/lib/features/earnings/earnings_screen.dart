import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_data/task_data.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/tech_colors.dart';
import '../../util/money.dart';
import '../../widgets/tech_ambient.dart';
import '../home/tech_shell.dart';
import '../jobs/jobs_providers.dart';

/// Read-only wallet balance (payout ledger), written by the backend.
final walletSummaryProvider = StreamProvider<WalletSummary>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream<WalletSummary>.value(WalletSummary.empty);
  return FirestoreWalletRepository().watchSummary(uid);
});

/// What a pro has earned. Job-based totals lead (they update the moment a job
/// completes); the backend-settled payout balance sits alongside.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<JobRequest> history = ref.watch(myHistoryProvider);
    final WalletSummary wallet =
        ref.watch(walletSummaryProvider).valueOrNull ?? WalletSummary.empty;

    final int totalEarned =
        history.fold<int>(0, (s, j) => s + j.settledPrice);
    final int avg = history.isEmpty ? 0 : (totalEarned / history.length).round();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient(intensity: 0.14)),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                  AppSpacing.lg, TechShell.barClearance),
              children: <Widget>[
                Text('Earnings',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.lg),
                EntranceReveal(
                  child: _EarningsHero(
                    totalEarned: totalEarned,
                    payoutMajor: wallet.balanceMajor,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                EntranceReveal(
                  index: 1,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniStat(
                          label: 'Completed',
                          value: '${history.length}',
                          icon: Icons.check_circle_rounded,
                          tint: const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MiniStat(
                          label: 'Avg / job',
                          value: egpLabel(avg),
                          icon: Icons.trending_up_rounded,
                          tint: TechColors.earnings,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Completed jobs'),
                const SizedBox(height: AppSpacing.md),
                if (history.isEmpty)
                  const _EmptyEarnings()
                else
                  ...history.asMap().entries.map(
                        (e) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EntranceReveal(
                            index: 2 + e.key.clamp(0, 6),
                            child: _CompletedRow(job: e.value),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsHero extends StatelessWidget {
  const _EarningsHero({required this.totalEarned, required this.payoutMajor});
  final int totalEarned;
  final double payoutMajor;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: TechColors.earnings.withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Total earned',
              style: text.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: AppSpacing.xs),
          Text(egpLabel(totalEarned),
              style: text.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              )),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Available for payout: EGP ${NumberFormat('#,##0.00').format(payoutMajor)}',
                  style: text.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: tint, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  )),
        ],
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.job});
  final JobRequest job;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = categoryTint(job.category);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon(job.category), color: tint, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(job.title.isEmpty ? job.category.displayLabel : job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(DateFormat('MMM d, yyyy').format(job.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        )),
              ],
            ),
          ),
          Text('+${egpLabel(job.settledPrice)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TechColors.online,
                  )),
        ],
      ),
    );
  }
}

class _EmptyEarnings extends StatelessWidget {
  const _EmptyEarnings();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.savings_outlined,
              size: 40, color: scheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('No earnings yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Complete your first job and it’ll show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  )),
        ],
      ),
    );
  }
}
