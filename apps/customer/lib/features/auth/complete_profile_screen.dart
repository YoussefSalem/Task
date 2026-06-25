import 'package:customer/l10n/app_localizations.dart';
import 'package:customer/features/home/home_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../profile/user_profile.dart';

/// Collects name and email from phone-only sign-ups before entering the app.
/// Social sign-in (Google / Apple) already provides this data, so only phone
/// users land here.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  static const String routeName = 'complete-profile';
  static const String routePath = '/complete-profile';

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  DateTime? _birthday;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty)
      ? AppLocalizations.of(context).requiredField
      : null;

  String? _emailValidator(String? v) {
    final AppLocalizations l = AppLocalizations.of(context);
    if (v == null || v.trim().isEmpty) return l.requiredField;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return valid ? null : l.enterValidEmail;
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 16),
      helpText: AppLocalizations.of(context).selectDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).pleaseSelectYourBirthday)));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final String first = _firstName.text.trim();
    final String last = _lastName.text.trim();
    try {
      // Display name on the Auth user (drives the home greeting instantly).
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName('$first $last'.trim());
        await user.reload();
      }
      // Full profile to Firestore users/{uid}.
      final repo = ref.read(userProfileRepositoryProvider);
      await repo?.save(
        firstName: first,
        lastName: last,
        email: _email.text.trim(),
        birthday: _birthday!,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    if (!mounted) return;
    context.goNamed(HomeShell.homeRouteName);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.08),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l.completeYourProfile,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.profileSubtitle,
                      style: text.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary.withValues(alpha: 0.7)
                            : AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _field(
                            controller: _firstName,
                            label: l.firstName,
                            hint: l.hintFirstName,
                            icon: Icons.badge_rounded,
                            validator: _requiredValidator,
                            autofillHints: const [AutofillHints.givenName],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _field(
                            controller: _lastName,
                            label: l.lastName,
                            hint: l.hintLastName,
                            icon: Icons.badge_rounded,
                            validator: _requiredValidator,
                            autofillHints: const [AutofillHints.familyName],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _field(
                      controller: _email,
                      label: l.emailAddress,
                      hint: 'ahmed@example.com',
                      icon: Icons.email_rounded,
                      keyboard: TextInputType.emailAddress,
                      validator: _emailValidator,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _birthdayPicker(),
                    const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                    GlowButton(
                      label: l.continueAction,
                      icon: Icons.arrow_forward_rounded,
                      loading: _saving,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _birthdayLabel {
    final AppLocalizations l = AppLocalizations.of(context);
    if (_birthday == null) return l.selectYourBirthday;
    final d = _birthday!;
    final List<String> months = <String>[
      l.january, l.february, l.march, l.april, l.may, l.june,
      l.july, l.august, l.september, l.october, l.november, l.december,
    ];
    return '${months[d.month - 1]} ${d.day}، ${d.year}';
  }

  Widget _birthdayPicker() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasValue = _birthday != null;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(AppLocalizations.of(context).birthday,
            style: text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            )),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _pickBirthday,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surface.withValues(alpha: 0.45)
                  : const Color(0xFFE9E5FB),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0x28000000),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.cake_rounded,
                  size: 20,
                  color: hasValue
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _birthdayLabel,
                    style: text.titleMedium?.copyWith(
                      color: hasValue
                          ? null
                          : (isDark
                              ? AppColors.textSecondary.withValues(alpha: 0.45)
                              : AppColors.textSecondaryLight.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.name,
    List<String> autofillHints = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                )),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: keyboard == TextInputType.name
              ? TextCapitalization.words
              : TextCapitalization.none,
          autofillHints: autofillHints,
          style: Theme.of(context).textTheme.titleMedium,
          validator: validator,
          inputFormatters: keyboard == TextInputType.name
              ? [LengthLimitingTextInputFormatter(40)]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}
