import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../auth/auth_controller.dart';
import '../notifications/push_messaging.dart';

/// Subtle-destructive "Delete account" affordance below Sign Out. Drives a
/// two-step confirmation, runs best-effort data cleanup, deletes the Firebase
/// Auth account, and re-authenticates first when Firebase requires it.
class DeleteAccountButton extends ConsumerStatefulWidget {
  const DeleteAccountButton({super.key});

  @override
  ConsumerState<DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<DeleteAccountButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Center(
      child: TextButton.icon(
        onPressed: _busy ? null : _start,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.error.withValues(alpha: 0.85)),
        label: Text(l.deleteAccount),
        style: TextButton.styleFrom(
          // Subtle red — destructive but quieter than the outlined Sign Out.
          foregroundColor: AppColors.error.withValues(alpha: 0.85),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (!await _confirmStep1(l)) return;
    if (!mounted) return;
    if (!await _confirmStep2(l)) return;
    if (!mounted) return;
    await _runDeletion(l);
  }

  Future<bool> _confirmStep1(AppLocalizations l) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteAccountConfirmTitle),
        content: Text(l.deleteAccountConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.continueAction),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<bool> _confirmStep2(AppLocalizations l) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => const _FinalDeleteDialog(),
    );
    return ok ?? false;
  }

  Future<void> _runDeletion(AppLocalizations l) async {
    setState(() => _busy = true);
    try {
      final AuthController auth = ref.read(authControllerProvider);
      DeleteAccountResult result = await auth.deleteAccount(cleanup: _cleanup);

      if (result == DeleteAccountResult.needsReauth) {
        final bool reauthed = await _reauthenticate(auth, l);
        if (!reauthed) {
          setState(() => _busy = false);
          return; // user cancelled or reauth failed (message already shown)
        }
        result = await auth.deleteAccount(cleanup: _cleanup);
      }

      if (!mounted) return;
      if (result == DeleteAccountResult.deleted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l.accountDeleted)));
        context.go('/');
      } else {
        setState(() => _busy = false);
        _snack(l.deleteAccountError);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(l.deleteAccountError);
    }
  }

  /// Removes the user's data while still authenticated, so the Firestore rules
  /// permit it. Best-effort: failures don't block account deletion.
  Future<void> _cleanup() async {
    final String? uid = ref.read(authStateProvider).valueOrNull?.uid;
    await ref.read(pushMessagingProvider).unregister();
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    }
  }

  /// Returns true once the user has re-authenticated. Phone users verify an OTP
  /// sent to their number; social users go through the provider flow.
  Future<bool> _reauthenticate(AuthController auth, AppLocalizations l) async {
    if (auth.reauthUsesPhone) {
      final AuthOutcome sent = await auth.startReauthOtp();
      if (!sent.ok) {
        _snack(sent.message ?? l.deleteAccountError);
        return false;
      }
      if (!mounted) return false;
      final String? code = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _OtpReauthSheet(),
      );
      if (code == null) return false; // dismissed
      final AuthOutcome confirmed = await auth.confirmReauthOtp(code);
      if (!confirmed.ok) {
        _snack(confirmed.message ?? l.deleteAccountError);
        return false;
      }
      return true;
    } else {
      final AuthOutcome social = await auth.reauthenticateWithSocial();
      if (!social.ok) {
        _snack(social.message ?? l.deleteAccountError);
        return false;
      }
      return true;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Step 2: the final, stronger warning. The destructive action stays disabled
/// until the user ticks the acknowledgement, guarding against accidental taps.
class _FinalDeleteDialog extends StatefulWidget {
  const _FinalDeleteDialog();

  @override
  State<_FinalDeleteDialog> createState() => _FinalDeleteDialogState();
}

class _FinalDeleteDialogState extends State<_FinalDeleteDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l.deleteAccountFinalTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.deleteAccountFinalBody, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            value: _acknowledged,
            onChanged: (bool? v) =>
                setState(() => _acknowledged = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.error,
            title: Text(l.deleteAccountAcknowledge, style: text.bodySmall),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _acknowledged
              ? () => Navigator.pop(context, true)
              : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(l.deleteAccountConfirmAction),
        ),
      ],
    );
  }
}

/// OTP sheet for re-authentication before deletion. Pops with the entered code,
/// or null when dismissed.
class _OtpReauthSheet extends StatefulWidget {
  const _OtpReauthSheet();

  @override
  State<_OtpReauthSheet> createState() => _OtpReauthSheetState();
}

class _OtpReauthSheetState extends State<_OtpReauthSheet> {
  final TextEditingController _code = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l.deleteAccountReauthTitle,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l.deleteAccountReauthBody,
                  style: text.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                onChanged: (String v) =>
                    setState(() => _valid = v.trim().length >= 4),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlowButton(
                label: l.confirmAction,
                onPressed: _valid
                    ? () => Navigator.pop(context, _code.text.trim())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
