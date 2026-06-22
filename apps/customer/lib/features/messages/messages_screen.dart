import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// Placeholder for the messages / inbox tab.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.08),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(AppLocalizations.of(context).messages,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                const Spacer(),
                Center(
                  child: Column(
                    children: <Widget>[
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 56,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondary.withValues(alpha: 0.3)
                              : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.lg),
                      Text(AppLocalizations.of(context).noMessagesYet,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppLocalizations.of(context).whenTechniciansRespond,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondary.withValues(alpha: 0.6)
                              : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
