import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// A read-only Google Static Map of a location. Accepts precise coordinates
/// (preferred) or a text [address] as a fallback, so it renders a customer's
/// job location whether or not the job was posted with a pin drop.
///
/// One HTTP image per distinct URL — cached by the network layer, so repeats in
/// a list reuse the same fetch.
class StaticMap extends StatelessWidget {
  const StaticMap({
    this.lat,
    this.lng,
    this.address,
    this.height = 130,
    this.zoom = 15,
    this.borderRadius = AppSpacing.radiusLg,
    super.key,
  });

  final double? lat;
  final double? lng;
  final String? address;
  final double height;
  final int zoom;
  final double borderRadius;

  // Shared Maps key (Static Maps API enabled for the project).
  static const String _key = 'AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA';

  bool get _hasCoords => lat != null && lng != null;
  bool get _hasTarget =>
      _hasCoords || (address != null && address!.trim().isNotEmpty);

  String get _target =>
      _hasCoords ? '$lat,$lng' : Uri.encodeComponent(address!.trim());

  String get _url =>
      'https://maps.googleapis.com/maps/api/staticmap?center=$_target'
      '&zoom=$zoom&size=640x280&scale=2'
      '&markers=color:0x14B8A6%7Clabel:C%7C$_target&key=$_key';

  @override
  Widget build(BuildContext context) {
    if (!_hasTarget) return const SizedBox.shrink();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(
          _url,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => _fallback(context, scheme,
              icon: Icons.location_on_outlined, text: address ?? 'Location'),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  color: scheme.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context, ColorScheme scheme,
      {required IconData icon, required String text}) {
    return Container(
      color: scheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65))),
          ),
        ],
      ),
    );
  }
}
