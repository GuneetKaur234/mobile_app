// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Welcome';

  @override
  String get pickup => 'Pickup';

  @override
  String get delivery => 'Delivery';

  @override
  String get settings => 'Settings';

  @override
  String get selectLanguage => 'Select your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get letsGetYouSetUp => 'Let\'s get you set up!';

  @override
  String get name => 'Name';

  @override
  String get licenseNumber => 'License Number';

  @override
  String get company => 'Company';

  @override
  String get scacCode => 'SCAC Code';

  @override
  String get phone => 'Phone';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String cannotBeEmpty(Object field) {
    return '$field cannot be empty';
  }

  @override
  String get unableToConnect =>
      'Unable to connect to the server. Check your connection.';

  @override
  String get connectionTimeout =>
      'Connection timed out. You are not approved or server is unreachable.';

  @override
  String unexpectedError(Object error) {
    return 'Unexpected error: $error';
  }

  @override
  String get notApproved =>
      'You are not approved. Please contact your company.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get noRecentLoads => 'No recent loads found.';

  @override
  String get load => 'Load';

  @override
  String get customer => 'Customer';

  @override
  String get status => 'Status';

  @override
  String get completed => 'Completed';

  @override
  String get pending => 'Pending';

  @override
  String get pickupInfo => 'Pickup Info';

  @override
  String get trailerUpload => 'Trailer Upload';

  @override
  String get deliveryInfo => 'Delivery Info';

  @override
  String get deliveryCompletedSnack => 'Delivery completed!';

  @override
  String get loadNumber => 'Load Number';

  @override
  String get pickupNumber => 'Pickup Number';

  @override
  String get noLoadDetails => 'No load details found.';

  @override
  String get loadDetails => 'Load Details';

  @override
  String get pickupDetails => 'Pickup Details';

  @override
  String get truckNumber => 'Truck Number';

  @override
  String get trailerNumber => 'Trailer Number';

  @override
  String get equipmentType => 'Equipment Type';

  @override
  String get equipmentTypeRequired => 'Equipment Type is required';

  @override
  String get customerRequired => 'Customer is required';

  @override
  String get orderNumber => 'Order Number';

  @override
  String get reeferPreCool => 'Reefer Pre-Cool (°F)';

  @override
  String get pickupInfoSaved => 'Pickup info saved';

  @override
  String get pickupInfoSavedTransit =>
      'Pickup info saved & status updated to In Transit';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String networkError(Object error) {
    return 'Network error: $error';
  }

  @override
  String get pictureUpload => 'Picture Upload';

  @override
  String get trailerPicture => 'Trailer Picture';

  @override
  String get pulp => 'Pulp';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get pulpPicture => 'Pulp Picture';

  @override
  String get pulpReason => 'If not, Why?';

  @override
  String get reeferPicture => 'Reefer Picture';

  @override
  String get loadSecurePicture => 'Load Secure Picture';

  @override
  String get sealedTrailerPicture => 'Sealed Trailer Picture';

  @override
  String get bol => 'BOL';

  @override
  String get reeferTempShipper => 'Reefer Temp (Set by Shipper)';

  @override
  String get reeferTempBol => 'Reefer Temp on BOL';

  @override
  String get temperatureUnit => 'Temperature Unit';

  @override
  String get sealNumber => 'Seal Number';

  @override
  String get pickupNotes => 'Pickup Notes';

  @override
  String get save => 'Save';

  @override
  String get sendPickupEmail => 'Send Pickup email';

  @override
  String get pickupEmailSuccess => 'Pickup email sent successfully!';

  @override
  String get pickupEmailFailed => 'Failed to send pickup email';

  @override
  String missingFields(Object fields) {
    return 'Please provide: $fields';
  }

  @override
  String get fillReeferTemp => 'Please fill Reefer temperatures';

  @override
  String get upload => 'Upload';

  @override
  String get addMoreFiles => 'Add More Files';

  @override
  String get failedToLoadFiles => 'Failed to load files';

  @override
  String errorLoadingFiles(Object error) {
    return 'Error loading files: $error';
  }

  @override
  String errorPickingImages(Object error) {
    return 'Error picking images: $error';
  }

  @override
  String pleaseProvide(Object fields) {
    return 'Please provide: $fields';
  }

  @override
  String get deliveryNumber => 'Delivery Number';

  @override
  String get enterDeliveryNumber => 'Please enter a Delivery Number';

  @override
  String get podFiles => 'POD Files';

  @override
  String get uploadAtLeastOnePod => 'Please upload at least one POD file';

  @override
  String get deliveryInfoSaved => 'Delivery info saved successfully';

  @override
  String get deliveryEmailSent => 'Delivery email sent successfully!';

  @override
  String get failedToLoadDeliveryInfo => 'Failed to load delivery info';

  @override
  String errorLoadingDeliveryInfo(Object error) {
    return 'Error loading delivery info: $error';
  }

  @override
  String get sendEmail => 'Send Email';

  @override
  String get notes => 'Notes';

  @override
  String get error => 'Error';

  @override
  String get tripCompleted => 'Trip Completed!';

  @override
  String get deliverySentSuccess =>
      'Delivery info has been sent successfully 🎉';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get status_in_transit => 'In Transit';

  @override
  String get status_pickup_completed => 'Pickup Completed';

  @override
  String get status_delivered => 'Delivered';

  @override
  String get myProfile => 'My Profile';

  @override
  String get fullName => 'Full Name';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get failedFetchProfile => 'Failed to fetch profile';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String fieldRequired(Object field) {
    return '$field is required';
  }

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get support => 'Support';

  @override
  String get security => 'Security';

  @override
  String get appInfo => 'App Info';

  @override
  String get viewUpdateDriverDetails => 'View/update driver details';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get darkModeFontSize => 'Dark mode, font size';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get contactDispatcherHotlineFaq => 'Contact dispatcher, hotline, FAQ';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get managePermissions => 'Manage permissions';

  @override
  String get aboutApp => 'About App';

  @override
  String get versionCompanyContact => 'Version info, company contact';

  @override
  String get logout => 'Logout';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get fontSize => 'Font Size';

  @override
  String get language => 'Language';
}
