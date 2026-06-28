import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../marketplace/marketplace_providers.dart';
import '../services/category_l10n.dart';

/// The Bookings tab: live + upcoming jobs first, history below. Tapping an
/// active job returns to live tracking.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<JobRequest>> jobsAsync = ref.watch(myJobsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const AmbientBackground(intensity: 0.1),
        SafeArea(
          bottom: false,
          child: jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, _) =>
                Center(child: Text(AppLocalizations.of(context).error(e.toString()))),
            data: (List<JobRequest> jobs) {
              final List<JobRequest> active = jobs
                  .where((JobRequest j) =>
                      j.status != JobStatus.completed &&
                      j.status != JobStatus.cancelled)
                  .toList();
              final List<JobRequest> past = jobs
                  .where((JobRequest j) =>
                      j.status == JobStatus.completed ||
                      j.status == JobStatus.cancelled)
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 112),
                children: <Widget>[
                  Text(AppLocalizations.of(context).yourBookings,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xl),
                  if (active.isNotEmpty) ...<Widget>[
                    SectionHeader(title: AppLocalizations.of(context).activeAndUpcoming),
                    const SizedBox(height: AppSpacing.md),
                    ...active.map((JobRequest j) => _card(context, ref, j, text,
                        onTap: () => context.push('/job/live'),
                        cancellable: true)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SectionHeader(title: AppLocalizations.of(context).history),
                  const SizedBox(height: AppSpacing.md),
                  if (past.isEmpty)
                    _empty(text)
                  else
                    ...past.map((JobRequest j) => _card(context, ref, j, text)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, JobRequest job,
      TextTheme text,
      {VoidCallback? onTap, bool cancellable = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l = AppLocalizations.of(context);
    final (Color, IconData) badge = switch (job.status) {
      JobStatus.completed => (AppColors.success, Icons.check_circle),
      JobStatus.inProgress => (AppColors.primary, Icons.bolt),
      JobStatus.accepted => (AppColors.warning, Icons.event),
      _ => (AppColors.textSecondary, Icons.circle),
    };
    final Color subtitleColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isDark ? null : Border.all(color: const Color(0x12000000)),
        ),
        child: Material(
          color: isDark ? AppColors.surface.withValues(alpha: 0.5) : Colors.white,
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
                      color: categoryTint(job.category).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(categoryIcon(job.category),
                        color: categoryTint(job.category)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(job.title,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(categoryLabel(job.category, l),
                            style: text.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                                  : AppColors.textSecondaryLight,
                            )),
                        const SizedBox(height: 6),
                        StatusPill(
                            label: jobStatusLabel(job.status, l),
                            tint: badge.$1,
                            icon: badge.$2),
                        if (job.status == JobStatus.cancelled &&
                            (job.cancellationReason?.isNotEmpty ?? false)) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            l.cancelledReasonLabel(job.cancellationReason!),
                            style: text.bodySmall?.copyWith(color: subtitleColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('${job.settledPrice} ${l.egp}',
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (cancellable)
                        TextButton(
                          onPressed: () => _confirmCancel(context, ref, job),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.error,
                          ),
                          child: Text(l.cancelBookingTitle,
                              style: text.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the reason sheet; on confirmation cancels [job] with the chosen
  /// reason and shows a brief confirmation. A dismissed sheet is a no-op.
  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, JobRequest job) async {
    final String? reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelBookingSheet(job: job),
    );
    if (reason == null) return; // dismissed
    await ref
        .read(jobMarketplaceRepositoryProvider)
        .cancelJob(job.id, reason: reason.isEmpty ? null : reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).bookingCancelled),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Widget _empty(TextTheme text) {
    return Builder(builder: (context) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Icon(Icons.receipt_long_rounded,
                size: 44,
                color: isDark
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(AppLocalizations.of(context).noPastJobs,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    });
  }
}

/// Bottom sheet that collects a cancellation reason: one tappable preset plus an
/// optional free-text note. Pops with the composed reason string on confirm, or
/// null when dismissed / "Keep booking". "Other" requires the note to be filled.
class _CancelBookingSheet extends StatefulWidget {
  const _CancelBookingSheet({required this.job});

  final JobRequest job;

  @override
  State<_CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<_CancelBookingSheet> {
  // Stable keys decouple selection state from the localized labels.
  static const String _other = 'other';
  String? _selected;
  bool _showError = false;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<(String, String)> _reasons(AppLocalizations l) => <(String, String)>[
        ('found_another', l.cancelReasonFoundAnother),
        ('no_longer_needed', l.cancelReasonNoLongerNeeded),
        ('price_too_high', l.cancelReasonPriceTooHigh),
        ('taking_too_long', l.cancelReasonTakingTooLong),
        ('posted_by_mistake', l.cancelReasonPostedByMistake),
        (_other, l.cancelReasonOther),
      ];

  void _confirm(AppLocalizations l) {
    final String? key = _selected;
    final String note = _note.text.trim();
    // Must pick a reason; "Other" must carry a note to mean anything.
    if (key == null || (key == _other && note.isEmpty)) {
      setState(() => _showError = true);
      return;
    }
    final String label =
        _reasons(l).firstWhere((r) => r.$1 == key).$2;
    final String reason = key == _other
        ? note
        : (note.isEmpty ? label : '$label — $note');
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(l.cancelBookingTitle,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l.cancelBookingPrompt,
                  style: text.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _reasons(l).map(((String, String) r) {
                  final bool sel = _selected == r.$1;
                  return ChoiceChip(
                    label: Text(r.$2),
                    selected: sel,
                    onSelected: (_) =>
                        setState(() {
                          _selected = r.$1;
                          _showError = false;
                        }),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l.cancelNoteHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              if (_showError) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(l.selectACancelReason,
                    style: text.bodySmall?.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              GlowButton(
                label: l.cancelConfirm,
                onPressed: () => _confirm(l),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.keepBooking),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
