import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

/// Help & Support: direct contact rows (tap to copy) plus a short FAQ. Contact
/// details are placeholders until the real support channels are live.
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const String routePath = '/profile/support';

  // Placeholder contact channels — swap for the real ones before launch.
  static const String _supportEmail = 'support@task.app';
  static const String _supportPhone = '+20 100 000 0000';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dividerColor =
        isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);
    final Color cardColor = isDark
        ? AppColors.surface.withValues(alpha: 0.5)
        : AppColors.surfaceLight;

    void copy(String value) {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.copiedToClipboard(value))));
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent, title: Text(l.helpAndSupport)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                Text(l.helpSupportIntro,
                    style: text.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.75)
                          : AppColors.textSecondaryLight,
                    )),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l.contactUs),
                const SizedBox(height: AppSpacing.md),
                _Card(
                  color: cardColor,
                  borderColor: dividerColor,
                  child: Column(
                    children: <Widget>[
                      _ContactRow(
                        icon: Icons.email_rounded,
                        label: l.contactEmail,
                        value: _supportEmail,
                        onTap: () => copy(_supportEmail),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _ContactRow(
                        icon: Icons.phone_rounded,
                        label: l.contactPhone,
                        value: _supportPhone,
                        onTap: () => copy(_supportPhone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l.commonQuestions),
                const SizedBox(height: AppSpacing.md),
                _Card(
                  color: cardColor,
                  borderColor: dividerColor,
                  child: Column(
                    children: <Widget>[
                      _FaqTile(question: l.faqBookingQ, answer: l.faqBookingA),
                      Divider(height: 1, color: dividerColor),
                      _FaqTile(question: l.faqCancelQ, answer: l.faqCancelA),
                      Divider(height: 1, color: dividerColor),
                      _FaqTile(question: l.faqPaymentQ, answer: l.faqPaymentA),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded card whose fill is a [Material] so child [ListTile]s can paint their
/// ink splashes (a plain colored [Container] would hide them). The border lives
/// on an outer [Container] that also clips the Material to the rounded shape.
class _Card extends StatelessWidget {
  const _Card({
    required this.color,
    required this.borderColor,
    required this.child,
  });

  final Color color;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSpacing.radiusLg);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: color,
        borderRadius: radius,
        child: child,
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textSecondaryLight;
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: text.bodySmall?.copyWith(color: labelColor)),
      subtitle: Text(value,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.copy_rounded,
          size: 18, color: AppColors.textSecondary.withValues(alpha: 0.6)),
      onTap: onTap,
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      // Strip the default ExpansionTile dividers so the card border owns them.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary.withValues(alpha: 0.6),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        title: Text(question,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(answer,
                style: text.bodyMedium?.copyWith(
                  height: 1.4,
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.75)
                      : AppColors.textSecondaryLight,
                )),
          ),
        ],
      ),
    );
  }
}
