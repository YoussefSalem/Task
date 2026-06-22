import 'package:customer/l10n/app_localizations.dart';
import 'package:customer/features/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

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

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return valid ? null : 'Enter a valid email';
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 16),
      helpText: 'Select your birthday',
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
        ..showSnackBar(const SnackBar(content: Text('Please select your birthday.')));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    // TODO: persist to Firestore user doc when backend is wired
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    context.goNamed(HomeShell.homeRouteName);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
                      'Complete your profile',
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "A few details so technicians know who they're helping.",
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
                            label: 'First name',
                            hint: 'Ahmed',
                            icon: Icons.badge_rounded,
                            validator: _requiredValidator,
                            autofillHints: const [AutofillHints.givenName],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _field(
                            controller: _lastName,
                            label: 'Last name',
                            hint: 'Hassan',
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
                      label: 'Email address',
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
                      label: 'Continue',
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
    if (_birthday == null) return 'Select your birthday';
    final d = _birthday!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _birthdayPicker() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasValue = _birthday != null;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Birthday',
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
