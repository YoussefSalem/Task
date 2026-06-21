import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../localization/language_switcher.dart';

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
                    child: Text('Profile',
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const LanguageSwitcher(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _identity(text),
              const SizedBox(height: AppSpacing.xl),
              _walletCard(text),
              const SizedBox(height: AppSpacing.xl),
              _menu(context, text),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
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

  Widget _identity(TextTheme text) {
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
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                )),
          ],
        ),
      ],
    );
  }

  Widget _walletCard(TextTheme text) {
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
                Text('Task credit',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    )),
                const SizedBox(height: 4),
                Text('125 EGP',
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
    final List<(IconData, String, String)> items = <(IconData, String, String)>[
      (Icons.location_on_rounded, 'Saved addresses', 'Home, Work'),
      (Icons.credit_card_rounded, 'Payment methods', 'Cash, Card'),
      (Icons.history_rounded, 'Booking history', ''),
      (Icons.headset_mic_rounded, 'Help & support', ''),
      (Icons.shield_rounded, 'Privacy & security', ''),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            ListTile(
              leading: Icon(items[i].$1, color: AppColors.textSecondary),
              title: Text(items[i].$2,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: items[i].$3.isEmpty
                  ? null
                  : Text(items[i].$3,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.55),
                      )),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                      content: Text('${items[i].$2} arrives in a later phase.')));
              },
            ),
            if (i < items.length - 1)
              const Divider(height: 1, color: Color(0x14FFFFFF)),
          ],
        ],
      ),
    );
  }
}
