import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'tech_theme_mode';

/// The active theme mode. Overridden in `bootstrap` with the persisted value so
/// the first frame already reflects the user's choice.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  /// Cycles dark → light → system, returning to dark. Drives the profile toggle.
  Future<void> cycle() => set(switch (state) {
        ThemeMode.dark => ThemeMode.light,
        ThemeMode.light => ThemeMode.system,
        ThemeMode.system => ThemeMode.dark,
      });
}

/// Reads the persisted theme mode ahead of `runApp`. Defaults to dark.
Future<ThemeMode> loadPersistedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kThemeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.dark,
    );
  } catch (_) {
    return ThemeMode.dark;
  }
}
