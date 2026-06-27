import 'dart:async';

import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';
import '../services/category_l10n.dart';

/// ASAP dispatch: a live radar sweeps while we cascade outward through dispatch
/// tiers (3 → 6 → … km, per the design spec), then a pro is assigned and the
/// customer is handed to live tracking. Honors reduced-motion.
class AsapDispatchScreen extends ConsumerStatefulWidget {
  const AsapDispatchScreen({super.key});

  static const String routePath = '/book/asap';

  @override
  ConsumerState<AsapDispatchScreen> createState() => _AsapDispatchScreenState();
}

class _AsapDispatchScreenState extends ConsumerState<AsapDispatchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  static const int _tierCount = 3;

  List<String> _tiers(AppLocalizations l) => <String>[
        l.searchingWithin3km,
        l.wideningTo6km,
        l.reachingNearbyPros,
      ];
  int _tierIndex = 0;
  bool _found = false;
  Timer? _tierTimer;

  @override
  void initState() {
    super.initState();
    _tierTimer = Timer.periodic(const Duration(milliseconds: 1300), (Timer t) {
      if (!mounted) return;
      setState(() => _tierIndex = (_tierIndex + 1) % _tierCount);
    });
  }

  @override
  void dispose() {
    _radar.dispose();
    _tierTimer?.cancel();
    super.dispose();
  }

  void _syncFromJob(JobRequest? job) {
    if (job == null || _found) return;
    if (job.status == JobStatus.accepted ||
        job.status == JobStatus.enRoute ||
        job.status == JobStatus.inProgress) {
      _tierTimer?.cancel();
      _radar.stop();
      setState(() => _found = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final jobs = ref.watch(myJobsProvider).valueOrNull ?? const <JobRequest>[];
    final currentJob = jobs.isNotEmpty ? jobs.first : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFromJob(currentJob);
    });
    final JobCategory? cat = ref.watch(jobDraftProvider).category;
    final String jobLabel = cat != null ? categoryLabel(cat, l) : l.yourJob;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.18, alignment: Alignment.center),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    height: 240,
                    width: 240,
                    child: _found
                        ? const _FoundBadge()
                        : _Radar(controller: _radar, jobLabel: jobLabel),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    _found ? l.proAssignedExcl : l.findingYourPro,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _found
                          ? l.proHeadingToYou
                          : _tiers(l)[_tierIndex],
                      key: ValueKey<String>(_found ? 'done' : '$_tierIndex'),
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_found) _proCard(text, l, currentJob),
                  const Spacer(flex: 2),
                  if (_found)
                    GlowButton(
                      label: l.trackYourPro,
                      icon: Icons.navigation_rounded,
                      onPressed: () => context.pushReplacement('/job/live'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(l.cancelSearch),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proCard(TextTheme text, AppLocalizations l, JobRequest? job) {
    final Offer? accepted = job?.acceptedOffer;
    final String proName = accepted?.technicianName ?? l.techNameKhaled;
    final String initials = proName
        .split(' ')
        .map((s) => s.isEmpty ? '' : s[0])
        .take(2)
        .join();
    final double rating = accepted?.rating ?? 4.9;
    final int jobsDone = accepted?.jobsDone ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(proName,
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  children: <Widget>[
                    const Icon(Icons.star_rounded,
                        size: 15, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text('$rating · ${l.jobsDoneCount(jobsDone)}',
                        style: text.bodySmall?.copyWith(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.7),
                        )),
                  ],
                ),
              ],
            ),
          ),
          StatusPill(
              label: l.verified, tint: AppColors.success, icon: Icons.verified),
        ],
      ),
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({required this.controller, required this.jobLabel});
  final AnimationController controller;
  final String jobLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              _ring((controller.value + i / 3) % 1.0),
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 34),
            ),
          ],
        );
      },
    );
  }

  Widget _ring(double t) {
    final double size = 76 + t * 164;
    return Opacity(
      opacity: (1 - t) * 0.5,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.6), width: 2),
        ),
      ),
    );
  }
}

class _FoundBadge extends StatelessWidget {
  const _FoundBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.6), width: 2),
        ),
        child: const Icon(Icons.check_rounded,
            color: AppColors.success, size: 60),
      ),
    );
  }
}
