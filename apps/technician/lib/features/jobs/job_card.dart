import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../util/money.dart';
import '../../widgets/static_map.dart';

/// A single job in a list: the trade, what it is, where, when, and the
/// customer's asking price — plus a badge when this pro has already bid. Tuned
/// for scanning a feed quickly, so the price and urgency read at a glance.
class JobCard extends StatelessWidget {
  const JobCard({
    required this.job,
    required this.onTap,
    this.myOfferAmount,
    super.key,
  });

  final JobRequest job;
  final VoidCallback onTap;

  /// This pro's current bid on the job, if any — shown as a footer.
  final int? myOfferAmount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = categoryTint(job.category);
    final bool searchingNow = job.isSearchingAt(DateTime.now());
    final int bids = job.offers
        .where((o) =>
            o.status != OfferStatus.withdrawn &&
            o.status != OfferStatus.declined)
        .length;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(categoryIcon(job.category), color: tint),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          job.title.isEmpty
                              ? job.category.displayLabel
                              : job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.category.displayLabel,
                          style: text.bodySmall?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        egpLabel(job.fixedPrice),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('asking',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (searchingNow)
                    const StatusPill(
                      label: 'Looking now',
                      tint: AppColors.success,
                      icon: Icons.sensors_rounded,
                    ),
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: job.locationLabel.isEmpty
                        ? 'Nearby'
                        : job.locationLabel,
                  ),
                  _MetaChip(
                    icon: job.timing == JobTiming.asap
                        ? Icons.flash_on_rounded
                        : Icons.event_outlined,
                    label: job.timing == JobTiming.asap ? 'ASAP' : 'Scheduled',
                  ),
                  StatusPill(
                    label: _urgencyLabel(job.urgency),
                    tint: _urgencyTint(job.urgency),
                  ),
                  if (bids > 0)
                    _MetaChip(
                      icon: Icons.gavel_rounded,
                      label: '$bids ${bids == 1 ? 'bid' : 'bids'}',
                    ),
                ],
              ),
              if (job.hasCoordinates || job.locationLabel.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                StaticMap(
                  lat: job.lat,
                  lng: job.lng,
                  address: job.locationLabel,
                  height: 120,
                ),
              ],
              if (myOfferAmount != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Your bid: ${egpLabel(myOfferAmount!)}',
                        style: text.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: c, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

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
