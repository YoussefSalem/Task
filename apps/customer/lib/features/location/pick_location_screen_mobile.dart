import 'dart:async';
import 'dart:convert';

import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:task_design/task_design.dart';

import '../address/address_repository.dart';
import '../booking/booking_state.dart';
import 'location_provider.dart';
import 'pick_location_common.dart';

const String _mapsKey = 'AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA';

/// Dark map theme matching the web picker's custom style.
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#255d6a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]}
]
''';

/// Native location picker (Android/iOS) — an interactive `google_maps_flutter`
/// map with a fixed center pin. Panning the map moves the pin; the address is
/// reverse-geocoded on idle via the Google Geocoding HTTP API.
class PickLocationScreen extends ConsumerStatefulWidget {
  const PickLocationScreen({super.key});

  static const String routePath = '/pick-location';
  static const String routeName = 'pick-location';

  @override
  ConsumerState<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends ConsumerState<PickLocationScreen> {
  GoogleMapController? _controller;
  final TextEditingController _searchController = TextEditingController();

  bool _detecting = false;
  bool _mapDragging = false;
  bool _addressLoading = false;
  String _pinAddress = '';
  late LatLng _center;
  int _geocodeToken = 0;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationProvider);
    _center = LatLng(loc.lat ?? 29.9602, loc.lng ?? 31.2569);
    _pinAddress = loc.address;
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ---- Map callbacks -------------------------------------------------------

  void _onCameraMoveStarted() {
    if (!_mapDragging && mounted) setState(() => _mapDragging = true);
  }

  void _onCameraMove(CameraPosition pos) {
    _center = pos.target;
  }

  void _onCameraIdle() {
    if (mounted) {
      setState(() {
        _mapDragging = false;
        _addressLoading = true;
      });
    }
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocode(_center.latitude, _center.longitude);
    });
  }

  // ---- Geocoding -----------------------------------------------------------

  Future<void> _reverseGeocode(double lat, double lng) async {
    final token = ++_geocodeToken;
    try {
      final l = AppLocalizations.of(context);
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$_mapsKey&language=${l.localeName}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return;
      // Prefer the first result that isn't a plus_code.
      Map<String, dynamic>? best;
      for (final r in results) {
        final m = r as Map<String, dynamic>;
        final types = (m['types'] as List<dynamic>? ?? const <dynamic>[]);
        if (types.contains('plus_code')) continue;
        best = m;
        break;
      }
      best ??= results.first as Map<String, dynamic>;
      final formatted = best['formatted_address'] as String? ?? '';
      // Ignore if a newer reverse-geocode has superseded this one.
      if (!mounted || token != _geocodeToken) return;
      setState(() {
        if (formatted.isNotEmpty) _pinAddress = _shorten(formatted);
        _addressLoading = false;
      });
    } catch (_) {
      if (mounted && token == _geocodeToken) {
        setState(() => _addressLoading = false);
      }
    }
  }

  static String _shorten(String full) {
    final parts = full.split(',').map((s) => s.trim()).toList();
    if (parts.length <= 2) return full;
    return '${parts[0]}, ${parts[1]}';
  }

  Future<void> _searchAndPan(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(q)}&key=$_mapsKey',
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context).moveMapToSet),
            ));
        }
        return;
      }
      final loc =
          (results.first as Map<String, dynamic>)['geometry']['location']
              as Map<String, dynamic>;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17),
      );
      _searchController.clear();
    } catch (_) {
      // Keep current map position on failure.
    }
  }

  // ---- My location ---------------------------------------------------------

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw const _LocationDenied();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          17,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).couldNotDetectLocation),
        ));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  // ---- Confirm / saved -----------------------------------------------------

  void _confirmLocation() {
    ref
        .read(locationProvider.notifier)
        .setFromPinDrop(_center.latitude, _center.longitude, _pinAddress);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Full-screen interactive map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            style: _darkMapStyle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: false,
            onMapCreated: (c) => _controller = c,
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          // Fixed center pin + ground shadow
          CenterPin(dragging: _mapDragging),
          PinShadow(dragging: _mapDragging),

          // Search bar
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            left: 60 + AppSpacing.lg,
            right: 60 + AppSpacing.lg,
            child: _SearchBar(
              controller: _searchController,
              hint: l.searchForAddress,
              onSubmitted: _searchAndPan,
            ),
          ),

          // Back button
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            left: AppSpacing.lg,
            child: LocationBackButton(onTap: () => context.pop()),
          ),

          // My location FAB
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            right: AppSpacing.lg,
            child: MyLocationFab(
              detecting: _detecting,
              onTap: _detectLocation,
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LocationBottomPanel(
              address: _pinAddress,
              addressLoading: _addressLoading,
              text: text,
              bottomPadding: mq.padding.bottom,
              onConfirm: _confirmLocation,
              savedAddresses: ref.watch(savedAddressesProvider).valueOrNull ??
                  const <SavedAddress>[],
              onSavedTap: (SavedAddress a) {
                ref
                    .read(locationProvider.notifier)
                    .setFromSavedCoords(a.label, a.line, a.lat, a.lng);
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDenied implements Exception {
  const _LocationDenied();
}

/// Glass search field styled to match the web picker's search input.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: Colors.white.withValues(alpha: 0.45)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 42, minHeight: 44),
          border: InputBorder.none,
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
