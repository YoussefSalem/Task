import 'package:customer/features/localization/locale_controller.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Globe button that switches the app language from anywhere. Drop it into any
/// `AppBar.actions` or overlay it on a screen.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  /// Display names shown in their own script (autonyms).
  static const Map<String, String> _names = <String, String>{
    'en': 'English',
    'ar': 'العربية',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider).languageCode;

    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).language,
      icon: const Icon(Icons.language_rounded),
      onSelected: (code) => ref
          .read(localeControllerProvider.notifier)
          .setLocale(Locale(code)),
      itemBuilder: (context) => [
        for (final entry in _names.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: entry.key == current
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                const SizedBox(width: 12),
                Text(entry.value),
              ],
            ),
          ),
      ],
    );
  }
}
