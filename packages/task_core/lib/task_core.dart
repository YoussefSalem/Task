/// Task core — framework-agnostic primitives shared by every layer and app.
///
/// Pure Dart only: no Flutter, no Firebase. Holds the [Result]/[Failure]
/// contract used across domain boundaries and the canonical business-rule
/// constants extracted from the PRD.
library;

export 'src/constants/business_rules.dart';
export 'src/failures/failure.dart';
export 'src/result/result.dart';
