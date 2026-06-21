import 'dart:async';

import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/auth/otp_verify_screen.dart';
import 'package:customer/features/localization/language_switcher.dart';
import 'package:customer/features/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

/// Phone-OTP entry with social sign-in. Wired to [AuthController] (real Firebase
/// phone auth against the emulator in dev, with a mock fallback when it is
/// unreachable so the prototype stays navigable).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const String routeName = 'sign-in';
  static const String routePath = '/sign-in';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _phone = TextEditingController();
  bool _sending = false;
  String? _socialBusy; // 'google' | 'apple' | null

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String get _e164 {
    final String digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final String local = digits.startsWith('0') ? digits.substring(1) : digits;
    return '+20$local';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
      _toast('Enter a valid phone number.');
      return;
    }
    setState(() => _sending = true);
    final AuthOutcome out = await ref.read(authControllerProvider).sendOtp(_e164);
    if (!mounted) return;
    setState(() => _sending = false);
    if (out.step == AuthStep.signedIn) {
      context.goNamed(HomeShell.homeRouteName);
    } else if (out.step == AuthStep.codeSent) {
      if (out.mock) _toast('Emulator offline — using demo code (any 6 digits).');
      unawaited(context.pushNamed(
        OtpVerifyScreen.routeName,
        queryParameters: <String, String>{'phone': _e164},
      ));
    } else {
      _toast(out.message ?? 'Could not send the code.');
    }
  }

  Future<void> _social(String which) async {
    setState(() => _socialBusy = which);
    final AuthController auth = ref.read(authControllerProvider);
    final AuthOutcome out = which == 'google'
        ? await auth.signInWithGoogle()
        : await auth.signInWithApple();
    if (!mounted) return;
    setState(() => _socialBusy = null);
    if (out.step == AuthStep.signedIn) {
      context.goNamed(HomeShell.homeRouteName);
    } else {
      _toast(out.message ?? 'Sign-in failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const <Widget>[
          LanguageSwitcher(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Sign in',
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Egypt's on-demand home services, a tap away.",
                      style: text.titleMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        height: 1.4,
                      )),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Phone number',
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  _phoneRow(text),
                  const SizedBox(height: AppSpacing.xl),
                  GlowButton(
                    label: 'Send OTP',
                    loading: _sending,
                    onPressed: _sendOtp,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _orDivider(text),
                  const SizedBox(height: AppSpacing.xl),
                  _socialButton(
                    label: 'Continue with Google',
                    iconWidget: const _GoogleMark(),
                    busy: _socialBusy == 'google',
                    onTap: () => _social('google'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _socialButton(
                    label: 'Continue with Apple',
                    iconWidget:
                        const Icon(Icons.apple, color: Colors.white, size: 24),
                    busy: _socialBusy == 'apple',
                    onTap: () => _social('apple'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _createAccount(text),
                  const SizedBox(height: AppSpacing.xl),
                  _legalRow(text),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneRow(TextTheme text) {
    return Row(
      children: <Widget>[
        // Country chip — Egypt only for v1.
        GestureDetector(
          onTap: () => _toast('More countries arrive with international launch.'),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('EG',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(width: 6),
                Text('+20',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const <String>[AutofillHints.telephoneNumber],
            style: text.titleMedium,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              hintText: '1XX XXX XXXX',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orDivider(TextTheme text) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: Color(0x22FFFFFF))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('OR',
              style: text.labelMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 1.5,
              )),
        ),
        const Expanded(child: Divider(color: Color(0x22FFFFFF))),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required Widget iconWidget,
    required bool busy,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    iconWidget,
                    const SizedBox(width: AppSpacing.md),
                    Text(label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _createAccount(TextTheme text) {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'New here? ',
          style: text.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          children: <InlineSpan>[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () =>
                    _toast('Accounts are created automatically on first sign-in.'),
                child: Text('Create an Account',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalRow(TextTheme text) {
    final TextStyle? style = text.bodySmall?.copyWith(
      color: AppColors.textSecondary.withValues(alpha: 0.5),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
            onTap: () => _toast('Privacy Policy opens in a later phase.'),
            child: Text('Privacy Policy', style: style)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Icon(Icons.circle,
              size: 4, color: AppColors.textSecondary.withValues(alpha: 0.4)),
        ),
        GestureDetector(
            onTap: () => _toast('Terms of Service opens in a later phase.'),
            child: Text('Terms of Service', style: style)),
      ],
    );
  }
}

/// A compact Google "G" mark on a white tile — recognizable without bundling
/// the multicolor brand asset.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w800,
            fontSize: 16,
            height: 1.1,
          )),
    );
  }
}
