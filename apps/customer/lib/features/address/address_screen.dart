import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';
import '../location/location_provider.dart';
import 'address_repository.dart';

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
                _mapPreview(context, text),
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
                  onPressed: () => _showAddAddressDialog(context, ref, l),
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

  Widget _mapPreview(BuildContext context, TextTheme text) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 40),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).pinOnMap,
                style: text.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _showAddAddressDialog(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddAddressDialog(
        onAdd: (label, line, iconKind) async {
          final repo = ref.read(addressRepositoryProvider);
          await repo?.add(label: label, line: line, iconKind: iconKind);
          // Immediately set as the active location.
          ref
              .read(locationProvider.notifier)
              .setFromSaved(label, line);
        },
      ),
    );
  }
}

class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog({required this.onAdd});
  final Future<void> Function(String label, String line, AddressIconKind kind)
      onAdd;

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  late TextEditingController _labelCtrl;
  late TextEditingController _lineCtrl;
  AddressIconKind _selectedKind = AddressIconKind.other;
  bool _isSubmitting = false;

  final List<(String, AddressIconKind)> _iconOptions = const [
    ('Home', AddressIconKind.home),
    ('Work', AddressIconKind.work),
    ('Other', AddressIconKind.other),
    ('Friend', AddressIconKind.friend),
    ('Gym', AddressIconKind.gym),
    ('School', AddressIconKind.school),
  ];

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController();
    _lineCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_labelCtrl.text.trim().isEmpty || _lineCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).fillAllFields)));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onAdd(
          _labelCtrl.text.trim(), _lineCtrl.text.trim(), _selectedKind);
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      if (context.mounted) context.pop(); // return from address screen
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.addANewAddress,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _labelCtrl,
                decoration: InputDecoration(
                  labelText: l.addressLabel,
                  hintText: l.addressLabelHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _lineCtrl,
                decoration: InputDecoration(
                  labelText: l.addressDetails,
                  hintText: l.addressDetailsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                maxLines: 2,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.selectIcon, style: text.titleSmall),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: _iconOptions.map((option) {
                  final name = option.$1;
                  final kind = option.$2;
                  final isSelected = kind == _selectedKind;
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surface.withValues(alpha: 0.5),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: !_isSubmitting ? () => setState(() => _selectedKind = kind) : null,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                kind.icon,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: text.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: !_isSubmitting ? () => Navigator.pop(context) : null,
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: !_isSubmitting ? _submit : null,
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            )
                          : Text(l.save),
                    ),
                  ),
                ],
              ),
            ],
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
