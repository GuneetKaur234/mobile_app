import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your language'**
  String get selectLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @letsGetYouSetUp.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you set up!'**
  String get letsGetYouSetUp;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @scacCode.
  ///
  /// In en, this message translates to:
  /// **'SCAC Code'**
  String get scacCode;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// Shown when a required field is empty
  ///
  /// In en, this message translates to:
  /// **'{field} cannot be empty'**
  String cannotBeEmpty(Object field);

  /// No description provided for @unableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Check your connection.'**
  String get unableToConnect;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. You are not approved or server is unreachable.'**
  String get connectionTimeout;

  /// Shown when an unexpected error occurs
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(Object error);

  /// No description provided for @notApproved.
  ///
  /// In en, this message translates to:
  /// **'You are not approved. Please contact your company.'**
  String get notApproved;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @noRecentLoads.
  ///
  /// In en, this message translates to:
  /// **'No recent loads found.'**
  String get noRecentLoads;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pickupInfo.
  ///
  /// In en, this message translates to:
  /// **'Pickup Info'**
  String get pickupInfo;

  /// No description provided for @trailerUpload.
  ///
  /// In en, this message translates to:
  /// **'Trailer Upload'**
  String get trailerUpload;

  /// No description provided for @deliveryInfo.
  ///
  /// In en, this message translates to:
  /// **'Delivery Info'**
  String get deliveryInfo;

  /// No description provided for @deliveryCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed!'**
  String get deliveryCompletedSnack;

  /// No description provided for @loadNumber.
  ///
  /// In en, this message translates to:
  /// **'Load Number'**
  String get loadNumber;

  /// No description provided for @pickupNumber.
  ///
  /// In en, this message translates to:
  /// **'Pickup Number'**
  String get pickupNumber;

  /// No description provided for @noLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'No load details found.'**
  String get noLoadDetails;

  /// No description provided for @loadDetails.
  ///
  /// In en, this message translates to:
  /// **'Load Details'**
  String get loadDetails;

  /// No description provided for @pickupDetails.
  ///
  /// In en, this message translates to:
  /// **'Pickup Details'**
  String get pickupDetails;

  /// No description provided for @truckNumber.
  ///
  /// In en, this message translates to:
  /// **'Truck Number'**
  String get truckNumber;

  /// No description provided for @trailerNumber.
  ///
  /// In en, this message translates to:
  /// **'Trailer Number'**
  String get trailerNumber;

  /// No description provided for @equipmentType.
  ///
  /// In en, this message translates to:
  /// **'Equipment Type'**
  String get equipmentType;

  /// No description provided for @equipmentTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Equipment Type is required'**
  String get equipmentTypeRequired;

  /// No description provided for @customerRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer is required'**
  String get customerRequired;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// No description provided for @reeferPreCool.
  ///
  /// In en, this message translates to:
  /// **'Reefer Pre-Cool (°F)'**
  String get reeferPreCool;

  /// No description provided for @pickupInfoSaved.
  ///
  /// In en, this message translates to:
  /// **'Pickup info saved'**
  String get pickupInfoSaved;

  /// No description provided for @pickupInfoSavedTransit.
  ///
  /// In en, this message translates to:
  /// **'Pickup info saved & status updated to In Transit'**
  String get pickupInfoSavedTransit;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// Shown when a network error occurs while saving
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String networkError(Object error);

  /// No description provided for @pictureUpload.
  ///
  /// In en, this message translates to:
  /// **'Picture Upload'**
  String get pictureUpload;

  /// No description provided for @trailerPicture.
  ///
  /// In en, this message translates to:
  /// **'Trailer Picture'**
  String get trailerPicture;

  /// No description provided for @pulp.
  ///
  /// In en, this message translates to:
  /// **'Pulp'**
  String get pulp;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @pulpPicture.
  ///
  /// In en, this message translates to:
  /// **'Pulp Picture'**
  String get pulpPicture;

  /// No description provided for @pulpReason.
  ///
  /// In en, this message translates to:
  /// **'If not, Why?'**
  String get pulpReason;

  /// No description provided for @reeferPicture.
  ///
  /// In en, this message translates to:
  /// **'Reefer Picture'**
  String get reeferPicture;

  /// No description provided for @loadSecurePicture.
  ///
  /// In en, this message translates to:
  /// **'Load Secure Picture'**
  String get loadSecurePicture;

  /// No description provided for @sealedTrailerPicture.
  ///
  /// In en, this message translates to:
  /// **'Sealed Trailer Picture'**
  String get sealedTrailerPicture;

  /// No description provided for @bol.
  ///
  /// In en, this message translates to:
  /// **'BOL'**
  String get bol;

  /// No description provided for @reeferTempShipper.
  ///
  /// In en, this message translates to:
  /// **'Reefer Temp (Set by Shipper)'**
  String get reeferTempShipper;

  /// No description provided for @reeferTempBol.
  ///
  /// In en, this message translates to:
  /// **'Reefer Temp on BOL'**
  String get reeferTempBol;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get temperatureUnit;

  /// No description provided for @sealNumber.
  ///
  /// In en, this message translates to:
  /// **'Seal Number'**
  String get sealNumber;

  /// No description provided for @pickupNotes.
  ///
  /// In en, this message translates to:
  /// **'Pickup Notes'**
  String get pickupNotes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sendPickupEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Pickup email'**
  String get sendPickupEmail;

  /// No description provided for @pickupEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pickup email sent successfully!'**
  String get pickupEmailSuccess;

  /// No description provided for @pickupEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send pickup email'**
  String get pickupEmailFailed;

  /// Shown when some required fields are missing
  ///
  /// In en, this message translates to:
  /// **'Please provide: {fields}'**
  String missingFields(Object fields);

  /// No description provided for @fillReeferTemp.
  ///
  /// In en, this message translates to:
  /// **'Please fill Reefer temperatures'**
  String get fillReeferTemp;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @addMoreFiles.
  ///
  /// In en, this message translates to:
  /// **'Add More Files'**
  String get addMoreFiles;

  /// No description provided for @failedToLoadFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files'**
  String get failedToLoadFiles;

  /// Shown when loading files fails
  ///
  /// In en, this message translates to:
  /// **'Error loading files: {error}'**
  String errorLoadingFiles(Object error);

  /// Shown when image picking fails
  ///
  /// In en, this message translates to:
  /// **'Error picking images: {error}'**
  String errorPickingImages(Object error);

  /// Shown when required fields are missing
  ///
  /// In en, this message translates to:
  /// **'Please provide: {fields}'**
  String pleaseProvide(Object fields);

  /// No description provided for @deliveryNumber.
  ///
  /// In en, this message translates to:
  /// **'Delivery Number'**
  String get deliveryNumber;

  /// No description provided for @enterDeliveryNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a Delivery Number'**
  String get enterDeliveryNumber;

  /// No description provided for @podFiles.
  ///
  /// In en, this message translates to:
  /// **'POD Files'**
  String get podFiles;

  /// No description provided for @uploadAtLeastOnePod.
  ///
  /// In en, this message translates to:
  /// **'Please upload at least one POD file'**
  String get uploadAtLeastOnePod;

  /// No description provided for @deliveryInfoSaved.
  ///
  /// In en, this message translates to:
  /// **'Delivery info saved successfully'**
  String get deliveryInfoSaved;

  /// No description provided for @deliveryEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Delivery email sent successfully!'**
  String get deliveryEmailSent;

  /// No description provided for @failedToLoadDeliveryInfo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load delivery info'**
  String get failedToLoadDeliveryInfo;

  /// Shown when fetching delivery info fails
  ///
  /// In en, this message translates to:
  /// **'Error loading delivery info: {error}'**
  String errorLoadingDeliveryInfo(Object error);

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Shown on the screen when the trip is finished
  ///
  /// In en, this message translates to:
  /// **'Trip Completed!'**
  String get tripCompleted;

  /// Shown when delivery info is successfully sent
  ///
  /// In en, this message translates to:
  /// **'Delivery info has been sent successfully 🎉'**
  String get deliverySentSuccess;

  /// Button text to return to the dashboard
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @status_in_transit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get status_in_transit;

  /// No description provided for @status_pickup_completed.
  ///
  /// In en, this message translates to:
  /// **'Pickup Completed'**
  String get status_pickup_completed;

  /// No description provided for @status_delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get status_delivered;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @failedFetchProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch profile'**
  String get failedFetchProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(Object field);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @viewUpdateDriverDetails.
  ///
  /// In en, this message translates to:
  /// **'View/update driver details'**
  String get viewUpdateDriverDetails;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// No description provided for @darkModeFontSize.
  ///
  /// In en, this message translates to:
  /// **'Dark mode, font size'**
  String get darkModeFontSize;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @contactDispatcherHotlineFaq.
  ///
  /// In en, this message translates to:
  /// **'Contact dispatcher, hotline, FAQ'**
  String get contactDispatcherHotlineFaq;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @managePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage permissions'**
  String get managePermissions;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @versionCompanyContact.
  ///
  /// In en, this message translates to:
  /// **'Version info, company contact'**
  String get versionCompanyContact;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
