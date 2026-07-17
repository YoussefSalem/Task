import 'package:intl/intl.dart';

/// Formats an EGP whole-pound amount with grouping, e.g. `1,250`. Prices in this
/// system are whole pounds (no minor units on jobs), so no decimals are shown.
String formatEgp(int amount) => NumberFormat.decimalPattern('en').format(amount);

/// `EGP 1,250` — the money label used across cards and totals.
String egpLabel(int amount) => 'EGP ${formatEgp(amount)}';
