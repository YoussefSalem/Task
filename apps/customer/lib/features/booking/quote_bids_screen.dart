import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../services/service_catalog.dart';
import 'booking_state.dart';

/// Quote engine: offers arrive sealed (price hidden from rival pros), capped at
/// five. We show a brief collecting state, then reveal the offers to compare.
class QuoteBidsScreen extends ConsumerStatefulWidget {
  const QuoteBidsScreen({super.key});

  static const String routePath = '/book/quotes';

  @override
  ConsumerState<QuoteBidsScreen> createState() => _QuoteBidsScreenState();
}

class _QuoteBidsScreenState extends ConsumerState<QuoteBidsScreen> {
  bool _collecting = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final bool reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _timer = Timer(Duration(milliseconds: reduce ? 150 : 2600), () {
      if (mounted) setState(() => _collecting = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BookingDraft draft = ref.watch(bookingProvider);
    final Service? service = draft.service;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Compare offers'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: _collecting
                ? _collectingState(text, service)
                : _bidsState(draft, text),
          ),
          if (!_collecting && draft.selectedBidId != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
                ),
                child: GlowButton(
                  label: 'Hire & track',
                  onPressed: () => context.push('/job/live'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _collectingState(TextTheme text, Service? service) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Collecting sealed offers…',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              'Up to 5 pros bid privately for your ${service?.name.toLowerCase() ?? 'job'}. No one sees the others’ price.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bidsState(BookingDraft draft, TextTheme text) {
    final int cheapest =
        kBids.map((Bid b) => b.price).reduce((int a, int b) => a < b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('${kBids.length} offers received',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const StatusPill(
                label: 'Sealed', tint: AppColors.primary, icon: Icons.lock),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...kBids.map((Bid b) => _bidCard(
              b,
              selected: draft.selectedBidId == b.id,
              best: b.price == cheapest,
              onTap: () => ref.read(bookingProvider.notifier).selectBid(b.id),
              text: text,
            )),
      ],
    );
  }

  Widget _bidCard(Bid b,
      {required bool selected,
      required bool best,
      required VoidCallback onTap,
      required TextTheme text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.surface.withValues(alpha: 0.5),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                      child: Text(
                        b.proName.split(' ').map((String s) => s[0]).take(2).join(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(b.proName,
                              style: text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 3),
                              Text('${b.rating} · ${b.jobsDone} jobs',
                                  style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.7),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text('${b.price} EGP',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (best)
                          Text('Lowest',
                              style: text.labelSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Icon(Icons.schedule_rounded,
                        size: 15,
                        color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(b.etaLabel,
                        style: text.bodySmall?.copyWith(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.7),
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Text('“${b.note}”',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.75),
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
