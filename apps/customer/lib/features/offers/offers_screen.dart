import 'package:customer/l10n/app_localizations.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../call/call_controller.dart';
import '../call/call_screen.dart';
import '../chat/chat_providers.dart';
import '../chat/chat_screen.dart';
import '../marketplace/marketplace_providers.dart';

/// Offer phase: technicians have responded with bids.
/// Users can chat or call each technician, compare offers, and hire.
class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  static const String routePath = '/offers';
  static const String routeName = 'offers';

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedOfferId;
  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
    final job = jobs.where((j) => j.offers.isNotEmpty).isEmpty
        ? null
        : jobs.where((j) => j.offers.isNotEmpty).first;
    final offers = job?.offers ?? const <Offer>[];
    final text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);

    final cheapest = offers.isEmpty
        ? 0
        : offers.map((o) => o.currentPrice).reduce(math.min);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBackground(intensity: 0.08),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                // Back to home — search is done once the user is reviewing offers.
                leading: IconButton(
                  tooltip: l.backToHome,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/home'),
                ),
                title: Text(l.offersReceived),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.success),
                        ),
                        const SizedBox(width: 6),
                        Text(l.offersCountShort(offers.length),
                            style: text.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.chatOrCallTechnician,
                            style: text.bodySmall?.copyWith(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final o = offers[i];
                    final delay = i * 60;
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _enterCtrl,
                        curve: Interval(
                          (delay / 500).clamp(0.0, 0.8),
                          ((delay + 300) / 500).clamp(0.0, 1.0),
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _enterCtrl,
                          curve: Interval(
                            (delay / 500).clamp(0.0, 0.8),
                            ((delay + 300) / 500).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                          child: _OfferCard(
                            offer: o,
                            selected: _selectedOfferId == o.id,
                            isBest: o.currentPrice == cheapest,
                            job: job,
                            onSelect: () => setState(() => _selectedOfferId = o.id),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: offers.length,
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 120 + mq.padding.bottom),
              ),
            ],
          ),

          // Sticky hire bar
          if (_selectedOfferId != null)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
                  AppSpacing.lg + mq.padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0x12000000),
                    ),
                  ),
                ),
                child: GlowButton(
                  label: l.hireAndTrack,
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    // Hiring closes the active search.
                    ref.read(activeSearchProvider.notifier).state = null;
                    context.pushReplacement('/job/live');
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offer card with chat + call
// ---------------------------------------------------------------------------
class _OfferCard extends ConsumerWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.isBest,
    required this.job,
    required this.onSelect,
  });

  final Offer offer;
  final bool selected;
  final bool isBest;
  final JobRequest? job;
  final VoidCallback onSelect;

  void _acceptAndSelect(WidgetRef ref, AppLocalizations l) {
    onSelect();
    if (job != null) {
      ref.read(jobMarketplaceRepositoryProvider).acceptOffer(job!.id, offer.id);
      // Tell the hired technician (in-app feed; no server fan-out yet).
      ref.read(notificationRepositoryProvider).notify(
            recipientUid: offer.technicianId,
            draft: NotificationDraft(
              type: NotificationType.hired,
              title: l.notifHiredTitle,
              body: l.notifHiredBody,
              jobId: job!.id,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? AppColors.surface.withValues(alpha: 0.45) : Colors.white),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.8)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0x12000000)),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: () => _acceptAndSelect(ref, l),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(name: offer.technicianName),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(offer.technicianName,
                                    style: text.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                              ),
                              if (isBest)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(l.bestPrice,
                                      style: text.labelSmall?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 13, color: AppColors.warning),
                              const SizedBox(width: 3),
                              Text(
                                '${offer.rating} · ${l.jobsDoneCount(offer.jobsDone)}',
                                style: text.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondary.withValues(alpha: 0.65)
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0x12FFFFFF)
                        : const Color(0x12000000)),
                const SizedBox(height: AppSpacing.md),

                // Price + ETA
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.price,
                              style: text.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                                    : AppColors.textSecondaryLight,
                              )),
                          const SizedBox(height: 3),
                          Text('${offer.currentPrice} ${l.egp}',
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: selected ? AppColors.primary : null,
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.arrives,
                              style: text.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                                    : AppColors.textSecondaryLight,
                              )),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.textSecondary.withValues(alpha: 0.6)
                                      : AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Text(offer.etaLabel,
                                  style: text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Chat + Call row
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: l.chat,
                        color: AppColors.primary,
                        onTap: () {
                          if (job == null) return;
                          context.push(
                            ChatScreen.routePath,
                            extra: ChatArgs(
                              jobId: job!.id,
                              technicianId: offer.technicianId,
                              technicianName: offer.technicianName,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: l.call,
                        color: AppColors.success,
                        onTap: () => _callTechnician(context, offer),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        icon: selected
                            ? Icons.check_rounded
                            : Icons.handshake_rounded,
                        label: selected ? l.selectedLabel : l.selectOffer,
                        color: selected ? AppColors.success : AppColors.primary,
                        filled: true,
                        onTap: () => _acceptAndSelect(ref, l),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _callTechnician(BuildContext context, Offer o) {
    context.push(
      CallScreen.routePath,
      extra: CallArgs(
        offerId: o.id,
        technicianId: o.technicianId,
        technicianName: o.technicianName,
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((s) => s.isEmpty ? '' : s[0])
        .take(2)
        .join();
    return Container(
      width: 48, height: 48,
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
