import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../services/service_catalog.dart';
import '../services/technician_catalog.dart';

/// Home dashboard: location header, promo banner, category grid, and the
/// top-rated technicians. Categories and technicians both lead into the
/// booking flow.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Reference order for the 3-column grid.
  static const List<String> _gridOrder = <String>[
    'plumbing',
    'electrical',
    'ac',
    'carpentry',
    'painting',
    'cleaning',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.13),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 112),
            children: <Widget>[
              _LocationHeader(text: text),
              const SizedBox(height: AppSpacing.xl),
              Text('Hello, Ahmed!',
                  style:
                      text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('What can we help you with today?',
                  style: text.titleSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
                  )),
              const SizedBox(height: AppSpacing.lg),
              const _SearchBar(),
              const SizedBox(height: AppSpacing.xl),
              const _PromoBanner(),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Categories',
                actionLabel: 'View All',
                onAction: () => _snack(context, 'All categories arrive soon.'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _categoryGrid(context),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Top Rated Technicians'),
              const SizedBox(height: AppSpacing.lg),
              ...kTechnicians.map((Technician t) => _TechnicianCard(
                    tech: t,
                    onTap: () => context.push('/service/${t.serviceId}'),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryGrid(BuildContext context) {
    final List<ServiceCategory> cats = _gridOrder
        .map((String id) =>
            kCategories.firstWhere((ServiceCategory c) => c.id == id))
        .toList();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.92,
      children: cats.map((ServiceCategory c) {
        final Service rep = servicesForCategory(c.id).first;
        return _CategoryTile(
          category: c,
          onTap: () => context.push('/service/${rep.id}'),
        );
      }).toList(),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.text});
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.location_on_rounded,
            color: AppColors.primary, size: 22),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Your Location',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.55),
                  )),
              Text('Maadi, Cairo',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        _circle(child: const Icon(Icons.notifications_none_rounded, size: 22)),
        const SizedBox(width: AppSpacing.sm),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const ClipOval(child: _Avatar(seed: 'ahmed-user', initials: 'A')),
        ),
      ],
    );
  }

  Widget _circle({required Widget child}) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: IconTheme(
        data: const IconThemeData(color: AppColors.textSecondary),
        child: child,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.md),
          Text('Search for plumbing, electrical, etc.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.55),
              )),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF6D28D9), Color(0xFF8B5CF6)],
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
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -8,
            top: -4,
            child: Icon(Icons.handyman_rounded,
                size: 120, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 220,
                child: Text('Professional Services at Your Fingertips',
                    style: text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    )),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Get 20% off your first plumbing request this month.',
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  )),
              const SizedBox(height: AppSpacing.lg),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(const SnackBar(
                          content: Text('Promo offers arrive in a later phase.')));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: 10),
                    child: Text('Claim Now',
                        style: text.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        )),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(category.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(category.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.tech, required this.onTap});
  final Technician tech;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: SizedBox(
                        height: 72,
                        width: 72,
                        child: _Avatar(seed: tech.id, initials: tech.initials,
                            url: tech.photoUrl),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        height: 18,
                        width: 18,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.background, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(tech.name,
                                style: text.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.star_rounded,
                                  size: 15, color: AppColors.warning),
                              const SizedBox(width: 2),
                              Text(tech.rating.toStringAsFixed(1),
                                  style: text.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${tech.specialty} · ${tech.jobsLabel}',
                          style: text.bodySmall?.copyWith(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 6,
                        children: <Widget>[
                          StatusPill(
                              label: tech.badge.label, tint: tech.badge.tint),
                          StatusPill(
                              label: '${tech.hourlyRate} EGP/HR',
                              tint: AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Network photo with a deterministic colored initials fallback (used while the
/// image loads or if it fails — keeps cards readable offline).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed, required this.initials, this.url});
  final String seed;
  final String initials;
  final String? url;

  static const List<Color> _palette = <Color>[
    Color(0xFF7C3AED),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
  ];

  @override
  Widget build(BuildContext context) {
    final Color bg = _palette[seed.hashCode.abs() % _palette.length];
    final Widget fallback = ColoredBox(
      color: bg,
      child: Center(
        child: Text(initials,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
      ),
    );
    if (url == null) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) =>
          p == null ? child : fallback,
    );
  }
}
