import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import '../location/location_provider.dart';
import '../location/pick_location_common.dart';
import '../location/pick_location_screen.dart';
import 'address_repository.dart';

const String _mapsKey = 'AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA';

/// Pick the service address from the user's saved book (Firestore, unique per
/// user). Selecting one sets it as the active location; "Add new" opens a form
/// dialog that writes a new address.
class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  static const String routePath = '/book/address';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final addressesAsync = ref.watch(savedAddressesProvider);
    final List<SavedAddress> addresses =
        addressesAsync.valueOrNull ?? const <SavedAddress>[];
    final UserLocation current = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l.serviceAddress)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                _mapPreview(context, ref, text, current),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l.savedAddresses),
                const SizedBox(height: AppSpacing.md),
                if (addressesAsync.isLoading && addresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  )
                else if (addresses.isEmpty)
                  _emptyState(text, l)
                else
                  ..._buildAddressCards(context, ref, text, addresses, current),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _addViaMap(context, ref),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: Text(l.addANewAddress),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(TextTheme text, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.location_off_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.5), size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(l.noSavedAddressesYet,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              )),
        ],
      ),
    );
  }

  /// Live preview of the current service location as a Google static map.
  /// Tapping it opens the full interactive picker to add a new address. Falls
  /// back to the grid placeholder if the static image can't load.
  Widget _mapPreview(BuildContext context, WidgetRef ref, TextTheme text,
      UserLocation current) {
    final double lat = current.lat ?? 29.9602;
    final double lng = current.lng ?? 31.2569;
    final String url = _staticMapUrl(lat, lng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _mapPlaceholder(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _mapPlaceholder(),
            ),
          ),
          // Subtle scrim so the chip stays readable over any map.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Row(
              children: <Widget>[
                const Icon(Icons.add_location_alt_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).tapToSetOnMap,
                    style: text.bodySmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Tap layer covering the whole preview.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: () => _addViaMap(context, ref)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1B2435), Color(0xFF111827)],
        ),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 40),
        ],
      ),
    );
  }

  /// Dark-styled Google Static Maps URL centred on [lat],[lng] with a marker.
  static String _staticMapUrl(double lat, double lng) {
    const String style =
        '&style=element:geometry%7Ccolor:0x1d2c4d'
        '&style=element:labels.text.fill%7Ccolor:0x8ec3b9'
        '&style=element:labels.text.stroke%7Ccolor:0x1a3646'
        '&style=feature:water%7Celement:geometry%7Ccolor:0x17263c'
        '&style=feature:road%7Celement:geometry%7Ccolor:0x304a7d';
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng&zoom=15&size=640x320&scale=2'
        '&markers=color:0x8B5CF6%7C$lat,$lng$style&key=$_mapsKey';
  }

  List<Widget> _buildAddressCards(
    BuildContext context,
    WidgetRef ref,
    TextTheme text,
    List<SavedAddress> addresses,
    UserLocation current,
  ) {
    final AppLocalizations l = AppLocalizations.of(context);
    return addresses.map((SavedAddress a) {
      final bool selected = a.line == current.address;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () {
              ref
                  .read(locationProvider.notifier)
                  .setFromSavedCoords(a.label, a.line, a.lat, a.lng);
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(a.icon, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          a.label,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.line,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(Icons.check_circle_rounded,
                          color: AppColors.primary),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.55)),
                    tooltip: l.delete,
                    onPressed: () =>
                        ref.read(addressRepositoryProvider)?.remove(a.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Add-address flow: open the interactive Google Maps picker to choose the
  /// real location, then collect a label/icon/optional detail and persist it
  /// (with coordinates) as a saved address that becomes the active location.
  Future<void> _addViaMap(BuildContext context, WidgetRef ref) async {
    final PickedPlace? place = await context.push<PickedPlace>(
        '${PickLocationScreen.routePath}?mode=address');
    if (place == null || !context.mounted) return; // backed out of the map

    final _AddressNaming? naming = await showModalBottomSheet<_AddressNaming>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameAddressSheet(addressLine: place.address),
    );
    if (naming == null || !context.mounted) return; // cancelled naming

    final String line = naming.details.isEmpty
        ? place.address
        : '${place.address} — ${naming.details}';
    final repo = ref.read(addressRepositoryProvider);
    await repo?.add(
      label: naming.label,
      line: line,
      iconKind: naming.kind,
      lat: place.lat,
      lng: place.lng,
    );
    // Make the freshly-added address the active service location.
    ref
        .read(locationProvider.notifier)
        .setFromSavedCoords(naming.label, line, place.lat, place.lng);
    if (context.mounted) context.pop();
  }
}

/// Result of the naming sheet: what the user typed for a map-picked address.
class _AddressNaming {
  const _AddressNaming(
      {required this.label, required this.kind, required this.details});
  final String label;
  final AddressIconKind kind;
  final String details;
}

/// Names a map-picked address: shows the geocoded line (read-only), then
/// collects a label, an icon, and an optional apartment/floor/landmark detail.
/// Pops with an [_AddressNaming], or null when cancelled.
class _NameAddressSheet extends StatefulWidget {
  const _NameAddressSheet({required this.addressLine});
  final String addressLine;

  @override
  State<_NameAddressSheet> createState() => _NameAddressSheetState();
}

class _NameAddressSheetState extends State<_NameAddressSheet> {
  final TextEditingController _labelCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();
  AddressIconKind _selectedKind = AddressIconKind.home;
  bool _showLabelError = false;

  final List<(String, AddressIconKind)> _iconOptions = const [
    ('Home', AddressIconKind.home),
    ('Work', AddressIconKind.work),
    ('Other', AddressIconKind.other),
    ('Friend', AddressIconKind.friend),
    ('Gym', AddressIconKind.gym),
    ('School', AddressIconKind.school),
  ];

  @override
  void dispose() {
    _labelCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final String label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _showLabelError = true);
      return;
    }
    Navigator.pop(
      context,
      _AddressNaming(
          label: label, kind: _selectedKind, details: _detailsCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                Text(l.nameThisAddress,
                    style:
                        text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),
                // The address that came back from the map (read-only).
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l.addressFromMap,
                                style: text.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(widget.addressLine,
                                style: text.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _labelCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_showLabelError) setState(() => _showLabelError = false);
                  },
                  decoration: InputDecoration(
                    labelText: l.addressLabel,
                    hintText: l.addressLabelHint,
                    errorText: _showLabelError ? l.enterALabel : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _detailsCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l.addressDetailsOptionalHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l.selectIcon, style: text.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: _iconOptions.map(((String, AddressIconKind) option) {
                    final String name = option.$1;
                    final AddressIconKind kind = option.$2;
                    final bool isSelected = kind == _selectedKind;
                    return Material(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: InkWell(
                        onTap: () => setState(() => _selectedKind = kind),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(kind.icon,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 24),
                              const SizedBox(height: 4),
                              Text(name,
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(l.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    const double step = 28;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
