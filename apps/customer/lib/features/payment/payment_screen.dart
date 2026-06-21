import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import '../services/service_catalog.dart';

/// Payment & review. `settle == true` after a finished job (pay the pro); else
/// it authorizes a scheduled booking upfront. The summary and method picker are
/// live; the charge is stubbed for the prototype.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.settle, super.key});

  /// true = pay after the job; false = authorize a scheduled booking.
  final bool settle;

  static const String routePath = '/book/payment';

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _processing = false;

  Future<void> _confirm() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final BookingDraft draft = ref.read(bookingProvider);
    final Service? service = draft.service;
    if (widget.settle) {
      // Job done — record it, then collect a rating.
      if (service != null) {
        ref.read(bookingsProvider.notifier).add(
              BookingRecord(
                id: 'TK-${4820 + DateTime.now().second}',
                serviceId: service.id,
                whenLabel: 'Just now',
                total: draft.total,
                status: 'Completed',
                completed: true,
              ),
            );
      }
      context.pushReplacement('/job/live/rate');
    } else {
      // Scheduled booking authorized — confirm and go home.
      if (service != null) {
        ref.read(bookingsProvider.notifier).add(
              BookingRecord(
                id: 'TK-${4820 + DateTime.now().second}',
                serviceId: service.id,
                whenLabel: 'Scheduled',
                total: draft.total,
                status: 'Upcoming',
                completed: false,
              ),
            );
      }
      await _showConfirmed();
    }
  }

  Future<void> _showConfirmed() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final TextTheme text = Theme.of(context).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
              AppSpacing.xl, AppSpacing.xl + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Booking confirmed',
                  style:
                      text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Text("We've locked in your pro. You'll get a reminder before they arrive.",
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    height: 1.4,
                  )),
              const SizedBox(height: AppSpacing.xl),
              GlowButton(
                label: 'Done',
                onPressed: () {
                  ref.read(bookingProvider.notifier).reset();
                  Navigator.of(context).pop();
                  context.go('/home');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BookingDraft draft = ref.watch(bookingProvider);
    final Service? service = draft.service;
    final TextTheme text = Theme.of(context).textTheme;
    if (service == null) {
      return const Scaffold(body: Center(child: Text('No booking')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.settle ? 'Pay & finish' : 'Review & pay'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 150),
              children: <Widget>[
                _summary(draft, service, text),
                const SizedBox(height: AppSpacing.xl),
                Text('Payment method',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                ...PaymentMethod.values.map((PaymentMethod m) => _methodTile(
                      m,
                      selected: draft.payment == m,
                      onTap: () =>
                          ref.read(bookingProvider.notifier).setPayment(m),
                      text: text,
                    )),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _payBar(draft, text),
          ),
        ],
      ),
    );
  }

  Widget _summary(BookingDraft draft, Service service, TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Column(
        children: <Widget>[
          _row(text, 'Service', service.name),
          _row(text, 'Pro', draft.selectedBid?.proName ?? 'Nearest available'),
          _row(text, 'Address', draft.address.label),
          if (draft.scheduledFor != null)
            _row(text, 'When',
                '${draft.scheduledFor!.day}/${draft.scheduledFor!.month} · ${draft.scheduledFor!.hour}:${draft.scheduledFor!.minute.toString().padLeft(2, '0')}'),
          const Divider(height: AppSpacing.xl, color: Color(0x18FFFFFF)),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Total',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${draft.total} EGP',
                  style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(TextTheme text, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(label,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                )),
          ),
          Expanded(
            child: Text(value,
                style:
                    text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(PaymentMethod m,
      {required bool selected,
      required VoidCallback onTap,
      required TextTheme text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(m.icon,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(m.label,
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(m.sub,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _payBar(BookingDraft draft, TextTheme text) {
    final String action = widget.settle
        ? 'Pay ${draft.total} EGP'
        : (draft.payment == PaymentMethod.cash
            ? 'Confirm booking'
            : 'Authorize ${draft.total} EGP');
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: GlowButton(
        label: action,
        loading: _processing,
        onPressed: _confirm,
      ),
    );
  }
}
