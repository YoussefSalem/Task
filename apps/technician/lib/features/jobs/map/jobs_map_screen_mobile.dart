import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../../../util/location_service.dart';
import '../../../util/money.dart';
import '../job_detail_screen.dart';
import '../jobs_providers.dart';

/// Native jobs map (Android/iOS): the open market plotted geographically so a
/// pro can see which nearby customers are looking and jump straight into a
/// job's detail. Reads the exact same [nearbyJobsProvider] the list feed uses,
/// so the map and list never disagree. Jobs posted without a pin drop can't be
/// placed, so the map surfaces a count of those and they stay list-only.
class JobsMapScreen extends ConsumerStatefulWidget {
  const JobsMapScreen({super.key});

  static const String routePath = '/jobs/map';
  static const String routeName = 'jobs-map';

  @override
  ConsumerState<JobsMapScreen> createState() => _JobsMapScreenState();
}

class _JobsMapScreenState extends ConsumerState<JobsMapScreen> {
  // Cairo, as a sensible default center before jobs load / when none have pins.
  static const LatLng _fallbackCenter = LatLng(29.9602, 31.2569);

  GoogleMapController? _controller;
  final LocationService _location = const LocationService();
  String? _selectedJobId;
  bool _fittedOnce = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<JobRequest> _mappable(List<JobRequest> jobs) =>
      jobs.where((JobRequest j) => j.hasCoordinates).toList();

  Set<Marker> _markers(List<JobRequest> jobs) {
    return jobs.map((JobRequest j) {
      final bool selected = j.id == _selectedJobId;
      return Marker(
        markerId: MarkerId(j.id),
        position: LatLng(j.lat!, j.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
        ),
        onTap: () => setState(() => _selectedJobId = j.id),
      );
    }).toSet();
  }

  /// After the map and jobs are both ready, frame all the pins once.
  Future<void> _fitToJobs(List<JobRequest> jobs) async {
    if (_fittedOnce || _controller == null || jobs.isEmpty) return;
    _fittedOnce = true;
    if (jobs.length == 1) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(jobs.first.lat!, jobs.first.lng!), 14),
      );
      return;
    }
    double minLat = jobs.first.lat!, maxLat = jobs.first.lat!;
    double minLng = jobs.first.lng!, maxLng = jobs.first.lng!;
    for (final JobRequest j in jobs) {
      minLat = j.lat! < minLat ? j.lat! : minLat;
      maxLat = j.lat! > maxLat ? j.lat! : maxLat;
      minLng = j.lng! < minLng ? j.lng! : minLng;
      maxLng = j.lng! > maxLng ? j.lng! : maxLng;
    }
    // A small delay lets the platform view finish laying out; bounds animation
    // throws if the map has no size yet.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          64,
        ),
      );
    } catch (_) {
      // Fall back to centering on the first job if bounds framing fails.
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(jobs.first.lat!, jobs.first.lng!), 12),
      );
    }
  }

  Future<void> _goToMyLocation() async {
    final ({double lat, double lng})? me = await _location.current();
    if (me == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Could not get your location. Check location permission.'),
        ));
      return;
    }
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(me.lat, me.lng), 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<JobRequest> all = ref.watch(nearbyJobsProvider);
    final List<JobRequest> mappable = _mappable(all);
    final int withoutPin = all.length - mappable.length;
    final JobRequest? selected = _selectedJobId == null
        ? null
        : mappable.where((JobRequest j) => j.id == _selectedJobId).firstOrNull;

    // Frame the pins once they (and the controller) are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToJobs(mappable));

    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _fallbackCenter,
              zoom: 11,
            ),
            markers: _markers(mappable),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController c) => _controller = c,
            onTap: (_) => setState(() => _selectedJobId = null),
          ),

          // Back button.
          Positioned(
            top: mq.padding.top + AppSpacing.sm,
            left: AppSpacing.lg,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),

          // My-location button.
          Positioned(
            top: mq.padding.top + AppSpacing.sm,
            right: AppSpacing.lg,
            child: _CircleButton(
              icon: Icons.my_location_rounded,
              onTap: _goToMyLocation,
            ),
          ),

          // Count banner.
          Positioned(
            top: mq.padding.top + AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(child: _CountPill(onMap: mappable.length, withoutPin: withoutPin)),
          ),

          // Selected-job card.
          if (selected != null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: mq.padding.bottom + AppSpacing.lg,
              child: _JobPreviewCard(
                job: selected,
                onView: () => context.pushNamed(
                  JobDetailScreen.routeName,
                  pathParameters: <String, String>{'jobId': selected.id},
                ),
              ),
            )
          else if (mappable.isEmpty)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: mq.padding.bottom + AppSpacing.lg,
              child: _EmptyHint(withoutPin: withoutPin),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: scheme.onSurface),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.onMap, required this.withoutPin});
  final int onMap;
  final int withoutPin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String label = withoutPin > 0
        ? '$onMap on map · $withoutPin without a pin'
        : '$onMap job${onMap == 1 ? '' : 's'} on map';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _JobPreviewCard extends StatelessWidget {
  const _JobPreviewCard({required this.job, required this.onView});
  final JobRequest job;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = categoryTint(job.category);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(categoryIcon(job.category), color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
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
                  const SizedBox(height: 2),
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
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: onView,
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.withoutPin});
  final int withoutPin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String msg = withoutPin > 0
        ? 'No jobs have a map pin right now. $withoutPin open job'
            '${withoutPin == 1 ? '' : 's'} without a pin ${withoutPin == 1 ? 'is' : 'are'} in the list.'
        : 'No customers are looking nearby right now.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.location_off_rounded,
              size: 20, color: scheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(msg,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    )),
          ),
        ],
      ),
    );
  }
}
