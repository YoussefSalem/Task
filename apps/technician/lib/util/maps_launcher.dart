import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps with driving navigation to a destination.
///
/// Uses the cross-platform Google Maps URL scheme: on mobile it hands off to the
/// Maps app (falling back to the browser), on web it opens Maps in a new tab.
/// Prefers precise [lat]/[lng]; otherwise routes to the text [address] as a
/// search query, so it still works for jobs posted before coordinates existed.
///
/// Returns false when there's nothing to navigate to or the launch failed.
Future<bool> openDirections({
  double? lat,
  double? lng,
  String? address,
}) async {
  final String destination;
  if (lat != null && lng != null) {
    destination = '$lat,$lng';
  } else if (address != null && address.trim().isNotEmpty) {
    destination = address.trim();
  } else {
    return false;
  }

  final Uri uri = Uri.https('www.google.com', '/maps/dir/', <String, String>{
    'api': '1',
    'destination': destination,
    'travelmode': 'driving',
  });

  try {
    return await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
