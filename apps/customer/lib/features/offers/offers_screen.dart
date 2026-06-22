import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';
import '../chat/chat_screen.dart';

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
                  tooltip: 'Back to home',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/home'),
                ),
                title: const Text('Offers received'),
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
                        Text('${offers.length} offers',
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
                            'Chat or call a technician before hiring. All payments go through the app.',
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
                  label: 'Hire & track',
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

  void _acceptAndSelect(WidgetRef ref) {
    onSelect();
    if (job != null) {
      ref.read(jobMarketplaceRepositoryProvider).acceptOffer(job!.id, offer.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
          onTap: () => _acceptAndSelect(ref),
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
                                  child: Text('Best price',
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
                                '${offer.rating} · ${offer.jobsDone} jobs done',
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
                          Text('Price',
                              style: text.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                                    : AppColors.textSecondaryLight,
                              )),
                          const SizedBox(height: 3),
                          Text('${offer.currentPrice} EGP',
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
                          Text('Arrives',
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
                        label: 'Chat',
                        color: AppColors.primary,
                        onTap: () => context.push(
                          ChatScreen.routePath,
                          extra: ChatArgs(
                            technicianId: offer.technicianId,
                            technicianName: offer.technicianName,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: AppColors.success,
                        onTap: () => _showCallSheet(context, offer),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        icon: selected
                            ? Icons.check_rounded
                            : Icons.handshake_rounded,
                        label: selected ? 'Selected' : 'Select offer',
                        color: selected ? AppColors.success : AppColors.primary,
                        filled: true,
                        onTap: () => _acceptAndSelect(ref),
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

  void _showCallSheet(BuildContext context, Offer o) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CallSheet(offer: o),
    );
  }
}

// ---------------------------------------------------------------------------
// Call bottom sheet (VoIP stub)
// ---------------------------------------------------------------------------
class _CallSheet extends StatefulWidget {
  const _CallSheet({required this.offer});
  final Offer offer;

  @override
  State<_CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends State<_CallSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _callActive = false;
  int _seconds = 0;
  Timer? _ticker;

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
    _ticker?.cancel();
    super.dispose();
  }

  void _startCall() {
    setState(() => _callActive = true);
    _ticker = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _seconds++));
  }

  void _endCall() {
    _ticker?.cancel();
    Navigator.pop(context);
  }

  String get _timer {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
          AppSpacing.xl + mq.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0x22000000),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
                boxShadow: _callActive
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(
                              alpha: 0.2 + _pulseCtrl.value * 0.18),
                          blurRadius: 24 + _pulseCtrl.value * 12,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: const Icon(Icons.call_rounded,
                  color: AppColors.success, size: 38),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(widget.offer.technicianName,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            _callActive ? _timer : 'In-app VoIP call',
            style: text.bodyMedium?.copyWith(
              color: _callActive
                  ? AppColors.success
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary.withValues(alpha: 0.6)
                      : AppColors.textSecondaryLight),
              fontWeight: _callActive ? FontWeight.w600 : null,
              fontFeatures: _callActive
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          if (!_callActive)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _startCall,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.call_rounded),
                label: const Text('Start call',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _endCall,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.call_end_rounded),
                label: const Text('End call',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go back to offers',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary.withValues(alpha: 0.6)
                      : AppColors.textSecondaryLight,
                )),
          ),
        ],
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
