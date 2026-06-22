import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import '../localization/language_switcher.dart';
import '../settings/theme_controller.dart';

/// The Profile tab: identity header, wallet credit, and account menu. Most rows
/// are stubbed affordances pending their feature phases; sign-out returns to
/// the entry screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.12),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 112),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(AppLocalizations.of(context).profile,
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const LanguageSwitcher(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _identity(context, text),
              const SizedBox(height: AppSpacing.xl),
              _walletCard(context, text, ref),
              const SizedBox(height: AppSpacing.xl),
              _AppearanceSection(text: text),
              const SizedBox(height: AppSpacing.xl),
              _menu(context, text),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.logout_rounded),
                label: Text(AppLocalizations.of(context).signOut),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _identity(BuildContext context, TextTheme text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: <Widget>[
        const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primary,
          child: Text('NA',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22)),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Nour Adel',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('+20 100 482 1928',
                style: text.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.65)
                      : AppColors.textSecondaryLight,
                )),
          ],
        ),
      ],
    );
  }

  Widget _walletCard(BuildContext context, TextTheme text, WidgetRef ref) {
    final int balance = ref.watch(walletCreditProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF5B21B6), Color(0xFF7C3AED)],
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppLocalizations.of(context).taskCredit,
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    )),
                const SizedBox(height: 4),
                Text('$balance EGP',
                    style: text.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 36),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, TextTheme text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;
    // Dark: α 0.55 on dark surface ≈ 5:1. Light: full opacity ≈ 6.7:1 on white.
    final Color subtitleColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textSecondaryLight;
    final Color dividerColor =
        isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);

    final AppLocalizations loc = AppLocalizations.of(context);
    final List<(IconData, String, String)> items = <(IconData, String, String)>[
      (Icons.location_on_rounded, loc.savedAddresses, '${loc.home}, ${loc.work}'),
      (Icons.credit_card_rounded, loc.paymentMethods, loc.cashCard),
      (Icons.history_rounded, loc.bookingHistory, ''),
      (Icons.headset_mic_rounded, loc.helpAndSupport, ''),
      (Icons.shield_rounded, loc.privacyAndSecurity, ''),
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.5)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            ListTile(
              leading: Icon(items[i].$1, color: iconColor),
              title: Text(items[i].$2,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: items[i].$3.isEmpty
                  ? null
                  : Text(items[i].$3,
                      style: text.bodySmall?.copyWith(color: subtitleColor)),
              trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                      content: Text('${items[i].$2} arrives in a later phase.')));
              },
            ),
            if (i < items.length - 1) Divider(height: 1, color: dividerColor),
          ],
        ],
      ),
    );
  }
}

/// Three-way appearance picker: System · Light · Dark.
///
/// Displayed as a segmented selector inside a card so it reads as a distinct
/// settings group rather than just another list item.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection({required this.text});

  final TextTheme text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode current = ref.watch(themeModeProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations loc = AppLocalizations.of(context);

    final List<(ThemeMode, IconData, String)> options = <(
      ThemeMode,
      IconData,
      String
    )>[
      (ThemeMode.system, Icons.brightness_auto_rounded, loc.system),
      (ThemeMode.light, Icons.light_mode_rounded, loc.light),
      (ThemeMode.dark, Icons.dark_mode_rounded, loc.dark),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            AppLocalizations.of(context).appearance,
            style: text.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface.withValues(alpha: 0.5)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark
                  ? const Color(0x14FFFFFF)
                  : const Color(0x14000000),
            ),
          ),
          child: Row(
            children: <Widget>[
              for (final (ThemeMode mode, IconData icon, String label)
                  in options)
                Expanded(
                  child: _AppearanceChip(
                    icon: icon,
                    label: label,
                    selected: current == mode,
                    primaryColor: cs.primary,
                    isDark: isDark,
                    onTap: () async {
                      ref.read(themeModeProvider.notifier).state = mode;
                      await saveThemeMode(mode);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceChip extends StatelessWidget {
  const _AppearanceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.7)
                        : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.7)
                          : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
