import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';

/// The primary CTA — a filled button wrapped in a soft teal glow so it reads as
/// the lit endpoint of a flow. Unlike the shared `GlowButton`, the glow is
/// derived from the active theme's primary, so it stays teal in this app.
class TechGlowButton extends StatelessWidget {
  const TechGlowButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: enabled ? 0.42 : 0.0),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          child: loading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}
