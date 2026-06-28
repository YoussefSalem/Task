// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancelBookingTitle => 'Cancel booking';

  @override
  String get cancelBookingPrompt => 'Why are you cancelling?';

  @override
  String get cancelReasonFoundAnother => 'Found another technician';

  @override
  String get cancelReasonNoLongerNeeded => 'No longer needed';

  @override
  String get cancelReasonPriceTooHigh => 'Price too high';

  @override
  String get cancelReasonTakingTooLong => 'Taking too long';

  @override
  String get cancelReasonPostedByMistake => 'Posted by mistake';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get cancelNoteHint => 'Add a note (optional)';

  @override
  String get cancelConfirm => 'Cancel booking';

  @override
  String get keepBooking => 'Keep booking';

  @override
  String get bookingCancelled => 'Booking cancelled';

  @override
  String get selectACancelReason => 'Please choose a reason';

  @override
  String cancelledReasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get editName => 'Edit name';

  @override
  String get nameUpdated => 'Name updated';

  @override
  String get birthdayUpdated => 'Birthday updated';

  @override
  String get birthdayPermanentWarning =>
      'Your date of birth can\'t be changed after this — please make sure it\'s correct.';

  @override
  String get birthdayCannotBeChanged => 'Date of birth can\'t be changed';

  @override
  String get confirmBirthdayTitle => 'Confirm your date of birth';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get addPhoneNumber => 'Add phone number';

  @override
  String get changePhoneNumber => 'Change phone number';

  @override
  String get phoneNumberVerified => 'Phone number verified';

  @override
  String get verifyYourPhone => 'Verify your phone';

  @override
  String get confirmPhoneHint =>
      'We\'ll text a 6-digit code to confirm it\'s your number.';

  @override
  String get enterYourPhoneNumber => 'Enter your phone number';

  @override
  String get couldNotVerifyPhone =>
      'Couldn\'t verify your phone. Please try again.';

  @override
  String get phoneNumberInUse =>
      'That number is already linked to another account.';

  @override
  String get signInAgainToChangePhone =>
      'For security, sign in again before changing your phone number.';

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

  @override
  String get loading => 'Loading…';

  @override
  String get home => 'Home';

  @override
  String get myJobs => 'My Jobs';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get services => 'Services';

  @override
  String get browseAll => 'Browse all';

  @override
  String get allServices => 'All Services';

  @override
  String get topRatedNearYou => 'Top-rated near you';

  @override
  String get activeAndUpcoming => 'Active & upcoming';

  @override
  String get bookingHistory => 'Booking history';

  @override
  String get bookingConfirmed => 'Booking confirmed';

  @override
  String get askTheAiAssistant => 'Ask the AI assistant';

  @override
  String get chat => 'Chat';

  @override
  String get call => 'Call';

  @override
  String get addPhotosOrVideo => 'Add photos or video';

  @override
  String get addAShortDescription =>
      'Add a short description and a price above 0.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get submit => 'Submit';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results found';

  @override
  String get tryAgain => 'Try again';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get logout => 'Logout';

  @override
  String get version => 'Version';

  @override
  String get aboutUs => 'About us';

  @override
  String get help => 'Help';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get plumbing => 'Plumbing';

  @override
  String get electrical => 'Electrical';

  @override
  String get cleaning => 'Cleaning';

  @override
  String get carpentry => 'Carpentry';

  @override
  String get painting => 'Painting';

  @override
  String get ac => 'AC';

  @override
  String get price => 'Price';

  @override
  String get location => 'Location';

  @override
  String get description => 'Description';

  @override
  String get selectLocation => 'Select location';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get payment => 'Payment';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get card => 'Card';

  @override
  String get cash => 'Cash';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get rating => 'Rating';

  @override
  String get review => 'Review';

  @override
  String get rateYourExperience => 'Rate your experience';

  @override
  String get shareYourFeedback => 'Share your feedback';

  @override
  String error(Object e) {
    return 'Error: $e';
  }

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get connectionError => 'Connection error';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get acTechnician => 'AC Technician';

  @override
  String get acDeepClean => 'AC Deep Clean';

  @override
  String get acNotCooling => 'AC not cooling';

  @override
  String get acServiceAndGasRefill => 'AC service & gas refill';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiAlwaysOn => 'AI · always on';

  @override
  String get addANewAddress => 'Add a new address';

  @override
  String get addANote => 'Add a note (optional)';

  @override
  String get addingAddressesArrivesSoon => 'Adding addresses arrives soon.';

  @override
  String get allSet => 'All set! 🎉';

  @override
  String get arrives => 'Arrives';

  @override
  String get authorization => 'Authorization';

  @override
  String authorizeRemaining(Object remaining) {
    return 'Authorize $remaining EGP';
  }

  @override
  String get availableThisEvening => 'Available this evening';

  @override
  String get avgArrival => 'Avg arrival';

  @override
  String get avgRating => 'Avg rating';

  @override
  String get backToHome => 'Back to home';

  @override
  String get bestPrice => 'Best price';

  @override
  String get birthday => 'Birthday';

  @override
  String get bookFullAcService =>
      'Book a full AC service before the heat hits - verified pros, same-day slots.';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get cancelSearch => 'Cancel search';

  @override
  String get carpenter => 'Carpenter';

  @override
  String get category => 'Category';

  @override
  String get chatOrCallTechnician =>
      'Chat or call a technician before hiring. All payments go through the app.';

  @override
  String get choosePhotos => 'Choose photos';

  @override
  String get cleaner => 'Cleaner';

  @override
  String get collectingSealed => 'Collecting sealed offers…';

  @override
  String get compareOffers => 'Compare offers';

  @override
  String get completeYourProfile => 'Complete your profile';

  @override
  String get confirmCreditOnly => 'Confirm — credit only';

  @override
  String get confirmedPreparingToHeadOut => 'Confirmed — preparing to head out';

  @override
  String get confirmed => 'Confirmed — preparing to head out';

  @override
  String get constructionAndFinishing => 'Construction & Finishing';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get couldNotAccessMedia => 'Could not access media.';

  @override
  String get couldNotDetectLocation =>
      'Could not detect location. Check browser permissions.';

  @override
  String get couldNotPublishJob =>
      'Could not publish the job. Check your connection and try again.';

  @override
  String get couldNotResendCode => 'Could not resend the code.';

  @override
  String get couldNotSendCode => 'Could not send the code.';

  @override
  String get couldYouTellMeMore =>
      'Could you tell me a bit more about the problem?';

  @override
  String get customLocation => 'Custom location';

  @override
  String get dark => 'Dark';

  @override
  String get demoModeEnterSixDigits => 'Demo mode — enter any 6 digits.';

  @override
  String get describeProblem => 'Describe the problem';

  @override
  String get describeYourProblemToAi =>
      'Describe your problem to the AI assistant and set your price';

  @override
  String get describeYourProblem => 'Describe your problem...';

  @override
  String get done => 'Done';

  @override
  String get doorsWindowsAndGlass => 'Doors, Windows & Glass';

  @override
  String get eg => 'EG';

  @override
  String egpFixedPrice(Object fixedPrice) {
    return 'EGP $fixedPrice\n\nShall I post this for technicians to review?';
  }

  @override
  String get egp => 'EGP';

  @override
  String get expert => 'EXPERT';

  @override
  String get electricalExpert => 'Electrical Expert';

  @override
  String get electricalFault => 'Electrical fault';

  @override
  String get electrician => 'Electrician';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emulatorOffline =>
      'Emulator offline — using demo code (any 6 digits).';

  @override
  String get enRoute => 'En route';

  @override
  String get endCall => 'End call';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterValidPhoneNumber => 'Enter a valid phone number.';

  @override
  String get enterFullCode => 'Enter the full code.';

  @override
  String get enterYourPriceInEgp => 'Enter your price in EGP…';

  @override
  String get fairPrice => 'Fair price';

  @override
  String get fastArrival => 'Fast arrival';

  @override
  String get findingAddress => 'Finding address...';

  @override
  String get findingNearbyProfessionals => 'Finding nearby professionals…';

  @override
  String get findingYourPro => 'Finding your pro';

  @override
  String get firstName => 'First name';

  @override
  String get friendly => 'Friendly';

  @override
  String get from120Egp => 'From 120 EGP';

  @override
  String get from150Egp => 'From 150 EGP';

  @override
  String get from250Egp => 'From 250 EGP';

  @override
  String get from400Egp => 'From 400 EGP';

  @override
  String get from600Egp => 'From 600 EGP';

  @override
  String get newCodeOnTheWay => 'A new code is on its way.';

  @override
  String get lastName => 'Last name';

  @override
  String get light => 'Light';

  @override
  String get maintenanceMode => 'Maintenance mode';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get viewProfile => 'View profile';

  @override
  String get aboutTheService => 'About the service';

  @override
  String get durationAndPrice => 'Duration & price';

  @override
  String get selectQuantity => 'Select quantity';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get orderConfirmed => 'Order confirmed';

  @override
  String get trackOrder => 'Track order';

  @override
  String get needHelp => 'Need help?';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get reportAnIssue => 'Report an issue';

  @override
  String get allCategories => 'All Categories';

  @override
  String get popular => 'Popular';

  @override
  String get recentlyViewed => 'Recently viewed';

  @override
  String get favorites => 'Favorites';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get clearAll => 'Clear all';

  @override
  String get filterBy => 'Filter by';

  @override
  String get sortBy => 'Sort by';

  @override
  String get priceRange => 'Price range';

  @override
  String get availability => 'Availability';

  @override
  String get reviews => 'Reviews';

  @override
  String get writeAReview => 'Write a review';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get changePassword => 'Change password';

  @override
  String get twoFactorAuth => 'Two-factor authentication';

  @override
  String get connectedAccounts => 'Connected accounts';

  @override
  String get blockList => 'Block list';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get dataAndPrivacy => 'Data & Privacy';

  @override
  String get downloadMyData => 'Download my data';

  @override
  String get languageAndRegion => 'Language & region';

  @override
  String get timeZone => 'Time zone';

  @override
  String get welcomeToTask => 'Welcome to Task';

  @override
  String get egyptOnDemandServices =>
      'Egypt\'s on-demand home services — describe it, set your price, done.';

  @override
  String get verifiedPros => 'Verified pros';

  @override
  String get youSetThePrice => 'You set the price';

  @override
  String get sendCode => 'Send code';

  @override
  String get or => 'OR';

  @override
  String get termsAndPrivacy => 'Terms of Service • Privacy Policy';

  @override
  String get yourBookings => 'Your bookings';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get whenTechniciansRespond =>
      'When technicians respond to your requests, conversations appear here';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get helpAndSupport => 'Help & support';

  @override
  String get privacyAndSecurity => 'Privacy & security';

  @override
  String get signOut => 'Sign out';

  @override
  String get taskCredit => 'Task credit';

  @override
  String get system => 'System';

  @override
  String get work => 'Work';

  @override
  String get cashCard => 'Cash, Card';

  @override
  String get leakingKitchenSink => 'Leaking kitchen sink';

  @override
  String get plumber => 'Plumber';

  @override
  String get biddingActive => 'biddingActive';

  @override
  String get acMaintenance => 'AC Maintenance';

  @override
  String get inProgress => 'inProgress';

  @override
  String get replaceTrippingBreaker => 'Replace tripping breaker';

  @override
  String get completed => 'completed';

  @override
  String get serviceAt => 'Service at';

  @override
  String electricianArrivingIn(Object minutes) {
    return 'Electrician arriving in $minutes min';
  }

  @override
  String get whatNeedsFixing => 'What needs fixing?';

  @override
  String get describeItInYourWords =>
      'Describe it in your words — I\'ll line up the right pro. You decide the price.';

  @override
  String get kitchenSinkIsBlocked => '...Kitchen sink is blocked';

  @override
  String get ramadanDeepClean => 'Ramadan Deep Clean';

  @override
  String get professionalWholeHomeCleaning =>
      'Professional whole-home cleaning packages - book now, pay after';

  @override
  String get popularInYourArea => 'Popular in your area';

  @override
  String get history => 'History';

  @override
  String helloUsername(Object username) {
    return 'Hello, $username';
  }

  @override
  String arrrivingIn(Object category, Object minutes) {
    return '$category arriving in $minutes min';
  }

  @override
  String technicianOnTheWay(String category) {
    return '$category pro is on the way';
  }

  @override
  String isWorking(Object category) {
    return '$category is working';
  }

  @override
  String get waitingForApproval => 'Waiting for your approval';

  @override
  String get jobActive => 'Job active';

  @override
  String get addAddress => 'Add address';

  @override
  String get describeTheProblem => 'Describe the problem';

  @override
  String get selectCategory => 'Select category';

  @override
  String get enterYourPrice => 'Enter your price in EGP…';

  @override
  String get thankYou => 'Thank you for booking with Task!';

  @override
  String get viewYourBooking => 'View your booking';

  @override
  String get bookingNumber => 'Booking number';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get pleaseAddYourName => 'Please add your name to continue';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get enterOtp => 'Enter the OTP sent to your phone';

  @override
  String get resendCode => 'Resend code';

  @override
  String get codeExpires => 'Code expires in';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get selectPaymentMethod => 'Select payment method';

  @override
  String get cashPayment => 'Cash on arrival';

  @override
  String get cardPayment => 'Pay with card';

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String get enterCardDetails => 'Enter your card details';

  @override
  String get cardNumber => 'Card number';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get cvv => 'CVV';

  @override
  String get paymentSuccessful => 'Payment successful';

  @override
  String get paymentFailed => 'Payment failed. Please try again.';

  @override
  String get currentLocation => 'Current location';

  @override
  String get bookNow => 'Book now';

  @override
  String get estimatedPrice => 'Estimated price';

  @override
  String get totalPrice => 'Total price';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get postAJob => 'Post a job';

  @override
  String get masonAndDecorationStones => 'Mason & Decoration Stones';

  @override
  String get optional => 'Optional';

  @override
  String get add => 'Add';

  @override
  String get yourBudget => 'Your budget';

  @override
  String get resize => 'Resize';

  @override
  String get referAndEarn => 'Refer & Earn 50 EGP';

  @override
  String get shareYourCode =>
      'Share your code with friends - you both get 50 EGP credit on your next booking';

  @override
  String get newTag => 'NEW';

  @override
  String get leakRepair => 'Leak Repair';

  @override
  String get booked => 'booked';

  @override
  String get myAcIsLeakingWater => '...My AC is leaking water';

  @override
  String get offersReceived => 'Offers received';

  @override
  String get goHome => 'Go home';

  @override
  String get skip => 'Skip';

  @override
  String get stay => 'Stay';

  @override
  String get serviceAddress => 'Service address';

  @override
  String get pleaseSelectYourBirthday => 'Please select your birthday.';

  @override
  String get badgePro => 'PRO';

  @override
  String get badgeExpert => 'EXPERT';

  @override
  String get badgePlatinum => 'PLATINUM';

  @override
  String get tierBronze => 'BRONZE';

  @override
  String get tierSilver => 'SILVER';

  @override
  String get tierGold => 'GOLD';

  @override
  String get tierPlatinum => 'PLATINUM';

  @override
  String get techNameMohamed => 'Mohamed Ali';

  @override
  String get techNameSara => 'Sara Hassan';

  @override
  String get techNameKarim => 'Karim Fouad';

  @override
  String get specialtyPlumbing => 'Plumbing Specialist';

  @override
  String get specialtyElectrical => 'Electrical Expert';

  @override
  String get specialtyAc => 'AC Technician';

  @override
  String jobsCountLabel(Object count) {
    return '$count+ Jobs';
  }

  @override
  String get payCard => 'Card';

  @override
  String get payWallet => 'Vodafone Cash';

  @override
  String get payInstapay => 'InstaPay';

  @override
  String get payCardSub => 'Visa, Mastercard, Meeza · via Paymob';

  @override
  String get payWalletSub => 'Pay from your mobile wallet';

  @override
  String get payInstapaySub => 'Instant bank transfer · confirmed by team';

  @override
  String get addrHome => 'Home';

  @override
  String get addrWork => 'Work';

  @override
  String get addrHomeLine => '14 Road 9, Maadi · Floor 3, Apt 6';

  @override
  String get addrWorkLine => 'Smart Village, Building B12 · Reception';

  @override
  String get stageSearching => 'Finding your pro';

  @override
  String get stageAccepted => 'Pro assigned';

  @override
  String get stageEnRoute => 'On the way';

  @override
  String get stageInProgress => 'Work in progress';

  @override
  String get stageCompleted => 'Job complete';

  @override
  String get locDefaultAddress => 'Maadi, Cairo';

  @override
  String get locPinDrop => 'Pin drop';

  @override
  String get locCustom => 'Custom location';

  @override
  String get locNasrCity => 'Nasr City, Cairo';

  @override
  String get locSheikhZayed => 'Sheikh Zayed, Giza';

  @override
  String get techNameKhaled => 'Khaled Mansour';

  @override
  String get techNameSayed => 'Sayed Abdel-Rahman';

  @override
  String get techNameMostafa => 'Mostafa Eid';

  @override
  String get etaCanStart40 => 'Can start in 40 min';

  @override
  String get etaThisEvening => 'Available this evening';

  @override
  String get etaCanStart25 => 'Can start in 25 min';

  @override
  String get jobSeed1Title => 'Leaking kitchen sink';

  @override
  String get jobSeed1Desc =>
      'Steady drip under the sink, water pooling in the cabinet.';

  @override
  String get jobSeed2Title => 'AC not cooling';

  @override
  String get jobSeed2Desc => 'Split unit runs but blows warm air.';

  @override
  String get jobSeed3Title => 'Replace tripping breaker';

  @override
  String get jobSeed3Desc => 'Main breaker trips when the heater runs.';

  @override
  String get catPainter => 'Painter';

  @override
  String get catSatellite => 'Satellite';

  @override
  String get catSmartHome => 'Smart Home';

  @override
  String get catTilesHandyman => 'Tiles Handyman';

  @override
  String get catPlaster => 'Plaster';

  @override
  String get catSmith => 'Smith';

  @override
  String get catParquet => 'Parquet';

  @override
  String get catGypsumWorks => 'Gypsum Works';

  @override
  String get catGypsumBoard => 'Gypsum Board';

  @override
  String get catMarbleGranite => 'Marble & Granite';

  @override
  String get catAlumetal => 'Alumetal';

  @override
  String get catGlassCecurit => 'Glass & Cecurit';

  @override
  String get catCurtainsUpholstery => 'Curtains & Upholstery';

  @override
  String get catWoodPainter => 'Wood Painter';

  @override
  String get catMovingServices => 'Moving Services';

  @override
  String get catPuCornices => 'PU Cornices';

  @override
  String get catMaterialWinch => 'Material Winch';

  @override
  String get catAppliancesMaintenance => 'Appliances Maintenance';

  @override
  String get catSwimmingPool => 'Swimming Pool Maintenance';

  @override
  String get catPestControl => 'Pest Control';

  @override
  String get statusSearching => 'Searching';

  @override
  String get statusPendingScheduled => 'Scheduled';

  @override
  String get statusBiddingActive => 'Receiving offers';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusEnRoute => 'On the way';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusPausedForApproval => 'Awaiting approval';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDisputed => 'Disputed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get demoUserName => 'Ahmed';

  @override
  String get yourProfile => 'Your profile';

  @override
  String get powerKeepsTripping => 'Power keeps tripping…';

  @override
  String get needDeepCleanWeekend => 'Need a deep clean this weekend…';

  @override
  String get summerAcCheckup => 'Summer AC Check-up';

  @override
  String get badgeLimited => 'LIMITED';

  @override
  String get outletInstall => 'Outlet Install';

  @override
  String get fullHomeClean => 'Full Home Clean';

  @override
  String get roomRepaint => 'Room Repaint';

  @override
  String get egpPerHour => 'EGP/hr';

  @override
  String get searchingForPros => 'Searching for pros…';

  @override
  String get tapToReviewHire => 'Tap to review and hire a technician';

  @override
  String get tapToViewProgress => 'Tap to view live search progress';

  @override
  String get stepConfirmed => 'Confirmed';

  @override
  String get stepWorking => 'Working';

  @override
  String get searchingWithin3km => 'Searching within 3 km…';

  @override
  String get wideningTo6km => 'Widening to 6 km…';

  @override
  String get reachingNearbyPros => 'Reaching nearby pros…';

  @override
  String get yourJob => 'your job';

  @override
  String get proAssignedExcl => 'Pro assigned!';

  @override
  String get proHeadingToYou => 'Khaled is 1.8 km away and heading to you.';

  @override
  String get trackYourPro => 'Track your pro';

  @override
  String get proKhaledInitials => 'KM';

  @override
  String get jobsWord => 'jobs';

  @override
  String get verified => 'Verified';

  @override
  String get hireAndTrack => 'Hire & track';

  @override
  String upToFiveProsBid(Object job) {
    return 'Up to 5 pros bid privately for your $job. No one sees the others\' price.';
  }

  @override
  String get jobWord => 'job';

  @override
  String offersReceivedCount(Object count) {
    return '$count offers received';
  }

  @override
  String get sealed => 'Sealed';

  @override
  String get lowest => 'Lowest';

  @override
  String prosFoundNearby(Object count) {
    return '$count pros found nearby';
  }

  @override
  String get waitingForOffers => 'Waiting for offers…';

  @override
  String get scanningYourArea => 'Scanning your area — usually under a minute';

  @override
  String get sendingJobDetails => 'Sending your job details to them now';

  @override
  String get prosReviewing => 'Pros are reviewing your request';

  @override
  String get openingYourOffers => 'Opening your offers…';

  @override
  String get stopSearchQ => 'Stop search?';

  @override
  String get stopSearchBody =>
      'Your request stays active and technicians can still send offers.\n\nYou\'ll get a notification when offers arrive. To fully stop, cancel the request.';

  @override
  String get liveSearch => 'Live search';

  @override
  String get youCanExitNote =>
      'You can exit — your request stays active. We\'ll notify you when offers arrive.';

  @override
  String get stopSearch => 'Stop search';

  @override
  String viewOffersCount(Object count) {
    return 'View $count offers';
  }

  @override
  String get phaseSearching => 'Searching';

  @override
  String get phaseFound => 'Found';

  @override
  String get phaseWaiting => 'Waiting';

  @override
  String get phaseOffers => 'Offers';

  @override
  String offersCountShort(Object count) {
    return '$count offers';
  }

  @override
  String jobsDoneCount(Object count) {
    return '$count jobs done';
  }

  @override
  String get selectedLabel => 'Selected';

  @override
  String get selectOffer => 'Select offer';

  @override
  String get inAppVoipCall => 'In-app VoIP call';

  @override
  String get startCall => 'Start call';

  @override
  String get goBackToOffers => 'Go back to offers';

  @override
  String get bookingConfirmedSub =>
      'We\'ve locked in your pro. You\'ll get a reminder before they arrive.';

  @override
  String get payAndFinish => 'Pay & finish';

  @override
  String get reviewAndPay => 'Review & pay';

  @override
  String get serviceLabel => 'Service';

  @override
  String get titleLabel => 'Title';

  @override
  String get jobTotal => 'Job total';

  @override
  String get taskCreditApplied => 'Task credit applied';

  @override
  String get youPay => 'You pay';

  @override
  String get free => 'Free';

  @override
  String get taskCreditCovers =>
      'Your Task credit fully covers this order — no additional payment needed.';

  @override
  String payAmount(Object amount) {
    return 'Pay $amount EGP';
  }

  @override
  String taskCreditAppliedAmount(Object amount) {
    return '$amount EGP Task credit applied';
  }

  @override
  String get walletTitle => 'Wallet';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get topUp => 'Top up';

  @override
  String get sendAction => 'Send';

  @override
  String featureArrivesWithPayments(Object feature) {
    return '$feature arrives with payments.';
  }

  @override
  String get walletTopUp => 'Wallet top-up';

  @override
  String get walletEmptyLedger => 'No transactions yet';

  @override
  String get walletEmptyLedgerHint => 'Credits and refunds will appear here.';

  @override
  String get walletLoadError => 'Couldn\'t load your wallet';

  @override
  String get referralCredit => 'Referral credit';

  @override
  String get txnToday240 => 'Today · 2:40 PM';

  @override
  String get txnYesterday => 'Yesterday';

  @override
  String get txnMar18 => 'Mar 18 · 6:15 PM';

  @override
  String get txnMar15 => 'Mar 15';

  @override
  String get tagOnTime => 'On time';

  @override
  String get tagTidyWork => 'Tidy work';

  @override
  String get tagSkilled => 'Skilled';

  @override
  String get tagGreatCommunication => 'Great communication';

  @override
  String howWasYour(Object service) {
    return 'How was your $service?';
  }

  @override
  String get serviceWord => 'service';

  @override
  String withPro(Object name) {
    return 'with $name';
  }

  @override
  String get submitReview => 'Submit review';

  @override
  String get reviewSubmitted => 'Review submitted!';

  @override
  String thanksForRating(Object name) {
    return 'Thanks for rating $name.\nYour feedback helps the whole community.';
  }

  @override
  String redirectingIn(Object seconds) {
    return 'Redirecting in $seconds s…';
  }

  @override
  String etaMinutes(Object minutes) {
    return 'ETA $minutes min';
  }

  @override
  String get awaitingLiveLocation => 'Waiting for live location…';

  @override
  String get noActiveJob => 'No active job right now';

  @override
  String get homeService => 'Home service';

  @override
  String get headingToAddress => 'Heading to your address';

  @override
  String get workingOnJob => 'Working on the job';

  @override
  String get jobCompleted => 'Job completed';

  @override
  String featureOpensComms(Object feature) {
    return '$feature opens in the comms phase.';
  }

  @override
  String get pinOnMap => 'Pin on map';

  @override
  String get specializedServices => 'Specialized Services';

  @override
  String get maintenanceGroup => 'Maintenance';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get recordAVideo => 'Record a video';

  @override
  String get describeProblemHint =>
      'e.g. Living-room lights keep flickering when I turn on the AC...';

  @override
  String get publishJob => 'Publish job';

  @override
  String get chatMsgHello =>
      'Hello! I reviewed your job. I can arrive within 30 minutes.';

  @override
  String get chatMsgQuote =>
      'My quote includes all materials. Any specific brand preference?';

  @override
  String get chatMsgReply =>
      'Got it! I\'ll bring everything needed. See you soon.';

  @override
  String get chatTime341 => '3:41 PM';

  @override
  String get online => 'Online';

  @override
  String get messageHint => 'Message…';

  @override
  String get typingIndicator => 'typing…';

  @override
  String get seenLabel => 'Seen';

  @override
  String get chatSignedOut => 'Sign in to message technicians.';

  @override
  String get chatLoadError =>
      'Couldn\'t load this conversation. Check your connection.';

  @override
  String get chatEmpty => 'Say hello to start the conversation.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up.';

  @override
  String get notificationsMarkAll => 'Mark all read';

  @override
  String get notifPostedTitle => 'Request posted';

  @override
  String get notifPostedBody =>
      'We\'re finding the right technician for your job.';

  @override
  String notifNewMessageTitle(String name) {
    return 'New message from $name';
  }

  @override
  String get notifHiredTitle => 'You\'re hired';

  @override
  String get notifHiredBody =>
      'The customer accepted your offer. Head over when ready.';

  @override
  String get customerWord => 'the customer';

  @override
  String get suggestionAcLeaking => 'My AC is leaking water';

  @override
  String get suggestionPowerTripping => 'Power keeps tripping';

  @override
  String get suggestionDeepClean => 'Need a deep clean this weekend';

  @override
  String get taskAssistant => 'Task Assistant';

  @override
  String get newRequest => 'New request';

  @override
  String get replyYesToPost => 'Reply yes to post, or no to change…';

  @override
  String get requestPosted => 'Request posted';

  @override
  String get messageAssistant => 'Message the assistant…';

  @override
  String get assistantGreeting =>
      'Hi! I\'m your Task assistant. Tell me what needs fixing and I\'ll write a clear summary for the right pro. You decide the price.';

  @override
  String get assistantAlreadyLive =>
      'Your request is already live with technicians. Tap \"New request\" below to start another one.';

  @override
  String get assistantPriceAsk =>
      'Great — I\'ve got everything I need. What would you like to pay for this service, in EGP?';

  @override
  String get assistantNoPriceCaught =>
      'I didn\'t catch a price there. About how much would you like to pay, in EGP? For example \"400\".';

  @override
  String get assistantSomethingMissing =>
      'Something\'s missing from the request — let\'s go over it again. What\'s the problem?';

  @override
  String get assistantPosted =>
      'Done — your request is now live for technicians to review. You\'ll start getting offers shortly.';

  @override
  String get assistantWhatToChange =>
      'No problem. What would you like to change? Tell me a new price, or describe anything about the job you want to adjust.';

  @override
  String get assistantJustConfirm =>
      'Just to confirm — should I post this for technicians? Reply \"yes\" to post, or \"no\" to change something.';

  @override
  String get assistantPostFailed =>
      'Sorry — I couldn\'t post your request just now. Please check your connection and reply \"yes\" to try again.';

  @override
  String assistantConfirm(Object cat, Object price, Object title) {
    return 'Here\'s your request:\n\n• $cat — $title\n• You pay: EGP $price\n\nShall I post this for technicians to review? Reply \"yes\" to post, or \"no\" to change something.';
  }

  @override
  String get assistantMockAskMore =>
      'Tell me what\'s going wrong — for example a leak, an AC that won\'t cool, or power that keeps tripping — and where in your home it is.';

  @override
  String assistantMockGotIt(Object category) {
    return 'Got it — this looks like a $category job. I\'ve put together a summary for technicians below. Set the price you want to pay and publish when you are ready.';
  }

  @override
  String get assistantError =>
      'I had trouble reaching the assistant just now — please try sending that again.';

  @override
  String get demoProfileName => 'Nour Adel';

  @override
  String get demoProfileInitials => 'NA';

  @override
  String featureArrivesLater(Object feature) {
    return '$feature arrives in a later phase.';
  }

  @override
  String get noPastJobs => 'No past jobs yet';

  @override
  String get requestNewCode => 'Request a new code, please.';

  @override
  String get invalidPhone => 'That phone number looks invalid.';

  @override
  String get incorrectCode => 'That code is incorrect.';

  @override
  String get tooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get signInCancelled => 'Sign-in was cancelled.';

  @override
  String get genericAuthError => 'Something went wrong. Please try again.';

  @override
  String sentCodeTo(Object phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String resendCodeIn(Object time) {
    return 'Resend code in $time';
  }

  @override
  String get verifyAction => 'Verify';

  @override
  String get signInFailed => 'Sign-in failed.';

  @override
  String get moreCountriesSoon =>
      'More countries arrive with international launch.';

  @override
  String get privacyOpensLater => 'Privacy Policy opens in a later phase.';

  @override
  String get termsOpensLater => 'Terms of Service opens in a later phase.';

  @override
  String get requiredField => 'Required';

  @override
  String get profileSubtitle =>
      'A few details so technicians know who they\'re helping.';

  @override
  String get hintFirstName => 'Ahmed';

  @override
  String get hintLastName => 'Hassan';

  @override
  String get selectYourBirthday => 'Select your birthday';

  @override
  String get searchForAddress => 'Search for an address...';

  @override
  String get serviceLocation => 'Service location';

  @override
  String get moveMapToSet => 'Move the map to set location';

  @override
  String get setServiceLocation => 'Set service location';

  @override
  String get postedSuccessBody =>
      'Your request is live — technicians are reviewing it now and will send you offers shortly.';

  @override
  String get takingYouHome => 'Taking you home…';

  @override
  String get fillAllFields => 'Please fill all required fields.';

  @override
  String get addressLabel => 'Address label';

  @override
  String get addressLabelHint => 'e.g., Home, Work, Friend\'s place';

  @override
  String get addressDetails => 'Address details';

  @override
  String get addressDetailsHint => 'e.g., 14 Road 9, Maadi · Floor 3, Apt 6';

  @override
  String get selectIcon => 'Select an icon';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callRinging => 'Ringing…';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callMute => 'Mute';

  @override
  String get callUnmute => 'Unmute';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String get callEarpiece => 'Earpiece';

  @override
  String get callRetry => 'Try again';

  @override
  String get callError => 'Could not connect.';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get notSet => 'Not set';

  @override
  String get noSavedAddressesYet =>
      'No saved addresses yet. Add one to reuse it later.';

  @override
  String get helpSupportIntro =>
      'We\'re here to help. Reach out directly or browse common questions below.';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactPhone => 'Phone';

  @override
  String copiedToClipboard(Object value) {
    return '$value copied to clipboard';
  }

  @override
  String get commonQuestions => 'Common questions';

  @override
  String get faqBookingQ => 'How do I book a service?';

  @override
  String get faqBookingA =>
      'Open the Home tab, pick a service, set your address, and confirm. We\'ll match you with a nearby technician.';

  @override
  String get faqCancelQ => 'Can I cancel a booking?';

  @override
  String get faqCancelA =>
      'Yes — open the booking from My Jobs and tap cancel. Cancellation terms depend on how far along the job is.';

  @override
  String get faqPaymentQ => 'How do payments work?';

  @override
  String get faqPaymentA =>
      'Pay with cash or card once the job is completed. A receipt is kept in your booking history.';

  @override
  String get privacyLastUpdated => 'Last updated: June 2026';

  @override
  String get privacyPlaceholderBadge => 'Placeholder — to be replaced';

  @override
  String get privacyPolicyBody =>
      'Your privacy matters to us. This policy explains what we collect and how we use it.\n\nWe collect the information you give us — your name, phone number, email, saved addresses, and booking history — so we can connect you with technicians and provide the service. Your location is used only to find nearby technicians and show your service address.\n\nWe never sell your personal data. We share it with technicians only as needed to complete a booking, and with service providers (such as payment and messaging) that help us run the app.\n\nYour data is stored securely and tied to your account. You can edit your profile and remove saved addresses at any time. To delete your account or request a copy of your data, contact support.\n\nBy using Task you agree to this policy. We\'ll notify you here when it changes.';

  @override
  String get termsOfServiceBody =>
      'Welcome to Task. By creating an account or using the app you agree to these terms.\n\nTask is a marketplace that connects you with independent technicians for home services. We are not the provider of the work itself; technicians are independent contractors responsible for the services they perform.\n\nWhen you post a job you set a price and may receive offers. Agreeing to an offer forms a direct booking between you and the technician. You agree to provide accurate details, allow safe access to the work site, and pay the agreed amount on completion.\n\nYou agree to use Task lawfully and respectfully: no fraudulent bookings, no harassment of technicians, and no attempts to take payments outside the app. We may suspend accounts that break these rules.\n\nRatings and reviews must reflect genuine experiences. Cancellations should be made as early as possible; repeated late cancellations may affect your account.\n\nTask is provided \"as is.\" To the extent permitted by law, we are not liable for the acts of independent technicians. These terms may change, and we\'ll post updates here.\n\nQuestions? Reach us any time through Help & Support.';
}
