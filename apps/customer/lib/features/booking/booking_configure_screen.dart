import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../services/service_catalog.dart';
import 'booking_state.dart';

/// The heart of the flow: pick a booking engine (ASAP / Scheduled / Quote),
/// confirm the address, schedule if needed, and add notes. Continue routes to
/// the engine-specific next step.
class BookingConfigureScreen extends ConsumerStatefulWidget {
  const BookingConfigureScreen({super.key});

  static const String routePath = '/book/configure';

  @override
  ConsumerState<BookingConfigureScreen> createState() =>
      _BookingConfigureScreenState();
}

class _BookingConfigureScreenState
    extends ConsumerState<BookingConfigureScreen> {
  final TextEditingController _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notes.text = ref.read(bookingProvider).notes;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    ref.read(bookingProvider.notifier).setSchedule(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
  }

  void _continue() {
    final BookingDraft draft = ref.read(bookingProvider);
    ref.read(bookingProvider.notifier).setNotes(_notes.text);
    switch (draft.mode) {
      case BookingMode.asap:
        context.push('/book/asap');
      case BookingMode.scheduled:
        if (draft.scheduledFor == null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(content: Text('Pick a date and time first.')),
            );
          return;
        }
        context.push('/book/payment');
      case BookingMode.quote:
        context.push('/book/quotes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingDraft draft = ref.watch(bookingProvider);
    final Service? service = draft.service;
    final TextTheme text = Theme.of(context).textTheme;
    if (service == null) {
      return const Scaffold(body: Center(child: Text('No service selected')));
    }

    final String continueLabel = switch (draft.mode) {
      BookingMode.asap => 'Find a pro now',
      BookingMode.scheduled => 'Continue to payment',
      BookingMode.quote => 'Request quotes',
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Confirm booking'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: <Widget>[
                _serviceRow(service, text),
                const SizedBox(height: AppSpacing.xl),
                Text('How would you like to book?',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                ...BookingMode.values.map((BookingMode m) => _modeCard(
                      m,
                      selected: draft.mode == m,
                      onTap: () => ref.read(bookingProvider.notifier).setMode(m),
                      text: text,
                    )),
                if (draft.mode == BookingMode.scheduled) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _scheduleTile(draft, text),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('Address',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                _addressTile(draft, text),
                const SizedBox(height: AppSpacing.xl),
                Text('Notes for the pro (optional)',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g. The leak is under the kitchen sink.',
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _bottomBar(continueLabel),
          ),
        ],
      ),
    );
  }

  Widget _serviceRow(Service service, TextTheme text) {
    return Row(
      children: <Widget>[
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: serviceGlow(service),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(service.icon, color: service.tint),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(service.name,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _modeCard(BookingMode m,
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
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(m.blurb,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.65),
                            height: 1.3,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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

  Widget _scheduleTile(BookingDraft draft, TextTheme text) {
    final DateTime? when = draft.scheduledFor;
    final String label = when == null
        ? 'Pick a date & time'
        : '${_weekday(when.weekday)}, ${when.day}/${when.month} · ${_time(when)}';
    return _tappableTile(
      icon: Icons.event_rounded,
      title: label,
      subtitle: when == null ? 'Required for scheduled bookings' : 'Tap to change',
      onTap: _pickSchedule,
      text: text,
      highlight: when == null,
    );
  }

  Widget _addressTile(BookingDraft draft, TextTheme text) {
    return _tappableTile(
      icon: draft.address.icon,
      title: draft.address.label,
      subtitle: draft.address.line,
      onTap: () => context.push('/book/address'),
      text: text,
    );
  }

  Widget _tappableTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required TextTheme text,
    bool highlight = false,
  }) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Icon(icon,
                  color: highlight ? AppColors.warning : AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: text.bodySmall?.copyWith(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.65),
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(String label) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: GlowButton(label: label, onPressed: _continue),
    );
  }

  static String _weekday(int w) => const <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ][w - 1];

  static String _time(DateTime d) {
    final int h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }
}
