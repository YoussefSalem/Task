import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../../widgets/static_map.dart';
import '../../../util/money.dart';
import '../job_detail_screen.dart';
import '../jobs_providers.dart';

/// Web fallback for the jobs map. `google_maps_flutter`'s interactive map is a
/// native platform view; on the browser (dev scaffolding only) we render each
/// available job as a static-map card instead, tapping through to the job
/// detail. Same [JobsMapScreen] name/route as the mobile impl so the router is
/// platform-agnostic.
class JobsMapScreen extends ConsumerWidget {
  const JobsMapScreen({super.key});

  static const String routePath = '/jobs/map';
  static const String routeName = 'jobs-map';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<JobRequest> all = ref.watch(nearbyJobsProvider);
    final List<JobRequest> mappable =
        all.where((JobRequest j) => j.hasCoordinates).toList();
    final int withoutPin = all.length - mappable.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs map'),
      ),
      body: mappable.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  withoutPin > 0
                      ? 'No jobs have a map pin right now. $withoutPin open '
                          'job${withoutPin == 1 ? '' : 's'} without a pin '
                          '${withoutPin == 1 ? 'is' : 'are'} in the list.'
                      : 'No customers are looking nearby right now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: mappable.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) {
                final JobRequest job = mappable[i];
                return _JobMapCard(
                  job: job,
                  onTap: () => context.pushNamed(
                    JobDetailScreen.routeName,
                    pathParameters: <String, String>{'jobId': job.id},
                  ),
                );
              },
            ),
    );
  }
}

class _JobMapCard extends StatelessWidget {
  const _JobMapCard({required this.job, required this.onTap});
  final JobRequest job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StaticMap(lat: job.lat, lng: job.lng, address: job.locationLabel),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Icon(categoryIcon(job.category), color: categoryTint(job.category)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          job.title.isEmpty ? job.category.displayLabel : job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${egpLabel(job.fixedPrice)} · ${job.locationLabel.isEmpty ? job.category.displayLabel : job.locationLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
