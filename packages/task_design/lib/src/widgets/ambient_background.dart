import 'package:flutter/material.dart';
import 'package:task_design/src/theme/app_colors.dart';

/// The signature backdrop: a quiet violet bloom drifting from a top corner over
/// the near-black scaffold. Carries the splash/sign-in atmosphere into every
/// screen so the app feels like one continuous surface.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    this.intensity = 0.16,
    this.alignment = const Alignment(-0.7, -1.0),
    super.key,
  });

  /// 0–1 peak alpha of the bloom. Keep low so content stays the focus.
  final double intensity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: 1.3,
          colors: <Color>[
            AppColors.primary.withValues(alpha: intensity),
            const Color(0x00000000),
          ],
          stops: const <double>[0.0, 0.72],
        ),
      ),
    );
  }
}
