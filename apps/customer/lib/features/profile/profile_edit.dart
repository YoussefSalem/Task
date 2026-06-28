import 'dart:async';

import 'package:customer/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

import '../auth/auth_controller.dart';
import 'user_profile.dart';

/// Edit surfaces for the Profile tab — each opens as a bottom sheet so the user
/// stays in place (progressive disclosure) instead of pushing a full screen.
///
/// Three entry points:
///  - [showEditNameSheet]      — edit first/last name
///  - [pickAndSaveBirthday]    — date picker, persist on pick
///  - [showPhoneSheet]         — add/change phone, verified by OTP

// ─────────────────────────────────────────────────────────────────────────
// Shared chrome
// ─────────────────────────────────────────────────────────────────────────

Future<T?> _openSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    // Present from the root navigator so the sheet + scrim sit ABOVE the
    // floating bottom nav bar (which lives inside the shell's branch navigator).
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext ctx) => Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: child,
    ),
  );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            )),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(subtitle!,
              style: text.bodyMedium?.copyWith(
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondary.withValues(alpha: 0.7)
                    : AppColors.textSecondaryLight,
              )),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// A labelled field matching the complete-profile form's look.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.autofillHints = const <String>[],
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final List<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            )),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          style: text.titleMedium,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(40),
          ],
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Edit name
// ─────────────────────────────────────────────────────────────────────────

Future<void> showEditNameSheet(
    BuildContext context, WidgetRef ref, UserProfile profile) async {
  await _openSheet<void>(context, _EditNameSheet(profile: profile, ref: ref));
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.profile, required this.ref});
  final UserProfile profile;
  final WidgetRef ref;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _first =
      TextEditingController(text: widget.profile.firstName);
  late final TextEditingController _last =
      TextEditingController(text: widget.profile.lastName);
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String first = _first.text.trim();
    final String last = _last.text.trim();
    if (first.isEmpty || last.isEmpty) {
      _toast(context, l.requiredField);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName('$first $last'.trim());
        await user.reload();
      }
      await widget.ref
          .read(userProfileRepositoryProvider)
          ?.updateName(firstName: first, lastName: last);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(context, e.toString());
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.nameUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SheetHeader(title: l.editName),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _LabeledField(
                  controller: _first,
                  label: l.firstName,
                  hint: l.hintFirstName,
                  icon: Icons.badge_rounded,
                  autofillHints: const <String>[AutofillHints.givenName],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LabeledField(
                  controller: _last,
                  label: l.lastName,
                  hint: l.hintLastName,
                  icon: Icons.badge_rounded,
                  autofillHints: const <String>[AutofillHints.familyName],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GlowButton(
            label: l.save,
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Birthday
// ─────────────────────────────────────────────────────────────────────────

/// Shows the platform date picker and persists the choice — a one-time action.
/// Birthday can only be set while unset (see ProfileScreen, which passes a null
/// [current] and locks the row once a value exists); a confirmation guards the
/// write because it can never be changed afterwards. No-op on cancel.
Future<void> pickAndSaveBirthday(
    BuildContext context, WidgetRef ref, DateTime? current) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final DateTime now = DateTime.now();
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final DateTime? picked = await showDatePicker(
    context: context,
    useRootNavigator: true,
    initialDate: current ?? DateTime(now.year - 25),
    firstDate: DateTime(now.year - 100),
    lastDate: DateTime(now.year - 16),
    helpText: l.selectDate,
    builder: (BuildContext context, Widget? child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
      ),
      child: child!,
    ),
  );
  if (picked == null) return;
  // Permanent, one-time: confirm before persisting since it can't be changed.
  if (!context.mounted) return;
  final bool confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l.confirmBirthdayTitle),
          content: Text(l.birthdayPermanentWarning),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.confirmAction),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;
  try {
    await ref.read(userProfileRepositoryProvider)?.updateBirthday(picked);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.birthdayUpdated)));
  } catch (e) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Phone — add / change, verified by OTP
// ─────────────────────────────────────────────────────────────────────────

Future<void> showPhoneSheet(
    BuildContext context, WidgetRef ref, {required bool hasPhone}) async {
  await _openSheet<void>(context, _PhoneSheet(ref: ref, hasPhone: hasPhone));
}

enum _PhoneStep { entry, otp }

class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet({required this.ref, required this.hasPhone});
  final WidgetRef ref;
  final bool hasPhone;

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();
  _PhoneStep _step = _PhoneStep.entry;
  bool _busy = false;
  int _secondsLeft = 0;
  Timer? _resendTimer;
  String _e164 = '';

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String _toE164(String raw) {
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    final String local = digits.startsWith('0') ? digits.substring(1) : digits;
    return '+20$local';
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
      if (_secondsLeft == 0) t.cancel();
    });
  }

  AuthController get _auth => widget.ref.read(authControllerProvider);

  Future<void> _sendCode() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
      _toast(context, l.enterValidPhoneNumber);
      return;
    }
    FocusScope.of(context).unfocus();
    _e164 = _toE164(_phone.text);
    setState(() => _busy = true);
    final AuthOutcome out = await _auth.startPhoneVerification(_e164);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (out.step) {
      case AuthStep.signedIn: // Android auto-retrieval linked it immediately.
        await _finalize();
      case AuthStep.codeSent:
        if (out.mock) _toast(context, l.demoModeEnterSixDigits);
        setState(() => _step = _PhoneStep.otp);
        _startResendCountdown();
      case AuthStep.failed:
        _toast(context, out.message ?? l.couldNotVerifyPhone);
    }
  }

  Future<void> _verify() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (_code.text.length < 6) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final AuthOutcome out = await _auth.confirmPhoneVerification(_code.text);
    if (!mounted) return;
    if (out.step == AuthStep.signedIn) {
      await _finalize();
    } else {
      setState(() => _busy = false);
      _toast(context, out.message ?? l.couldNotVerifyPhone);
      _code.clear();
    }
  }

  Future<void> _resend() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthOutcome out = await _auth.startPhoneVerification(_e164);
    if (!mounted) return;
    if (out.ok) {
      _startResendCountdown();
      _toast(context, out.mock ? l.demoModeEnterSixDigits : l.newCodeOnTheWay);
    } else {
      _toast(context, out.message ?? l.couldNotResendCode);
    }
  }

  /// Persist the verified number to Firestore, close, and confirm.
  Future<void> _finalize() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await widget.ref.read(userProfileRepositoryProvider)?.updatePhone(_e164);
    } catch (_) {
      // The number is verified on the Auth account even if the mirror write
      // fails; the profile stream will still surface user.phoneNumber.
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.phoneNumberVerified)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: _step == _PhoneStep.entry ? _entryStep() : _otpStep(),
      ),
    );
  }

  Widget _entryStep() {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey<String>('entry'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SheetHeader(
          title: widget.hasPhone ? l.changePhoneNumber : l.addPhoneNumber,
          subtitle: l.confirmPhoneHint,
        ),
        Text(l.phoneNumberLabel,
            style: text.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface.withValues(alpha: 0.7)
                    : const Color(0xFFE9E5FB),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color:
                      isDark ? const Color(0x1AFFFFFF) : const Color(0x28000000),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l.eg,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      )),
                  const SizedBox(width: 6),
                  Text('+20',
                      style:
                          text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofocus: true,
                autofillHints: const <String>[AutofillHints.telephoneNumber],
                style: text.titleMedium,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onSubmitted: (_) => _sendCode(),
                decoration: const InputDecoration(
                  hintText: '1XX XXX XXXX',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        GlowButton(
          label: l.sendCode,
          icon: Icons.arrow_forward_rounded,
          loading: _busy,
          onPressed: _sendCode,
        ),
      ],
    );
  }

  Widget _otpStep() {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey<String>('otp'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SheetHeader(title: l.verifyYourPhone, subtitle: l.sentCodeTo(_e164)),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (String v) {
            setState(() {});
            if (v.length == 6) _verify();
          },
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: _secondsLeft > 0
              ? Text(
                  l.resendCodeIn('0:${_secondsLeft.toString().padLeft(2, '0')}'),
                  style: text.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.6)
                        : AppColors.textSecondaryLight,
                  ),
                )
              : TextButton(onPressed: _resend, child: Text(l.resendCode)),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlowButton(
          label: l.verifyAction,
          loading: _busy,
          onPressed: _code.text.length == 6 ? _verify : null,
        ),
      ],
    );
  }
}
