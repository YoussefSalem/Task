import 'package:flutter/material.dart';

import '../app/tech_colors.dart';

/// The Technician app's signature backdrop: a quiet teal bloom drifting from a
/// corner over the scaffold. The sibling of the Customer app's violet bloom —
/// same atmosphere, different accent — carried across screens so the app reads
/// as one continuous surface.
class TechAmbient extends StatelessWidget {
  const TechAmbient({
    this.intensity = 0.18,
    this.alignment = const Alignment(-0.7, -1.0),
    super.key,
  });

  /// 0–1 peak alpha of the bloom. Kept low so content stays the focus.
  final double intensity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: 1.3,
          colors: <Color>[
            TechColors.accentBright
                .withValues(alpha: isDark ? intensity : intensity * 0.6),
            const Color(0x00000000),
          ],
          stops: const <double>[0.0, 0.72],
        ),
      ),
    );
  }
}
