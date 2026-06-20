import 'package:customer/features/localization/language_switcher.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_design/task_design.dart';

/// Entry point of the sign-in flow (phone OTP — PRD §1.1). The OTP exchange is
/// wired in the Auth phase; for now the form is live and Continue confirms the
/// number was captured so the journey from the splash is unbroken.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const String routeName = 'sign-in';
  static const String routePath = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _onContinue() {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.signInComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const <Widget>[
          LanguageSwitcher(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.signInTitle,
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.signInSubtitle,
                style: textTheme.titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  prefixText: '+20 ',
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _onContinue,
                child: Text(l10n.continueAction),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
