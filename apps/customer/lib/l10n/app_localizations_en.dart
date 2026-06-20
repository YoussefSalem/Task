// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'On-demand home services';

  @override
  String get getStarted => 'Get started';

  @override
  String get language => 'Language';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle => 'Enter your phone number to continue.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get continueAction => 'Continue';

  @override
  String get signInComingSoon => 'Phone sign-in arrives with the next update.';
}
