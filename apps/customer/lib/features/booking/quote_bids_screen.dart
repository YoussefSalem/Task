import 'package:customer/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';

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
    final List<JobRequest> jobs =
        ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
    final JobRequest? job =
        jobs.where((JobRequest j) => j.offers.isNotEmpty).isEmpty
            ? null
            : jobs.where((JobRequest j) => j.offers.isNotEmpty).first;
    final List<Offer> offers = job?.offers ?? const <Offer>[];
    final TextTheme text = Theme.of(context).textTheme;

    // Track a locally selected offer id for the CTA visibility.
    return _QuoteBidsBody(
      collecting: _collecting,
      job: job,
      offers: offers,
      text: text,
    );
  }
}

class _QuoteBidsBody extends ConsumerStatefulWidget {
  const _QuoteBidsBody({
    required this.collecting,
    required this.job,
    required this.offers,
    required this.text,
  });

  final bool collecting;
  final JobRequest? job;
  final List<Offer> offers;
  final TextTheme text;

  @override
  ConsumerState<_QuoteBidsBody> createState() => _QuoteBidsBodyState();
}

class _QuoteBidsBodyState extends ConsumerState<_QuoteBidsBody> {
  String? _selectedOfferId;

  @override
  Widget build(BuildContext context) {
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
            child: widget.collecting
                ? _collectingState(widget.text, widget.job)
                : _bidsState(widget.offers, widget.text),
          ),
          if (!widget.collecting && _selectedOfferId != null)
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

  Widget _collectingState(TextTheme text, JobRequest? job) {
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
              "Up to 5 pros bid privately for your ${job?.title.toLowerCase() ?? 'job'}. No one sees the others' price.",
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

  Widget _bidsState(List<Offer> offers, TextTheme text) {
    final int cheapest = offers.isEmpty
        ? 0
        : offers
            .map((Offer o) => o.currentPrice)
            .reduce((int a, int b) => a < b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('${offers.length} offers received',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const StatusPill(
                label: 'Sealed', tint: AppColors.primary, icon: Icons.lock),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...offers.map((Offer o) => _bidCard(
              o,
              selected: _selectedOfferId == o.id,
              best: o.currentPrice == cheapest,
              onTap: () {
                setState(() => _selectedOfferId = o.id);
                if (widget.job != null) {
                  ref
                      .read(jobMarketplaceRepositoryProvider)
                      .acceptOffer(widget.job!.id, o.id);
                }
              },
              text: text,
            )),
      ],
    );
  }

  Widget _bidCard(Offer o,
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
                        o.technicianName
                            .split(' ')
                            .map((String s) => s[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(o.technicianName,
                              style: text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 3),
                              Text('${o.rating} · ${o.jobsDone} jobs',
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
                        Text('${o.currentPrice} EGP',
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
                    Text(o.etaLabel,
                        style: text.bodySmall?.copyWith(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.7),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
