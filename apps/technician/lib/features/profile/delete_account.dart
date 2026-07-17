import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_data/task_data.dart';
import 'package:task_design/task_design.dart';

import '../auth/auth_controller.dart';
import '../splash/splash_screen.dart';

/// Account deletion with the re-auth step Firebase requires for a sensitive
/// action. Phone users re-verify by OTP; social users re-run the provider popup.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const String routeName = 'delete-account';
  static const String routePath = '/delete-account';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _code = TextEditingController();
  bool _busy = false;
  bool _awaitingOtp = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Best-effort cleanup that runs while still authenticated: remove this user's
  /// device tokens (the users doc itself is admin-only to delete, per the rules).
  Future<void> _cleanup() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap =
        await FirestorePaths.fcmTokensCollection(FirebaseFirestore.instance, user.uid)
            .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _attemptDelete() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider);
    final result = await auth.deleteAccount(cleanup: _cleanup);
    if (!mounted) return;
    switch (result) {
      case DeleteAccountResult.deleted:
        _finish();
      case DeleteAccountResult.needsReauth:
        await _reauthThenRetry();
      case DeleteAccountResult.failed:
        setState(() => _busy = false);
        _snack('Could not delete your account. Please try again.');
    }
  }

  Future<void> _reauthThenRetry() async {
    final auth = ref.read(authControllerProvider);
    if (auth.reauthUsesPhone) {
      final outcome = await auth.startReauthOtp();
      if (!mounted) return;
      if (outcome.step == AuthStep.codeSent || outcome.mock) {
        setState(() {
          _busy = false;
          _awaitingOtp = true;
        });
      } else {
        setState(() => _busy = false);
        _snack(outcome.message ?? 'Could not verify your identity.');
      }
    } else {
      final outcome = await auth.reauthenticateWithSocial();
      if (!mounted) return;
      if (outcome.ok) {
        // Re-authenticated; retry the delete.
        final retry = await auth.deleteAccount(cleanup: _cleanup);
        if (!mounted) return;
        if (retry == DeleteAccountResult.deleted) {
          _finish();
        } else {
          setState(() => _busy = false);
          _snack('Could not delete your account. Please try again.');
        }
      } else {
        setState(() => _busy = false);
        _snack(outcome.message ?? 'Verification cancelled.');
      }
    }
  }

  Future<void> _confirmOtpAndDelete() async {
    if (_busy || _code.text.trim().length < 4) return;
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider);
    final outcome = await auth.confirmReauthOtp(_code.text.trim());
    if (!mounted) return;
    if (!outcome.ok) {
      setState(() => _busy = false);
      _snack(outcome.message ?? 'That code is incorrect.');
      return;
    }
    final retry = await auth.deleteAccount(cleanup: _cleanup);
    if (!mounted) return;
    if (retry == DeleteAccountResult.deleted) {
      _finish();
    } else {
      setState(() => _busy = false);
      _snack('Could not delete your account. Please try again.');
    }
  }

  void _finish() {
    context.goNamed(SplashScreen.routeName);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete account'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text('This can’t be undone',
                textAlign: TextAlign.center,
                style: text.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Deleting your account removes your sign-in and device tokens. Your '
              'completed job history may be retained in anonymized form as required.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_awaitingOtp) ...<Widget>[
              Text('Enter the code we sent to confirm it’s you.',
                  textAlign: TextAlign.center, style: text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    counterText: '', hintText: '••••••'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DangerButton(
                label: 'Confirm & delete',
                loading: _busy,
                onPressed: _code.text.trim().length >= 4
                    ? _confirmOtpAndDelete
                    : null,
              ),
            ] else
              _DangerButton(
                label: 'Delete my account',
                loading: _busy,
                onPressed: _attemptDelete,
              ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _busy ? null : () => context.pop(),
              child: const Text('Keep my account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: AppColors.error,
      ),
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
    );
  }
}
