import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import '../services/service_catalog.dart';

/// The Bookings tab: live + upcoming jobs first, history below. Tapping an
/// active job returns to live tracking.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<BookingRecord> records = ref.watch(bookingsProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final List<BookingRecord> active =
        records.where((BookingRecord r) => !r.completed).toList();
    final List<BookingRecord> past =
        records.where((BookingRecord r) => r.completed).toList();

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.1),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 112),
            children: <Widget>[
              Text('Your bookings',
                  style:
                      text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xl),
              if (active.isNotEmpty) ...<Widget>[
                const SectionHeader(title: 'Active & upcoming'),
                const SizedBox(height: AppSpacing.md),
                ...active.map((BookingRecord r) => _card(context, r, text,
                    onTap: () => context.push('/job/live'))),
                const SizedBox(height: AppSpacing.xl),
              ],
              const SectionHeader(title: 'History'),
              const SizedBox(height: AppSpacing.md),
              if (past.isEmpty)
                _empty(text)
              else
                ...past.map((BookingRecord r) => _card(context, r, text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, BookingRecord r, TextTheme text,
      {VoidCallback? onTap}) {
    final Service service = r.service;
    final (Color, IconData) badge = switch (r.status) {
      'Completed' => (AppColors.success, Icons.check_circle),
      'In progress' => (AppColors.primary, Icons.bolt),
      'Upcoming' => (AppColors.warning, Icons.event),
      _ => (AppColors.textSecondary, Icons.circle),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: serviceGlow(service),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(service.icon, color: service.tint),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(service.name,
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${r.id} · ${r.whenLabel}',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6),
                          )),
                      const SizedBox(height: 6),
                      StatusPill(
                          label: r.status, tint: badge.$1, icon: badge.$2),
                    ],
                  ),
                ),
                Text('${r.total} EGP',
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      alignment: Alignment.center,
      child: Column(
        children: <Widget>[
          Icon(Icons.receipt_long_rounded,
              size: 44, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          Text('No past jobs yet',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
