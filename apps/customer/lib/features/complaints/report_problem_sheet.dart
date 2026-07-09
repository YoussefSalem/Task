import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../auth/auth_controller.dart';
import 'complaint_providers.dart';

/// Bottom sheet for filing a complaint about a specific job, mirroring the
/// existing cancel-reason sheet in bookings_screen.dart (category chips + an
/// optional note + a confirm button). Not localized yet (plain English
/// strings) - this is new, safe scaffolding; wiring these into app_en.arb/
/// app_ar.arb is a follow-up, not required for the feature to function.
class ReportProblemSheet extends ConsumerStatefulWidget {
  const ReportProblemSheet({
    super.key,
    required this.jobId,
    this.technicianId,
  });

  final String jobId;
  final String? technicianId;

  @override
  ConsumerState<ReportProblemSheet> createState() => _ReportProblemSheetState();

  static const List<(String, String)> categories = <(String, String)>[
    ('no_show', 'Technician never showed up'),
    ('late', 'Arrived very late'),
    ('unsafe_behavior', 'Unsafe or unprofessional behavior'),
    ('billing', 'Charged the wrong amount'),
    ('quality', 'Poor quality of work'),
    ('other', 'Something else'),
  ];
}

class _ReportProblemSheetState extends ConsumerState<ReportProblemSheet> {
  String? _selected;
  final TextEditingController _note = TextEditingController();
  bool _submitting = false;
  bool _showError = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _showError = true);
      return;
    }
    final String? uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _submitting = true);
    final result = await ref.read(complaintRepositoryProvider).submit(
          ComplaintDraft(
            jobId: widget.jobId,
            raisedBy: ComplaintRaisedBy.customer,
            reporterId: uid,
            subjectId: widget.technicianId,
            category: _selected!,
            description: _note.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.isOk) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit your report. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        decoration: const BoxDecoration(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
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
              Text('Report a problem',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('What went wrong with this job?',
                  style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: ReportProblemSheet.categories.map(((String, String) c) {
                  final bool sel = _selected == c.$1;
                  return ChoiceChip(
                    label: Text(c.$2),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _selected = c.$1;
                      _showError = false;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Add any details that might help (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              if (_showError) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text('Please choose what went wrong',
                    style: text.bodySmall?.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              GlowButton(
                label: _submitting ? 'Submitting...' : 'Submit report',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
