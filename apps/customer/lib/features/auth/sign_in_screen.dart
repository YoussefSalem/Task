import 'dart:async';

import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/auth/otp_verify_screen.dart';
import 'package:customer/features/profile/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer/features/localization/language_switcher.dart';
import 'package:customer/features/home/home_shell.dart';
import 'package:customer/l10n/app_localizations.dart';
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
      _toast(AppLocalizations.of(context).enterValidPhoneNumber);
      return;
    }
    setState(() => _sending = true);
    final AuthOutcome out = await ref.read(authControllerProvider).sendOtp(_e164);
    if (!mounted) return;
    setState(() => _sending = false);
    if (out.step == AuthStep.signedIn) {
      context.goNamed(HomeShell.homeRouteName);
    } else if (out.step == AuthStep.codeSent) {
      if (out.mock) _toast(AppLocalizations.of(context).emulatorOffline);
      unawaited(context.pushNamed(
        OtpVerifyScreen.routeName,
        queryParameters: <String, String>{'phone': _e164},
      ));
    } else {
      _toast(out.message ?? AppLocalizations.of(context).couldNotSendCode);
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
      // Persist the social profile (name/email/photo from the provider) so it
      // pulls on any device, then go straight home.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await seedUserDocument(user);
        } catch (_) {}
      }
      if (!mounted) return;
      context.goNamed(HomeShell.homeRouteName);
    } else {
      _toast(out.message ?? AppLocalizations.of(context).signInFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AuthBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xs, AppSpacing.sm, 0),
                  child: Row(
                    children: <Widget>[
                      const Spacer(),
                      Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: IconThemeData(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        child: const LanguageSwitcher(),
                      ),
                    ],
                  ),
                ),
                EntranceReveal(index: 0, child: _brandHero(text)),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: EntranceReveal(index: 1, child: _formSheet(text)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Branded top zone: the mark, a welcome line, and trust chips that echo the
  /// home dashboard's trust strip so the two screens read as one product.
  Widget _brandHero(TextTheme text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (Rect rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    Color(0x00FFFFFF),
                    Colors.white,
                    Colors.white,
                    Color(0x00FFFFFF),
                  ],
                  stops: <double>[0.0, 0.18, 0.82, 1.0],
                ).createShader(rect),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (Rect rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x00FFFFFF),
                      Colors.white,
                      Colors.white,
                      Color(0x00FFFFFF),
                    ],
                    stops: <double>[0.0, 0.18, 0.82, 1.0],
                  ).createShader(rect),
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/task_logo.jpg'
                        : 'assets/images/task_logo_light.jpg',
                    height: 48,
                    width: 48,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'Task',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Task',
                  style: AppTypography.wordmark(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(AppLocalizations.of(context).welcomeToTask,
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 6),
          Text(AppLocalizations.of(context).egyptOnDemandServices,
              style: text.bodyLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary.withValues(alpha: 0.7)
                    : AppColors.textSecondaryLight,
                height: 1.4,
              )),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _TrustChip(icon: Icons.verified_rounded, label: AppLocalizations.of(context).verifiedPros),
              _TrustChip(icon: Icons.sell_rounded, label: AppLocalizations.of(context).youSetThePrice),
              _TrustChip(icon: Icons.bolt_rounded, label: AppLocalizations.of(context).fastArrival),
            ],
          ),
        ],
      ),
    );
  }

  /// The form lifts onto a raised sheet, giving the inputs depth over the
  /// branded backdrop.
  Widget _formSheet(TextTheme text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.42)
            : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0x14000000),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(AppLocalizations.of(context).phoneNumberLabel,
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                )),
            const SizedBox(height: AppSpacing.sm),
            _phoneRow(text),
            const SizedBox(height: AppSpacing.xl),
            GlowButton(
              label: AppLocalizations.of(context).sendCode,
              icon: Icons.arrow_forward_rounded,
              loading: _sending,
              onPressed: _sendOtp,
            ),
            const SizedBox(height: AppSpacing.xl),
            _orDivider(text),
            const SizedBox(height: AppSpacing.xl),
            _socialButton(
              label: AppLocalizations.of(context).continueWithGoogle,
              iconWidget: const _GoogleMark(),
              busy: _socialBusy == 'google',
              onTap: () => _social('google'),
            ),
            const SizedBox(height: AppSpacing.md),
            _socialButton(
              label: AppLocalizations.of(context).continueWithApple,
              iconWidget: Icon(
                Icons.apple,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textPrimaryLight,
                size: 24,
              ),
              busy: _socialBusy == 'apple',
              onTap: () => _social('apple'),
            ),
            const SizedBox(height: AppSpacing.xl),
            _legalRow(text),
          ],
        ),
      ),
    );
  }

  Widget _phoneRow(TextTheme text) {
    return Row(
      children: <Widget>[
        // Country chip — Egypt only for v1.
        GestureDetector(
          onTap: () => _toast(AppLocalizations.of(context).moreCountriesSoon),
          child: Builder(builder: (context) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color secondary = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
            return Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface.withValues(alpha: 0.7)
                    : const Color(0xFFE9E5FB),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x28000000),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(AppLocalizations.of(context).eg,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: secondary,
                      )),
                  const SizedBox(width: 6),
                  Text('+20',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: secondary),
                ],
              ),
            );
          }),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color divColor = isDark ? const Color(0x22FFFFFF) : const Color(0x22000000);
    final Color labelColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : AppColors.textSecondaryLight;
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: divColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(AppLocalizations.of(context).or,
              style: text.labelMedium?.copyWith(
                color: labelColor,
                letterSpacing: 1.5,
              )),
        ),
        Expanded(child: Divider(color: divColor)),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required Widget iconWidget,
    required bool busy,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? AppColors.surface.withValues(alpha: 0.7)
          : const Color(0xFFF0EEFF),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x20000000),
            ),
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

  Widget _legalRow(TextTheme text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : AppColors.textSecondaryLight;
    final TextStyle? style = text.bodySmall?.copyWith(color: muted);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
            onTap: () => _toast(AppLocalizations.of(context).privacyOpensLater),
            child: Text(AppLocalizations.of(context).privacyPolicy, style: style)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Icon(Icons.circle, size: 4, color: muted),
        ),
        GestureDetector(
            onTap: () => _toast(AppLocalizations.of(context).termsOpensLater),
            child: Text(AppLocalizations.of(context).termsOfService, style: style)),
      ],
    );
  }
}

/// A small trust signal pill shown under the welcome line.
class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.5)
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.9)
                        : AppColors.textPrimaryLight,
                  )),
        ],
      ),
    );
  }
}

/// Branded backdrop: adapts to the current brightness.
class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(
          color: isDark ? AppColors.background : AppColors.backgroundLight,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: <Color>[Color(0x4D7C3AED), Color(0x00000000)],
            ),
          ),
        ),
        const AmbientBackground(intensity: 0.10),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: const _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    // Blue
    final Path blue = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10)
      ..lineTo(12, 10)
      ..lineTo(12, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
      ..close();
    canvas.drawPath(blue, Paint()..color = const Color(0xFF4285F4));

    // Green
    final Path green = Path()
      ..moveTo(12, 23)
      ..cubicTo(14.97, 23, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23, 12, 23)
      ..close();
    canvas.drawPath(green, Paint()..color = const Color(0xFF34A853));

    // Yellow
    final Path yellow = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
      ..cubicTo(1, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellow, Paint()..color = const Color(0xFFFBBC05));

    // Red
    final Path red = Path()
      ..moveTo(12, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
      ..cubicTo(7.70, 1, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12, 5.38)
      ..close();
    canvas.drawPath(red, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
