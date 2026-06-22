import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Splash screen subtitle under the Task wordmark
  ///
  /// In en, this message translates to:
  /// **'On-demand home services'**
  String get tagline;

  /// Primary call-to-action on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// Tooltip/label for the language switcher
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Sign-in screen heading
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Sign-in screen supporting text
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue.'**
  String get signInSubtitle;

  /// Label for the phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// Primary action on the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Feedback shown when Continue is tapped before auth is wired
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in arrives with the next update.'**
  String get signInComingSoon;

  /// Status label shown under the splash progress bar while the app prepares
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Bottom nav item
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Bottom nav item
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// Bottom nav item
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Bottom nav item
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Section header on home screen
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// Action link on service sections
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get browseAll;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Top-rated near you'**
  String get topRatedNearYou;

  /// Tab/section label for bookings
  ///
  /// In en, this message translates to:
  /// **'Active & upcoming'**
  String get activeAndUpcoming;

  /// Tab/section label for past bookings
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistory;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// Floating button label
  ///
  /// In en, this message translates to:
  /// **'Ask the AI assistant'**
  String get askTheAiAssistant;

  /// Action button or tab
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Action button
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Add photos or video'**
  String get addPhotosOrVideo;

  /// Form validation message
  ///
  /// In en, this message translates to:
  /// **'Add a short description and a price above 0.'**
  String get addAShortDescription;

  /// Button to dismiss or cancel an action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button to save changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button to delete an item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button to edit an item
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Navigation button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Navigation button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Form submission button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Button to close dialog or modal
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Search input placeholder or button
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Button in error state
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Screen title or menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Settings action
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Service category
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get plumbing;

  /// Service category
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get electrical;

  /// Service category
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// Service category
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get carpentry;

  /// Service category
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get painting;

  /// Service category (Air Conditioning)
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get ac;

  /// Label for price field
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Label for location field
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Button or prompt
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get selectLocation;

  /// Button or prompt
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Button or prompt
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// Screen title or section
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// Payment option
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// Payment option
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Price summary label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Price summary label
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Label for rating/review
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Label for leaving a review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// Prompt to leave a rating
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// Prompt to write a review
  ///
  /// In en, this message translates to:
  /// **'Share your feedback'**
  String get shareYourFeedback;

  /// Error message header
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message header
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning message header
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
