import 'package:flutter/material.dart';
import 'package:task_domain/task_domain.dart';

/// Material icon for a job category. UI-only — the pure-Dart domain never holds
/// `IconData`, so this mapping is the single source of category iconography.
IconData categoryIcon(JobCategory category) => switch (category) {
      JobCategory.plumbing => Icons.plumbing_rounded,
      JobCategory.electrical => Icons.bolt_rounded,
      JobCategory.ac => Icons.ac_unit_rounded,
      JobCategory.cleaning => Icons.cleaning_services_rounded,
      JobCategory.carpentry => Icons.handyman_rounded,
      JobCategory.painting => Icons.format_paint_rounded,
      JobCategory.satelliteInstallation => Icons.satellite_alt_rounded,
      JobCategory.smartHome => Icons.home_max_rounded,
    };

/// Accent tint used for a category tile glow.
Color categoryTint(JobCategory category) => switch (category) {
      JobCategory.plumbing => const Color(0xFF38BDF8),
      JobCategory.electrical => const Color(0xFFFBBF24),
      JobCategory.ac => const Color(0xFF22D3EE),
      JobCategory.cleaning => const Color(0xFF34D399),
      JobCategory.carpentry => const Color(0xFFF472B6),
      JobCategory.painting => const Color(0xFFA78BFA),
      JobCategory.satelliteInstallation => const Color(0xFF818CF8),
      JobCategory.smartHome => const Color(0xFF2DD4BF),
    };
