// packages/task_design/test/category_visuals_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  test('every category has an icon and a tint', () {
    for (final JobCategory c in JobCategory.values) {
      expect(categoryIcon(c), isA<IconData>());
      expect(categoryTint(c), isA<Color>());
    }
  });

  test('maps specific categories to their icon and tint', () {
    expect(categoryIcon(JobCategory.electrical), Icons.bolt_rounded);
    expect(categoryIcon(JobCategory.satelliteInstallation), Icons.satellite_alt_rounded);
    expect(categoryTint(JobCategory.plumbing), const Color(0xFF38BDF8));
  });
}
