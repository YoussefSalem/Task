import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../legal/legal_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/delete_account.dart';
import '../support/help_support_screen.dart';
import 'theme_controller.dart';

/// App preferences and account controls in one place.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String routeName = 'settings';
  static const String routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          _Group(title: 'Preferences', children: <Widget>[
            _SettingTile(
              icon: switch (mode) {
                ThemeMode.dark => Icons.dark_mode_outlined,
                ThemeMode.light => Icons.light_mode_outlined,
                ThemeMode.system => Icons.brightness_auto_outlined,
              },
              title: 'Appearance',
              subtitle: switch (mode) {
                ThemeMode.dark => 'Dark',
                ThemeMode.light => 'Light',
                ThemeMode.system => 'Match system',
              },
              onTap: () => ref.read(themeModeProvider.notifier).cycle(),
            ),
            _SettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              onTap: () => context.pushNamed(NotificationsScreen.routeName),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _Group(title: 'Support & legal', children: <Widget>[
            _SettingTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & support',
              onTap: () => context.pushNamed(HelpSupportScreen.routeName),
            ),
            _SettingTile(
              icon: Icons.description_outlined,
              title: 'Terms of service',
              onTap: () => context.pushNamed(LegalScreen.routeName,
                  queryParameters: <String, String>{'kind': 'terms'}),
            ),
            _SettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              onTap: () => context.pushNamed(LegalScreen.routeName,
                  queryParameters: <String, String>{'kind': 'privacy'}),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _Group(title: 'Account', children: <Widget>[
            _SettingTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              danger: true,
              onTap: () => context.pushNamed(DeleteAccountScreen.routeName),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text('Task Pro · v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    )),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  )),
        ),
        ...children,
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: danger ? AppColors.error : scheme.onSurface,
              )),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: Icon(Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.4)),
          onTap: onTap,
        ),
      ),
    );
  }
}
