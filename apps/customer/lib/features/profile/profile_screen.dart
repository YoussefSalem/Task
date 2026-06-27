import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../auth/auth_controller.dart';
import '../address/address_repository.dart';
import '../address/address_screen.dart';
import '../booking/booking_state.dart';
import '../bookings/booking_history_screen.dart';
import '../legal/privacy_screen.dart';
import '../support/help_support_screen.dart';
import '../localization/language_switcher.dart';
import '../settings/theme_controller.dart';
import 'profile_edit.dart';
import 'user_profile.dart';

/// The Profile tab: identity header, wallet credit, and account menu. Most rows
/// are stubbed affordances pending their feature phases; sign-out returns to
/// the entry screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final UserProfile profile =
        ref.watch(userProfileProvider).valueOrNull ?? const UserProfile();

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
              EntranceReveal(
                index: 0,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(AppLocalizations.of(context).profile,
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const LanguageSwitcher(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              EntranceReveal(
                index: 1,
                child: _identity(context, text, profile, ref),
              ),
              const SizedBox(height: AppSpacing.xl),
              EntranceReveal(
                index: 2,
                child: _personalDetails(context, text, profile, ref),
              ),
              const SizedBox(height: AppSpacing.xl),
              EntranceReveal(index: 3, child: _walletCard(context, text, ref)),
              const SizedBox(height: AppSpacing.xl),
              EntranceReveal(index: 4, child: _AppearanceSection(text: text)),
              const SizedBox(height: AppSpacing.xl),
              EntranceReveal(index: 5, child: _menu(context, text, ref)),
              const SizedBox(height: AppSpacing.xl),
              EntranceReveal(
                index: 6,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted) context.go('/');
                  },
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _identity(BuildContext context, TextTheme text, UserProfile profile,
      WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);
    final String name =
        profile.fullName.isNotEmpty ? profile.fullName : l.demoProfileName;
    final String phone =
        profile.phone.isNotEmpty ? profile.phone : l.notSet;
    final String initials =
        profile.fullName.isNotEmpty ? profile.initials : l.demoProfileInitials;
    final Color editTint = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.7)
        : AppColors.textSecondaryLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showEditNameSheet(context, ref, profile),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name,
                        style: text.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(phone,
                        style: text.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondary.withValues(alpha: 0.65)
                              : AppColors.textSecondaryLight,
                        )),
                  ],
                ),
              ),
              // Edit affordance — taps anywhere on the row open the name editor.
              Semantics(
                button: true,
                label: l.editName,
                child: Container(
                  height: 36,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.surface.withValues(alpha: 0.5)
                        : AppColors.primaryContainer,
                  ),
                  child: Icon(Icons.edit_rounded, size: 18, color: editTint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Email + birthday card. Both fall back to "Not set" when the user signed in
  /// via a path that didn't collect them.
  Widget _personalDetails(BuildContext context, TextTheme text,
      UserProfile profile, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);
    final Color dividerColor =
        isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);
    final Color labelColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textSecondaryLight;

    final bool hasPhone = profile.phone.isNotEmpty;
    final bool hasBirthday = profile.birthday != null;
    final String email = profile.email.isNotEmpty ? profile.email : l.notSet;
    final String phone = hasPhone ? profile.phone : l.notSet;
    final String birthday =
        hasBirthday ? _formatBirthday(profile.birthday!, l) : l.notSet;

    // A detail row. When [onTap] is set the row is interactive and shows an
    // affordance — a pencil to change an existing value, or a plus to add a
    // missing one. Read-only rows (email) render without either.
    Widget row(IconData icon, String label, String value,
        {VoidCallback? onTap, bool unset = false}) {
      final Widget content = Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: text.bodySmall?.copyWith(color: labelColor)),
            const SizedBox(width: AppSpacing.lg),
            // Value fills the rest of the row and right-aligns, so every value
            // lands flush against the same right margin regardless of length
            // (a Spacer + Flexible would split the gap 50/50 instead).
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                unset ? Icons.add_circle_outline_rounded : Icons.edit_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      );
      if (onTap == null) return content;
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(l.personalDetails,
              style: text.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              )),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface.withValues(alpha: 0.5)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: dividerColor),
          ),
          child: Column(
            children: <Widget>[
              row(Icons.email_rounded, l.emailAddress, email),
              Divider(height: 1, color: dividerColor),
              row(
                Icons.phone_rounded,
                l.phoneNumberLabel,
                phone,
                unset: !hasPhone,
                onTap: () => showPhoneSheet(context, ref, hasPhone: hasPhone),
              ),
              Divider(height: 1, color: dividerColor),
              row(
                Icons.cake_rounded,
                l.birthday,
                birthday,
                unset: !hasBirthday,
                onTap: () =>
                    pickAndSaveBirthday(context, ref, profile.birthday),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBirthday(DateTime d, AppLocalizations l) {
    final List<String> months = <String>[
      l.january, l.february, l.march, l.april, l.may, l.june,
      l.july, l.august, l.september, l.october, l.november, l.december,
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
                Text('$balance ${AppLocalizations.of(context).egp}',
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

  Widget _menu(BuildContext context, TextTheme text, WidgetRef ref) {
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
    final List<SavedAddress> addresses =
        ref.watch(savedAddressesProvider).valueOrNull ?? const <SavedAddress>[];
    final String addressSummary =
        addresses.map((SavedAddress a) => a.label).join(', ');
    // (icon, title, subtitle, onTap). A null onTap falls back to the
    // "arrives later" snackbar — currently only Payment methods.
    final List<(IconData, String, String, VoidCallback?)> items =
        <(IconData, String, String, VoidCallback?)>[
      (
        Icons.location_on_rounded,
        loc.savedAddresses,
        addressSummary,
        () => context.push(AddressScreen.routePath)
      ),
      (Icons.credit_card_rounded, loc.paymentMethods, loc.cashCard, null),
      (
        Icons.history_rounded,
        loc.bookingHistory,
        '',
        () => context.push(BookingHistoryScreen.routePath)
      ),
      (
        Icons.headset_mic_rounded,
        loc.helpAndSupport,
        '',
        () => context.push(HelpSupportScreen.routePath)
      ),
      (
        Icons.shield_rounded,
        loc.privacyAndSecurity,
        '',
        () => context.push(PrivacyScreen.routePath)
      ),
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
              onTap: items[i].$4 ??
                  () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                          content: Text(loc.featureArrivesLater(items[i].$2))));
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
