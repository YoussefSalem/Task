import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../widgets/tech_ambient.dart';
import '../../widgets/tech_glow_button.dart';
import '../home/tech_shell.dart';
import '../profile/technician_profile.dart';

/// First-run setup. A pro tells us who they are and their main trade; we write
/// the `users/{uid}` doc with `role: technician` so the customer directory and
/// the security rules recognise them.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String routeName = 'onboarding';
  static const String routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _first = TextEditingController();
  final TextEditingController _last = TextEditingController();
  JobCategory? _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Prefill from any auth-derived name already on the profile.
    final p = ref.read(techProfileProvider).valueOrNull;
    if (p != null) {
      _first.text = p.firstName;
      _last.text = p.lastName;
      _category = p.primaryCategory;
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  bool get _valid =>
      _first.text.trim().isNotEmpty && _category != null;

  Future<void> _finish() async {
    if (!_valid || _busy) return;
    final repo = ref.read(techProfileRepositoryProvider);
    if (repo == null) return;
    setState(() => _busy = true);
    try {
      await repo.completeOnboarding(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        primaryCategory: _category!,
        email: ref.read(techProfileProvider).valueOrNull?.email,
      );
      if (!mounted) return;
      context.goNamed(TechShell.dashboardRouteName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient()),
          SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        EntranceReveal(
                          child: Text(
                            'Set up your pro profile',
                            style: text.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        EntranceReveal(
                          index: 1,
                          child: Text(
                            'Customers see your name and trade when you bid.',
                            style: text.bodyLarge?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        EntranceReveal(
                          index: 2,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _first,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'First name'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextField(
                                  controller: _last,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Last name'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        EntranceReveal(
                          index: 3,
                          child: Text(
                            'Your main trade',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        EntranceReveal(
                          index: 3,
                          child: Text(
                            'Pick the service you lead with. You can bid on others too.',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 130,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.98,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final c = JobCategory.values[i];
                        return _CategoryTile(
                          category: c,
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        );
                      },
                      childCount: JobCategory.values.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
          child: TechGlowButton(
            label: 'Start working',
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _valid ? _finish : null,
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final JobCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = categoryTint(category);
    return Semantics(
      button: true,
      selected: selected,
      label: category.displayLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : scheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon(category), color: tint, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.displayLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
