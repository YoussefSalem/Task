import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../util/money.dart';
import '../../widgets/static_map.dart';
import '../chat/chat_screen.dart';
import 'active_job_screen.dart';
import 'jobs_providers.dart';
import 'place_bid_sheet.dart';

/// The full brief for one job, and the place a pro decides to bid, negotiate, or
/// (once hired) jump to the active-job workspace.
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  static const String routeName = 'job-detail';
  static const String routePath = '/job/:jobId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JobRequest? job = ref.watch(jobByIdProvider(jobId));
    final String? uid = ref.watch(currentUidProvider);

    if (job == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Offer? myOffer =
        job.offers.where((o) => o.technicianId == uid).firstOrNull;
    final bool hiredMe = job.acceptedOffer?.technicianId == uid;
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = categoryTint(job.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(job.category.displayLabel),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(categoryIcon(job.category), color: tint, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      job.title.isEmpty ? job.category.displayLabel : job.title,
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text('Posted ${_ago(job.createdAt)}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PriceHero(job: job, myOffer: myOffer),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              StatusPill(
                label: _urgencyLabel(job.urgency),
                tint: _urgencyTint(job.urgency),
                icon: Icons.priority_high_rounded,
              ),
              StatusPill(
                label: job.timing == JobTiming.asap
                    ? 'ASAP'
                    : 'Scheduled ${job.scheduledAt != null ? DateFormat('MMM d, h:mm a').format(job.scheduledAt!) : ''}',
                tint: scheme.primary,
                icon: job.timing == JobTiming.asap
                    ? Icons.flash_on_rounded
                    : Icons.event_rounded,
              ),
            ],
          ),
          if (job.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            _Section(title: 'The job', body: job.description),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Details'),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: job.locationLabel.isEmpty ? 'Shared after hire' : job.locationLabel),
          _DetailRow(
              icon: Icons.home_work_outlined,
              label: 'Property',
              value: _propertyLabel(job.propertyType)),
          if ((job.floor ?? '').isNotEmpty)
            _DetailRow(
                icon: Icons.stairs_outlined, label: 'Floor', value: job.floor!),
          if (job.parking != null)
            _DetailRow(
                icon: Icons.local_parking_outlined,
                label: 'Parking',
                value: job.parking! ? 'Available' : 'None'),
          if (job.notes.isNotEmpty)
            _DetailRow(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notes',
                value: job.notes),
          if (job.hasCoordinates || job.locationLabel.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Customer location'),
            const SizedBox(height: AppSpacing.sm),
            StaticMap(
              lat: job.lat,
              lng: job.lng,
              address: job.locationLabel,
              height: 180,
            ),
            if (job.locationLabel.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Icon(Icons.location_on_rounded,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(job.locationLabel,
                        style: text.bodyMedium),
                  ),
                ],
              ),
            ],
          ],
          if (myOffer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Your negotiation'),
            const SizedBox(height: AppSpacing.sm),
            _NegotiationThread(offer: myOffer),
          ],
        ],
      ),
      bottomNavigationBar: _BottomBar(
        job: job,
        myOffer: myOffer,
        hiredMe: hiredMe,
      ),
    );
  }
}

class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.job, required this.myOffer});
  final JobRequest job;
  final Offer? myOffer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Customer is asking',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    )),
                const SizedBox(height: 2),
                Text(egpLabel(job.fixedPrice),
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    )),
              ],
            ),
          ),
          if (myOffer != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text('Your bid',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    )),
                const SizedBox(height: 2),
                Text(egpLabel(myOffer!.currentPrice),
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
        ],
      ),
    );
  }
}

class _NegotiationThread extends StatelessWidget {
  const _NegotiationThread({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: <Widget>[
          ...offer.proposals.map((p) {
            final bool mine = p.by == ProposalAuthor.technician;
            return Align(
              alignment:
                  mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: mine
                      ? scheme.primary.withValues(alpha: 0.16)
                      : scheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(mine ? 'You proposed' : 'Customer countered',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        )),
                    Text(egpLabel(p.amount),
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          _OfferStatusLine(status: offer.status),
        ],
      ),
    );
  }
}

class _OfferStatusLine extends StatelessWidget {
  const _OfferStatusLine({required this.status});
  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, IconData icon) = switch (status) {
      OfferStatus.pending => (
          'Waiting for the customer to respond',
          AppColors.warning,
          Icons.hourglass_top_rounded
        ),
      OfferStatus.countered => (
          'Customer countered — respond below',
          const Color(0xFF38BDF8),
          Icons.swap_horiz_rounded
        ),
      OfferStatus.accepted => (
          "You're hired!",
          AppColors.success,
          Icons.verified_rounded
        ),
      OfferStatus.declined => (
          'Customer went with someone else',
          AppColors.error,
          Icons.cancel_outlined
        ),
      OfferStatus.withdrawn => (
          'You withdrew this bid',
          AppColors.error,
          Icons.undo_rounded
        ),
    };
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({
    required this.job,
    required this.myOffer,
    required this.hiredMe,
  });

  final JobRequest job;
  final Offer? myOffer;
  final bool hiredMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    Widget primary;
    if (hiredMe) {
      primary = FilledButton.icon(
        onPressed: () => context.pushReplacementNamed(
          ActiveJobScreen.routeName,
          pathParameters: <String, String>{'jobId': job.id},
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Open active job'),
      );
    } else if (myOffer != null &&
        (myOffer!.status == OfferStatus.pending ||
            myOffer!.status == OfferStatus.countered)) {
      primary = Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _withdraw(context, ref),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Withdraw'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _bid(context),
              icon: const Icon(Icons.edit_rounded),
              label: Text(myOffer!.status == OfferStatus.countered
                  ? 'Respond'
                  : 'Update bid'),
            ),
          ),
        ],
      );
    } else {
      primary = FilledButton.icon(
        onPressed: () => _bid(context),
        icon: const Icon(Icons.gavel_rounded),
        label: const Text('Place bid'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      );
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: <Widget>[
          if (myOffer != null || hiredMe) ...<Widget>[
            _CircleAction(
              icon: Icons.chat_bubble_rounded,
              tooltip: 'Message customer',
              onTap: () => context.pushNamed(
                ChatScreen.routeName,
                pathParameters: <String, String>{'jobId': job.id},
                extra: ChatArgs(
                  jobId: job.id,
                  technicianId: ref.read(currentUidProvider) ?? '',
                  customerId: job.customerId,
                  customerName: 'Customer',
                ),
              ),
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: primary),
        ],
      ),
    );
  }

  Future<void> _bid(BuildContext context) async {
    final bool? placed = await PlaceBidSheet.show(context, job);
    if (placed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid sent. You’ll be notified if hired.')),
      );
    }
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw bid?'),
        content: const Text(
            'Your offer will be removed from this job. You can bid again later.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep bid')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(technicianJobsRepositoryProvider);
    await repo?.withdrawBid(job.id);
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 52,
            width: 52,
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        Text(body,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(height: 1.5)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 84,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    )),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

String _ago(DateTime t) {
  final Duration d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

String _propertyLabel(PropertyType p) => switch (p) {
      PropertyType.apartment => 'Apartment',
      PropertyType.villa => 'Villa',
      PropertyType.office => 'Office',
      PropertyType.other => 'Other',
    };

String _urgencyLabel(Urgency u) => switch (u) {
      Urgency.flexible => 'Flexible',
      Urgency.soon => 'Soon',
      Urgency.urgent => 'Urgent',
      Urgency.emergency => 'Emergency',
    };

Color _urgencyTint(Urgency u) => switch (u) {
      Urgency.flexible => AppColors.success,
      Urgency.soon => const Color(0xFF38BDF8),
      Urgency.urgent => AppColors.warning,
      Urgency.emergency => AppColors.error,
    };
