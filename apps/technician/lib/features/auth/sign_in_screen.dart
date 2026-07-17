import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../../widgets/tech_ambient.dart';
import '../../widgets/tech_glow_button.dart';
import 'auth_controller.dart';
import 'otp_verify_screen.dart';

/// Technician entry point. Phone-OTP first, social as a fallback. The hero is
/// the promise of work: a pro signs in to pick up jobs, not to browse.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const String routeName = 'sign-in';
  static const String routePath = '/sign-in';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// Composes an E.164 Egyptian number from the local digits entered.
  String get _e164 {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.startsWith('0') ? digits.substring(1) : digits;
    return '+20$trimmed';
  }

  bool get _valid => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  Future<void> _sendOtp() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    final outcome = await ref.read(authControllerProvider).sendOtp(_e164);
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.step == AuthStep.codeSent || outcome.mock) {
      unawaited(context.pushNamed(
        OtpVerifyScreen.routeName,
        queryParameters: <String, String>{'phone': _e164},
      ));
    } else if (outcome.step == AuthStep.signedIn) {
      // Android auto-retrieval already signed us in; splash routes onward.
    } else {
      _snack(outcome.message ?? 'Could not send the code.');
    }
  }

  Future<void> _social(Future<AuthOutcome> Function() run) async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await run();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!outcome.ok) _snack(outcome.message ?? 'Sign-in failed.');
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Spacer(flex: 2),
                  EntranceReveal(
                    child: _WordMark(color: scheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  EntranceReveal(
                    index: 1,
                    child: Text(
                      'Get to work.',
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  EntranceReveal(
                    index: 2,
                    child: Text(
                      'Sign in to pick up jobs near you, set your price, and get paid.',
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  EntranceReveal(
                    index: 3,
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const <String>[AutofillHints.telephoneNumber],
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendOtp(),
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '10 1234 5678',
                        prefixIcon: _CountryPrefix(),
                        prefixIconConstraints:
                            BoxConstraints(minWidth: 64, minHeight: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EntranceReveal(
                    index: 4,
                    child: TechGlowButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      loading: _busy,
                      onPressed: _valid ? _sendOtp : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const EntranceReveal(index: 5, child: _OrDivider()),
                  const SizedBox(height: AppSpacing.lg),
                  EntranceReveal(
                    index: 6,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.g_mobiledata_rounded,
                            label: 'Google',
                            onTap: () => _social(auth.signInWithGoogle),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.apple_rounded,
                            label: 'Apple',
                            onTap: () => _social(auth.signInWithApple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  EntranceReveal(
                    index: 7,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Text(
                        'By continuing you agree to the Pro Terms and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordMark extends StatelessWidget {
  const _WordMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.handyman_rounded,
              color: Theme.of(context).colorScheme.onPrimary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'Task Pro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('🇪🇬', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 6),
          Text('+20',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final Color c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: c)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
        ),
        Expanded(child: Divider(color: c)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
