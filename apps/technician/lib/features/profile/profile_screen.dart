import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/tech_colors.dart';
import '../assignments/assignments.dart';
import '../auth/auth_controller.dart';
import '../reviews/reviews_providers.dart';
import '../reviews/reviews_screen.dart';
import '../settings/settings_screen.dart';
import '../splash/splash_screen.dart';
import 'technician_profile.dart';

/// The pro's account: identity, trade, standing, and the levers they control —
/// edit name, switch trade, theme, and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String routeName = 'profile';
  static const String routePath = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TechProfile? profile = ref.watch(techProfileProvider).valueOrNull;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final summary = ref.watch(ratingSummaryProvider);
    final int activeAssignments = ref.watch(activeAssignmentCountProvider);
    // Prefer the live review average; fall back to the seeded profile rating.
    final double displayRating =
        summary.count > 0 ? summary.average : (profile?.rating ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.primary.withValues(alpha: 0.16),
                  backgroundImage: profile?.photoUrl != null
                      ? NetworkImage(profile!.photoUrl!)
                      : null,
                  child: profile?.photoUrl == null
                      ? Text(profile?.initials ?? '?',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ))
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  (profile?.fullName ?? '').isEmpty
                      ? 'Your name'
                      : profile!.fullName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (profile?.primaryCategory != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(categoryIcon(profile!.primaryCategory!),
                          size: 16,
                          color: categoryTint(profile.primaryCategory!)),
                      const SizedBox(width: 6),
                      Text(profile.primaryCategory!.displayLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (profile != null)
                  Wrap(
                    spacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      _TierBadge(tier: profile.tier),
                      _VerificationBadge(status: profile.kycStatus),
                    ],
                  ),
                if ((profile?.serviceArea ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.map_outlined,
                          size: 15,
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(profile!.serviceArea,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              )),
                    ],
                  ),
                ],
                if ((profile?.bio ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(profile!.bio,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.45)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: _StandingCard(
                  icon: Icons.star_rounded,
                  value: displayRating > 0
                      ? displayRating.toStringAsFixed(1)
                      : '—',
                  label: summary.count > 0
                      ? '${summary.count} ${summary.count == 1 ? 'review' : 'reviews'}'
                      : 'Rating',
                  tint: AppColors.warning,
                  onTap: () => context.pushNamed(ReviewsScreen.routeName),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StandingCard(
                  icon: Icons.workspace_premium_rounded,
                  value: '${profile?.jobsDone ?? 0}',
                  label: 'Jobs done',
                  tint: TechColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _Tile(
            icon: Icons.badge_outlined,
            title: 'Edit name',
            subtitle: (profile?.fullName ?? '').isEmpty ? null : profile!.fullName,
            onTap: () => _editName(context, ref, profile),
          ),
          _Tile(
            icon: Icons.handyman_outlined,
            title: 'Primary trade',
            subtitle: profile?.primaryCategory?.displayLabel,
            onTap: () => _changeTrade(context, ref),
          ),
          _Tile(
            icon: Icons.info_outline_rounded,
            title: 'About & coverage',
            subtitle: (profile?.bio ?? '').isNotEmpty
                ? profile!.bio
                : 'Add a blurb and your service area',
            onTap: () => _editAbout(context, ref, profile),
          ),
          _Tile(
            icon: Icons.phone_outlined,
            title: 'Phone',
            subtitle: (profile?.phone ?? '').isEmpty ? 'Not set' : profile!.phone,
            onTap: null,
          ),
          _Tile(
            icon: Icons.reviews_outlined,
            title: 'Your reviews',
            subtitle: summary.count > 0
                ? '${summary.average.toStringAsFixed(1)} · ${summary.count} ${summary.count == 1 ? 'review' : 'reviews'}'
                : null,
            onTap: () => context.pushNamed(ReviewsScreen.routeName),
          ),
          _Tile(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Linked jobs',
            subtitle: activeAssignments > 0
                ? '$activeAssignments active ${activeAssignments == 1 ? 'assignment' : 'assignments'}'
                : 'Jobs you’re hired on link here',
            onTap: null,
          ),
          const Divider(height: AppSpacing.xxl),
          _Tile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => context.pushNamed(SettingsScreen.routeName),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Tile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            danger: true,
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, TechProfile? profile) async {
    final first = TextEditingController(text: profile?.firstName ?? '');
    final last = TextEditingController(text: profile?.lastName ?? '');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: first,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: last,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && first.text.trim().isNotEmpty) {
      await ref.read(techProfileRepositoryProvider)?.updateName(
            firstName: first.text.trim(),
            lastName: last.text.trim(),
          );
    }
  }

  Future<void> _editAbout(
      BuildContext context, WidgetRef ref, TechProfile? profile) async {
    final bio = TextEditingController(text: profile?.bio ?? '');
    final area = TextEditingController(text: profile?.serviceArea ?? '');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About & coverage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: bio,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'About you',
                hintText: 'e.g. 10 years in AC & appliance repair.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: area,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Service area',
                hintText: 'e.g. Nasr City & New Cairo',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(techProfileRepositoryProvider)?.updateAbout(
            bio: bio.text.trim(),
            serviceArea: area.text.trim(),
          );
    }
  }

  Future<void> _changeTrade(BuildContext context, WidgetRef ref) async {
    final JobCategory? picked = await showModalBottomSheet<JobCategory>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('Choose your trade',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...JobCategory.values.map((c) => ListTile(
                  leading: Icon(categoryIcon(c), color: categoryTint(c)),
                  title: Text(c.displayLabel),
                  onTap: () => Navigator.of(context).pop(c),
                )),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(techProfileRepositoryProvider)?.updateCategory(picked);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in anytime.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider).signOut();
    if (context.mounted) context.goNamed(SplashScreen.routeName);
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final TechnicianTier tier;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (tier) {
      TechnicianTier.bronze => ('Bronze pro', const Color(0xFFB45309)),
      TechnicianTier.silver => ('Silver pro', const Color(0xFF94A3B8)),
      TechnicianTier.gold => ('Gold pro', const Color(0xFFF59E0B)),
      TechnicianTier.platinum => ('Platinum pro', const Color(0xFF7DD3FC)),
    };
    return StatusPill(
      label: label,
      tint: color,
      icon: Icons.military_tech_rounded,
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});
  final KycStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, IconData icon) = switch (status) {
      KycStatus.approved => ('Verified', TechColors.online, Icons.verified_rounded),
      KycStatus.underReview => (
          'Under review',
          AppColors.warning,
          Icons.hourglass_top_rounded
        ),
      KycStatus.rejected => ('Not verified', AppColors.error, Icons.error_outline_rounded),
      KycStatus.suspended => ('Suspended', AppColors.error, Icons.block_rounded),
      KycStatus.applied => (
          'Unverified',
          AppColors.textSecondaryLight,
          Icons.shield_outlined
        ),
    };
    return StatusPill(label: label, tint: color, icon: icon);
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: tint),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            )),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = danger ? AppColors.error : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          leading: Icon(icon, color: danger ? AppColors.error : scheme.primary),
          title: Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
          onTap: onTap,
        ),
      ),
    );
  }
}
