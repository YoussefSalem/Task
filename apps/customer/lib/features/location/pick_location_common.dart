import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

import '../booking/booking_state.dart';

// ---------------------------------------------------------------------------
// Shared presentation widgets for the location picker.
//
// Both the web (iframe map) and mobile (google_maps_flutter) pickers render the
// same chrome — a fixed center pin, a back button, a my-location FAB and the
// bottom address/confirm panel — so those live here and are platform-agnostic.
// ---------------------------------------------------------------------------

/// Fixed center pin. Lifts slightly while the map is being dragged.
class CenterPin extends StatelessWidget {
  const CenterPin({super.key, required this.dragging});
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 44),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, dragging ? -12 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 22),
              ),
              // Pin stem
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(2)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ground shadow under the center pin. Shrinks while dragging.
class PinShadow extends StatelessWidget {
  const PinShadow({super.key, required this.dragging});
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: dragging ? 8 : 14,
          height: dragging ? 4 : 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: dragging ? 0.2 : 0.35),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

/// Circular back button.
class LocationBackButton extends StatelessWidget {
  const LocationBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

/// Circular "my location" FAB. Shows a spinner while [detecting].
class MyLocationFab extends StatelessWidget {
  const MyLocationFab({super.key, required this.detecting, required this.onTap});
  final bool detecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: detecting ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: detecting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 20),
      ),
    );
  }
}

/// Bottom panel — current pin address, saved-address chips, confirm button.
class LocationBottomPanel extends StatelessWidget {
  const LocationBottomPanel({
    super.key,
    required this.address,
    required this.addressLoading,
    required this.text,
    required this.bottomPadding,
    required this.onConfirm,
    required this.savedAddresses,
    required this.onSavedTap,
  });

  final String address;
  final bool addressLoading;
  final TextTheme text;
  final double bottomPadding;
  final VoidCallback onConfirm;
  final List<SavedAddress> savedAddresses;
  final ValueChanged<SavedAddress> onSavedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        bottomPadding + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Current pin address
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AppLocalizations.of(context).serviceLocation,
                        style: text.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                    const SizedBox(height: 2),
                    addressLoading
                        ? Row(
                            children: <Widget>[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).findingAddress,
                                  style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                                  )),
                            ],
                          )
                        : Text(
                            address.isNotEmpty
                                ? address
                                : AppLocalizations.of(context).moveMapToSet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Saved address chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: savedAddresses.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final a = savedAddresses[i];
                return GestureDetector(
                  onTap: () => onSavedTap(a),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(a.icon, size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(a.label,
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onConfirm,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context).setServiceLocation,
                          style: text.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
