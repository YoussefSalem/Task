import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../../widgets/tech_ambient.dart';
import '../../widgets/tech_glow_button.dart';
import '../splash/splash_screen.dart';
import 'auth_controller.dart';

/// Confirms the SMS code. On success the auth stream flips and the Splash route
/// re-evaluates onboarding, so this screen only owns code entry.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({required this.phone, super.key});

  final String phone;

  static const String routeName = 'otp';
  static const String routePath = '/otp';

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final TextEditingController _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _valid => _code.text.trim().length >= 4;

  Future<void> _confirm() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    final outcome =
        await ref.read(authControllerProvider).confirmOtp(_code.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.step == AuthStep.signedIn) {
      context.goNamed(SplashScreen.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(outcome.message ?? 'That code is incorrect.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  EntranceReveal(
                    child: Text(
                      'Enter the code',
                      style: text.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  EntranceReveal(
                    index: 1,
                    child: Text(
                      'We sent a 6-digit code to ${widget.phone}.',
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  EntranceReveal(
                    index: 2,
                    child: TextField(
                      controller: _code,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _confirm(),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  EntranceReveal(
                    index: 3,
                    child: TechGlowButton(
                      label: 'Verify & continue',
                      loading: _busy,
                      onPressed: _valid ? _confirm : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EntranceReveal(
                    index: 4,
                    child: Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Change number'),
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
