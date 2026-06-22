import 'package:customer/l10n/app_localizations.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const String _mapsKey = 'AIzaSyBkGqJxUaSwTtMdLG6HEArY2Ca_VO0yZKE';

@immutable
class UserLocation {
  const UserLocation({required this.label, required this.address, this.lat, this.lng});
  final String label;
  final String address;
  final double? lat;
  final double? lng;

  UserLocation copyWith({String? label, String? address, double? lat, double? lng}) =>
      UserLocation(
        label: label ?? this.label,
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}

const UserLocation _defaultLocation = UserLocation(
  label: 'Home',
  address: 'Maadi, Cairo',
  lat: 29.9602,
  lng: 31.2569,
);

class LocationNotifier extends StateNotifier<UserLocation> {
  LocationNotifier() : super(_defaultLocation);

  void setFromSaved(String label, String line) {
    state = UserLocation(label: label, address: line);
  }

  void setFromCoords(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng);
    _reverseGeocode(lat, lng);
  }

  void setFromPinDrop(double lat, double lng, String address) {
    state = UserLocation(
      label: 'Pin drop',
      address: address.isNotEmpty ? address : 'Custom location',
      lat: lat,
      lng: lng,
    );
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$_mapsKey&language=en',
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return;
      final formatted = results[0]['formatted_address'] as String? ?? '';
      if (formatted.isNotEmpty) {
        state = state.copyWith(address: _shorten(formatted));
      }
    } catch (_) {
      // Keep existing address on failure.
    }
  }

  /// Trim overly long geocoded addresses to the first 2–3 meaningful parts.
  static String _shorten(String full) {
    final parts = full.split(',').map((s) => s.trim()).toList();
    if (parts.length <= 2) return full;
    return '${parts[0]}, ${parts[1]}';
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, UserLocation>(
  (ref) => LocationNotifier(),
);
