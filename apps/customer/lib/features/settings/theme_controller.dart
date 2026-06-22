import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemePrefKey = 'app_theme_mode';

/// Current [ThemeMode] preference. Override at startup with the persisted
/// value via [loadPersistedThemeMode] + ProviderScope overrides.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Persist [mode] to local storage.
Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kThemePrefKey, mode.index);
}

/// Read the previously saved [ThemeMode], defaulting to [ThemeMode.system].
Future<ThemeMode> loadPersistedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final idx = prefs.getInt(_kThemePrefKey);
  if (idx == null) return ThemeMode.system;
  return ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
}
