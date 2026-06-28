import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Terms of Service. Shows mock (but realistic) terms copy; swap for the final,
/// legally reviewed text before launch.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String routePath = '/legal/terms';
  static const String routeName = 'terms';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l.termsOfService)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                Text(l.privacyLastUpdated,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    )),
                const SizedBox(height: AppSpacing.xl),
                Text(l.termsOfServiceBody,
                    style: text.bodyMedium?.copyWith(
                      height: 1.55,
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.85)
                          : AppColors.textSecondaryLight,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
