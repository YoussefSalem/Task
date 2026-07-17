import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../util/money.dart';
import '../../widgets/tech_glow_button.dart';
import '../chat/chat_providers.dart';
import '../profile/technician_profile.dart';
import 'jobs_providers.dart';

/// The bid composer. A pro names their price and an arrival window; we default
/// the price to the customer's asking figure so accepting-as-is is one tap.
/// Returns true if a bid was placed so the caller can confirm.
class PlaceBidSheet extends ConsumerStatefulWidget {
  const PlaceBidSheet({required this.job, super.key});

  final JobRequest job;

  static Future<bool?> show(BuildContext context, JobRequest job) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PlaceBidSheet(job: job),
      ),
    );
  }

  @override
  ConsumerState<PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends ConsumerState<PlaceBidSheet> {
  late final TextEditingController _amount;
  String _eta = 'Within 1 hour';
  bool _busy = false;

  static const List<String> _etaOptions = <String>[
    'Within 1 hour',
    'Within 3 hours',
    'Today',
    'Tomorrow',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.job.offers
        .where((o) => o.technicianId == ref.read(currentUidProvider))
        .firstOrNull;
    _amount = TextEditingController(
      text: (existing?.currentPrice ?? widget.job.fixedPrice).toString(),
    );
    if (existing != null && existing.etaLabel.isNotEmpty) {
      _eta = _etaOptions.contains(existing.etaLabel)
          ? existing.etaLabel
          : _etaOptions.first;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _amountValue => int.tryParse(_amount.text.trim()) ?? 0;
  bool get _valid => _amountValue > 0;

  Future<void> _submit() async {
    final repo = ref.read(technicianJobsRepositoryProvider);
    final profile = ref.read(techProfileProvider).valueOrNull;
    if (repo == null || profile == null || !_valid || _busy) return;
    setState(() => _busy = true);
    try {
      final String techName =
          profile.fullName.isEmpty ? 'Technician' : profile.fullName;
      await repo.placeBid(
        jobId: widget.job.id,
        amount: _amountValue,
        technicianName: techName,
        rating: profile.rating,
        jobsDone: profile.jobsDone,
        etaLabel: _eta,
      );
      // Light up the customer's in-app feed (no server fan-out yet).
      if (widget.job.customerId.isNotEmpty) {
        await ref.read(notificationRepositoryProvider).notify(
              recipientUid: widget.job.customerId,
              draft: NotificationDraft(
                type: NotificationType.offer,
                title: 'New bid from $techName',
                body:
                    '${egpLabel(_amountValue)} · ${widget.job.category.displayLabel}',
                actorId: ref.read(currentUidProvider),
                jobId: widget.job.id,
              ),
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place bid: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isUpdate = widget.job.offers
            .any((o) => o.technicianId == ref.read(currentUidProvider));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(isUpdate ? 'Update your bid' : 'Place your bid',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Customer is asking ${egpLabel(widget.job.fixedPrice)}.',
            style: text.bodyMedium
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Your price (EGP)',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixText: 'EGP  ',
              hintText: '0',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('When can you arrive?',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _etaOptions.map((o) {
              final bool sel = o == _eta;
              return ChoiceChip(
                label: Text(o),
                selected: sel,
                onSelected: (_) => setState(() => _eta = o),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          TechGlowButton(
            label: isUpdate ? 'Update bid' : 'Send bid',
            icon: Icons.send_rounded,
            loading: _busy,
            onPressed: _valid ? _submit : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
