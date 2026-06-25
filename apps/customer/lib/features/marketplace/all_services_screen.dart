import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';
import '../services/category_l10n.dart';
import 'job_create_stub_screen.dart';

class AllServicesScreen extends ConsumerWidget {
  const AllServicesScreen({super.key});

  static const String routePath = '/services';
  static const String routeName = 'all-services';

  static List<_ServiceGroup> _groupsFor(AppLocalizations l) => <_ServiceGroup>[
        _ServiceGroup(l.popular, const [
          JobCategory.plumbing,
          JobCategory.electrical,
          JobCategory.painting,
          JobCategory.carpentry,
          JobCategory.ac,
          JobCategory.cleaning,
        ]),
        _ServiceGroup(l.constructionAndFinishing, const [
          JobCategory.tilesHandyman,
          JobCategory.masonStones,
          JobCategory.plaster,
          JobCategory.gypsumWorks,
          JobCategory.gypsumBoard,
          JobCategory.marbleGranite,
          JobCategory.parquet,
          JobCategory.puCornices,
        ]),
        _ServiceGroup(l.doorsWindowsAndGlass, const [
          JobCategory.alumetal,
          JobCategory.glassCecurit,
          JobCategory.curtainsUpholstery,
        ]),
        _ServiceGroup(l.specializedServices, const [
          JobCategory.smith,
          JobCategory.woodPainter,
          JobCategory.satelliteInstallation,
          JobCategory.smartHome,
          JobCategory.movingServices,
          JobCategory.materialWinch,
        ]),
        _ServiceGroup(l.maintenanceGroup, const [
          JobCategory.appliancesMaintenance,
          JobCategory.swimmingPool,
          JobCategory.pestControl,
        ]),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<_ServiceGroup> groups = _groupsFor(l);
    final mq = MediaQuery.of(context);

    void selectCategory(JobCategory c) {
      ref.read(jobDraftProvider.notifier).startCategory(c);
      context.push(JobCreateStubScreen.routePath);
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBackground(intensity: 0.08),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Builder(builder: (context) {
                    final bool isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.surface.withValues(alpha: 0.6)
                            : const Color(0xFFF0EEFF),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0x14000000),
                        ),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          size: 18),
                    );
                  }),
                  onPressed: () => context.pop(),
                ),
                title: Text(l.allServices,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                centerTitle: true,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                    AppSpacing.lg, mq.padding.bottom + AppSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final group = groups[index];
                      return _GroupSection(
                        group: group,
                        text: text,
                        groupIndex: index,
                        onTap: selectCategory,
                      );
                    },
                    childCount: groups.length,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------
class _ServiceGroup {
  const _ServiceGroup(this.title, this.categories);
  final String title;
  final List<JobCategory> categories;
}

// ---------------------------------------------------------------------------
// Group section with staggered animation
// ---------------------------------------------------------------------------
class _GroupSection extends StatefulWidget {
  const _GroupSection({
    required this.group,
    required this.text,
    required this.groupIndex,
    required this.onTap,
  });
  final _ServiceGroup group;
  final TextTheme text;
  final int groupIndex;
  final ValueChanged<JobCategory> onTap;

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.groupIndex * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(curved),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 4, bottom: AppSpacing.md),
                child: Builder(builder: (context) {
                  final bool isDark = Theme.of(context).brightness == Brightness.dark;
                  return Text(widget.group.title,
                      style: widget.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.textSecondaryLight,
                        letterSpacing: 0.3,
                      ));
                }),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.group.categories
                    .map((c) => _ServiceTile(
                          category: c,
                          onTap: () => widget.onTap(c),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual service tile
// ---------------------------------------------------------------------------
class _ServiceTile extends StatefulWidget {
  const _ServiceTile({required this.category, required this.onTap});
  final JobCategory category;
  final VoidCallback onTap;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tint = categoryTint(widget.category);
    final icon = categoryIcon(widget.category);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final width = (MediaQuery.of(context).size.width - AppSpacing.lg * 2 - 20) / 3;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Container(
                width: width,
                height: width * 0.82,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [tint.withValues(alpha: 0.12), tint.withValues(alpha: 0.04)]
                        : [tint.withValues(alpha: 0.15), tint.withValues(alpha: 0.07)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tint.withValues(alpha: isDark ? 0.15 : 0.30),
                  ),
                ),
                child: Icon(icon, color: tint, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                categoryLabel(widget.category, AppLocalizations.of(context)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textPrimaryLight,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
