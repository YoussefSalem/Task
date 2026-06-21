// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tagline => 'خدمات منزلية عند الطلب';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get language => 'اللغة';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'أدخل رقم هاتفك للمتابعة.';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get continueAction => 'متابعة';

  @override
  String get signInComingSoon =>
      'تسجيل الدخول عبر الهاتف سيتوفر في التحديث القادم.';

  @override
  String get loading => 'جارٍ التحميل…';
}
