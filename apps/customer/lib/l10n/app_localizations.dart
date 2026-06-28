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

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get cancelBookingPrompt;

  /// No description provided for @cancelReasonFoundAnother.
  ///
  /// In en, this message translates to:
  /// **'Found another technician'**
  String get cancelReasonFoundAnother;

  /// No description provided for @cancelReasonNoLongerNeeded.
  ///
  /// In en, this message translates to:
  /// **'No longer needed'**
  String get cancelReasonNoLongerNeeded;

  /// No description provided for @cancelReasonPriceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Price too high'**
  String get cancelReasonPriceTooHigh;

  /// No description provided for @cancelReasonTakingTooLong.
  ///
  /// In en, this message translates to:
  /// **'Taking too long'**
  String get cancelReasonTakingTooLong;

  /// No description provided for @cancelReasonPostedByMistake.
  ///
  /// In en, this message translates to:
  /// **'Posted by mistake'**
  String get cancelReasonPostedByMistake;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @cancelNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get cancelNoteHint;

  /// No description provided for @cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelConfirm;

  /// No description provided for @keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get keepBooking;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @selectACancelReason.
  ///
  /// In en, this message translates to:
  /// **'Please choose a reason'**
  String get selectACancelReason;

  /// No description provided for @cancelledReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String cancelledReasonLabel(String reason);

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get nameUpdated;

  /// No description provided for @birthdayUpdated.
  ///
  /// In en, this message translates to:
  /// **'Birthday updated'**
  String get birthdayUpdated;

  /// No description provided for @birthdayPermanentWarning.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth can\'t be changed after this — please make sure it\'s correct.'**
  String get birthdayPermanentWarning;

  /// No description provided for @birthdayCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Date of birth can\'t be changed'**
  String get birthdayCannotBeChanged;

  /// No description provided for @confirmBirthdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your date of birth'**
  String get confirmBirthdayTitle;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get addPhoneNumber;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @phoneNumberVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get phoneNumberVerified;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get verifyYourPhone;

  /// No description provided for @confirmPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text a 6-digit code to confirm it\'s your number.'**
  String get confirmPhoneHint;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @couldNotVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify your phone. Please try again.'**
  String get couldNotVerifyPhone;

  /// No description provided for @phoneNumberInUse.
  ///
  /// In en, this message translates to:
  /// **'That number is already linked to another account.'**
  String get phoneNumberInUse;

  /// No description provided for @signInAgainToChangePhone.
  ///
  /// In en, this message translates to:
  /// **'For security, sign in again before changing your phone number.'**
  String get signInAgainToChangePhone;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'On-demand home services'**
  String get tagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue.'**
  String get signInSubtitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @signInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in arrives with the next update.'**
  String get signInComingSoon;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @browseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get browseAll;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @topRatedNearYou.
  ///
  /// In en, this message translates to:
  /// **'Top-rated near you'**
  String get topRatedNearYou;

  /// No description provided for @activeAndUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Active & upcoming'**
  String get activeAndUpcoming;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistory;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// No description provided for @askTheAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI assistant'**
  String get askTheAiAssistant;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @addPhotosOrVideo.
  ///
  /// In en, this message translates to:
  /// **'Add photos or video'**
  String get addPhotosOrVideo;

  /// No description provided for @addAShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a short description and a price above 0.'**
  String get addAShortDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @plumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get plumbing;

  /// No description provided for @electrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get electrical;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// No description provided for @carpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get carpentry;

  /// No description provided for @painting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get painting;

  /// No description provided for @ac.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get ac;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get selectLocation;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// No description provided for @shareYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share your feedback'**
  String get shareYourFeedback;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String error(Object e);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @acTechnician.
  ///
  /// In en, this message translates to:
  /// **'AC Technician'**
  String get acTechnician;

  /// No description provided for @acDeepClean.
  ///
  /// In en, this message translates to:
  /// **'AC Deep Clean'**
  String get acDeepClean;

  /// No description provided for @acNotCooling.
  ///
  /// In en, this message translates to:
  /// **'AC not cooling'**
  String get acNotCooling;

  /// No description provided for @acServiceAndGasRefill.
  ///
  /// In en, this message translates to:
  /// **'AC service & gas refill'**
  String get acServiceAndGasRefill;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'AI · always on'**
  String get aiAlwaysOn;

  /// No description provided for @addANewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a new address'**
  String get addANewAddress;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addANote;

  /// No description provided for @addingAddressesArrivesSoon.
  ///
  /// In en, this message translates to:
  /// **'Adding addresses arrives soon.'**
  String get addingAddressesArrivesSoon;

  /// No description provided for @allSet.
  ///
  /// In en, this message translates to:
  /// **'All set! 🎉'**
  String get allSet;

  /// No description provided for @arrives.
  ///
  /// In en, this message translates to:
  /// **'Arrives'**
  String get arrives;

  /// No description provided for @authorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get authorization;

  /// No description provided for @authorizeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Authorize {remaining} EGP'**
  String authorizeRemaining(Object remaining);

  /// No description provided for @availableThisEvening.
  ///
  /// In en, this message translates to:
  /// **'Available this evening'**
  String get availableThisEvening;

  /// No description provided for @avgArrival.
  ///
  /// In en, this message translates to:
  /// **'Avg arrival'**
  String get avgArrival;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg rating'**
  String get avgRating;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @bestPrice.
  ///
  /// In en, this message translates to:
  /// **'Best price'**
  String get bestPrice;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @bookFullAcService.
  ///
  /// In en, this message translates to:
  /// **'Book a full AC service before the heat hits - verified pros, same-day slots.'**
  String get bookFullAcService;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Cancel search'**
  String get cancelSearch;

  /// No description provided for @carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get carpenter;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @chatOrCallTechnician.
  ///
  /// In en, this message translates to:
  /// **'Chat or call a technician before hiring. All payments go through the app.'**
  String get chatOrCallTechnician;

  /// No description provided for @choosePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get choosePhotos;

  /// No description provided for @cleaner.
  ///
  /// In en, this message translates to:
  /// **'Cleaner'**
  String get cleaner;

  /// No description provided for @collectingSealed.
  ///
  /// In en, this message translates to:
  /// **'Collecting sealed offers…'**
  String get collectingSealed;

  /// No description provided for @compareOffers.
  ///
  /// In en, this message translates to:
  /// **'Compare offers'**
  String get compareOffers;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @confirmCreditOnly.
  ///
  /// In en, this message translates to:
  /// **'Confirm — credit only'**
  String get confirmCreditOnly;

  /// No description provided for @confirmedPreparingToHeadOut.
  ///
  /// In en, this message translates to:
  /// **'Confirmed — preparing to head out'**
  String get confirmedPreparingToHeadOut;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed — preparing to head out'**
  String get confirmed;

  /// No description provided for @constructionAndFinishing.
  ///
  /// In en, this message translates to:
  /// **'Construction & Finishing'**
  String get constructionAndFinishing;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @couldNotAccessMedia.
  ///
  /// In en, this message translates to:
  /// **'Could not access media.'**
  String get couldNotAccessMedia;

  /// No description provided for @couldNotDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not detect location. Check browser permissions.'**
  String get couldNotDetectLocation;

  /// No description provided for @couldNotPublishJob.
  ///
  /// In en, this message translates to:
  /// **'Could not publish the job. Check your connection and try again.'**
  String get couldNotPublishJob;

  /// No description provided for @couldNotResendCode.
  ///
  /// In en, this message translates to:
  /// **'Could not resend the code.'**
  String get couldNotResendCode;

  /// No description provided for @couldNotSendCode.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code.'**
  String get couldNotSendCode;

  /// No description provided for @couldYouTellMeMore.
  ///
  /// In en, this message translates to:
  /// **'Could you tell me a bit more about the problem?'**
  String get couldYouTellMeMore;

  /// No description provided for @customLocation.
  ///
  /// In en, this message translates to:
  /// **'Custom location'**
  String get customLocation;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @demoModeEnterSixDigits.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — enter any 6 digits.'**
  String get demoModeEnterSixDigits;

  /// No description provided for @describeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get describeProblem;

  /// No description provided for @describeYourProblemToAi.
  ///
  /// In en, this message translates to:
  /// **'Describe your problem to the AI assistant and set your price'**
  String get describeYourProblemToAi;

  /// No description provided for @describeYourProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe your problem...'**
  String get describeYourProblem;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @doorsWindowsAndGlass.
  ///
  /// In en, this message translates to:
  /// **'Doors, Windows & Glass'**
  String get doorsWindowsAndGlass;

  /// No description provided for @eg.
  ///
  /// In en, this message translates to:
  /// **'EG'**
  String get eg;

  /// No description provided for @egpFixedPrice.
  ///
  /// In en, this message translates to:
  /// **'EGP {fixedPrice}\n\nShall I post this for technicians to review?'**
  String egpFixedPrice(Object fixedPrice);

  /// No description provided for @egp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egp;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'EXPERT'**
  String get expert;

  /// No description provided for @electricalExpert.
  ///
  /// In en, this message translates to:
  /// **'Electrical Expert'**
  String get electricalExpert;

  /// No description provided for @electricalFault.
  ///
  /// In en, this message translates to:
  /// **'Electrical fault'**
  String get electricalFault;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get electrician;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emulatorOffline.
  ///
  /// In en, this message translates to:
  /// **'Emulator offline — using demo code (any 6 digits).'**
  String get emulatorOffline;

  /// No description provided for @enRoute.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get enRoute;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get endCall;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get enterValidPhoneNumber;

  /// No description provided for @enterFullCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the full code.'**
  String get enterFullCode;

  /// No description provided for @enterYourPriceInEgp.
  ///
  /// In en, this message translates to:
  /// **'Enter your price in EGP…'**
  String get enterYourPriceInEgp;

  /// No description provided for @fairPrice.
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get fairPrice;

  /// No description provided for @fastArrival.
  ///
  /// In en, this message translates to:
  /// **'Fast arrival'**
  String get fastArrival;

  /// No description provided for @findingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address...'**
  String get findingAddress;

  /// No description provided for @findingNearbyProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby professionals…'**
  String get findingNearbyProfessionals;

  /// No description provided for @findingYourPro.
  ///
  /// In en, this message translates to:
  /// **'Finding your pro'**
  String get findingYourPro;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @friendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get friendly;

  /// No description provided for @from120Egp.
  ///
  /// In en, this message translates to:
  /// **'From 120 EGP'**
  String get from120Egp;

  /// No description provided for @from150Egp.
  ///
  /// In en, this message translates to:
  /// **'From 150 EGP'**
  String get from150Egp;

  /// No description provided for @from250Egp.
  ///
  /// In en, this message translates to:
  /// **'From 250 EGP'**
  String get from250Egp;

  /// No description provided for @from400Egp.
  ///
  /// In en, this message translates to:
  /// **'From 400 EGP'**
  String get from400Egp;

  /// No description provided for @from600Egp.
  ///
  /// In en, this message translates to:
  /// **'From 600 EGP'**
  String get from600Egp;

  /// No description provided for @newCodeOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get newCodeOnTheWay;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get maintenanceMode;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @aboutTheService.
  ///
  /// In en, this message translates to:
  /// **'About the service'**
  String get aboutTheService;

  /// No description provided for @durationAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Duration & price'**
  String get durationAndPrice;

  /// No description provided for @selectQuantity.
  ///
  /// In en, this message translates to:
  /// **'Select quantity'**
  String get selectQuantity;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed'**
  String get orderConfirmed;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewed;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRange;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeAReview;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get twoFactorAuth;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get connectedAccounts;

  /// No description provided for @blockList.
  ///
  /// In en, this message translates to:
  /// **'Block list'**
  String get blockList;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataAndPrivacy;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get languageAndRegion;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZone;

  /// No description provided for @welcomeToTask.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Task'**
  String get welcomeToTask;

  /// No description provided for @egyptOnDemandServices.
  ///
  /// In en, this message translates to:
  /// **'Egypt\'s on-demand home services — describe it, set your price, done.'**
  String get egyptOnDemandServices;

  /// No description provided for @verifiedPros.
  ///
  /// In en, this message translates to:
  /// **'Verified pros'**
  String get verifiedPros;

  /// No description provided for @youSetThePrice.
  ///
  /// In en, this message translates to:
  /// **'You set the price'**
  String get youSetThePrice;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service • Privacy Policy'**
  String get termsAndPrivacy;

  /// No description provided for @yourBookings.
  ///
  /// In en, this message translates to:
  /// **'Your bookings'**
  String get yourBookings;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @whenTechniciansRespond.
  ///
  /// In en, this message translates to:
  /// **'When technicians respond to your requests, conversations appear here'**
  String get whenTechniciansRespond;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpAndSupport;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacyAndSecurity;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @taskCredit.
  ///
  /// In en, this message translates to:
  /// **'Task credit'**
  String get taskCredit;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @cashCard.
  ///
  /// In en, this message translates to:
  /// **'Cash, Card'**
  String get cashCard;

  /// No description provided for @leakingKitchenSink.
  ///
  /// In en, this message translates to:
  /// **'Leaking kitchen sink'**
  String get leakingKitchenSink;

  /// No description provided for @plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get plumber;

  /// No description provided for @biddingActive.
  ///
  /// In en, this message translates to:
  /// **'biddingActive'**
  String get biddingActive;

  /// No description provided for @acMaintenance.
  ///
  /// In en, this message translates to:
  /// **'AC Maintenance'**
  String get acMaintenance;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'inProgress'**
  String get inProgress;

  /// No description provided for @replaceTrippingBreaker.
  ///
  /// In en, this message translates to:
  /// **'Replace tripping breaker'**
  String get replaceTrippingBreaker;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @serviceAt.
  ///
  /// In en, this message translates to:
  /// **'Service at'**
  String get serviceAt;

  /// No description provided for @electricianArrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Electrician arriving in {minutes} min'**
  String electricianArrivingIn(Object minutes);

  /// No description provided for @whatNeedsFixing.
  ///
  /// In en, this message translates to:
  /// **'What needs fixing?'**
  String get whatNeedsFixing;

  /// No description provided for @describeItInYourWords.
  ///
  /// In en, this message translates to:
  /// **'Describe it in your words — I\'ll line up the right pro. You decide the price.'**
  String get describeItInYourWords;

  /// No description provided for @kitchenSinkIsBlocked.
  ///
  /// In en, this message translates to:
  /// **'...Kitchen sink is blocked'**
  String get kitchenSinkIsBlocked;

  /// No description provided for @ramadanDeepClean.
  ///
  /// In en, this message translates to:
  /// **'Ramadan Deep Clean'**
  String get ramadanDeepClean;

  /// No description provided for @professionalWholeHomeCleaning.
  ///
  /// In en, this message translates to:
  /// **'Professional whole-home cleaning packages - book now, pay after'**
  String get professionalWholeHomeCleaning;

  /// No description provided for @popularInYourArea.
  ///
  /// In en, this message translates to:
  /// **'Popular in your area'**
  String get popularInYourArea;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @helloUsername.
  ///
  /// In en, this message translates to:
  /// **'Hello, {username}'**
  String helloUsername(Object username);

  /// No description provided for @arrrivingIn.
  ///
  /// In en, this message translates to:
  /// **'{category} arriving in {minutes} min'**
  String arrrivingIn(Object category, Object minutes);

  /// No description provided for @technicianOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'{category} pro is on the way'**
  String technicianOnTheWay(String category);

  /// No description provided for @isWorking.
  ///
  /// In en, this message translates to:
  /// **'{category} is working'**
  String isWorking(Object category);

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get waitingForApproval;

  /// No description provided for @jobActive.
  ///
  /// In en, this message translates to:
  /// **'Job active'**
  String get jobActive;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @describeTheProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get describeTheProblem;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @enterYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter your price in EGP…'**
  String get enterYourPrice;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for booking with Task!'**
  String get thankYou;

  /// No description provided for @viewYourBooking.
  ///
  /// In en, this message translates to:
  /// **'View your booking'**
  String get viewYourBooking;

  /// No description provided for @bookingNumber.
  ///
  /// In en, this message translates to:
  /// **'Booking number'**
  String get bookingNumber;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @pleaseAddYourName.
  ///
  /// In en, this message translates to:
  /// **'Please add your name to continue'**
  String get pleaseAddYourName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to your phone'**
  String get enterOtp;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @codeExpires.
  ///
  /// In en, this message translates to:
  /// **'Code expires in'**
  String get codeExpires;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash on arrival'**
  String get cashPayment;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Pay with card'**
  String get cardPayment;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get confirmPayment;

  /// No description provided for @enterCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your card details'**
  String get enterCardDetails;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @estimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get estimatedPrice;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postAJob;

  /// No description provided for @masonAndDecorationStones.
  ///
  /// In en, this message translates to:
  /// **'Mason & Decoration Stones'**
  String get masonAndDecorationStones;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @yourBudget.
  ///
  /// In en, this message translates to:
  /// **'Your budget'**
  String get yourBudget;

  /// No description provided for @resize.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get resize;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn 50 EGP'**
  String get referAndEarn;

  /// No description provided for @shareYourCode.
  ///
  /// In en, this message translates to:
  /// **'Share your code with friends - you both get 50 EGP credit on your next booking'**
  String get shareYourCode;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newTag;

  /// No description provided for @leakRepair.
  ///
  /// In en, this message translates to:
  /// **'Leak Repair'**
  String get leakRepair;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'booked'**
  String get booked;

  /// No description provided for @myAcIsLeakingWater.
  ///
  /// In en, this message translates to:
  /// **'...My AC is leaking water'**
  String get myAcIsLeakingWater;

  /// No description provided for @offersReceived.
  ///
  /// In en, this message translates to:
  /// **'Offers received'**
  String get offersReceived;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @serviceAddress.
  ///
  /// In en, this message translates to:
  /// **'Service address'**
  String get serviceAddress;

  /// No description provided for @pleaseSelectYourBirthday.
  ///
  /// In en, this message translates to:
  /// **'Please select your birthday.'**
  String get pleaseSelectYourBirthday;

  /// No description provided for @badgePro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get badgePro;

  /// No description provided for @badgeExpert.
  ///
  /// In en, this message translates to:
  /// **'EXPERT'**
  String get badgeExpert;

  /// No description provided for @badgePlatinum.
  ///
  /// In en, this message translates to:
  /// **'PLATINUM'**
  String get badgePlatinum;

  /// No description provided for @tierBronze.
  ///
  /// In en, this message translates to:
  /// **'BRONZE'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In en, this message translates to:
  /// **'SILVER'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In en, this message translates to:
  /// **'GOLD'**
  String get tierGold;

  /// No description provided for @tierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'PLATINUM'**
  String get tierPlatinum;

  /// No description provided for @techNameMohamed.
  ///
  /// In en, this message translates to:
  /// **'Mohamed Ali'**
  String get techNameMohamed;

  /// No description provided for @techNameSara.
  ///
  /// In en, this message translates to:
  /// **'Sara Hassan'**
  String get techNameSara;

  /// No description provided for @techNameKarim.
  ///
  /// In en, this message translates to:
  /// **'Karim Fouad'**
  String get techNameKarim;

  /// No description provided for @specialtyPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing Specialist'**
  String get specialtyPlumbing;

  /// No description provided for @specialtyElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical Expert'**
  String get specialtyElectrical;

  /// No description provided for @specialtyAc.
  ///
  /// In en, this message translates to:
  /// **'AC Technician'**
  String get specialtyAc;

  /// No description provided for @jobsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}+ Jobs'**
  String jobsCountLabel(Object count);

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payCard;

  /// No description provided for @payWallet.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get payWallet;

  /// No description provided for @payInstapay.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get payInstapay;

  /// No description provided for @payCardSub.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, Meeza · via Paymob'**
  String get payCardSub;

  /// No description provided for @payWalletSub.
  ///
  /// In en, this message translates to:
  /// **'Pay from your mobile wallet'**
  String get payWalletSub;

  /// No description provided for @payInstapaySub.
  ///
  /// In en, this message translates to:
  /// **'Instant bank transfer · confirmed by team'**
  String get payInstapaySub;

  /// No description provided for @addrHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addrHome;

  /// No description provided for @addrWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addrWork;

  /// No description provided for @addrHomeLine.
  ///
  /// In en, this message translates to:
  /// **'14 Road 9, Maadi · Floor 3, Apt 6'**
  String get addrHomeLine;

  /// No description provided for @addrWorkLine.
  ///
  /// In en, this message translates to:
  /// **'Smart Village, Building B12 · Reception'**
  String get addrWorkLine;

  /// No description provided for @stageSearching.
  ///
  /// In en, this message translates to:
  /// **'Finding your pro'**
  String get stageSearching;

  /// No description provided for @stageAccepted.
  ///
  /// In en, this message translates to:
  /// **'Pro assigned'**
  String get stageAccepted;

  /// No description provided for @stageEnRoute.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get stageEnRoute;

  /// No description provided for @stageInProgress.
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get stageInProgress;

  /// No description provided for @stageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Job complete'**
  String get stageCompleted;

  /// No description provided for @locDefaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Maadi, Cairo'**
  String get locDefaultAddress;

  /// No description provided for @locPinDrop.
  ///
  /// In en, this message translates to:
  /// **'Pin drop'**
  String get locPinDrop;

  /// No description provided for @locCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom location'**
  String get locCustom;

  /// No description provided for @locNasrCity.
  ///
  /// In en, this message translates to:
  /// **'Nasr City, Cairo'**
  String get locNasrCity;

  /// No description provided for @locSheikhZayed.
  ///
  /// In en, this message translates to:
  /// **'Sheikh Zayed, Giza'**
  String get locSheikhZayed;

  /// No description provided for @techNameKhaled.
  ///
  /// In en, this message translates to:
  /// **'Khaled Mansour'**
  String get techNameKhaled;

  /// No description provided for @techNameSayed.
  ///
  /// In en, this message translates to:
  /// **'Sayed Abdel-Rahman'**
  String get techNameSayed;

  /// No description provided for @techNameMostafa.
  ///
  /// In en, this message translates to:
  /// **'Mostafa Eid'**
  String get techNameMostafa;

  /// No description provided for @etaCanStart40.
  ///
  /// In en, this message translates to:
  /// **'Can start in 40 min'**
  String get etaCanStart40;

  /// No description provided for @etaThisEvening.
  ///
  /// In en, this message translates to:
  /// **'Available this evening'**
  String get etaThisEvening;

  /// No description provided for @etaCanStart25.
  ///
  /// In en, this message translates to:
  /// **'Can start in 25 min'**
  String get etaCanStart25;

  /// No description provided for @jobSeed1Title.
  ///
  /// In en, this message translates to:
  /// **'Leaking kitchen sink'**
  String get jobSeed1Title;

  /// No description provided for @jobSeed1Desc.
  ///
  /// In en, this message translates to:
  /// **'Steady drip under the sink, water pooling in the cabinet.'**
  String get jobSeed1Desc;

  /// No description provided for @jobSeed2Title.
  ///
  /// In en, this message translates to:
  /// **'AC not cooling'**
  String get jobSeed2Title;

  /// No description provided for @jobSeed2Desc.
  ///
  /// In en, this message translates to:
  /// **'Split unit runs but blows warm air.'**
  String get jobSeed2Desc;

  /// No description provided for @jobSeed3Title.
  ///
  /// In en, this message translates to:
  /// **'Replace tripping breaker'**
  String get jobSeed3Title;

  /// No description provided for @jobSeed3Desc.
  ///
  /// In en, this message translates to:
  /// **'Main breaker trips when the heater runs.'**
  String get jobSeed3Desc;

  /// No description provided for @catPainter.
  ///
  /// In en, this message translates to:
  /// **'Painter'**
  String get catPainter;

  /// No description provided for @catSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get catSatellite;

  /// No description provided for @catSmartHome.
  ///
  /// In en, this message translates to:
  /// **'Smart Home'**
  String get catSmartHome;

  /// No description provided for @catTilesHandyman.
  ///
  /// In en, this message translates to:
  /// **'Tiles Handyman'**
  String get catTilesHandyman;

  /// No description provided for @catPlaster.
  ///
  /// In en, this message translates to:
  /// **'Plaster'**
  String get catPlaster;

  /// No description provided for @catSmith.
  ///
  /// In en, this message translates to:
  /// **'Smith'**
  String get catSmith;

  /// No description provided for @catParquet.
  ///
  /// In en, this message translates to:
  /// **'Parquet'**
  String get catParquet;

  /// No description provided for @catGypsumWorks.
  ///
  /// In en, this message translates to:
  /// **'Gypsum Works'**
  String get catGypsumWorks;

  /// No description provided for @catGypsumBoard.
  ///
  /// In en, this message translates to:
  /// **'Gypsum Board'**
  String get catGypsumBoard;

  /// No description provided for @catMarbleGranite.
  ///
  /// In en, this message translates to:
  /// **'Marble & Granite'**
  String get catMarbleGranite;

  /// No description provided for @catAlumetal.
  ///
  /// In en, this message translates to:
  /// **'Alumetal'**
  String get catAlumetal;

  /// No description provided for @catGlassCecurit.
  ///
  /// In en, this message translates to:
  /// **'Glass & Cecurit'**
  String get catGlassCecurit;

  /// No description provided for @catCurtainsUpholstery.
  ///
  /// In en, this message translates to:
  /// **'Curtains & Upholstery'**
  String get catCurtainsUpholstery;

  /// No description provided for @catWoodPainter.
  ///
  /// In en, this message translates to:
  /// **'Wood Painter'**
  String get catWoodPainter;

  /// No description provided for @catMovingServices.
  ///
  /// In en, this message translates to:
  /// **'Moving Services'**
  String get catMovingServices;

  /// No description provided for @catPuCornices.
  ///
  /// In en, this message translates to:
  /// **'PU Cornices'**
  String get catPuCornices;

  /// No description provided for @catMaterialWinch.
  ///
  /// In en, this message translates to:
  /// **'Material Winch'**
  String get catMaterialWinch;

  /// No description provided for @catAppliancesMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Appliances Maintenance'**
  String get catAppliancesMaintenance;

  /// No description provided for @catSwimmingPool.
  ///
  /// In en, this message translates to:
  /// **'Swimming Pool Maintenance'**
  String get catSwimmingPool;

  /// No description provided for @catPestControl.
  ///
  /// In en, this message translates to:
  /// **'Pest Control'**
  String get catPestControl;

  /// No description provided for @statusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get statusSearching;

  /// No description provided for @statusPendingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusPendingScheduled;

  /// No description provided for @statusBiddingActive.
  ///
  /// In en, this message translates to:
  /// **'Receiving offers'**
  String get statusBiddingActive;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusEnRoute.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusEnRoute;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusPausedForApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get statusPausedForApproval;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get statusDisputed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @demoUserName.
  ///
  /// In en, this message translates to:
  /// **'Ahmed'**
  String get demoUserName;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @powerKeepsTripping.
  ///
  /// In en, this message translates to:
  /// **'Power keeps tripping…'**
  String get powerKeepsTripping;

  /// No description provided for @needDeepCleanWeekend.
  ///
  /// In en, this message translates to:
  /// **'Need a deep clean this weekend…'**
  String get needDeepCleanWeekend;

  /// No description provided for @summerAcCheckup.
  ///
  /// In en, this message translates to:
  /// **'Summer AC Check-up'**
  String get summerAcCheckup;

  /// No description provided for @badgeLimited.
  ///
  /// In en, this message translates to:
  /// **'LIMITED'**
  String get badgeLimited;

  /// No description provided for @outletInstall.
  ///
  /// In en, this message translates to:
  /// **'Outlet Install'**
  String get outletInstall;

  /// No description provided for @fullHomeClean.
  ///
  /// In en, this message translates to:
  /// **'Full Home Clean'**
  String get fullHomeClean;

  /// No description provided for @roomRepaint.
  ///
  /// In en, this message translates to:
  /// **'Room Repaint'**
  String get roomRepaint;

  /// No description provided for @egpPerHour.
  ///
  /// In en, this message translates to:
  /// **'EGP/hr'**
  String get egpPerHour;

  /// No description provided for @searchingForPros.
  ///
  /// In en, this message translates to:
  /// **'Searching for pros…'**
  String get searchingForPros;

  /// No description provided for @tapToReviewHire.
  ///
  /// In en, this message translates to:
  /// **'Tap to review and hire a technician'**
  String get tapToReviewHire;

  /// No description provided for @tapToViewProgress.
  ///
  /// In en, this message translates to:
  /// **'Tap to view live search progress'**
  String get tapToViewProgress;

  /// No description provided for @stepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get stepConfirmed;

  /// No description provided for @stepWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get stepWorking;

  /// No description provided for @searchingWithin3km.
  ///
  /// In en, this message translates to:
  /// **'Searching within 3 km…'**
  String get searchingWithin3km;

  /// No description provided for @wideningTo6km.
  ///
  /// In en, this message translates to:
  /// **'Widening to 6 km…'**
  String get wideningTo6km;

  /// No description provided for @reachingNearbyPros.
  ///
  /// In en, this message translates to:
  /// **'Reaching nearby pros…'**
  String get reachingNearbyPros;

  /// No description provided for @yourJob.
  ///
  /// In en, this message translates to:
  /// **'your job'**
  String get yourJob;

  /// No description provided for @proAssignedExcl.
  ///
  /// In en, this message translates to:
  /// **'Pro assigned!'**
  String get proAssignedExcl;

  /// No description provided for @proHeadingToYou.
  ///
  /// In en, this message translates to:
  /// **'Khaled is 1.8 km away and heading to you.'**
  String get proHeadingToYou;

  /// No description provided for @trackYourPro.
  ///
  /// In en, this message translates to:
  /// **'Track your pro'**
  String get trackYourPro;

  /// No description provided for @proKhaledInitials.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get proKhaledInitials;

  /// No description provided for @jobsWord.
  ///
  /// In en, this message translates to:
  /// **'jobs'**
  String get jobsWord;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @hireAndTrack.
  ///
  /// In en, this message translates to:
  /// **'Hire & track'**
  String get hireAndTrack;

  /// No description provided for @upToFiveProsBid.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 pros bid privately for your {job}. No one sees the others\' price.'**
  String upToFiveProsBid(Object job);

  /// No description provided for @jobWord.
  ///
  /// In en, this message translates to:
  /// **'job'**
  String get jobWord;

  /// No description provided for @offersReceivedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} offers received'**
  String offersReceivedCount(Object count);

  /// No description provided for @sealed.
  ///
  /// In en, this message translates to:
  /// **'Sealed'**
  String get sealed;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @prosFoundNearby.
  ///
  /// In en, this message translates to:
  /// **'{count} pros found nearby'**
  String prosFoundNearby(Object count);

  /// No description provided for @waitingForOffers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for offers…'**
  String get waitingForOffers;

  /// No description provided for @scanningYourArea.
  ///
  /// In en, this message translates to:
  /// **'Scanning your area — usually under a minute'**
  String get scanningYourArea;

  /// No description provided for @sendingJobDetails.
  ///
  /// In en, this message translates to:
  /// **'Sending your job details to them now'**
  String get sendingJobDetails;

  /// No description provided for @prosReviewing.
  ///
  /// In en, this message translates to:
  /// **'Pros are reviewing your request'**
  String get prosReviewing;

  /// No description provided for @openingYourOffers.
  ///
  /// In en, this message translates to:
  /// **'Opening your offers…'**
  String get openingYourOffers;

  /// No description provided for @stopSearchQ.
  ///
  /// In en, this message translates to:
  /// **'Stop search?'**
  String get stopSearchQ;

  /// No description provided for @stopSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Your request stays active and technicians can still send offers.\n\nYou\'ll get a notification when offers arrive. To fully stop, cancel the request.'**
  String get stopSearchBody;

  /// No description provided for @liveSearch.
  ///
  /// In en, this message translates to:
  /// **'Live search'**
  String get liveSearch;

  /// No description provided for @youCanExitNote.
  ///
  /// In en, this message translates to:
  /// **'You can exit — your request stays active. We\'ll notify you when offers arrive.'**
  String get youCanExitNote;

  /// No description provided for @stopSearch.
  ///
  /// In en, this message translates to:
  /// **'Stop search'**
  String get stopSearch;

  /// No description provided for @viewOffersCount.
  ///
  /// In en, this message translates to:
  /// **'View {count} offers'**
  String viewOffersCount(Object count);

  /// No description provided for @phaseSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get phaseSearching;

  /// No description provided for @phaseFound.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get phaseFound;

  /// No description provided for @phaseWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get phaseWaiting;

  /// No description provided for @phaseOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get phaseOffers;

  /// No description provided for @offersCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count} offers'**
  String offersCountShort(Object count);

  /// No description provided for @jobsDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs done'**
  String jobsDoneCount(Object count);

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @selectOffer.
  ///
  /// In en, this message translates to:
  /// **'Select offer'**
  String get selectOffer;

  /// No description provided for @inAppVoipCall.
  ///
  /// In en, this message translates to:
  /// **'In-app VoIP call'**
  String get inAppVoipCall;

  /// No description provided for @startCall.
  ///
  /// In en, this message translates to:
  /// **'Start call'**
  String get startCall;

  /// No description provided for @goBackToOffers.
  ///
  /// In en, this message translates to:
  /// **'Go back to offers'**
  String get goBackToOffers;

  /// No description provided for @bookingConfirmedSub.
  ///
  /// In en, this message translates to:
  /// **'We\'ve locked in your pro. You\'ll get a reminder before they arrive.'**
  String get bookingConfirmedSub;

  /// No description provided for @payAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Pay & finish'**
  String get payAndFinish;

  /// No description provided for @reviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'Review & pay'**
  String get reviewAndPay;

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get serviceLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @jobTotal.
  ///
  /// In en, this message translates to:
  /// **'Job total'**
  String get jobTotal;

  /// No description provided for @taskCreditApplied.
  ///
  /// In en, this message translates to:
  /// **'Task credit applied'**
  String get taskCreditApplied;

  /// No description provided for @youPay.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get youPay;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @taskCreditCovers.
  ///
  /// In en, this message translates to:
  /// **'Your Task credit fully covers this order — no additional payment needed.'**
  String get taskCreditCovers;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} EGP'**
  String payAmount(Object amount);

  /// No description provided for @taskCreditAppliedAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} EGP Task credit applied'**
  String taskCreditAppliedAmount(Object amount);

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendAction;

  /// No description provided for @featureArrivesWithPayments.
  ///
  /// In en, this message translates to:
  /// **'{feature} arrives with payments.'**
  String featureArrivesWithPayments(Object feature);

  /// No description provided for @walletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Wallet top-up'**
  String get walletTopUp;

  /// No description provided for @walletEmptyLedger.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletEmptyLedger;

  /// No description provided for @walletEmptyLedgerHint.
  ///
  /// In en, this message translates to:
  /// **'Credits and refunds will appear here.'**
  String get walletEmptyLedgerHint;

  /// No description provided for @walletLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your wallet'**
  String get walletLoadError;

  /// No description provided for @referralCredit.
  ///
  /// In en, this message translates to:
  /// **'Referral credit'**
  String get referralCredit;

  /// No description provided for @txnToday240.
  ///
  /// In en, this message translates to:
  /// **'Today · 2:40 PM'**
  String get txnToday240;

  /// No description provided for @txnYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get txnYesterday;

  /// No description provided for @txnMar18.
  ///
  /// In en, this message translates to:
  /// **'Mar 18 · 6:15 PM'**
  String get txnMar18;

  /// No description provided for @txnMar15.
  ///
  /// In en, this message translates to:
  /// **'Mar 15'**
  String get txnMar15;

  /// No description provided for @tagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get tagOnTime;

  /// No description provided for @tagTidyWork.
  ///
  /// In en, this message translates to:
  /// **'Tidy work'**
  String get tagTidyWork;

  /// No description provided for @tagSkilled.
  ///
  /// In en, this message translates to:
  /// **'Skilled'**
  String get tagSkilled;

  /// No description provided for @tagGreatCommunication.
  ///
  /// In en, this message translates to:
  /// **'Great communication'**
  String get tagGreatCommunication;

  /// No description provided for @howWasYour.
  ///
  /// In en, this message translates to:
  /// **'How was your {service}?'**
  String howWasYour(Object service);

  /// No description provided for @serviceWord.
  ///
  /// In en, this message translates to:
  /// **'service'**
  String get serviceWord;

  /// No description provided for @withPro.
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String withPro(Object name);

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted!'**
  String get reviewSubmitted;

  /// No description provided for @thanksForRating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for rating {name}.\nYour feedback helps the whole community.'**
  String thanksForRating(Object name);

  /// No description provided for @redirectingIn.
  ///
  /// In en, this message translates to:
  /// **'Redirecting in {seconds} s…'**
  String redirectingIn(Object seconds);

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'ETA {minutes} min'**
  String etaMinutes(Object minutes);

  /// No description provided for @awaitingLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for live location…'**
  String get awaitingLiveLocation;

  /// No description provided for @noActiveJob.
  ///
  /// In en, this message translates to:
  /// **'No active job right now'**
  String get noActiveJob;

  /// No description provided for @homeService.
  ///
  /// In en, this message translates to:
  /// **'Home service'**
  String get homeService;

  /// No description provided for @headingToAddress.
  ///
  /// In en, this message translates to:
  /// **'Heading to your address'**
  String get headingToAddress;

  /// No description provided for @workingOnJob.
  ///
  /// In en, this message translates to:
  /// **'Working on the job'**
  String get workingOnJob;

  /// No description provided for @jobCompleted.
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get jobCompleted;

  /// No description provided for @featureOpensComms.
  ///
  /// In en, this message translates to:
  /// **'{feature} opens in the comms phase.'**
  String featureOpensComms(Object feature);

  /// No description provided for @pinOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pin on map'**
  String get pinOnMap;

  /// No description provided for @specializedServices.
  ///
  /// In en, this message translates to:
  /// **'Specialized Services'**
  String get specializedServices;

  /// No description provided for @maintenanceGroup.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceGroup;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @recordAVideo.
  ///
  /// In en, this message translates to:
  /// **'Record a video'**
  String get recordAVideo;

  /// No description provided for @describeProblemHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living-room lights keep flickering when I turn on the AC...'**
  String get describeProblemHint;

  /// No description provided for @publishJob.
  ///
  /// In en, this message translates to:
  /// **'Publish job'**
  String get publishJob;

  /// No description provided for @chatMsgHello.
  ///
  /// In en, this message translates to:
  /// **'Hello! I reviewed your job. I can arrive within 30 minutes.'**
  String get chatMsgHello;

  /// No description provided for @chatMsgQuote.
  ///
  /// In en, this message translates to:
  /// **'My quote includes all materials. Any specific brand preference?'**
  String get chatMsgQuote;

  /// No description provided for @chatMsgReply.
  ///
  /// In en, this message translates to:
  /// **'Got it! I\'ll bring everything needed. See you soon.'**
  String get chatMsgReply;

  /// No description provided for @chatTime341.
  ///
  /// In en, this message translates to:
  /// **'3:41 PM'**
  String get chatTime341;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get messageHint;

  /// No description provided for @typingIndicator.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get typingIndicator;

  /// No description provided for @seenLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seenLabel;

  /// No description provided for @chatSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in to message technicians.'**
  String get chatSignedOut;

  /// No description provided for @chatLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this conversation. Check your connection.'**
  String get chatLoadError;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start the conversation.'**
  String get chatEmpty;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAll;

  /// No description provided for @notifPostedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request posted'**
  String get notifPostedTitle;

  /// No description provided for @notifPostedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re finding the right technician for your job.'**
  String get notifPostedBody;

  /// No description provided for @notifNewMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String notifNewMessageTitle(String name);

  /// No description provided for @notifHiredTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re hired'**
  String get notifHiredTitle;

  /// No description provided for @notifHiredBody.
  ///
  /// In en, this message translates to:
  /// **'The customer accepted your offer. Head over when ready.'**
  String get notifHiredBody;

  /// No description provided for @customerWord.
  ///
  /// In en, this message translates to:
  /// **'the customer'**
  String get customerWord;

  /// No description provided for @suggestionAcLeaking.
  ///
  /// In en, this message translates to:
  /// **'My AC is leaking water'**
  String get suggestionAcLeaking;

  /// No description provided for @suggestionPowerTripping.
  ///
  /// In en, this message translates to:
  /// **'Power keeps tripping'**
  String get suggestionPowerTripping;

  /// No description provided for @suggestionDeepClean.
  ///
  /// In en, this message translates to:
  /// **'Need a deep clean this weekend'**
  String get suggestionDeepClean;

  /// No description provided for @taskAssistant.
  ///
  /// In en, this message translates to:
  /// **'Task Assistant'**
  String get taskAssistant;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequest;

  /// No description provided for @replyYesToPost.
  ///
  /// In en, this message translates to:
  /// **'Reply yes to post, or no to change…'**
  String get replyYesToPost;

  /// No description provided for @requestPosted.
  ///
  /// In en, this message translates to:
  /// **'Request posted'**
  String get requestPosted;

  /// No description provided for @messageAssistant.
  ///
  /// In en, this message translates to:
  /// **'Message the assistant…'**
  String get messageAssistant;

  /// No description provided for @assistantGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your Task assistant. Tell me what needs fixing and I\'ll write a clear summary for the right pro. You decide the price.'**
  String get assistantGreeting;

  /// No description provided for @assistantAlreadyLive.
  ///
  /// In en, this message translates to:
  /// **'Your request is already live with technicians. Tap \"New request\" below to start another one.'**
  String get assistantAlreadyLive;

  /// No description provided for @assistantPriceAsk.
  ///
  /// In en, this message translates to:
  /// **'Great — I\'ve got everything I need. What would you like to pay for this service, in EGP?'**
  String get assistantPriceAsk;

  /// No description provided for @assistantNoPriceCaught.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t catch a price there. About how much would you like to pay, in EGP? For example \"400\".'**
  String get assistantNoPriceCaught;

  /// No description provided for @assistantSomethingMissing.
  ///
  /// In en, this message translates to:
  /// **'Something\'s missing from the request — let\'s go over it again. What\'s the problem?'**
  String get assistantSomethingMissing;

  /// No description provided for @assistantPosted.
  ///
  /// In en, this message translates to:
  /// **'Done — your request is now live for technicians to review. You\'ll start getting offers shortly.'**
  String get assistantPosted;

  /// No description provided for @assistantWhatToChange.
  ///
  /// In en, this message translates to:
  /// **'No problem. What would you like to change? Tell me a new price, or describe anything about the job you want to adjust.'**
  String get assistantWhatToChange;

  /// No description provided for @assistantJustConfirm.
  ///
  /// In en, this message translates to:
  /// **'Just to confirm — should I post this for technicians? Reply \"yes\" to post, or \"no\" to change something.'**
  String get assistantJustConfirm;

  /// No description provided for @assistantPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Sorry — I couldn\'t post your request just now. Please check your connection and reply \"yes\" to try again.'**
  String get assistantPostFailed;

  /// No description provided for @assistantConfirm.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your request:\n\n• {cat} — {title}\n• You pay: EGP {price}\n\nShall I post this for technicians to review? Reply \"yes\" to post, or \"no\" to change something.'**
  String assistantConfirm(Object cat, Object price, Object title);

  /// No description provided for @assistantMockAskMore.
  ///
  /// In en, this message translates to:
  /// **'Tell me what\'s going wrong — for example a leak, an AC that won\'t cool, or power that keeps tripping — and where in your home it is.'**
  String get assistantMockAskMore;

  /// No description provided for @assistantMockGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it — this looks like a {category} job. I\'ve put together a summary for technicians below. Set the price you want to pay and publish when you are ready.'**
  String assistantMockGotIt(Object category);

  /// No description provided for @assistantError.
  ///
  /// In en, this message translates to:
  /// **'I had trouble reaching the assistant just now — please try sending that again.'**
  String get assistantError;

  /// No description provided for @demoProfileName.
  ///
  /// In en, this message translates to:
  /// **'Nour Adel'**
  String get demoProfileName;

  /// No description provided for @demoProfileInitials.
  ///
  /// In en, this message translates to:
  /// **'NA'**
  String get demoProfileInitials;

  /// No description provided for @featureArrivesLater.
  ///
  /// In en, this message translates to:
  /// **'{feature} arrives in a later phase.'**
  String featureArrivesLater(Object feature);

  /// No description provided for @noPastJobs.
  ///
  /// In en, this message translates to:
  /// **'No past jobs yet'**
  String get noPastJobs;

  /// No description provided for @requestNewCode.
  ///
  /// In en, this message translates to:
  /// **'Request a new code, please.'**
  String get requestNewCode;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'That phone number looks invalid.'**
  String get invalidPhone;

  /// No description provided for @incorrectCode.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect.'**
  String get incorrectCode;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get tooManyAttempts;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get signInCancelled;

  /// No description provided for @genericAuthError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericAuthError;

  /// No description provided for @sentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}.'**
  String sentCodeTo(Object phone);

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendCodeIn(Object time);

  /// No description provided for @verifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyAction;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed.'**
  String get signInFailed;

  /// No description provided for @moreCountriesSoon.
  ///
  /// In en, this message translates to:
  /// **'More countries arrive with international launch.'**
  String get moreCountriesSoon;

  /// No description provided for @privacyOpensLater.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy opens in a later phase.'**
  String get privacyOpensLater;

  /// No description provided for @termsOpensLater.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service opens in a later phase.'**
  String get termsOpensLater;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details so technicians know who they\'re helping.'**
  String get profileSubtitle;

  /// No description provided for @hintFirstName.
  ///
  /// In en, this message translates to:
  /// **'Ahmed'**
  String get hintFirstName;

  /// No description provided for @hintLastName.
  ///
  /// In en, this message translates to:
  /// **'Hassan'**
  String get hintLastName;

  /// No description provided for @selectYourBirthday.
  ///
  /// In en, this message translates to:
  /// **'Select your birthday'**
  String get selectYourBirthday;

  /// No description provided for @searchForAddress.
  ///
  /// In en, this message translates to:
  /// **'Search for an address...'**
  String get searchForAddress;

  /// No description provided for @serviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Service location'**
  String get serviceLocation;

  /// No description provided for @moveMapToSet.
  ///
  /// In en, this message translates to:
  /// **'Move the map to set location'**
  String get moveMapToSet;

  /// No description provided for @setServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Set service location'**
  String get setServiceLocation;

  /// No description provided for @postedSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your request is live — technicians are reviewing it now and will send you offers shortly.'**
  String get postedSuccessBody;

  /// No description provided for @takingYouHome.
  ///
  /// In en, this message translates to:
  /// **'Taking you home…'**
  String get takingYouHome;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields.'**
  String get fillAllFields;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address label'**
  String get addressLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Home, Work, Friend\'s place'**
  String get addressLabelHint;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get addressDetails;

  /// No description provided for @addressDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 14 Road 9, Maadi · Floor 3, Apt 6'**
  String get addressDetailsHint;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select an icon'**
  String get selectIcon;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// No description provided for @callRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing…'**
  String get callRinging;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @callMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callMute;

  /// No description provided for @callUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callUnmute;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callSpeaker;

  /// No description provided for @callEarpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get callEarpiece;

  /// No description provided for @callRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get callRetry;

  /// No description provided for @callError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect.'**
  String get callError;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noSavedAddressesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet. Add one to reuse it later.'**
  String get noSavedAddressesYet;

  /// No description provided for @helpSupportIntro.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help. Reach out directly or browse common questions below.'**
  String get helpSupportIntro;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{value} copied to clipboard'**
  String copiedToClipboard(Object value);

  /// No description provided for @commonQuestions.
  ///
  /// In en, this message translates to:
  /// **'Common questions'**
  String get commonQuestions;

  /// No description provided for @faqBookingQ.
  ///
  /// In en, this message translates to:
  /// **'How do I book a service?'**
  String get faqBookingQ;

  /// No description provided for @faqBookingA.
  ///
  /// In en, this message translates to:
  /// **'Open the Home tab, pick a service, set your address, and confirm. We\'ll match you with a nearby technician.'**
  String get faqBookingA;

  /// No description provided for @faqCancelQ.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel a booking?'**
  String get faqCancelQ;

  /// No description provided for @faqCancelA.
  ///
  /// In en, this message translates to:
  /// **'Yes — open the booking from My Jobs and tap cancel. Cancellation terms depend on how far along the job is.'**
  String get faqCancelA;

  /// No description provided for @faqPaymentQ.
  ///
  /// In en, this message translates to:
  /// **'How do payments work?'**
  String get faqPaymentQ;

  /// No description provided for @faqPaymentA.
  ///
  /// In en, this message translates to:
  /// **'Pay with cash or card once the job is completed. A receipt is kept in your booking history.'**
  String get faqPaymentA;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: June 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacyPlaceholderBadge.
  ///
  /// In en, this message translates to:
  /// **'Placeholder — to be replaced'**
  String get privacyPlaceholderBadge;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters to us. This policy explains what we collect and how we use it.\n\nWe collect the information you give us — your name, phone number, email, saved addresses, and booking history — so we can connect you with technicians and provide the service. Your location is used only to find nearby technicians and show your service address.\n\nWe never sell your personal data. We share it with technicians only as needed to complete a booking, and with service providers (such as payment and messaging) that help us run the app.\n\nYour data is stored securely and tied to your account. You can edit your profile and remove saved addresses at any time. To delete your account or request a copy of your data, contact support.\n\nBy using Task you agree to this policy. We\'ll notify you here when it changes.'**
  String get privacyPolicyBody;

  /// No description provided for @termsOfServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Task. By creating an account or using the app you agree to these terms.\n\nTask is a marketplace that connects you with independent technicians for home services. We are not the provider of the work itself; technicians are independent contractors responsible for the services they perform.\n\nWhen you post a job you set a price and may receive offers. Agreeing to an offer forms a direct booking between you and the technician. You agree to provide accurate details, allow safe access to the work site, and pay the agreed amount on completion.\n\nYou agree to use Task lawfully and respectfully: no fraudulent bookings, no harassment of technicians, and no attempts to take payments outside the app. We may suspend accounts that break these rules.\n\nRatings and reviews must reflect genuine experiences. Cancellations should be made as early as possible; repeated late cancellations may affect your account.\n\nTask is provided \"as is.\" To the extent permitted by law, we are not liable for the acts of independent technicians. These terms may change, and we\'ll post updates here.\n\nQuestions? Reach us any time through Help & Support.'**
  String get termsOfServiceBody;
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
