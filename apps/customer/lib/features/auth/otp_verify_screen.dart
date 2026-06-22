import 'package:customer/l10n/app_localizations.dart';
import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/auth/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

/// Phone OTP entry. Verifies the 6-digit code through [AuthController] (real
/// Firebase against the emulator, or the mock fallback when it is offline).
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({required this.phone, super.key});

  final String phone;

  static const String routeName = 'verify';
  static const String routePath = '/verify';

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  static const int _len = 6;
  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(_len, (_) => TextEditingController());
  final List<FocusNode> _nodes =
      List<FocusNode>.generate(_len, (_) => FocusNode());

  bool _verifying = false;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _tickResend();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nodes.first.requestFocus());
  }

  void _tickResend() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
      if (_secondsLeft > 0) _tickResend();
    });
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((TextEditingController c) => c.text).join();
  bool get _complete => _code.length == _len;

  void _onChanged(int i, String value) {
    if (value.isNotEmpty && i < _len - 1) {
      _nodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
    if (_complete) _verify();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verify() async {
    if (!_complete || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    final AuthOutcome out =
        await ref.read(authControllerProvider).confirmOtp(_code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (out.step == AuthStep.signedIn) {
      context.goNamed(CompleteProfileScreen.routeName);
    } else {
      _toast(out.message ?? 'That code is incorrect.');
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      setState(() {});
    }
  }

  Future<void> _resend() async {
    final AuthOutcome out =
        await ref.read(authControllerProvider).sendOtp(widget.phone);
    if (!mounted) return;
    if (out.ok) {
      setState(() => _secondsLeft = 30);
      _tickResend();
      _toast(out.mock
          ? 'Demo mode — enter any 6 digits.'
          : 'A new code is on its way.');
    } else {
      _toast(out.message ?? 'Could not resend the code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Verify your number',
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Text('We sent a 6-digit code to ${widget.phone}.',
                      style: text.titleMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary.withValues(alpha: 0.7)
                            : AppColors.textSecondaryLight,
                        height: 1.4,
                      )),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List<Widget>.generate(_len, _otpBox),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: text.bodyMedium?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                                  : AppColors.textSecondaryLight,
                            ),
                          )
                        : TextButton(
                            onPressed: _resend,
                            child: const Text('Resend code'),
                          ),
                  ),
                  const Spacer(),
                  GlowButton(
                    label: 'Verify',
                    loading: _verifying,
                    onPressed: _complete ? _verify : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int i) {
    final bool filled = _controllers[i].text.isNotEmpty;
    return SizedBox(
      width: 46,
      child: TextField(
        controller: _controllers[i],
        focusNode: _nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: filled
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
        ),
        onChanged: (String v) => _onChanged(i, v),
      ),
    );
  }
}
