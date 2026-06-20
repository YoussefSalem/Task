import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide locale state. Defaults to English and persists the user's choice
/// across launches, so the language switcher works from anywhere in the app.
class LocaleController extends Notifier<Locale> {
  static const String _prefsKey = 'app_locale';

  /// Locales the app ships with. Order is the fallback order.
  static const List<Locale> supported = <Locale>[Locale('en'), Locale('ar')];

  @override
  Locale build() {
    // Restore asynchronously; English is shown until a saved value loads.
    unawaited(_restore());
    return const Locale('en');
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code != state.languageCode) {
      state = Locale(code);
    }
  }

  /// Switch the active language and persist it.
  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
