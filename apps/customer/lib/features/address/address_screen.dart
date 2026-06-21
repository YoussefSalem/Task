import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';

/// Pick the service address from the saved book. Selecting one writes it to the
/// draft and returns. "Add new" is a stubbed affordance for the prototype.
class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  static const String routePath = '/book/address';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookingDraft draft = ref.watch(bookingProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Service address'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AmbientBackground(intensity: 0.1),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                _mapPreview(text),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Saved addresses'),
                const SizedBox(height: AppSpacing.md),
                ...kSavedAddresses.map((SavedAddress a) {
                  final bool selected = a.id == draft.addressId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        onTap: () {
                          ref.read(bookingProvider.notifier).setAddress(a.id);
                          context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
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
                                    Text(a.label,
                                        style: text.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(a.line,
                                        style: text.bodySmall?.copyWith(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.65),
                                        )),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(const SnackBar(
                          content: Text('Adding addresses arrives soon.')));
                  },
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Add a new address'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5)),
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

  Widget _mapPreview(TextTheme text) {
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
              const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 40),
              const SizedBox(height: 4),
              Text('Pin on map',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  )),
            ],
          ),
        ],
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
