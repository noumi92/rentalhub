import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

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
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RentalHub Pakistan'**
  String get appTitle;

  /// No description provided for @appStartFailed.
  ///
  /// In en, this message translates to:
  /// **'RentalHub couldn\'t start. Please restart the app and try again.'**
  String get appStartFailed;

  /// No description provided for @blacklist.
  ///
  /// In en, this message translates to:
  /// **'Blacklist Reports'**
  String get blacklist;

  /// No description provided for @fixedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Fixed Routes'**
  String get fixedRoutes;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get quickLinks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Shop Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, theme and your showroom'**
  String get settingsSubtitle;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Your showroom'**
  String get shop;

  /// No description provided for @shopNotSet.
  ///
  /// In en, this message translates to:
  /// **'Shop name not set yet'**
  String get shopNotSet;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @ownerSignOutError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Please try again.'**
  String get ownerSignOutError;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @whatsappLogs.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Logs'**
  String get whatsappLogs;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @customerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings & Preferences'**
  String get customerSettings;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @whatsappNotifications.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Notifications'**
  String get whatsappNotifications;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @disputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get disputes;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get statusOnTrip;

  /// No description provided for @statusProofSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted'**
  String get statusProofSubmitted;

  /// No description provided for @statusRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get statusRequestSent;

  /// No description provided for @statusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get statusPendingReview;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get inReview;

  /// No description provided for @disputeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get disputeOpen;

  /// No description provided for @disputeResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get disputeResolved;

  /// No description provided for @disputeDecisionChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a decision'**
  String get disputeDecisionChoose;

  /// No description provided for @disputeDecisionRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a decision before saving.'**
  String get disputeDecisionRequired;

  /// No description provided for @disputeDecisionFullToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Full refund to customer'**
  String get disputeDecisionFullToCustomer;

  /// No description provided for @disputeDecisionPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial — split'**
  String get disputeDecisionPartial;

  /// No description provided for @disputeDecisionFullToOwner.
  ///
  /// In en, this message translates to:
  /// **'Full to owner (claim upheld)'**
  String get disputeDecisionFullToOwner;

  /// No description provided for @disputeDecisionAmount.
  ///
  /// In en, this message translates to:
  /// **'Decision amount'**
  String get disputeDecisionAmount;

  /// No description provided for @disputeDecisionNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note'**
  String get disputeDecisionNote;

  /// No description provided for @disputeMarkInReview.
  ///
  /// In en, this message translates to:
  /// **'Mark in review'**
  String get disputeMarkInReview;

  /// No description provided for @disputeMarkedInReview.
  ///
  /// In en, this message translates to:
  /// **'Marked in review.'**
  String get disputeMarkedInReview;

  /// No description provided for @disputeMarkInReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark the dispute in review.'**
  String get disputeMarkInReviewFailed;

  /// No description provided for @handoverPhotoFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get handoverPhotoFront;

  /// No description provided for @handoverPhotoBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get handoverPhotoBack;

  /// No description provided for @handoverPhotoLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get handoverPhotoLeft;

  /// No description provided for @handoverPhotoRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get handoverPhotoRight;

  /// No description provided for @handoverDocumentsGiven.
  ///
  /// In en, this message translates to:
  /// **'Documents given'**
  String get handoverDocumentsGiven;

  /// No description provided for @handoverAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get handoverAccessories;

  /// No description provided for @handoverKeysHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Keys handed over'**
  String get handoverKeysHandedOver;

  /// No description provided for @handoverKeysNotHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Keys not handed over'**
  String get handoverKeysNotHandedOver;

  /// No description provided for @returnChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Return checklist'**
  String get returnChecklistTitle;

  /// No description provided for @returnChecklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No return record yet — the vehicle has not been returned through the settlement flow.'**
  String get returnChecklistEmpty;

  /// No description provided for @returnCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get returnCondition;

  /// No description provided for @returnOdometer.
  ///
  /// In en, this message translates to:
  /// **'Return odometer'**
  String get returnOdometer;

  /// No description provided for @returnDamageNotes.
  ///
  /// In en, this message translates to:
  /// **'Return damage notes'**
  String get returnDamageNotes;

  /// No description provided for @returnRemainingCollected.
  ///
  /// In en, this message translates to:
  /// **'Remaining rent collected'**
  String get returnRemainingCollected;

  /// No description provided for @returnNetRefund.
  ///
  /// In en, this message translates to:
  /// **'Net refund'**
  String get returnNetRefund;

  /// No description provided for @returnPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get returnPaymentMethod;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @rentedOut.
  ///
  /// In en, this message translates to:
  /// **'Rented Out'**
  String get rentedOut;

  /// No description provided for @inMaintenance.
  ///
  /// In en, this message translates to:
  /// **'In Maintenance'**
  String get inMaintenance;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNow;

  /// No description provided for @selfDrive.
  ///
  /// In en, this message translates to:
  /// **'Self Drive'**
  String get selfDrive;

  /// No description provided for @withDriver.
  ///
  /// In en, this message translates to:
  /// **'With Driver'**
  String get withDriver;

  /// No description provided for @withChauffeur.
  ///
  /// In en, this message translates to:
  /// **'With Chauffeur'**
  String get withChauffeur;

  /// No description provided for @selfDriveHyphen.
  ///
  /// In en, this message translates to:
  /// **'Self-Drive'**
  String get selfDriveHyphen;

  /// No description provided for @inCity.
  ///
  /// In en, this message translates to:
  /// **'In city'**
  String get inCity;

  /// No description provided for @withinCity.
  ///
  /// In en, this message translates to:
  /// **'Within city'**
  String get withinCity;

  /// No description provided for @outOfCity.
  ///
  /// In en, this message translates to:
  /// **'Out of city'**
  String get outOfCity;

  /// No description provided for @inCityHyphen.
  ///
  /// In en, this message translates to:
  /// **'In-City'**
  String get inCityHyphen;

  /// No description provided for @outOfCityHyphen.
  ///
  /// In en, this message translates to:
  /// **'Out-of-City'**
  String get outOfCityHyphen;

  /// No description provided for @supportUrgencyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get supportUrgencyLow;

  /// No description provided for @supportUrgencyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get supportUrgencyMedium;

  /// No description provided for @supportUrgencyHigh.
  ///
  /// In en, this message translates to:
  /// **'High — urgent'**
  String get supportUrgencyHigh;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @viewFleet.
  ///
  /// In en, this message translates to:
  /// **'View Fleet'**
  String get viewFleet;

  /// No description provided for @showroomLabel.
  ///
  /// In en, this message translates to:
  /// **'Showroom'**
  String get showroomLabel;

  /// No description provided for @rentalCar.
  ///
  /// In en, this message translates to:
  /// **'Rental Car'**
  String get rentalCar;

  /// No description provided for @rentalShowroom.
  ///
  /// In en, this message translates to:
  /// **'Rental Showroom'**
  String get rentalShowroom;

  /// No description provided for @summaryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get summaryVehicle;

  /// No description provided for @packageLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packageLabel;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickupLabel;

  /// No description provided for @summaryReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get summaryReturn;

  /// No description provided for @summaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summaryTotal;

  /// No description provided for @summaryTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get summaryTrip;

  /// No description provided for @summaryMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get summaryMode;

  /// No description provided for @summaryPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get summaryPlate;

  /// No description provided for @summaryRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get summaryRemaining;

  /// No description provided for @packageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get packageContinue;

  /// No description provided for @kycUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get kycUpload;

  /// No description provided for @kycEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get kycEncrypted;

  /// No description provided for @kycCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get kycCustomer;

  /// No description provided for @walletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletLabel;

  /// No description provided for @profileGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuest;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeSwitchToMap.
  ///
  /// In en, this message translates to:
  /// **'Switch to Interactive Map'**
  String get homeSwitchToMap;

  /// No description provided for @homeFindingShops.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby shops…'**
  String get homeFindingShops;

  /// No description provided for @homeNearbyShowrooms.
  ///
  /// In en, this message translates to:
  /// **'Nearby Showrooms'**
  String get homeNearbyShowrooms;

  /// No description provided for @homeMyLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'My Live Location'**
  String get homeMyLiveLocation;

  /// No description provided for @homeSwitchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to List View'**
  String get homeSwitchToList;

  /// No description provided for @locationSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Rental Location'**
  String get locationSetTitle;

  /// No description provided for @locationCenterPin.
  ///
  /// In en, this message translates to:
  /// **'Center Location Pin'**
  String get locationCenterPin;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Tap a city to explore.'**
  String get locationPermissionDenied;

  /// No description provided for @locationEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS / Location Services on your device.'**
  String get locationEnableGps;

  /// No description provided for @locationSelectCityManually.
  ///
  /// In en, this message translates to:
  /// **'Select City Manually (Lahore)'**
  String get locationSelectCityManually;

  /// No description provided for @locationAllowWhileUsing.
  ///
  /// In en, this message translates to:
  /// **'Allow While Using App'**
  String get locationAllowWhileUsing;

  /// No description provided for @locationEnablePrecise.
  ///
  /// In en, this message translates to:
  /// **'Enable Precise Location'**
  String get locationEnablePrecise;

  /// No description provided for @locationPermissionExplainer.
  ///
  /// In en, this message translates to:
  /// **'RentalHub uses your real-time GPS coordinates to calculate road distances and discover verified rental showrooms within 1–5 km around you in Pakistan.'**
  String get locationPermissionExplainer;

  /// No description provided for @emptyRadarExpandHint.
  ///
  /// In en, this message translates to:
  /// **'Expand your GPS discovery radius to 5 km to view accredited showrooms nearby.'**
  String get emptyRadarExpandHint;

  /// No description provided for @emptyRadarExpandToKm.
  ///
  /// In en, this message translates to:
  /// **'Expand to {radius} km'**
  String emptyRadarExpandToKm(int radius);

  /// No description provided for @emptyRadarNoShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'No rental shops near you yet'**
  String get emptyRadarNoShopsTitle;

  /// No description provided for @emptyRadarNoShopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different area or browse all shops.'**
  String get emptyRadarNoShopsSubtitle;

  /// No description provided for @emptyRadarBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all shops'**
  String get emptyRadarBrowseAll;

  /// No description provided for @noShopsBanner.
  ///
  /// In en, this message translates to:
  /// **'No verified showrooms within this radius yet. Try a wider radius.'**
  String get noShopsBanner;

  /// No description provided for @radiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius:'**
  String get radiusLabel;

  /// No description provided for @quickBookCar.
  ///
  /// In en, this message translates to:
  /// **'Book a Car'**
  String get quickBookCar;

  /// No description provided for @quickMyReservations.
  ///
  /// In en, this message translates to:
  /// **'My Reservations'**
  String get quickMyReservations;

  /// No description provided for @quickNearbyShops.
  ///
  /// In en, this message translates to:
  /// **'Nearby Shops'**
  String get quickNearbyShops;

  /// No description provided for @shopCarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Fleet'**
  String get shopCarsTitle;

  /// No description provided for @shopCarsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading available cars…'**
  String get shopCarsLoading;

  /// No description provided for @shopCarsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this showroom’s cars. Check your connection and try again.'**
  String get shopCarsLoadError;

  /// No description provided for @shopCarsTryOther.
  ///
  /// In en, this message translates to:
  /// **'Try a different category, or check back later.'**
  String get shopCarsTryOther;

  /// No description provided for @shopSave.
  ///
  /// In en, this message translates to:
  /// **'Save showroom'**
  String get shopSave;

  /// No description provided for @shopSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get shopSaved;

  /// No description provided for @shopSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save this showroom.'**
  String get shopSaveError;

  /// No description provided for @shopSaveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save showrooms.'**
  String get shopSaveSignIn;

  /// No description provided for @shopNoCars.
  ///
  /// In en, this message translates to:
  /// **'This shop has no cars listed yet.'**
  String get shopNoCars;

  /// No description provided for @shopCheckLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later, or browse other showrooms.'**
  String get shopCheckLater;

  /// No description provided for @shopLoadingCars.
  ///
  /// In en, this message translates to:
  /// **'Loading this showroom’s cars…'**
  String get shopLoadingCars;

  /// No description provided for @shopViewAllCars.
  ///
  /// In en, this message translates to:
  /// **'View all cars with filters'**
  String get shopViewAllCars;

  /// No description provided for @vehicleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get vehicleCapacity;

  /// No description provided for @vehicleFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get vehicleFuelType;

  /// No description provided for @vehicleMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get vehicleMileage;

  /// No description provided for @vehicleTransmission.
  ///
  /// In en, this message translates to:
  /// **'Transmission'**
  String get vehicleTransmission;

  /// No description provided for @vehicleChoosePackage.
  ///
  /// In en, this message translates to:
  /// **'Choose Rental Package'**
  String get vehicleChoosePackage;

  /// No description provided for @couldNotOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get couldNotOpenWhatsapp;

  /// No description provided for @couldNotCall.
  ///
  /// In en, this message translates to:
  /// **'Could not place the call.'**
  String get couldNotCall;

  /// No description provided for @shopNoWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'This shop has no WhatsApp number listed.'**
  String get shopNoWhatsapp;

  /// No description provided for @shopNoWhatsappShowroom.
  ///
  /// In en, this message translates to:
  /// **'This showroom has no WhatsApp number listed.'**
  String get shopNoWhatsappShowroom;

  /// No description provided for @bookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reservations'**
  String get bookingsTitle;

  /// No description provided for @bookingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your reservations…'**
  String get bookingsLoading;

  /// No description provided for @bookingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your bookings. Check your connection and try again.'**
  String get bookingsLoadError;

  /// No description provided for @bookingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Bookings you make will appear here.'**
  String get bookingsEmptyHint;

  /// No description provided for @bookingsPayAdvance.
  ///
  /// In en, this message translates to:
  /// **'Pay Advance'**
  String get bookingsPayAdvance;

  /// No description provided for @bookingsViewPass.
  ///
  /// In en, this message translates to:
  /// **'View Pass'**
  String get bookingsViewPass;

  /// No description provided for @bookingsRateTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate Trip'**
  String get bookingsRateTrip;

  /// No description provided for @activeTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get activeTripTitle;

  /// No description provided for @countdownToPickup.
  ///
  /// In en, this message translates to:
  /// **'COUNTDOWN TO PICKUP'**
  String get countdownToPickup;

  /// No description provided for @timeUntilReturn.
  ///
  /// In en, this message translates to:
  /// **'TIME UNTIL RETURN'**
  String get timeUntilReturn;

  /// No description provided for @kmIncluded.
  ///
  /// In en, this message translates to:
  /// **'KM included'**
  String get kmIncluded;

  /// No description provided for @returnDue.
  ///
  /// In en, this message translates to:
  /// **'Return due'**
  String get returnDue;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Total fare'**
  String get totalFare;

  /// No description provided for @viewPickupPassQr.
  ///
  /// In en, this message translates to:
  /// **'View Pickup Pass (QR)'**
  String get viewPickupPassQr;

  /// No description provided for @viewPassQr.
  ///
  /// In en, this message translates to:
  /// **'View Pass / QR'**
  String get viewPassQr;

  /// No description provided for @activeRentalCar.
  ///
  /// In en, this message translates to:
  /// **'Active Rental Car'**
  String get activeRentalCar;

  /// No description provided for @handoverAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Handover at Pickup'**
  String get handoverAtPickup;

  /// No description provided for @odometerAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Odometer at pickup'**
  String get odometerAtPickup;

  /// No description provided for @fuelAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Fuel at pickup'**
  String get fuelAtPickup;

  /// No description provided for @damageNoted.
  ///
  /// In en, this message translates to:
  /// **'Damage noted'**
  String get damageNoted;

  /// No description provided for @handoverPendingNote.
  ///
  /// In en, this message translates to:
  /// **'The shop records the odometer and fuel level at handover — they will appear here once the car is handed over.'**
  String get handoverPendingNote;

  /// No description provided for @browseOtherShops.
  ///
  /// In en, this message translates to:
  /// **'Browse other shops'**
  String get browseOtherShops;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @fileDispute.
  ///
  /// In en, this message translates to:
  /// **'File a dispute'**
  String get fileDispute;

  /// No description provided for @rateThisTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get rateThisTrip;

  /// No description provided for @viewPickupPass.
  ///
  /// In en, this message translates to:
  /// **'View pickup pass'**
  String get viewPickupPass;

  /// No description provided for @summaryAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance paid'**
  String get summaryAdvancePaid;

  /// No description provided for @summaryAdvanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Advance required'**
  String get summaryAdvanceRequired;

  /// No description provided for @summaryDriveMode.
  ///
  /// In en, this message translates to:
  /// **'Drive mode'**
  String get summaryDriveMode;

  /// No description provided for @summaryPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup Time'**
  String get summaryPickupTime;

  /// No description provided for @summaryReturnDue.
  ///
  /// In en, this message translates to:
  /// **'Return Due'**
  String get summaryReturnDue;

  /// No description provided for @summaryPackageTier.
  ///
  /// In en, this message translates to:
  /// **'Package Tier'**
  String get summaryPackageTier;

  /// No description provided for @summaryKmIncluded.
  ///
  /// In en, this message translates to:
  /// **'KM Included'**
  String get summaryKmIncluded;

  /// No description provided for @summarySecurityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit'**
  String get summarySecurityDeposit;

  /// No description provided for @summaryTotalFare.
  ///
  /// In en, this message translates to:
  /// **'Total Rental Fare'**
  String get summaryTotalFare;

  /// No description provided for @summaryAdvancePayable.
  ///
  /// In en, this message translates to:
  /// **'Advance Payable'**
  String get summaryAdvancePayable;

  /// No description provided for @summaryBalanceAtHandover.
  ///
  /// In en, this message translates to:
  /// **'Balance at Handover'**
  String get summaryBalanceAtHandover;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Security Escrow'**
  String get walletTitle;

  /// No description provided for @walletActiveEscrow.
  ///
  /// In en, this message translates to:
  /// **'Total with shop: advances paid + deposit held'**
  String get walletActiveEscrow;

  /// No description provided for @walletAdvancesPaid.
  ///
  /// In en, this message translates to:
  /// **'Advances Paid'**
  String get walletAdvancesPaid;

  /// No description provided for @walletSecurityEscrow.
  ///
  /// In en, this message translates to:
  /// **'Security Escrow'**
  String get walletSecurityEscrow;

  /// No description provided for @walletLedger.
  ///
  /// In en, this message translates to:
  /// **'Transaction Ledger'**
  String get walletLedger;

  /// No description provided for @walletHideAmount.
  ///
  /// In en, this message translates to:
  /// **'Hide amount'**
  String get walletHideAmount;

  /// No description provided for @walletShowAmount.
  ///
  /// In en, this message translates to:
  /// **'Show amount'**
  String get walletShowAmount;

  /// No description provided for @walletHideBalance.
  ///
  /// In en, this message translates to:
  /// **'Hide balance'**
  String get walletHideBalance;

  /// No description provided for @walletShowBalance.
  ///
  /// In en, this message translates to:
  /// **'Show balance'**
  String get walletShowBalance;

  /// No description provided for @walletEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Advances and deposits will appear here.'**
  String get walletEmptyHint;

  /// No description provided for @walletLedgerEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Advances you pay and deposits you leave will appear here.'**
  String get walletLedgerEmptyHint;

  /// No description provided for @walletLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your wallet. Check your connection and try again.'**
  String get walletLoadError;

  /// No description provided for @walletLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your wallet…'**
  String get walletLoading;

  /// No description provided for @walletNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No wallet activity yet.'**
  String get walletNoActivity;

  /// No description provided for @profileTotalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get profileTotalTrips;

  /// No description provided for @profileTrustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get profileTrustScore;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get profileLoading;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get profileNotSignedIn;

  /// No description provided for @profileNotSignedInShort.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profileNotSignedInShort;

  /// No description provided for @profileSavedShops.
  ///
  /// In en, this message translates to:
  /// **'Saved Showrooms'**
  String get profileSavedShops;

  /// No description provided for @profileSavedShopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked rental agencies'**
  String get profileSavedShopsSubtitle;

  /// No description provided for @profileMyDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents (KYC)'**
  String get profileMyDocuments;

  /// No description provided for @profileKycSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CNIC Front/Back & Driving License'**
  String get profileKycSubtitle;

  /// No description provided for @profileSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Settings & Language'**
  String get profileSettingsLanguage;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English / Urdu, Notifications'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support & Settings'**
  String get profileSectionSupport;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get editFullName;

  /// No description provided for @editPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editPhone;

  /// No description provided for @editCnicOptional.
  ///
  /// In en, this message translates to:
  /// **'CNIC (optional)'**
  String get editCnicOptional;

  /// No description provided for @editEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get editEnterName;

  /// No description provided for @editSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get editSaveProfile;

  /// No description provided for @editSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get editSaving;

  /// No description provided for @cnicLabel.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get cnicLabel;

  /// No description provided for @cnicHide.
  ///
  /// In en, this message translates to:
  /// **'Hide CNIC'**
  String get cnicHide;

  /// No description provided for @cnicShow.
  ///
  /// In en, this message translates to:
  /// **'Show CNIC'**
  String get cnicShow;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @reputationTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trust & Reputation'**
  String get reputationTitle;

  /// No description provided for @reputationShopRatings.
  ///
  /// In en, this message translates to:
  /// **'Showroom Ratings of You'**
  String get reputationShopRatings;

  /// No description provided for @reputationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No showroom has rated you yet. Your reputation appears here after your first completed trip.'**
  String get reputationEmpty;

  /// No description provided for @reputationVisibleNote.
  ///
  /// In en, this message translates to:
  /// **'Showrooms see these ratings when they review your booking requests.'**
  String get reputationVisibleNote;

  /// No description provided for @reputationPunctuality.
  ///
  /// In en, this message translates to:
  /// **'On-Time Handover Punctuality'**
  String get reputationPunctuality;

  /// No description provided for @reputationVehicleCare.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Care & Cleanliness'**
  String get reputationVehicleCare;

  /// No description provided for @reputationStaffBehavior.
  ///
  /// In en, this message translates to:
  /// **'Staff Interaction & Behavior'**
  String get reputationStaffBehavior;

  /// No description provided for @reputationTrustScoreDash.
  ///
  /// In en, this message translates to:
  /// **'Trust Score: —'**
  String get reputationTrustScoreDash;

  /// No description provided for @disputesMyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Disputes'**
  String get disputesMyTitle;

  /// No description provided for @disputesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No disputes filed yet.'**
  String get disputesEmpty;

  /// No description provided for @savedShopsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved showrooms yet.'**
  String get savedShopsEmpty;

  /// No description provided for @savedShopsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any showroom to save it here.'**
  String get savedShopsEmptyHint;

  /// No description provided for @savedShopsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get savedShopsRemove;

  /// No description provided for @savedShopsRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this showroom.'**
  String get savedShopsRemoveError;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support Center'**
  String get supportTitle;

  /// No description provided for @supportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search help'**
  String get supportSearchHint;

  /// No description provided for @supportCallShop.
  ///
  /// In en, this message translates to:
  /// **'Call your showroom'**
  String get supportCallShop;

  /// No description provided for @supportWhatsappShop.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp your showroom'**
  String get supportWhatsappShop;

  /// No description provided for @supportNoBooking.
  ///
  /// In en, this message translates to:
  /// **'No booking yet'**
  String get supportNoBooking;

  /// No description provided for @supportNoBookingHint.
  ///
  /// In en, this message translates to:
  /// **'No booking yet — the showroom contact appears here once you have a booking.'**
  String get supportNoBookingHint;

  /// No description provided for @supportFileDispute.
  ///
  /// In en, this message translates to:
  /// **'File a Formal Complaint / Dispute'**
  String get supportFileDispute;

  /// No description provided for @supportDisputeHint.
  ///
  /// In en, this message translates to:
  /// **'Overcharged or deposit withheld? File an arbitration claim.'**
  String get supportDisputeHint;

  /// No description provided for @supportFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get supportFaqTitle;

  /// No description provided for @supportFaqEmpty.
  ///
  /// In en, this message translates to:
  /// **'No help topics match your search.'**
  String get supportFaqEmpty;

  /// No description provided for @supportFaqEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword, or ask your showroom directly.'**
  String get supportFaqEmptyHint;

  /// No description provided for @supportSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get supportSosTitle;

  /// No description provided for @supportSosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Police 15 · Rescue 1122 — one-tap emergency help.'**
  String get supportSosSubtitle;

  /// No description provided for @supportFaqQ1.
  ///
  /// In en, this message translates to:
  /// **'How does advance payment protect my booking?'**
  String get supportFaqQ1;

  /// No description provided for @supportFaqA1.
  ///
  /// In en, this message translates to:
  /// **'Your advance payment locks the vehicle exclusively for your scheduled time and guarantees showroom reservation. It is safely recorded and deducted from your final bill.'**
  String get supportFaqA1;

  /// No description provided for @supportFaqQ2.
  ///
  /// In en, this message translates to:
  /// **'When is my security deposit returned?'**
  String get supportFaqQ2;

  /// No description provided for @supportFaqA2.
  ///
  /// In en, this message translates to:
  /// **'The deposit is settled at return handover. Any deduction for excess kilometres, fuel or damage is shown on the settlement, and the rest is released to you.'**
  String get supportFaqA2;

  /// No description provided for @supportFaqQ3.
  ///
  /// In en, this message translates to:
  /// **'What happens if a vehicle breaks down?'**
  String get supportFaqQ3;

  /// No description provided for @supportFaqA3.
  ///
  /// In en, this message translates to:
  /// **'Roadside help depends on the showroom — ask yours when you pick up the car. For an emergency, use the Emergency SOS screen.'**
  String get supportFaqA3;

  /// No description provided for @supportFaqQ4.
  ///
  /// In en, this message translates to:
  /// **'Can I take the rental car out of city?'**
  String get supportFaqQ4;

  /// No description provided for @supportFaqA4.
  ///
  /// In en, this message translates to:
  /// **'Yes, out-of-city packages are available. Select the \"Out of City\" tier or inform the showroom beforehand to ensure tracker clearance.'**
  String get supportFaqA4;

  /// No description provided for @supportMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Support'**
  String get supportMessageTitle;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. Our team will reach you on WhatsApp — replies do not appear in the app yet.'**
  String get supportMessageHint;

  /// No description provided for @supportUrgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'How urgent is this?'**
  String get supportUrgencyLabel;

  /// No description provided for @supportSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get supportSendMessage;

  /// No description provided for @supportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get supportSending;

  /// No description provided for @supportWriteFirst.
  ///
  /// In en, this message translates to:
  /// **'Please write your message first.'**
  String get supportWriteFirst;

  /// No description provided for @supportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent. Our team will contact you on WhatsApp.'**
  String get supportMessageSent;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS Assistance'**
  String get sosTitle;

  /// No description provided for @sosPress.
  ///
  /// In en, this message translates to:
  /// **'Press SOS in Emergency'**
  String get sosPress;

  /// No description provided for @sosExplainer.
  ///
  /// In en, this message translates to:
  /// **'The SOS button calls Police 15. You can also call Rescue 1122 or share your live location with your showroom.'**
  String get sosExplainer;

  /// No description provided for @sosCallPolice.
  ///
  /// In en, this message translates to:
  /// **'Call Police 15'**
  String get sosCallPolice;

  /// No description provided for @sosCallRescue.
  ///
  /// In en, this message translates to:
  /// **'Call Rescue 1122'**
  String get sosCallRescue;

  /// No description provided for @sosCallPoliceEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call Police Emergency 15'**
  String get sosCallPoliceEmergency;

  /// No description provided for @sosCallPoliceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Call Police 15?'**
  String get sosCallPoliceConfirm;

  /// No description provided for @sosCallPoliceConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'This dials the police emergency number (15). Use it only in a real emergency.'**
  String get sosCallPoliceConfirmHint;

  /// No description provided for @sosPoliceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Punjab & Federal Police helpline'**
  String get sosPoliceSubtitle;

  /// No description provided for @sosRescueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ambulance, fire and rescue services'**
  String get sosRescueSubtitle;

  /// No description provided for @sosPolice.
  ///
  /// In en, this message translates to:
  /// **'Police 15'**
  String get sosPolice;

  /// No description provided for @sosRescue.
  ///
  /// In en, this message translates to:
  /// **'Rescue 1122'**
  String get sosRescue;

  /// No description provided for @sosShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Live Location via WhatsApp'**
  String get sosShareLocation;

  /// No description provided for @sosSendToShop.
  ///
  /// In en, this message translates to:
  /// **'Send your live location to your showroom'**
  String get sosSendToShop;

  /// No description provided for @sosNoBookingHint.
  ///
  /// In en, this message translates to:
  /// **'No booking yet — your live location is shared with your showroom once you have a booking.'**
  String get sosNoBookingHint;

  /// No description provided for @sosLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to share your live location.'**
  String get sosLocationPermission;

  /// No description provided for @disputeTitle.
  ///
  /// In en, this message translates to:
  /// **'File Complaint / Dispute'**
  String get disputeTitle;

  /// No description provided for @disputeDepositWithheld.
  ///
  /// In en, this message translates to:
  /// **'Deposit Withheld'**
  String get disputeDepositWithheld;

  /// No description provided for @disputeOvercharge.
  ///
  /// In en, this message translates to:
  /// **'Showroom Overcharge'**
  String get disputeOvercharge;

  /// No description provided for @disputeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Breakdown Delay'**
  String get disputeBreakdown;

  /// No description provided for @disputeDamagePenalty.
  ///
  /// In en, this message translates to:
  /// **'Unfair Damage Penalty'**
  String get disputeDamagePenalty;

  /// No description provided for @disputeRudeStaff.
  ///
  /// In en, this message translates to:
  /// **'Rude / Unprofessional Staff'**
  String get disputeRudeStaff;

  /// No description provided for @disputeSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Dispute Category'**
  String get disputeSelectCategory;

  /// No description provided for @disputeBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID / Reference'**
  String get disputeBookingId;

  /// No description provided for @disputeBookingIdHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. RH-849201'**
  String get disputeBookingIdHint;

  /// No description provided for @disputeDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed Explanation'**
  String get disputeDetailsLabel;

  /// No description provided for @disputeDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened with dates, amounts, and showroom staff names...'**
  String get disputeDetailsHint;

  /// No description provided for @disputeRecordedNote.
  ///
  /// In en, this message translates to:
  /// **'Your dispute is recorded and shared with the showroom for review. There is no fixed resolution time yet.'**
  String get disputeRecordedNote;

  /// No description provided for @disputeEnterBookingId.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Booking ID.'**
  String get disputeEnterBookingId;

  /// No description provided for @disputeExplainIssue.
  ///
  /// In en, this message translates to:
  /// **'Please explain the issue encountered.'**
  String get disputeExplainIssue;

  /// No description provided for @disputeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Claim'**
  String get disputeSubmit;

  /// No description provided for @disputeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting Dispute...'**
  String get disputeSubmitting;

  /// No description provided for @disputeFiled.
  ///
  /// In en, this message translates to:
  /// **'Dispute filed. The showroom can see it in their disputes inbox.'**
  String get disputeFiled;

  /// No description provided for @disputeFiledAgo.
  ///
  /// In en, this message translates to:
  /// **'Filed {time} ago'**
  String disputeFiledAgo(String time);

  /// No description provided for @disputeSlaLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String disputeSlaLeft(String time);

  /// No description provided for @disputeSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Dispute saved on this device — it will reach the showroom once you are back online.'**
  String get disputeSavedOffline;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for Cancellation'**
  String get cancelReasonLabel;

  /// No description provided for @cancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reservation'**
  String get cancelTitle;

  /// No description provided for @cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get cancelConfirm;

  /// No description provided for @cancelCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelCancelling;

  /// No description provided for @cancelWhatHappens.
  ///
  /// In en, this message translates to:
  /// **'What happens when you cancel'**
  String get cancelWhatHappens;

  /// No description provided for @cancelNoAdvanceNote.
  ///
  /// In en, this message translates to:
  /// **'No advance has been paid yet, so there is nothing to refund. No security deposit was collected: deposits are only taken at handover.'**
  String get cancelNoAdvanceNote;

  /// No description provided for @cancelDone.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled.'**
  String get cancelDone;

  /// No description provided for @cancelReasonPlans.
  ///
  /// In en, this message translates to:
  /// **'Change of travel plans'**
  String get cancelReasonPlans;

  /// No description provided for @cancelReasonOtherVehicle.
  ///
  /// In en, this message translates to:
  /// **'Found another vehicle'**
  String get cancelReasonOtherVehicle;

  /// No description provided for @cancelReasonShopDelay.
  ///
  /// In en, this message translates to:
  /// **'Showroom delay in approval'**
  String get cancelReasonShopDelay;

  /// No description provided for @cancelReasonEmergency.
  ///
  /// In en, this message translates to:
  /// **'Unexpected emergency'**
  String get cancelReasonEmergency;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get cancelReasonOther;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateTitle;

  /// No description provided for @rateVehicleCondition.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Condition & Cleanliness'**
  String get rateVehicleCondition;

  /// No description provided for @rateVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'AC cooling, tires, interior, mechanical health'**
  String get rateVehicleHint;

  /// No description provided for @rateShopService.
  ///
  /// In en, this message translates to:
  /// **'Showroom Service Quality'**
  String get rateShopService;

  /// No description provided for @rateShopHint.
  ///
  /// In en, this message translates to:
  /// **'Handover speed, staff behavior, transparency'**
  String get rateShopHint;

  /// No description provided for @rateFeedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Feedback (Optional)'**
  String get rateFeedbackLabel;

  /// No description provided for @rateFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share any highlights or suggestions for future renters...'**
  String get rateFeedbackHint;

  /// No description provided for @rateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Trip Review'**
  String get rateSubmit;

  /// No description provided for @rateSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get rateSubmitting;

  /// No description provided for @rateSaved.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your review is saved for this trip.'**
  String get rateSaved;

  /// No description provided for @rateAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'You already rated this trip — your review is shown below.'**
  String get rateAlreadyRated;

  /// No description provided for @rateEditRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin asked you to edit this review'**
  String get rateEditRequestedTitle;

  /// No description provided for @rateWarnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning from the admin about this review'**
  String get rateWarnedTitle;

  /// No description provided for @adminAnncDeliveredNotTracked.
  ///
  /// In en, this message translates to:
  /// **'Delivered: not tracked yet'**
  String get adminAnncDeliveredNotTracked;

  /// No description provided for @adminAnncScheduleDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time for the scheduled announcement.'**
  String get adminAnncScheduleDateRequired;

  /// No description provided for @rateSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device — it will sync when you are back online.'**
  String get rateSavedOffline;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Reservation'**
  String get reviewTitle;

  /// No description provided for @reviewSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions for Showroom'**
  String get reviewSpecialInstructions;

  /// No description provided for @reviewInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Clean car required, airport terminal pickup...'**
  String get reviewInstructionsHint;

  /// No description provided for @reviewSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request to Owner'**
  String get reviewSendRequest;

  /// No description provided for @reviewSending.
  ///
  /// In en, this message translates to:
  /// **'Sending Request...'**
  String get reviewSending;

  /// No description provided for @reviewSent.
  ///
  /// In en, this message translates to:
  /// **'Reservation request sent to showroom!'**
  String get reviewSent;

  /// No description provided for @approvedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Approved!'**
  String get approvedTitle;

  /// No description provided for @approvedReadyAdvance.
  ///
  /// In en, this message translates to:
  /// **'Ready for Advance Payment'**
  String get approvedReadyAdvance;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Sent Successfully!'**
  String get successTitle;

  /// No description provided for @successTransmitted.
  ///
  /// In en, this message translates to:
  /// **'Request Transmitted'**
  String get successTransmitted;

  /// No description provided for @successAdvanceDue.
  ///
  /// In en, this message translates to:
  /// **'Advance Due Upon Approval:'**
  String get successAdvanceDue;

  /// No description provided for @successShopStatus.
  ///
  /// In en, this message translates to:
  /// **'Showroom Status:'**
  String get successShopStatus;

  /// No description provided for @successMessageShop.
  ///
  /// In en, this message translates to:
  /// **'Message Showroom on WhatsApp'**
  String get successMessageShop;

  /// No description provided for @successViewPayment.
  ///
  /// In en, this message translates to:
  /// **'View Payment Details / Status'**
  String get successViewPayment;

  /// No description provided for @successBackToBookings.
  ///
  /// In en, this message translates to:
  /// **'Return to My Bookings'**
  String get successBackToBookings;

  /// No description provided for @paymentAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Showroom Payment Accounts'**
  String get paymentAccountsTitle;

  /// No description provided for @paymentAccountsDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct Transfer Channels'**
  String get paymentAccountsDirect;

  /// No description provided for @paymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentBankTransfer;

  /// No description provided for @paymentJazzcash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get paymentJazzcash;

  /// No description provided for @paymentEasypaisa.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa'**
  String get paymentEasypaisa;

  /// No description provided for @paymentVerified.
  ///
  /// In en, this message translates to:
  /// **'RentalHub Verified'**
  String get paymentVerified;

  /// No description provided for @paymentApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservation Request Approved!'**
  String get paymentApprovedTitle;

  /// No description provided for @paymentPayHint.
  ///
  /// In en, this message translates to:
  /// **'Pay to the verified showroom accounts below and capture a screenshot of your transfer.'**
  String get paymentPayHint;

  /// No description provided for @paymentNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No payment accounts configured for this shop yet.'**
  String get paymentNoAccounts;

  /// No description provided for @paymentAddAccountsNote.
  ///
  /// In en, this message translates to:
  /// **'Add JazzCash, EasyPaisa or bank accounts in Shop Settings so customers know where to pay.'**
  String get paymentAddAccountsNote;

  /// No description provided for @paymentLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading payment accounts…'**
  String get paymentLoading;

  /// No description provided for @paymentUploadProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Proof & Receipt'**
  String get paymentUploadProof;

  /// No description provided for @proofSelectedCar.
  ///
  /// In en, this message translates to:
  /// **'Selected Car'**
  String get proofSelectedCar;

  /// No description provided for @proofScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Proof Screenshot'**
  String get proofScreenshot;

  /// No description provided for @proofTidLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction Reference / TID'**
  String get proofTidLabel;

  /// No description provided for @proofTidHint.
  ///
  /// In en, this message translates to:
  /// **'Enter JazzCash / Bank TID (e.g. 892019281)'**
  String get proofTidHint;

  /// No description provided for @proofAttachFirst.
  ///
  /// In en, this message translates to:
  /// **'Please attach your payment screenshot or receipt.'**
  String get proofAttachFirst;

  /// No description provided for @proofEnterTid.
  ///
  /// In en, this message translates to:
  /// **'Please enter the transaction reference / TID.'**
  String get proofEnterTid;

  /// No description provided for @proofSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Payment Proof'**
  String get proofSubmit;

  /// No description provided for @proofUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading Proof...'**
  String get proofUploading;

  /// No description provided for @proofSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted! Waiting for showroom confirmation.'**
  String get proofSubmitted;

  /// No description provided for @proofSubmittedOffline.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted! Receipt will sync when you are back online.'**
  String get proofSubmittedOffline;

  /// No description provided for @proofPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Proof is uploaded to private storage. The showroom checks it and confirms your booking, and you will be notified in the app when it is confirmed. If you do not hear back, message the shop on WhatsApp.'**
  String get proofPrivateNote;

  /// No description provided for @passTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup Countdown Pass'**
  String get passTitle;

  /// No description provided for @passDoneHome.
  ///
  /// In en, this message translates to:
  /// **'Done • Back to Home'**
  String get passDoneHome;

  /// No description provided for @passRentalVehicle.
  ///
  /// In en, this message translates to:
  /// **'Rental Vehicle'**
  String get passRentalVehicle;

  /// No description provided for @passPickupTarget.
  ///
  /// In en, this message translates to:
  /// **'Pickup Target:'**
  String get passPickupTarget;

  /// No description provided for @passShowQr.
  ///
  /// In en, this message translates to:
  /// **'Present this QR Code to showroom staff at handover'**
  String get passShowQr;

  /// No description provided for @countdownHours.
  ///
  /// In en, this message translates to:
  /// **'HRS'**
  String get countdownHours;

  /// No description provided for @countdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get countdownMinutes;

  /// No description provided for @countdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'SEC'**
  String get countdownSeconds;

  /// No description provided for @packageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Rental Package'**
  String get packageSelectTitle;

  /// No description provided for @packageTiersTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Duration Tiers'**
  String get packageTiersTitle;

  /// No description provided for @pkg1h.
  ///
  /// In en, this message translates to:
  /// **'1-Hour City Commute'**
  String get pkg1h;

  /// No description provided for @pkg3h.
  ///
  /// In en, this message translates to:
  /// **'3-Hour Quick Trip'**
  String get pkg3h;

  /// No description provided for @pkg6h.
  ///
  /// In en, this message translates to:
  /// **'6-Hour Express'**
  String get pkg6h;

  /// No description provided for @pkg12h.
  ///
  /// In en, this message translates to:
  /// **'12-Hour Half Day'**
  String get pkg12h;

  /// No description provided for @pkgDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily 24-Hours'**
  String get pkgDaily;

  /// No description provided for @pkgWeeklyPackage.
  ///
  /// In en, this message translates to:
  /// **'Weekly Package'**
  String get pkgWeeklyPackage;

  /// No description provided for @pkg1hDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick city hops'**
  String get pkg1hDesc;

  /// No description provided for @pkg3hDesc.
  ///
  /// In en, this message translates to:
  /// **'Airport drop/pickup & short commutes'**
  String get pkg3hDesc;

  /// No description provided for @pkg12hDesc.
  ///
  /// In en, this message translates to:
  /// **'Ideal for city errands, weddings & meetings'**
  String get pkg12hDesc;

  /// No description provided for @pkg6hDesc.
  ///
  /// In en, this message translates to:
  /// **'Half-day outings & events'**
  String get pkg6hDesc;

  /// No description provided for @pkgDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Full day flexibility with grace return period'**
  String get pkgDailyDesc;

  /// No description provided for @pkgWeeklyDesc.
  ///
  /// In en, this message translates to:
  /// **'Seven days, one price'**
  String get pkgWeeklyDesc;

  /// No description provided for @tripFixedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Fixed routes from this shop'**
  String get tripFixedRoutes;

  /// No description provided for @tripTrackerNote.
  ///
  /// In en, this message translates to:
  /// **'Tracker clearance required — the shop confirms it before pickup. If clearance is refused, the shop contacts you before pickup.'**
  String get tripTrackerNote;

  /// No description provided for @advanceNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Advance & Verification Notice'**
  String get advanceNoticeTitle;

  /// No description provided for @pickerPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get pickerPickupDate;

  /// No description provided for @pickerPickupSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pickup Schedule'**
  String get pickerPickupSchedule;

  /// No description provided for @pickerDuration.
  ///
  /// In en, this message translates to:
  /// **'Rental Duration'**
  String get pickerDuration;

  /// No description provided for @pickerIncreaseDays.
  ///
  /// In en, this message translates to:
  /// **'Increase rental days'**
  String get pickerIncreaseDays;

  /// No description provided for @pickerDecreaseDays.
  ///
  /// In en, this message translates to:
  /// **'Decrease rental days'**
  String get pickerDecreaseDays;

  /// No description provided for @proofCaptureCamera.
  ///
  /// In en, this message translates to:
  /// **'Capture Camera'**
  String get proofCaptureCamera;

  /// No description provided for @proofFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get proofFromGallery;

  /// No description provided for @proofScreenshotReady.
  ///
  /// In en, this message translates to:
  /// **'Screenshot Ready'**
  String get proofScreenshotReady;

  /// No description provided for @proofScreenshotSupport.
  ///
  /// In en, this message translates to:
  /// **'Support JPG, PNG receipt from banking app'**
  String get proofScreenshotSupport;

  /// No description provided for @proofUploadScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Upload Transfer Screenshot'**
  String get proofUploadScreenshot;

  /// No description provided for @paymentProofPayTo.
  ///
  /// In en, this message translates to:
  /// **'Pay to: {account}'**
  String paymentProofPayTo(String account);

  /// No description provided for @paymentAccountMobile.
  ///
  /// In en, this message translates to:
  /// **'Account / Mobile'**
  String get paymentAccountMobile;

  /// No description provided for @paymentAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Title'**
  String get paymentAccountTitle;

  /// No description provided for @paymentCopyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy Number'**
  String get paymentCopyNumber;

  /// No description provided for @paymentIban.
  ///
  /// In en, this message translates to:
  /// **'IBAN Number'**
  String get paymentIban;

  /// No description provided for @passCallShop.
  ///
  /// In en, this message translates to:
  /// **'Call Shop'**
  String get passCallShop;

  /// No description provided for @passDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get passDirections;

  /// No description provided for @passHandoverPoint.
  ///
  /// In en, this message translates to:
  /// **'Showroom Handover Point'**
  String get passHandoverPoint;

  /// No description provided for @passViewAgreement.
  ///
  /// In en, this message translates to:
  /// **'View Rental Agreement (PDF)'**
  String get passViewAgreement;

  /// No description provided for @passAgreementHint.
  ///
  /// In en, this message translates to:
  /// **'Your signed rental agreement will appear here after handover.'**
  String get passAgreementHint;

  /// No description provided for @passNoLocation.
  ///
  /// In en, this message translates to:
  /// **'This showroom has no location listed yet.'**
  String get passNoLocation;

  /// No description provided for @passNoPhone.
  ///
  /// In en, this message translates to:
  /// **'This showroom has no phone number listed.'**
  String get passNoPhone;

  /// No description provided for @passOpenMapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps.'**
  String get passOpenMapsError;

  /// No description provided for @passOpenAgreementError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the agreement.'**
  String get passOpenAgreementError;

  /// No description provided for @driverRequiresCnic.
  ///
  /// In en, this message translates to:
  /// **'Requires CNIC + Deposit'**
  String get driverRequiresCnic;

  /// No description provided for @driverVerifiedIncluded.
  ///
  /// In en, this message translates to:
  /// **'Verified Driver Included'**
  String get driverVerifiedIncluded;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RentalHub'**
  String get authWelcome;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to rent a car near you'**
  String get authSignInSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authSignInEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get authSignInEmail;

  /// No description provided for @authSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully!'**
  String get authSignedIn;

  /// No description provided for @authSignedInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google!'**
  String get authSignedInGoogle;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Authentication unavailable. Please try again later.'**
  String get authUnavailable;

  /// No description provided for @authValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authValidEmail;

  /// No description provided for @authPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordLength;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Pakistan Premier Car Rental & Fleet Ecosystem • خوش آمدید'**
  String get authTagline;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// No description provided for @onboardingStep1.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Your Profile'**
  String get onboardingStep1;

  /// No description provided for @onboardingEnterContact.
  ///
  /// In en, this message translates to:
  /// **'Enter your contact information'**
  String get onboardingEnterContact;

  /// No description provided for @onboardingFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get onboardingFullName;

  /// No description provided for @onboardingWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get onboardingWhatsappNumber;

  /// No description provided for @onboardingValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit number starting with 3 (e.g. 300 1234567)'**
  String get onboardingValidPhone;

  /// No description provided for @onboardingValidNamePhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid full name and Pakistani WhatsApp number (+92 3XX or 03XX).'**
  String get onboardingValidNamePhone;

  /// No description provided for @onboardingNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get onboardingNameRequired;

  /// No description provided for @onboardingNameLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get onboardingNameLength;

  /// No description provided for @onboardingPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number is required'**
  String get onboardingPhoneRequired;

  /// No description provided for @onboardingContinueRole.
  ///
  /// In en, this message translates to:
  /// **'Continue to Role Selection'**
  String get onboardingContinueRole;

  /// No description provided for @onboardingProfileVerified.
  ///
  /// In en, this message translates to:
  /// **'Profile details verified.'**
  String get onboardingProfileVerified;

  /// No description provided for @onboardingStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Account Role'**
  String get onboardingStep2;

  /// No description provided for @roleSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Permanent Account Role'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use RentalHub'**
  String get roleSelectSubtitle;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Rent a Vehicle (Customer)'**
  String get roleCustomer;

  /// No description provided for @roleCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer (Rent a Vehicle)'**
  String get roleCustomerTitle;

  /// No description provided for @roleCustomerDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover verified rental shops within 1–5 km, book Self-Drive or With-Driver packages.'**
  String get roleCustomerDesc;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Fleet Owner (Showroom)'**
  String get roleOwner;

  /// No description provided for @roleOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'List My Fleet (Shop Owner)'**
  String get roleOwnerTitle;

  /// No description provided for @roleOwnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Register your showroom, manage fleet rates, digital handovers, and RentalHub\'s shared blacklist.'**
  String get roleOwnerDesc;

  /// No description provided for @roleContinueCustomer.
  ///
  /// In en, this message translates to:
  /// **'Continue as Customer'**
  String get roleContinueCustomer;

  /// No description provided for @roleContinueOwner.
  ///
  /// In en, this message translates to:
  /// **'Continue as Fleet Owner'**
  String get roleContinueOwner;

  /// No description provided for @roleReview.
  ///
  /// In en, this message translates to:
  /// **'Review Selection'**
  String get roleReview;

  /// No description provided for @roleSecurityPolicy.
  ///
  /// In en, this message translates to:
  /// **'Security Policy: Role selection is strictly one-way and immutable once confirmed.'**
  String get roleSecurityPolicy;

  /// No description provided for @roleLockProceed.
  ///
  /// In en, this message translates to:
  /// **'Lock My Role & Proceed'**
  String get roleLockProceed;

  /// No description provided for @roleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Permanent Role'**
  String get roleConfirm;

  /// No description provided for @stepperProfile.
  ///
  /// In en, this message translates to:
  /// **'1. Profile Info'**
  String get stepperProfile;

  /// No description provided for @stepperRole.
  ///
  /// In en, this message translates to:
  /// **'2. Select Role'**
  String get stepperRole;

  /// No description provided for @avatarSelectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Profile Photo'**
  String get avatarSelectPhoto;

  /// No description provided for @avatarSetPicture.
  ///
  /// In en, this message translates to:
  /// **'Set Profile Picture'**
  String get avatarSetPicture;

  /// No description provided for @avatarChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get avatarChangePhoto;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get avatarTakePhoto;

  /// No description provided for @avatarFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get avatarFromGallery;

  /// No description provided for @kycTitle.
  ///
  /// In en, this message translates to:
  /// **'NADRA CNIC & Driving License KYC'**
  String get kycTitle;

  /// No description provided for @kycSubmittedNote.
  ///
  /// In en, this message translates to:
  /// **'KYC documents submitted — pending verification.'**
  String get kycSubmittedNote;

  /// No description provided for @kycVaultNote.
  ///
  /// In en, this message translates to:
  /// **'Private cPanel vault • شناختی کارڈ تصدیق'**
  String get kycVaultNote;

  /// No description provided for @kycStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted — pending verification'**
  String get kycStatusSubmitted;

  /// No description provided for @kycStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected — please resubmit'**
  String get kycStatusRejected;

  /// No description provided for @kycCnicNumber.
  ///
  /// In en, this message translates to:
  /// **'13-Digit NADRA CNIC Number'**
  String get kycCnicNumber;

  /// No description provided for @kycCnicRead.
  ///
  /// In en, this message translates to:
  /// **'CNIC number read from the card.'**
  String get kycCnicRead;

  /// No description provided for @kycHighResHint.
  ///
  /// In en, this message translates to:
  /// **'High-resolution scan with clear photo'**
  String get kycHighResHint;

  /// No description provided for @kycCnicBack.
  ///
  /// In en, this message translates to:
  /// **'NADRA CNIC — Back Side'**
  String get kycCnicBack;

  /// No description provided for @kycCnicFront.
  ///
  /// In en, this message translates to:
  /// **'NADRA CNIC — Front Side'**
  String get kycCnicFront;

  /// No description provided for @kycAttachBoth.
  ///
  /// In en, this message translates to:
  /// **'Please attach both front and back photos of your NADRA CNIC.'**
  String get kycAttachBoth;

  /// No description provided for @kycQrHint.
  ///
  /// In en, this message translates to:
  /// **'QR code & address clearly visible'**
  String get kycQrHint;

  /// No description provided for @kycSelfDriveNote.
  ///
  /// In en, this message translates to:
  /// **'Required for Self-Drive rental packages'**
  String get kycSelfDriveNote;

  /// No description provided for @kycScanCard.
  ///
  /// In en, this message translates to:
  /// **'Scan CNIC card'**
  String get kycScanCard;

  /// No description provided for @kycScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning card...'**
  String get kycScanning;

  /// No description provided for @kycSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit KYC Documents'**
  String get kycSubmit;

  /// No description provided for @kycUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get kycUploading;

  /// No description provided for @kycLicense.
  ///
  /// In en, this message translates to:
  /// **'Valid Pakistan Driving License (LTV/HTV)'**
  String get kycLicense;

  /// No description provided for @kycFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get kycFromGallery;

  /// No description provided for @kycTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get kycTakePhoto;

  /// No description provided for @settingsPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booking approvals and payment alerts'**
  String get settingsPushSubtitle;

  /// No description provided for @settingsWhatsappSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement and handover receipts'**
  String get settingsWhatsappSubtitle;

  /// No description provided for @settingsNotifNote.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences save to your profile once you have a customer record.'**
  String get settingsNotifNote;

  /// No description provided for @shopCategorySedan.
  ///
  /// In en, this message translates to:
  /// **'Sedan'**
  String get shopCategorySedan;

  /// No description provided for @shopCategorySuv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get shopCategorySuv;

  /// No description provided for @shopCategoryHiace.
  ///
  /// In en, this message translates to:
  /// **'Hiace'**
  String get shopCategoryHiace;

  /// No description provided for @shopCategoryLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get shopCategoryLuxury;

  /// No description provided for @summaryWithDriver.
  ///
  /// In en, this message translates to:
  /// **'With driver'**
  String get summaryWithDriver;

  /// No description provided for @summarySelfDrive.
  ///
  /// In en, this message translates to:
  /// **'Self drive'**
  String get summarySelfDrive;

  /// No description provided for @summaryDeclinedPrefix.
  ///
  /// In en, this message translates to:
  /// **'The shop declined this request: '**
  String get summaryDeclinedPrefix;

  /// No description provided for @proofRejectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Your payment proof was rejected — please upload a new one: '**
  String get proofRejectedPrefix;

  /// No description provided for @cancellationReasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason: '**
  String get cancellationReasonPrefix;

  /// No description provided for @proofWithShop.
  ///
  /// In en, this message translates to:
  /// **'Your payment proof is with the shop. You will see the pickup pass here once it is verified.'**
  String get proofWithShop;

  /// No description provided for @kycScanUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read a CNIC number from that photo — please type it.'**
  String get kycScanUnreadable;

  /// No description provided for @trustKycVerified.
  ///
  /// In en, this message translates to:
  /// **'KYC verified'**
  String get trustKycVerified;

  /// No description provided for @trustKycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC pending'**
  String get trustKycPending;

  /// No description provided for @trustBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Flagged on blacklist'**
  String get trustBlacklisted;

  /// No description provided for @trustNoBlacklist.
  ///
  /// In en, this message translates to:
  /// **'No blacklist record'**
  String get trustNoBlacklist;

  /// No description provided for @vehicleSelfDriveUrdu.
  ///
  /// In en, this message translates to:
  /// **'سیلف ڈرائیو'**
  String get vehicleSelfDriveUrdu;

  /// No description provided for @vehicleWithDriverUrdu.
  ///
  /// In en, this message translates to:
  /// **'ڈرائیور کے ساتھ'**
  String get vehicleWithDriverUrdu;

  /// No description provided for @roleCustomerUrdu.
  ///
  /// In en, this message translates to:
  /// **'گاڑی کرایہ پر لیں'**
  String get roleCustomerUrdu;

  /// No description provided for @roleOwnerUrdu.
  ///
  /// In en, this message translates to:
  /// **'شوروم رجسٹر کریں'**
  String get roleOwnerUrdu;

  /// No description provided for @advanceNoticeWithDriver.
  ///
  /// In en, this message translates to:
  /// **'• Chauffeur arrives at showroom/pickup point 15 mins early.\n• Advance payment confirms vehicle lock and fuel reservation.\n• Outstation overnight stay: {nightStay}/night driver food & lodge.'**
  String advanceNoticeWithDriver(String nightStay);

  /// No description provided for @advanceNoticeSelfDrive.
  ///
  /// In en, this message translates to:
  /// **'• Original NADRA CNIC & valid Driving License required at handover.\n• Advance confirms vehicle booking lock with showroom.\n• Refundable security deposit collected digitally or in cash at handover.'**
  String get advanceNoticeSelfDrive;

  /// No description provided for @ticketShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show this code at the counter for handover — it opens your booking and its agreement.'**
  String get ticketShowCode;

  /// No description provided for @bookingsEmptyForTab.
  ///
  /// In en, this message translates to:
  /// **'No {tab} bookings found.'**
  String bookingsEmptyForTab(String tab);

  /// No description provided for @shopCarsNoneInCategory.
  ///
  /// In en, this message translates to:
  /// **'No {category} vehicles available right now.'**
  String shopCarsNoneInCategory(String category);

  /// No description provided for @homeGpsActive.
  ///
  /// In en, this message translates to:
  /// **'{area} • GPS Active'**
  String homeGpsActive(String area);

  /// No description provided for @mapTapMarker.
  ///
  /// In en, this message translates to:
  /// **'{area} • Tap marker to preview'**
  String mapTapMarker(String area);

  /// No description provided for @mapGpsRadar.
  ///
  /// In en, this message translates to:
  /// **'GPS Radar: {km} km ({count} Verified Shops)'**
  String mapGpsRadar(int km, int count);

  /// No description provided for @mapShopDistance.
  ///
  /// In en, this message translates to:
  /// **'{address} • {km} km away'**
  String mapShopDistance(String address, Object km);

  /// No description provided for @mapShowShop.
  ///
  /// In en, this message translates to:
  /// **'Show {name}'**
  String mapShowShop(String name);

  /// No description provided for @shopRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'★ {rating} Rating'**
  String shopRatingLabel(Object rating);

  /// No description provided for @shopCarsReady.
  ///
  /// In en, this message translates to:
  /// **'• {count} Cars Ready'**
  String shopCarsReady(int count);

  /// No description provided for @shopCarsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} cars available'**
  String shopCarsAvailable(int count);

  /// No description provided for @callingShop.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}...'**
  String callingShop(String name);

  /// No description provided for @callingShopNumber.
  ///
  /// In en, this message translates to:
  /// **'Calling {name} ({phone})...'**
  String callingShopNumber(String name, String phone);

  /// No description provided for @openingWhatsappShop.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp with {name}...'**
  String openingWhatsappShop(String name);

  /// No description provided for @vehicleSelfRate.
  ///
  /// In en, this message translates to:
  /// **'Self: Rs. {rate}/day'**
  String vehicleSelfRate(String rate);

  /// No description provided for @vehicleDriverRate.
  ///
  /// In en, this message translates to:
  /// **'With Driver: Rs. {rate}/day'**
  String vehicleDriverRate(String rate);

  /// No description provided for @vehicleSeats.
  ///
  /// In en, this message translates to:
  /// **'{count} Seats'**
  String vehicleSeats(int count);

  /// No description provided for @vehicleShowroom.
  ///
  /// In en, this message translates to:
  /// **'Showroom: {name}'**
  String vehicleShowroom(String name);

  /// No description provided for @vehicleDriverPackageDetail.
  ///
  /// In en, this message translates to:
  /// **'Verified chauffeur included • Overtime: Rs. {overtime}/hr • Outstation: +Rs. {outstation}/day'**
  String vehicleDriverPackageDetail(String overtime, String outstation);

  /// No description provided for @vehicleSelectedMode.
  ///
  /// In en, this message translates to:
  /// **'Selected: {mode}. Advance deposit required.'**
  String vehicleSelectedMode(String mode);

  /// No description provided for @vehicleWhatsappInterest.
  ///
  /// In en, this message translates to:
  /// **'Hi {shop}, I am interested in the {vehicle} ({plate}) on RentalHub.'**
  String vehicleWhatsappInterest(String shop, String vehicle, String plate);

  /// No description provided for @bookNowWithRate.
  ///
  /// In en, this message translates to:
  /// **'Book Now ({rate}/day)'**
  String bookNowWithRate(String rate);

  /// No description provided for @vehicleManageRates.
  ///
  /// In en, this message translates to:
  /// **'Manage rates'**
  String get vehicleManageRates;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking {id}'**
  String bookingDetailTitle(String id);

  /// No description provided for @bookingShopLine.
  ///
  /// In en, this message translates to:
  /// **'{shop} • {id}'**
  String bookingShopLine(String shop, String id);

  /// No description provided for @activeTripShopLine.
  ///
  /// In en, this message translates to:
  /// **'{shop} • {plate}'**
  String activeTripShopLine(String shop, String plate);

  /// No description provided for @activeTripPackageRental.
  ///
  /// In en, this message translates to:
  /// **'{type} rental'**
  String activeTripPackageRental(String type);

  /// No description provided for @bookingIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String bookingIdLabel(String id);

  /// No description provided for @summaryPackageRental.
  ///
  /// In en, this message translates to:
  /// **'{type} Rental'**
  String summaryPackageRental(String type);

  /// No description provided for @summaryShowroom.
  ///
  /// In en, this message translates to:
  /// **'Showroom: {shop}'**
  String summaryShowroom(String shop);

  /// No description provided for @summaryOutOfCityTo.
  ///
  /// In en, this message translates to:
  /// **'Out of city → {city}'**
  String summaryOutOfCityTo(String city);

  /// No description provided for @summaryDepositAtHandover.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount} (at handover)'**
  String summaryDepositAtHandover(String amount);

  /// No description provided for @payAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay advance (Rs. {amount})'**
  String payAdvanceAmount(String amount);

  /// No description provided for @shopNotFound.
  ///
  /// In en, this message translates to:
  /// **'Shop {id} was not found.'**
  String shopNotFound(String id);

  /// No description provided for @vehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {id} was not found.'**
  String vehicleNotFound(String id);

  /// No description provided for @locationFindCarsInCity.
  ///
  /// In en, this message translates to:
  /// **'Find Nearby Cars in {city}'**
  String locationFindCarsInCity(String city);

  /// No description provided for @sosCallError.
  ///
  /// In en, this message translates to:
  /// **'Could not call {label}.'**
  String sosCallError(String label);

  /// No description provided for @sosLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location: {error}'**
  String sosLocationError(String error);

  /// No description provided for @sosEmergencyMessage.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY — I need help. My live location: {url}'**
  String sosEmergencyMessage(String url);

  /// No description provided for @sosSendToShopNamed.
  ///
  /// In en, this message translates to:
  /// **'Send your live location to {shop}'**
  String sosSendToShopNamed(String shop);

  /// No description provided for @supportWhatsappMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi {shop}, I need help with my RentalHub booking.'**
  String supportWhatsappMessage(String shop);

  /// No description provided for @disputeFileError.
  ///
  /// In en, this message translates to:
  /// **'Failed to file dispute: {error}'**
  String disputeFileError(String error);

  /// No description provided for @cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation failed: {error}'**
  String cancelFailed(String error);

  /// No description provided for @cancelFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Cancellation failed. Please try again.'**
  String get cancelFailedGeneric;

  /// No description provided for @cancelAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'You paid Rs. {amount} advance directly to the showroom\'s account — the showroom decides the refund, so contact them about it. No security deposit was collected: deposits are only taken at handover.'**
  String cancelAdvancePaid(String amount);

  /// No description provided for @rateSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rating: {error}'**
  String rateSaveError(String error);

  /// No description provided for @rateTripRef.
  ///
  /// In en, this message translates to:
  /// **'Trip Reference: {id}'**
  String rateTripRef(String id);

  /// No description provided for @rateStarLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate {star} out of 5'**
  String rateStarLabel(int star);

  /// No description provided for @editSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile: {error}'**
  String editSaveError(String error);

  /// No description provided for @supportSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send your message: {error}'**
  String supportSendError(String error);

  /// No description provided for @proofSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit payment proof: {error}'**
  String proofSubmitError(String error);

  /// No description provided for @proofSubmitFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your payment proof. Please try again.'**
  String get proofSubmitFailedGeneric;

  /// No description provided for @proofBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID: {id}'**
  String proofBookingId(String id);

  /// No description provided for @reviewSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit booking: {error}'**
  String reviewSubmitError(String error);

  /// No description provided for @successBody.
  ///
  /// In en, this message translates to:
  /// **'Your reservation request for {vehicle} has been delivered to {shop}. Once approved, you will be notified to submit the advance deposit.'**
  String successBody(String vehicle, String shop);

  /// No description provided for @successReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {id}'**
  String successReference(String id);

  /// No description provided for @successWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Hi {shop}, this is about my RentalHub booking {id} ({vehicle}).'**
  String successWhatsapp(String shop, String id, String vehicle);

  /// No description provided for @paymentTransferToLock.
  ///
  /// In en, this message translates to:
  /// **'Transfer Rs. {amount} to lock your vehicle.'**
  String paymentTransferToLock(String amount);

  /// No description provided for @approvedPayToGuarantee.
  ///
  /// In en, this message translates to:
  /// **'Pay Rs. {amount} to guarantee pickup.'**
  String approvedPayToGuarantee(String amount);

  /// No description provided for @packageAdvanceDue.
  ///
  /// In en, this message translates to:
  /// **'Advance Due: Rs. {amount}'**
  String packageAdvanceDue(String amount);

  /// No description provided for @packageSecurityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit: Rs. {amount}'**
  String packageSecurityDeposit(String amount);

  /// No description provided for @packageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: Rs. {amount}'**
  String packageTotal(String amount);

  /// No description provided for @tierAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance: Rs. {amount}'**
  String tierAdvance(String amount);

  /// No description provided for @paymentCopied.
  ///
  /// In en, this message translates to:
  /// **'{method} account copied to clipboard'**
  String paymentCopied(String method);

  /// No description provided for @passShopNoAddress.
  ///
  /// In en, this message translates to:
  /// **'{shop} — address not listed yet.'**
  String passShopNoAddress(String shop);

  /// No description provided for @kycSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String kycSelectedFile(String name);

  /// No description provided for @kycScanError.
  ///
  /// In en, this message translates to:
  /// **'CNIC scan failed: {error}'**
  String kycScanError(String error);

  /// No description provided for @kycStatus.
  ///
  /// In en, this message translates to:
  /// **'KYC status: {label}'**
  String kycStatus(String label);

  /// No description provided for @avatarPickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not open image picker: {error}'**
  String avatarPickerError(String error);

  /// No description provided for @onboardingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {error}'**
  String onboardingSaveError(String error);

  /// No description provided for @roleSelectingNote.
  ///
  /// In en, this message translates to:
  /// **'You are selecting \"{role}\". In accordance with National NADRA KYC policies, this role is locked permanently and cannot be changed later.'**
  String roleSelectingNote(String role);

  /// No description provided for @roleConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Account role \"{role}\" confirmed.'**
  String roleConfirmed(String role);

  /// No description provided for @authCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} RentalHub. All rights reserved.'**
  String authCopyright(int year);

  /// No description provided for @reputationBasedOnReviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Based on 1 showroom review from your completed trips.} other{Based on {count} showroom reviews from your completed trips.}}'**
  String reputationBasedOnReviews(int count);

  /// No description provided for @reputationTrustScoreValue.
  ///
  /// In en, this message translates to:
  /// **'Trust Score: {score} / 5.0'**
  String reputationTrustScoreValue(String score);

  /// No description provided for @profileTrustScoreValue.
  ///
  /// In en, this message translates to:
  /// **'Trust Score: {score} / 5.0'**
  String profileTrustScoreValue(String score);

  /// No description provided for @pickerDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Day} other{{count} Days}}'**
  String pickerDays(int count);

  /// No description provided for @walletAdvancesEscrow.
  ///
  /// In en, this message translates to:
  /// **'Advances Rs. {adv} • Escrow Rs. {esc}'**
  String walletAdvancesEscrow(String adv, String esc);

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @activeTripTotalFare.
  ///
  /// In en, this message translates to:
  /// **'Total Fare'**
  String get activeTripTotalFare;

  /// No description provided for @emptyRadarNoShops.
  ///
  /// In en, this message translates to:
  /// **'No Verified Shops Within {radiusKm} km'**
  String emptyRadarNoShops(int radiusKm);

  /// No description provided for @vehiclePerDay.
  ///
  /// In en, this message translates to:
  /// **'/ per day'**
  String get vehiclePerDay;

  /// No description provided for @bookingTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: Rs. {amount}'**
  String bookingTotalAmount(String amount);

  /// No description provided for @fleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Management'**
  String get fleetTitle;

  /// No description provided for @fleetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live Showroom'**
  String get fleetSubtitle;

  /// No description provided for @fleetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or plate'**
  String get fleetSearchHint;

  /// No description provided for @fleetTotalFleet.
  ///
  /// In en, this message translates to:
  /// **'Total Fleet'**
  String get fleetTotalFleet;

  /// No description provided for @fleetTotalCars.
  ///
  /// In en, this message translates to:
  /// **'{count} Cars'**
  String fleetTotalCars(int count);

  /// No description provided for @fleetAvailableReady.
  ///
  /// In en, this message translates to:
  /// **'{count} Ready'**
  String fleetAvailableReady(int count);

  /// No description provided for @fleetOnRent.
  ///
  /// In en, this message translates to:
  /// **'On Rent'**
  String get fleetOnRent;

  /// No description provided for @fleetOnRentActive.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String fleetOnRentActive(int count);

  /// No description provided for @fleetFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fleetFilterAll;

  /// No description provided for @fleetFilterMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get fleetFilterMaintenance;

  /// No description provided for @fleetFilterChip.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String fleetFilterChip(String label, int count);

  /// No description provided for @fleetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your fleet…'**
  String get fleetLoading;

  /// No description provided for @fleetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your fleet: {error}'**
  String fleetLoadError(String error);

  /// No description provided for @fleetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet — add your first car'**
  String get fleetEmptyTitle;

  /// No description provided for @fleetEmptyFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'No vehicles found in this filter'**
  String get fleetEmptyFilterTitle;

  /// No description provided for @fleetEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a car to start taking bookings.'**
  String get fleetEmptyMessage;

  /// No description provided for @fleetEmptyFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter.'**
  String get fleetEmptyFilterMessage;

  /// No description provided for @fleetAddVehicleNow.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle Now'**
  String get fleetAddVehicleNow;

  /// No description provided for @fleetDailySelfDriveRate.
  ///
  /// In en, this message translates to:
  /// **'Daily Self-Drive Rate'**
  String get fleetDailySelfDriveRate;

  /// No description provided for @fleetDailyRate.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount}/day'**
  String fleetDailyRate(String amount);

  /// No description provided for @fleetEditRatesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit rates'**
  String get fleetEditRatesTooltip;

  /// No description provided for @fleetCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Booking calendar'**
  String get fleetCalendarTooltip;

  /// No description provided for @fleetVehicleSpecs.
  ///
  /// In en, this message translates to:
  /// **'{transmission} • {fuelType} • {seats} Seats'**
  String fleetVehicleSpecs(String transmission, String fuelType, int seats);

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Showroom Revenue & Operations'**
  String get dashboardTitle;

  /// No description provided for @dashboardMyShowroom.
  ///
  /// In en, this message translates to:
  /// **'My Showroom'**
  String get dashboardMyShowroom;

  /// No description provided for @dashboardNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotificationsTooltip;

  /// No description provided for @dashboardSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shop settings'**
  String get dashboardSettingsTooltip;

  /// No description provided for @dashboardRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get dashboardRefreshTooltip;

  /// No description provided for @dashboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your showroom…'**
  String get dashboardLoading;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your dashboard. Check your connection and try again.'**
  String get dashboardLoadError;

  /// No description provided for @dashboardNoRevenueLastMonth.
  ///
  /// In en, this message translates to:
  /// **'No revenue last month'**
  String get dashboardNoRevenueLastMonth;

  /// No description provided for @dashboardGrowthLabel.
  ///
  /// In en, this message translates to:
  /// **'{value}% vs last month'**
  String dashboardGrowthLabel(String value);

  /// No description provided for @dashboardNoCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get dashboardNoCompletedTrips;

  /// No description provided for @dashboardSettleRate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% deposits settled'**
  String dashboardSettleRate(int percent);

  /// No description provided for @dashboardGrossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross Revenue (This Month)'**
  String get dashboardGrossRevenue;

  /// No description provided for @dashboardActiveOnRent.
  ///
  /// In en, this message translates to:
  /// **'Active on Rent'**
  String get dashboardActiveOnRent;

  /// No description provided for @dashboardCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed Trips'**
  String get dashboardCompletedTrips;

  /// No description provided for @dashboardRequestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Requests Waiting'**
  String get dashboardRequestsWaiting;

  /// No description provided for @dashboardFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get dashboardFleet;

  /// No description provided for @dashboardOnTheRoad.
  ///
  /// In en, this message translates to:
  /// **'On the road'**
  String get dashboardOnTheRoad;

  /// No description provided for @dashboardNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs your review'**
  String get dashboardNeedsReview;

  /// No description provided for @dashboardAvailableTotal.
  ///
  /// In en, this message translates to:
  /// **'Available / total cars'**
  String get dashboardAvailableTotal;

  /// No description provided for @dashboardCarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Cars'**
  String dashboardCarsCount(int count);

  /// No description provided for @dashboardFinishedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Finished'**
  String dashboardFinishedCount(int count);

  /// No description provided for @dashboardLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed Trip Ledger & Settlements'**
  String get dashboardLedgerTitle;

  /// No description provided for @dashboardLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trips yet — bookings will appear here.'**
  String get dashboardLedgerEmpty;

  /// No description provided for @dashboardViewAllRequests.
  ///
  /// In en, this message translates to:
  /// **'View all requests'**
  String get dashboardViewAllRequests;

  /// No description provided for @dashboardLedgerVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get dashboardLedgerVehicle;

  /// No description provided for @dashboardLedgerCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get dashboardLedgerCustomer;

  /// No description provided for @dashboardQuickAddCar.
  ///
  /// In en, this message translates to:
  /// **'Add Car'**
  String get dashboardQuickAddCar;

  /// No description provided for @dashboardQuickScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get dashboardQuickScanQr;

  /// No description provided for @dashboardQuickNewBooking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get dashboardQuickNewBooking;

  /// No description provided for @dashboardQuickFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get dashboardQuickFinance;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Requests Triage'**
  String get requestsTitle;

  /// No description provided for @bookingsManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings Management'**
  String get bookingsManagementTitle;

  /// No description provided for @requestsAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} Requests Awaiting Review'**
  String requestsAwaitingReview(int count);

  /// No description provided for @requestsScanQrTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan booking QR'**
  String get requestsScanQrTooltip;

  /// No description provided for @requestsRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get requestsRefreshTooltip;

  /// No description provided for @requestsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading booking requests…'**
  String get requestsLoading;

  /// No description provided for @requestsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load booking requests. Check your connection and try again.'**
  String get requestsLoadError;

  /// No description provided for @requestsFilterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get requestsFilterNew;

  /// No description provided for @requestsFilterProof.
  ///
  /// In en, this message translates to:
  /// **'Proof'**
  String get requestsFilterProof;

  /// No description provided for @requestsFilterChip.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String requestsFilterChip(String label, int count);

  /// No description provided for @requestsEmptyProof.
  ///
  /// In en, this message translates to:
  /// **'No payment proofs waiting for verification'**
  String get requestsEmptyProof;

  /// No description provided for @requestsEmptyApproved.
  ///
  /// In en, this message translates to:
  /// **'No approved bookings waiting for payment'**
  String get requestsEmptyApproved;

  /// No description provided for @requestsEmptyNew.
  ///
  /// In en, this message translates to:
  /// **'No pending booking requests'**
  String get requestsEmptyNew;

  /// No description provided for @requestsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'New requests will appear here for review.'**
  String get requestsEmptyMessage;

  /// No description provided for @requestsRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get requestsRejectTitle;

  /// No description provided for @requestsRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get requestsRejectReasonLabel;

  /// No description provided for @requestsRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vehicle is not available on those dates'**
  String get requestsRejectReasonHint;

  /// No description provided for @requestsRejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get requestsRejectButton;

  /// No description provided for @requestsApproved.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id} approved! Payment instructions sent to customer.'**
  String requestsApproved(String id);

  /// No description provided for @requestsApprovalFailed.
  ///
  /// In en, this message translates to:
  /// **'Approval failed: {error}'**
  String requestsApprovalFailed(String error);

  /// No description provided for @requestsRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id} rejected.'**
  String requestsRejected(String id);

  /// No description provided for @requestsDeclineFailed.
  ///
  /// In en, this message translates to:
  /// **'Decline failed: {error}'**
  String requestsDeclineFailed(String error);

  /// No description provided for @requestsCustomerFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get requestsCustomerFallback;

  /// No description provided for @requestsRequestedCar.
  ///
  /// In en, this message translates to:
  /// **'Requested Car'**
  String get requestsRequestedCar;

  /// No description provided for @requestsWithChauffeur.
  ///
  /// In en, this message translates to:
  /// **'With Chauffeur'**
  String get requestsWithChauffeur;

  /// No description provided for @requestsVerifyProof.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment Proof'**
  String get requestsVerifyProof;

  /// No description provided for @requestsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get requestsDecline;

  /// No description provided for @requestsApprovePay.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get requestsApprovePay;

  /// No description provided for @requestsStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requestsStatusRequested;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get calendarFree;

  /// No description provided for @calendarRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get calendarRequested;

  /// No description provided for @calendarConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get calendarConfirmed;

  /// No description provided for @calendarPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get calendarPast;

  /// No description provided for @calendarTapDayHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to see its bookings.'**
  String get calendarTapDayHint;

  /// No description provided for @calendarBookingsOn.
  ///
  /// In en, this message translates to:
  /// **'Bookings on {day}/{month}/{year}'**
  String calendarBookingsOn(int day, int month, int year);

  /// No description provided for @calendarNoBookingsDay.
  ///
  /// In en, this message translates to:
  /// **'No bookings on this day.'**
  String get calendarNoBookingsDay;

  /// No description provided for @calendarMonthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get calendarMonthJanuary;

  /// No description provided for @calendarMonthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get calendarMonthFebruary;

  /// No description provided for @calendarMonthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get calendarMonthMarch;

  /// No description provided for @calendarMonthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get calendarMonthApril;

  /// No description provided for @calendarMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get calendarMonthMay;

  /// No description provided for @calendarMonthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get calendarMonthJune;

  /// No description provided for @calendarMonthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get calendarMonthJuly;

  /// No description provided for @calendarMonthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get calendarMonthAugust;

  /// No description provided for @calendarMonthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get calendarMonthSeptember;

  /// No description provided for @calendarMonthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get calendarMonthOctober;

  /// No description provided for @calendarMonthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get calendarMonthNovember;

  /// No description provided for @calendarMonthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get calendarMonthDecember;

  /// No description provided for @calendarWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calendarWeekdayMon;

  /// No description provided for @calendarWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calendarWeekdayTue;

  /// No description provided for @calendarWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calendarWeekdayWed;

  /// No description provided for @calendarWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calendarWeekdayThu;

  /// No description provided for @calendarWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calendarWeekdayFri;

  /// No description provided for @calendarWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calendarWeekdaySat;

  /// No description provided for @calendarWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calendarWeekdaySun;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarSelectDay.
  ///
  /// In en, this message translates to:
  /// **'Select day {day}'**
  String calendarSelectDay(int day);

  /// No description provided for @addVehicleModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify vehicle model variant.'**
  String get addVehicleModelRequired;

  /// No description provided for @addVehiclePlateRequired.
  ///
  /// In en, this message translates to:
  /// **'Registration plate number is required.'**
  String get addVehiclePlateRequired;

  /// No description provided for @addVehicleAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to showroom fleet!'**
  String addVehicleAdded(String name);

  /// No description provided for @addVehicleStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle - Specs'**
  String get addVehicleStep1Title;

  /// No description provided for @addVehicleStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Car Photos & Docs'**
  String get addVehicleStep2Title;

  /// No description provided for @addVehicleStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Rental Rates & Policy'**
  String get addVehicleStep3Title;

  /// No description provided for @addVehicleStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Review & Publish'**
  String get addVehicleStep4Title;

  /// No description provided for @addVehicleStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Capacity, AC, features & specs'**
  String get addVehicleStep1Subtitle;

  /// No description provided for @addVehicleStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'4-angle photos, book & excise tax'**
  String get addVehicleStep2Subtitle;

  /// No description provided for @addVehicleStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hourly rates, deposit & fuel policy'**
  String get addVehicleStep3Subtitle;

  /// No description provided for @addVehicleStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify vehicle details before listing'**
  String get addVehicleStep4Subtitle;

  /// No description provided for @addVehicleStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String addVehicleStepCounter(int step);

  /// No description provided for @addVehicleConfirmPublish.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Publish Vehicle'**
  String get addVehicleConfirmPublish;

  /// No description provided for @addVehicleNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get addVehicleNextStep;

  /// No description provided for @addVehicleStepperSpecs.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Specs'**
  String get addVehicleStepperSpecs;

  /// No description provided for @addVehicleStepperPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos & Docs'**
  String get addVehicleStepperPhotos;

  /// No description provided for @addVehicleStepperRates.
  ///
  /// In en, this message translates to:
  /// **'Rates & Policy'**
  String get addVehicleStepperRates;

  /// No description provided for @addVehicleStepperReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get addVehicleStepperReview;

  /// No description provided for @addVehicleMakeBrand.
  ///
  /// In en, this message translates to:
  /// **'Make / Brand'**
  String get addVehicleMakeBrand;

  /// No description provided for @addVehicleModelVariant.
  ///
  /// In en, this message translates to:
  /// **'Model Variant'**
  String get addVehicleModelVariant;

  /// No description provided for @addVehicleModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corolla Altis 1.8 Grande'**
  String get addVehicleModelHint;

  /// No description provided for @addVehicleManufacturingYear.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing Year'**
  String get addVehicleManufacturingYear;

  /// No description provided for @addVehicleExteriorColor.
  ///
  /// In en, this message translates to:
  /// **'Exterior Color'**
  String get addVehicleExteriorColor;

  /// No description provided for @addVehicleBodyCategory.
  ///
  /// In en, this message translates to:
  /// **'Body Category'**
  String get addVehicleBodyCategory;

  /// No description provided for @addVehicleRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration Number'**
  String get addVehicleRegistrationNumber;

  /// No description provided for @addVehicleTransmission.
  ///
  /// In en, this message translates to:
  /// **'Transmission'**
  String get addVehicleTransmission;

  /// No description provided for @addVehicleAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get addVehicleAutomatic;

  /// No description provided for @addVehicleManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get addVehicleManual;

  /// No description provided for @addVehicleFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get addVehicleFuelType;

  /// No description provided for @addVehicleSeatingCapacity.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Seating Capacity'**
  String get addVehicleSeatingCapacity;

  /// No description provided for @addVehicleSeatsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Seats'**
  String addVehicleSeatsCount(int count);

  /// No description provided for @addVehicleAcTitle.
  ///
  /// In en, this message translates to:
  /// **'Air Conditioning (Full AC)'**
  String get addVehicleAcTitle;

  /// No description provided for @addVehicleAcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle equipped with working chilled AC'**
  String get addVehicleAcSubtitle;

  /// No description provided for @addVehicleExtraFeatures.
  ///
  /// In en, this message translates to:
  /// **'Extra Features (Shown on Car Detail)'**
  String get addVehicleExtraFeatures;

  /// No description provided for @addVehicleExtraFeaturesHint.
  ///
  /// In en, this message translates to:
  /// **'Select amenities included with this vehicle to attract more renters.'**
  String get addVehicleExtraFeaturesHint;

  /// No description provided for @addVehiclePhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle 4-Angle Photos'**
  String get addVehiclePhotosTitle;

  /// No description provided for @addVehiclePhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Upload photos using Camera or Gallery. Tap to change or remove.'**
  String get addVehiclePhotosHint;

  /// No description provided for @addVehicleFrontPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'A front photo is required before publishing this vehicle.'**
  String get addVehicleFrontPhotoRequired;

  /// No description provided for @addVehiclePhotoFront.
  ///
  /// In en, this message translates to:
  /// **'Front View'**
  String get addVehiclePhotoFront;

  /// No description provided for @addVehiclePhotoRear.
  ///
  /// In en, this message translates to:
  /// **'Rear View'**
  String get addVehiclePhotoRear;

  /// No description provided for @addVehiclePhotoSide.
  ///
  /// In en, this message translates to:
  /// **'Side Profile'**
  String get addVehiclePhotoSide;

  /// No description provided for @addVehiclePhotoInterior.
  ///
  /// In en, this message translates to:
  /// **'Interior & Dash'**
  String get addVehiclePhotoInterior;

  /// No description provided for @addVehicleLegalDocs.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get addVehicleLegalDocs;

  /// No description provided for @addVehicleDocRegBook.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration Book / Smart Card'**
  String get addVehicleDocRegBook;

  /// No description provided for @addVehicleDocRegBookHint.
  ///
  /// In en, this message translates to:
  /// **'Original ownership document required'**
  String get addVehicleDocRegBookHint;

  /// No description provided for @addVehicleDocTokenTax.
  ///
  /// In en, this message translates to:
  /// **'Excise Token Tax Paid Receipt'**
  String get addVehicleDocTokenTax;

  /// No description provided for @addVehicleDocTokenTaxHint.
  ///
  /// In en, this message translates to:
  /// **'Must be valid for current fiscal year'**
  String get addVehicleDocTokenTaxHint;

  /// No description provided for @addVehicleDocInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance / Tracker Certificate (Optional)'**
  String get addVehicleDocInsurance;

  /// No description provided for @addVehicleDocInsuranceHint.
  ///
  /// In en, this message translates to:
  /// **'Provides verified VIP badge in search'**
  String get addVehicleDocInsuranceHint;

  /// No description provided for @addVehicleDurationPackages.
  ///
  /// In en, this message translates to:
  /// **'Duration Packages (Hourly & Daily)'**
  String get addVehicleDurationPackages;

  /// No description provided for @addVehicleDurationPackagesHint.
  ///
  /// In en, this message translates to:
  /// **'Enable packages and edit rates in PKR per booking tier.'**
  String get addVehicleDurationPackagesHint;

  /// No description provided for @addVehicleRate1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour Rate'**
  String get addVehicleRate1Hour;

  /// No description provided for @addVehicleRate3Hours.
  ///
  /// In en, this message translates to:
  /// **'3 Hours Rate'**
  String get addVehicleRate3Hours;

  /// No description provided for @addVehicleRate6Hours.
  ///
  /// In en, this message translates to:
  /// **'6 Hours Rate'**
  String get addVehicleRate6Hours;

  /// No description provided for @addVehicleRateFullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day (24h) Rate'**
  String get addVehicleRateFullDay;

  /// No description provided for @addVehicleRateWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly (7 Days) Rate'**
  String get addVehicleRateWeekly;

  /// No description provided for @addVehicleServiceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type & Driver Options'**
  String get addVehicleServiceType;

  /// No description provided for @addVehicleSelfDriveService.
  ///
  /// In en, this message translates to:
  /// **'Self-Drive Service'**
  String get addVehicleSelfDriveService;

  /// No description provided for @addVehicleSelfDriveHint.
  ///
  /// In en, this message translates to:
  /// **'Customer drives the vehicle themselves'**
  String get addVehicleSelfDriveHint;

  /// No description provided for @addVehicleWithDriverService.
  ///
  /// In en, this message translates to:
  /// **'With-Driver Service'**
  String get addVehicleWithDriverService;

  /// No description provided for @addVehicleWithDriverHint.
  ///
  /// In en, this message translates to:
  /// **'Shop provides experienced chauffeur'**
  String get addVehicleWithDriverHint;

  /// No description provided for @addVehicleDriverAllowance.
  ///
  /// In en, this message translates to:
  /// **'Driver Daily Allowance:'**
  String get addVehicleDriverAllowance;

  /// No description provided for @addVehiclePerDaySuffix.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get addVehiclePerDaySuffix;

  /// No description provided for @addVehicleDepositPolicies.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit & Rental Policies'**
  String get addVehicleDepositPolicies;

  /// No description provided for @addVehicleSecurityDepositSelfDrive.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit (Self-Drive)'**
  String get addVehicleSecurityDepositSelfDrive;

  /// No description provided for @addVehicleSecurityDepositHint.
  ///
  /// In en, this message translates to:
  /// **'Refunded on car return in clean condition'**
  String get addVehicleSecurityDepositHint;

  /// No description provided for @addVehicleAdvanceFee.
  ///
  /// In en, this message translates to:
  /// **'Advance Booking Fee'**
  String get addVehicleAdvanceFee;

  /// No description provided for @addVehicleAdvanceHint.
  ///
  /// In en, this message translates to:
  /// **'Required up front to lock slot'**
  String get addVehicleAdvanceHint;

  /// No description provided for @addVehicleExtraHourCharge.
  ///
  /// In en, this message translates to:
  /// **'Extra Hour Overstay Charge'**
  String get addVehicleExtraHourCharge;

  /// No description provided for @addVehicleExtraHourHint.
  ///
  /// In en, this message translates to:
  /// **'Billed per hour past scheduled return'**
  String get addVehicleExtraHourHint;

  /// No description provided for @addVehiclePerHourSuffix.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get addVehiclePerHourSuffix;

  /// No description provided for @addVehicleFuelPolicy.
  ///
  /// In en, this message translates to:
  /// **'Fuel Policy'**
  String get addVehicleFuelPolicy;

  /// No description provided for @addVehicleFuelPolicyHint.
  ///
  /// In en, this message translates to:
  /// **'Condition expected upon return'**
  String get addVehicleFuelPolicyHint;

  /// No description provided for @addVehicleReviewGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get addVehicleReviewGear;

  /// No description provided for @addVehicleReviewAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get addVehicleReviewAuto;

  /// No description provided for @addVehicleReviewFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get addVehicleReviewFuel;

  /// No description provided for @addVehicleReviewSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get addVehicleReviewSeats;

  /// No description provided for @addVehicleReviewAc.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get addVehicleReviewAc;

  /// No description provided for @addVehicleReviewFullAc.
  ///
  /// In en, this message translates to:
  /// **'Full AC'**
  String get addVehicleReviewFullAc;

  /// No description provided for @addVehicleReviewSelfDriveRate.
  ///
  /// In en, this message translates to:
  /// **'Self-Drive Rate'**
  String get addVehicleReviewSelfDriveRate;

  /// No description provided for @addVehicleReviewWithDriverRate.
  ///
  /// In en, this message translates to:
  /// **'With-Driver Rate'**
  String get addVehicleReviewWithDriverRate;

  /// No description provided for @addVehicleReviewNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Not Offered'**
  String get addVehicleReviewNotOffered;

  /// No description provided for @addVehicleReviewDailyRate.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount}/day'**
  String addVehicleReviewDailyRate(String amount);

  /// No description provided for @addVehicleReviewOverstayRate.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount}/hr'**
  String addVehicleReviewOverstayRate(String amount);

  /// No description provided for @addVehicleReviewDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get addVehicleReviewDeposit;

  /// No description provided for @addVehicleReviewAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get addVehicleReviewAdvance;

  /// No description provided for @addVehicleReviewOverstay.
  ///
  /// In en, this message translates to:
  /// **'Overstay'**
  String get addVehicleReviewOverstay;

  /// No description provided for @addVehicleReviewBanner.
  ///
  /// In en, this message translates to:
  /// **'This car will be immediately available in your fleet catalog and visible to nearby customers upon approval.'**
  String get addVehicleReviewBanner;

  /// No description provided for @pricingDriveModeAvailability.
  ///
  /// In en, this message translates to:
  /// **'Drive Mode Availability'**
  String get pricingDriveModeAvailability;

  /// No description provided for @pricingRentalPackages.
  ///
  /// In en, this message translates to:
  /// **'Rental Packages'**
  String get pricingRentalPackages;

  /// No description provided for @pricingPackagesHint.
  ///
  /// In en, this message translates to:
  /// **'Switch a package off to hide it from customers.'**
  String get pricingPackagesHint;

  /// No description provided for @pricingPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing Policy'**
  String get pricingPolicyTitle;

  /// No description provided for @pricingSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pricing matrix updated in showroom!'**
  String get pricingSavedSuccess;

  /// No description provided for @pricingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update rates: {error}'**
  String pricingSaveFailed(String error);

  /// No description provided for @pricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Pricing Matrix'**
  String get pricingTitle;

  /// No description provided for @rateMatrixInvalidField.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number for {field}'**
  String rateMatrixInvalidField(String field);

  /// No description provided for @pricingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving Matrix...'**
  String get pricingSaving;

  /// No description provided for @pricingSave.
  ///
  /// In en, this message translates to:
  /// **'Save Pricing Matrix'**
  String get pricingSave;

  /// No description provided for @pricingUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved prices?'**
  String get pricingUnsavedTitle;

  /// No description provided for @pricingUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Your edited prices have not been saved.'**
  String get pricingUnsavedBody;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes have not been saved.'**
  String get unsavedChangesBody;

  /// No description provided for @pricingSelfDriveAllowed.
  ///
  /// In en, this message translates to:
  /// **'Self-Drive Allowed'**
  String get pricingSelfDriveAllowed;

  /// No description provided for @pricingSelfDriveHint.
  ///
  /// In en, this message translates to:
  /// **'Requires original NADRA CNIC + security deposit'**
  String get pricingSelfDriveHint;

  /// No description provided for @pricingChauffeurAllowed.
  ///
  /// In en, this message translates to:
  /// **'Chauffeur Service Allowed'**
  String get pricingChauffeurAllowed;

  /// No description provided for @pricingChauffeurHint.
  ///
  /// In en, this message translates to:
  /// **'Showroom driver assigned to booking'**
  String get pricingChauffeurHint;

  /// No description provided for @pricingPackage1h.
  ///
  /// In en, this message translates to:
  /// **'1-Hour City Commute'**
  String get pricingPackage1h;

  /// No description provided for @pricingPackage3h.
  ///
  /// In en, this message translates to:
  /// **'3-Hour Airport / Quick Trip'**
  String get pricingPackage3h;

  /// No description provided for @pricingPackage6h.
  ///
  /// In en, this message translates to:
  /// **'6-Hour Express Rate'**
  String get pricingPackage6h;

  /// No description provided for @pricingPackage12h.
  ///
  /// In en, this message translates to:
  /// **'12-Hour Half Day'**
  String get pricingPackage12h;

  /// No description provided for @pricingPackage24h.
  ///
  /// In en, this message translates to:
  /// **'In-City Daily (24h)'**
  String get pricingPackage24h;

  /// No description provided for @pricingPackageWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly Package (7 Days)'**
  String get pricingPackageWeekly;

  /// No description provided for @pricingKmIncluded.
  ///
  /// In en, this message translates to:
  /// **'{km} km included'**
  String pricingKmIncluded(int km);

  /// No description provided for @pricingOutOfCityDaily.
  ///
  /// In en, this message translates to:
  /// **'Out-of-City Daily (24h)'**
  String get pricingOutOfCityDaily;

  /// No description provided for @pricingOutOfCityDailyCap.
  ///
  /// In en, this message translates to:
  /// **'300 km included + tracker cleared'**
  String get pricingOutOfCityDailyCap;

  /// No description provided for @pricingWithDriverSurcharge.
  ///
  /// In en, this message translates to:
  /// **'With-Driver Surcharge (per day)'**
  String get pricingWithDriverSurcharge;

  /// No description provided for @pricingWithDriverSurchargeCap.
  ///
  /// In en, this message translates to:
  /// **'Added on top of the package price'**
  String get pricingWithDriverSurchargeCap;

  /// No description provided for @pricingSecurityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit'**
  String get pricingSecurityDeposit;

  /// No description provided for @pricingSecurityDepositCap.
  ///
  /// In en, this message translates to:
  /// **'Refundable after return inspection'**
  String get pricingSecurityDepositCap;

  /// No description provided for @pricingAdvanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Advance Required'**
  String get pricingAdvanceRequired;

  /// No description provided for @pricingAdvanceCap.
  ///
  /// In en, this message translates to:
  /// **'Due before the booking is confirmed'**
  String get pricingAdvanceCap;

  /// No description provided for @pricingExtraHourCharge.
  ///
  /// In en, this message translates to:
  /// **'Extra Hour Charge'**
  String get pricingExtraHourCharge;

  /// No description provided for @pricingExtraHourCap.
  ///
  /// In en, this message translates to:
  /// **'Charged for late returns'**
  String get pricingExtraHourCap;

  /// No description provided for @pricingExtraKmCharge.
  ///
  /// In en, this message translates to:
  /// **'Extra KM Charge'**
  String get pricingExtraKmCharge;

  /// No description provided for @pricingExtraKmCap.
  ///
  /// In en, this message translates to:
  /// **'Charged beyond the included km'**
  String get pricingExtraKmCap;

  /// No description provided for @pricingOutOfCityKmAllowance.
  ///
  /// In en, this message translates to:
  /// **'Out-of-City KM Allowance (per day)'**
  String get pricingOutOfCityKmAllowance;

  /// No description provided for @pricingOutOfCityKmCap.
  ///
  /// In en, this message translates to:
  /// **'Tracker clearance required beyond the city'**
  String get pricingOutOfCityKmCap;

  /// No description provided for @pricingFuelPolicy.
  ///
  /// In en, this message translates to:
  /// **'Fuel Policy'**
  String get pricingFuelPolicy;

  /// No description provided for @fixedRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed Out-of-City Routes'**
  String get fixedRoutesTitle;

  /// No description provided for @fixedRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One fixed price per destination'**
  String get fixedRoutesSubtitle;

  /// No description provided for @fixedRoutesDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete fixed route'**
  String get fixedRoutesDeleteTooltip;

  /// No description provided for @fixedRoutesPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a fixed price above zero.'**
  String get fixedRoutesPriceRequired;

  /// No description provided for @fixedRoutesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the fixed route. Please try again.'**
  String get fixedRoutesSaveFailed;

  /// No description provided for @fixedRoutesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the fixed route. Please try again.'**
  String get fixedRoutesDeleteFailed;

  /// No description provided for @fixedRoutesDistanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the distance in km.'**
  String get fixedRoutesDistanceRequired;

  /// No description provided for @fixedRoutesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your fixed routes. Check your connection and try again.'**
  String get fixedRoutesLoadError;

  /// No description provided for @fixedRoutesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fixed routes yet — add your first destination below.'**
  String get fixedRoutesEmpty;

  /// No description provided for @fixedRouteDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This route already exists'**
  String get fixedRouteDuplicate;

  /// No description provided for @fixedRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'{km} km • Rs. {price} fixed'**
  String fixedRouteSummary(int km, String price);

  /// No description provided for @fixedRouteChip.
  ///
  /// In en, this message translates to:
  /// **'{city} • Rs. {price}'**
  String fixedRouteChip(String city, String price);

  /// No description provided for @fixedRouteAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a route'**
  String get fixedRouteAddTitle;

  /// No description provided for @fixedRouteFromCity.
  ///
  /// In en, this message translates to:
  /// **'From (city)'**
  String get fixedRouteFromCity;

  /// No description provided for @fixedRouteToCity.
  ///
  /// In en, this message translates to:
  /// **'To (city)'**
  String get fixedRouteToCity;

  /// No description provided for @fixedRouteDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get fixedRouteDistance;

  /// No description provided for @fixedRoutePrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed price (Rs.)'**
  String get fixedRoutePrice;

  /// No description provided for @fixedRouteAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Fixed Route'**
  String get fixedRouteAddButton;

  /// No description provided for @fleetAddVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get fleetAddVehicle;

  /// No description provided for @amountRs.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount}'**
  String amountRs(String amount);

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers Management'**
  String get customersManagementTitle;

  /// No description provided for @customersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customers'**
  String customersCount(int count);

  /// No description provided for @customersLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get customersLoading;

  /// No description provided for @customersLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your customers…'**
  String get customersLoadingMessage;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone or CNIC'**
  String get customersSearchHint;

  /// No description provided for @customersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your customers. Check your connection and try again.'**
  String get customersLoadError;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan a CNIC or take a walk-in booking.'**
  String get customersEmptyMessage;

  /// No description provided for @customersScanCnic.
  ///
  /// In en, this message translates to:
  /// **'Scan a CNIC'**
  String get customersScanCnic;

  /// No description provided for @customersBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Blacklisted'**
  String get customersBlacklisted;

  /// No description provided for @customersBookingsLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} booking} other{{count} bookings}} • Rs. {amount}'**
  String customersBookingsLine(int count, String amount);

  /// No description provided for @customersNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet — saved from a CNIC scan or as a guarantor.'**
  String get customersNoBookings;

  /// No description provided for @customersScanTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC & Blacklist Radar'**
  String get customersScanTitle;

  /// No description provided for @addCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomerTitle;

  /// No description provided for @addCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get addCustomerName;

  /// No description provided for @addCustomerCnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC Number'**
  String get addCustomerCnic;

  /// No description provided for @addCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get addCustomerPhone;

  /// No description provided for @addCustomerSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer saved'**
  String get addCustomerSaved;

  /// No description provided for @addCustomerSave.
  ///
  /// In en, this message translates to:
  /// **'Save customer'**
  String get addCustomerSave;

  /// No description provided for @addCustomerFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get addCustomerFullNameRequired;

  /// No description provided for @addCustomerHelper.
  ///
  /// In en, this message translates to:
  /// **'Guarantor can be added later from the booking flow'**
  String get addCustomerHelper;

  /// No description provided for @customersScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'RentalHub shared blacklist • Real-time'**
  String get customersScanSubtitle;

  /// No description provided for @customersScanTribunalPolicy.
  ///
  /// In en, this message translates to:
  /// **'Tribunal Policy'**
  String get customersScanTribunalPolicy;

  /// No description provided for @customersScanTribunalInfo.
  ///
  /// In en, this message translates to:
  /// **'Every RentalHub shop shares fraud reports in one blacklist.'**
  String get customersScanTribunalInfo;

  /// No description provided for @customersScanViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All Customers'**
  String get customersScanViewAll;

  /// No description provided for @customersScanInvalidCnic.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 13-digit Pakistani CNIC'**
  String get customersScanInvalidCnic;

  /// No description provided for @customersScanLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification lookup failed: {error}'**
  String customersScanLookupFailed(String error);

  /// No description provided for @customersScanFailed.
  ///
  /// In en, this message translates to:
  /// **'CNIC scan failed: {error}'**
  String customersScanFailed(String error);

  /// No description provided for @customersScanUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the card — type the CNIC manually.'**
  String get customersScanUnreadable;

  /// No description provided for @customersScanDeclined.
  ///
  /// In en, this message translates to:
  /// **'Customer flagged and declined entry into showroom.'**
  String get customersScanDeclined;

  /// No description provided for @customersScanFallbackReason.
  ///
  /// In en, this message translates to:
  /// **'Reported in RentalHub\'s shared blacklist'**
  String get customersScanFallbackReason;

  /// No description provided for @customersScanFallbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Severe fraud / non-payment incident flagged.'**
  String get customersScanFallbackDescription;

  /// No description provided for @customersRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Reputation & Review'**
  String get customersRatingTitle;

  /// No description provided for @customersRatingFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer Review'**
  String get customersRatingFallback;

  /// No description provided for @customersRatingFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Performance Feedback'**
  String get customersRatingFeedbackTitle;

  /// No description provided for @customersRatingPunctuality.
  ///
  /// In en, this message translates to:
  /// **'Return Punctuality & Timekeeping'**
  String get customersRatingPunctuality;

  /// No description provided for @customersRatingPunctualityHint.
  ///
  /// In en, this message translates to:
  /// **'Vehicle returned as per agreed contract schedule'**
  String get customersRatingPunctualityHint;

  /// No description provided for @customersRatingCare.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Care & Cleanliness'**
  String get customersRatingCare;

  /// No description provided for @customersRatingCareHint.
  ///
  /// In en, this message translates to:
  /// **'Interior cleanliness and scratch-free return'**
  String get customersRatingCareHint;

  /// No description provided for @customersRatingBehavior.
  ///
  /// In en, this message translates to:
  /// **'Overall Behavior & Civility'**
  String get customersRatingBehavior;

  /// No description provided for @customersRatingBehaviorHint.
  ///
  /// In en, this message translates to:
  /// **'Professionalism and adherence to showroom policies'**
  String get customersRatingBehaviorHint;

  /// No description provided for @rateCustomerSelectStars.
  ///
  /// In en, this message translates to:
  /// **'Select at least one star rating'**
  String get rateCustomerSelectStars;

  /// No description provided for @customersRatingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add optional feedback notes for community showroom records...'**
  String get customersRatingCommentHint;

  /// No description provided for @customersRatingFlagTitle.
  ///
  /// In en, this message translates to:
  /// **'Flag Customer to Shared Blacklist'**
  String get customersRatingFlagTitle;

  /// No description provided for @customersRatingFlagDescription.
  ///
  /// In en, this message translates to:
  /// **'Customer flagged during return settlement for {reason}.'**
  String customersRatingFlagDescription(String reason);

  /// No description provided for @customersRatingFlagNoCnic.
  ///
  /// In en, this message translates to:
  /// **'Needs the customer CNIC on this booking — none is recorded, so a report cannot be filed from here.'**
  String get customersRatingFlagNoCnic;

  /// No description provided for @customersRatingFlagVisible.
  ///
  /// In en, this message translates to:
  /// **'Other showrooms using RentalHub can see this report'**
  String get customersRatingFlagVisible;

  /// No description provided for @customersRatingReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason Category for Tribunal:'**
  String get customersRatingReasonLabel;

  /// No description provided for @customersRatingReasonPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Default / Refusal to Settle'**
  String get customersRatingReasonPayment;

  /// No description provided for @customersRatingReasonBorder.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized Border Crossing'**
  String get customersRatingReasonBorder;

  /// No description provided for @customersRatingReasonAbuse.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Abuse / Abandonment'**
  String get customersRatingReasonAbuse;

  /// No description provided for @customersRatingReasonFake.
  ///
  /// In en, this message translates to:
  /// **'Fake Identity / Impersonation'**
  String get customersRatingReasonFake;

  /// No description provided for @customersRatingSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Recording Rating...'**
  String get customersRatingSubmitting;

  /// No description provided for @customersRatingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating & Close Trip'**
  String get customersRatingSubmit;

  /// No description provided for @customersRatingSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Rating saved on this device — it will sync when you are back online.'**
  String get customersRatingSavedOffline;

  /// No description provided for @customersRatingSavedBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Rating saved and the customer was reported to the shared blacklist.'**
  String get customersRatingSavedBlacklisted;

  /// No description provided for @customersRatingSaved.
  ///
  /// In en, this message translates to:
  /// **'Your rating of the customer has been saved.'**
  String get customersRatingSaved;

  /// No description provided for @customersRatingSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String customersRatingSubmitFailed(String error);

  /// No description provided for @customersCnicReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Scanned CNIC'**
  String get customersCnicReviewTitle;

  /// No description provided for @customersCnicReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Correct anything OCR misread'**
  String get customersCnicReviewSubtitle;

  /// No description provided for @customersCnicFatherName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Name'**
  String get customersCnicFatherName;

  /// No description provided for @customersCnicNumber.
  ///
  /// In en, this message translates to:
  /// **'CNIC Number'**
  String get customersCnicNumber;

  /// No description provided for @customersCnicDob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (dd.mm.yyyy)'**
  String get customersCnicDob;

  /// No description provided for @cnicReviewDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the date as DD.MM.YYYY.'**
  String get cnicReviewDateInvalid;

  /// No description provided for @customersCnicExpiry.
  ///
  /// In en, this message translates to:
  /// **'CNIC Expiry (dd.mm.yyyy)'**
  String get customersCnicExpiry;

  /// No description provided for @customersCnicPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get customersCnicPhone;

  /// No description provided for @customersCnicAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (from back of card)'**
  String get customersCnicAddress;

  /// No description provided for @customersCnicScanBack.
  ///
  /// In en, this message translates to:
  /// **'Scan Back of CNIC (address)'**
  String get customersCnicScanBack;

  /// No description provided for @customersCnicSave.
  ///
  /// In en, this message translates to:
  /// **'Save Customer & Check Blacklist'**
  String get customersCnicSave;

  /// No description provided for @customersCnicNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address read from the back of the card.'**
  String get customersCnicNoAddress;

  /// No description provided for @customersCnicBackScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Back scan failed: {error}'**
  String customersCnicBackScanFailed(String error);

  /// No description provided for @customersCnicNamePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and phone are required to save the customer.'**
  String get customersCnicNamePhoneRequired;

  /// No description provided for @customersCnicSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String customersCnicSaveFailed(String error);

  /// No description provided for @blacklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared with every shop • Tribunal reviewed'**
  String get blacklistSubtitle;

  /// No description provided for @blacklistReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a customer'**
  String get blacklistReportTitle;

  /// No description provided for @blacklistCustomerCnic.
  ///
  /// In en, this message translates to:
  /// **'Customer CNIC'**
  String get blacklistCustomerCnic;

  /// No description provided for @blacklistCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer phone'**
  String get blacklistCustomerPhone;

  /// No description provided for @blacklistReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get blacklistReasonLabel;

  /// No description provided for @blacklistReasonNonPayment.
  ///
  /// In en, this message translates to:
  /// **'Non-payment'**
  String get blacklistReasonNonPayment;

  /// No description provided for @blacklistReasonCarDamage.
  ///
  /// In en, this message translates to:
  /// **'Car damage'**
  String get blacklistReasonCarDamage;

  /// No description provided for @blacklistReasonLateReturn.
  ///
  /// In en, this message translates to:
  /// **'Late return'**
  String get blacklistReasonLateReturn;

  /// No description provided for @blacklistReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud / fake documents'**
  String get blacklistReasonFraud;

  /// No description provided for @blacklistReasonImpoundment.
  ///
  /// In en, this message translates to:
  /// **'Default & Car Impoundment'**
  String get blacklistReasonImpoundment;

  /// No description provided for @blacklistReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get blacklistReasonOther;

  /// No description provided for @blacklistWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened? (dates, car, amount)'**
  String get blacklistWhatHappened;

  /// No description provided for @blacklistReportButton.
  ///
  /// In en, this message translates to:
  /// **'Report to Blacklist'**
  String get blacklistReportButton;

  /// No description provided for @blacklistMyReports.
  ///
  /// In en, this message translates to:
  /// **'My reports ({count})'**
  String blacklistMyReports(int count);

  /// No description provided for @blacklistNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports from this shop yet. Reports cannot be undone by the shop — only the tribunal admin can revert one.'**
  String get blacklistNoReports;

  /// No description provided for @blacklistEnterCnic.
  ///
  /// In en, this message translates to:
  /// **'Enter the full 13-digit CNIC of the customer.'**
  String get blacklistEnterCnic;

  /// No description provided for @blacklistDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened — the tribunal reads this.'**
  String get blacklistDescribe;

  /// No description provided for @blacklistReported.
  ///
  /// In en, this message translates to:
  /// **'Reported. The CNIC is now flagged for every shop.'**
  String get blacklistReported;

  /// No description provided for @blacklistLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load blacklist reports. Please try again.'**
  String get blacklistLoadError;

  /// No description provided for @blacklistReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report failed: {error}'**
  String blacklistReportFailed(String error);

  /// No description provided for @blacklistReverted.
  ///
  /// In en, this message translates to:
  /// **'Reverted'**
  String get blacklistReverted;

  /// No description provided for @financeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts, ledger and profit'**
  String get financeSubtitle;

  /// No description provided for @financeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get financeThisMonth;

  /// No description provided for @financeLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get financeLastMonth;

  /// No description provided for @financeAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get financeAllTime;

  /// No description provided for @financeNetAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Rs. {amount}'**
  String financeNetAmount(String amount);

  /// No description provided for @financeMonthBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Bookings Rs. {bookings} • Other income Rs. {income} • Expenses Rs. {expenses}'**
  String financeMonthBreakdown(String bookings, String income, String expenses);

  /// No description provided for @financeCustomerDues.
  ///
  /// In en, this message translates to:
  /// **'Customer dues'**
  String get financeCustomerDues;

  /// No description provided for @financeCashClosing.
  ///
  /// In en, this message translates to:
  /// **'Cash closing'**
  String get financeCashClosing;

  /// No description provided for @financeCarPnl.
  ///
  /// In en, this message translates to:
  /// **'Car P&L'**
  String get financeCarPnl;

  /// No description provided for @financeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financeIncome;

  /// No description provided for @financeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get financeExpense;

  /// No description provided for @financeCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get financeCategoryRent;

  /// No description provided for @financeCategoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get financeCategoryFuel;

  /// No description provided for @financeCategorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get financeCategorySalary;

  /// No description provided for @financeCategoryPartnerShare.
  ///
  /// In en, this message translates to:
  /// **'Partner share'**
  String get financeCategoryPartnerShare;

  /// No description provided for @financeCategoryDepositRefund.
  ///
  /// In en, this message translates to:
  /// **'Deposit refund'**
  String get financeCategoryDepositRefund;

  /// No description provided for @financeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeCategoryLabel;

  /// No description provided for @financeNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get financeNoteOptional;

  /// No description provided for @financeLedgerAmount.
  ///
  /// In en, this message translates to:
  /// **'{sign} Rs. {amount}'**
  String financeLedgerAmount(String sign, String amount);

  /// No description provided for @financeAccountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get financeAccountTypeCash;

  /// No description provided for @financeAccountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get financeAccountTypeBank;

  /// No description provided for @financeAccountTypeJazzCash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get financeAccountTypeJazzCash;

  /// No description provided for @financeAccountTypeEasyPaisa.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa'**
  String get financeAccountTypeEasyPaisa;

  /// No description provided for @financeAccountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get financeAccountTypeLabel;

  /// No description provided for @financeAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get financeAccountsTitle;

  /// No description provided for @financeAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get financeAccountsEmpty;

  /// No description provided for @financeAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get financeAddAccount;

  /// No description provided for @financeLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get financeLedgerTitle;

  /// No description provided for @financeAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get financeAddEntry;

  /// No description provided for @financeLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet — record your first income or expense.'**
  String get financeLedgerEmpty;

  /// No description provided for @financeAccountFallback.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get financeAccountFallback;

  /// No description provided for @financeSecurityDeposits.
  ///
  /// In en, this message translates to:
  /// **'Security Deposits'**
  String get financeSecurityDeposits;

  /// No description provided for @financeDepositsHeld.
  ///
  /// In en, this message translates to:
  /// **'Held now'**
  String get financeDepositsHeld;

  /// No description provided for @financeDepositsRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded in full'**
  String get financeDepositsRefunded;

  /// No description provided for @financeDepositsDeducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted at return'**
  String get financeDepositsDeducted;

  /// No description provided for @financeDepositsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} deposit} other{{count} deposits}}'**
  String financeDepositsCount(int count);

  /// No description provided for @financePartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get financePartners;

  /// No description provided for @financeAddPartner.
  ///
  /// In en, this message translates to:
  /// **'Add partner'**
  String get financeAddPartner;

  /// No description provided for @financePartnersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No partners yet — add one to record their share.'**
  String get financePartnersEmpty;

  /// No description provided for @financePartnerShareLine.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of profit'**
  String financePartnerShareLine(int percent);

  /// No description provided for @financeSaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get financeSaveAccount;

  /// No description provided for @financeAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get financeAccountName;

  /// No description provided for @financeSavePartner.
  ///
  /// In en, this message translates to:
  /// **'Save partner'**
  String get financeSavePartner;

  /// No description provided for @financePartnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner name'**
  String get financePartnerName;

  /// No description provided for @financePartnerShare.
  ///
  /// In en, this message translates to:
  /// **'Share (%)'**
  String get financePartnerShare;

  /// No description provided for @financeAddTransfer.
  ///
  /// In en, this message translates to:
  /// **'Add ledger entry'**
  String get financeAddTransfer;

  /// No description provided for @financeAmountRs.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs.)'**
  String get financeAmountRs;

  /// No description provided for @financeVehicleOptional.
  ///
  /// In en, this message translates to:
  /// **'Vehicle (optional — for car P&L)'**
  String get financeVehicleOptional;

  /// No description provided for @financeNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No vehicle'**
  String get financeNoVehicle;

  /// No description provided for @financeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. driver salary — Ahmed'**
  String get financeNoteHint;

  /// No description provided for @financeSaveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get financeSaveEntry;

  /// No description provided for @financeClosingExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected in till today'**
  String get financeClosingExpected;

  /// No description provided for @financeClosingOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening Rs. {opening} • Difference Rs. {difference}'**
  String financeClosingOpening(String opening, String difference);

  /// No description provided for @financeClosingCounted.
  ///
  /// In en, this message translates to:
  /// **'Counted Rs. {counted} • Diff Rs. {difference}'**
  String financeClosingCounted(String counted, String difference);

  /// No description provided for @financePnlTitle.
  ///
  /// In en, this message translates to:
  /// **'P&L Statement'**
  String get financePnlTitle;

  /// No description provided for @financePnlBookingRevenue.
  ///
  /// In en, this message translates to:
  /// **'Booking revenue'**
  String get financePnlBookingRevenue;

  /// No description provided for @financePnlOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get financePnlOtherIncome;

  /// No description provided for @financePnlExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financePnlExpenses;

  /// No description provided for @financePnlNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get financePnlNetProfit;

  /// No description provided for @pnlLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get pnlLoss;

  /// No description provided for @financePnlExport.
  ///
  /// In en, this message translates to:
  /// **'Export P&L as CSV (opens in Excel)'**
  String get financePnlExport;

  /// No description provided for @financeCarPnlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One car, all its money'**
  String get financeCarPnlSubtitle;

  /// No description provided for @financeCarPnlNoCars.
  ///
  /// In en, this message translates to:
  /// **'No cars in the fleet yet.'**
  String get financeCarPnlNoCars;

  /// No description provided for @financeCarPnlTagged.
  ///
  /// In en, this message translates to:
  /// **'Tagged entries'**
  String get financeCarPnlTagged;

  /// No description provided for @financeCarPnlNoTagged.
  ///
  /// In en, this message translates to:
  /// **'Nothing tagged to this car yet — tag an entry in the ledger.'**
  String get financeCarPnlNoTagged;

  /// No description provided for @financeCarPnlBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Booking revenue Rs. {revenue} • Other income Rs. {income} • Expenses Rs. {expenses}'**
  String financeCarPnlBreakdown(String revenue, String income, String expenses);

  /// No description provided for @financeClosingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count the till, close the day'**
  String get financeClosingSubtitle;

  /// No description provided for @financeClosingCountedLabel.
  ///
  /// In en, this message translates to:
  /// **'Counted cash (Rs.)'**
  String get financeClosingCountedLabel;

  /// No description provided for @financeClosingSaving.
  ///
  /// In en, this message translates to:
  /// **'Closing...'**
  String get financeClosingSaving;

  /// No description provided for @financeClosingButton.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get financeClosingButton;

  /// No description provided for @financeClosingPast.
  ///
  /// In en, this message translates to:
  /// **'Past closings'**
  String get financeClosingPast;

  /// No description provided for @financeClosingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No closings yet.'**
  String get financeClosingEmpty;

  /// No description provided for @financeClosingEnterCounted.
  ///
  /// In en, this message translates to:
  /// **'Enter the counted cash first.'**
  String get financeClosingEnterCounted;

  /// No description provided for @financeClosingClosed.
  ///
  /// In en, this message translates to:
  /// **'Day closed — difference Rs. {difference}.'**
  String financeClosingClosed(String difference);

  /// No description provided for @cashClosingShortBy.
  ///
  /// In en, this message translates to:
  /// **'Short by Rs. {amount}'**
  String cashClosingShortBy(String amount);

  /// No description provided for @cashClosingOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by Rs. {amount}'**
  String cashClosingOverBy(String amount);

  /// No description provided for @financeDuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Dues'**
  String get financeDuesTitle;

  /// No description provided for @financeDuesOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount} outstanding'**
  String financeDuesOutstanding(String amount);

  /// No description provided for @financeDuesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No outstanding dues. All clear.'**
  String get financeDuesEmpty;

  /// No description provided for @financeDuesBookingsLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} booking} other{{count} bookings}} • {phone}'**
  String financeDuesBookingsLine(int count, String phone);

  /// No description provided for @financeDuesNoPhone.
  ///
  /// In en, this message translates to:
  /// **'no phone'**
  String get financeDuesNoPhone;

  /// No description provided for @financeDuesLastReminded.
  ///
  /// In en, this message translates to:
  /// **'Last reminded {day}/{month}/{year}'**
  String financeDuesLastReminded(int day, int month, int year);

  /// No description provided for @financeDuesLastRemindedDate.
  ///
  /// In en, this message translates to:
  /// **'Last reminded {date}'**
  String financeDuesLastRemindedDate(String date);

  /// No description provided for @financeDuesRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind on WhatsApp'**
  String get financeDuesRemind;

  /// No description provided for @financeDuesRemindAgain.
  ///
  /// In en, this message translates to:
  /// **'Remind again on WhatsApp'**
  String get financeDuesRemindAgain;

  /// No description provided for @financeDuesNoPhoneError.
  ///
  /// In en, this message translates to:
  /// **'No phone number for this customer.'**
  String get financeDuesNoPhoneError;

  /// No description provided for @financeDuesReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum {name}, your RentalHub balance of Rs. {due} is pending. Please clear it at your earliest convenience. Thank you!'**
  String financeDuesReminderMessage(String name, String due);

  /// No description provided for @financeDuesWhatsappFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get financeDuesWhatsappFailed;

  /// No description provided for @financeDuesReminderSent.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp opened — send the reminder from the chat.'**
  String get financeDuesReminderSent;

  /// No description provided for @financeDuesAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Automated WhatsApp reminders (every 3 days) need the WhatsApp Business setup — Phase I.'**
  String get financeDuesAutoNote;

  /// No description provided for @handoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Handover & Inspection'**
  String get handoverTitle;

  /// No description provided for @handoverOdometerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid odometer reading.'**
  String get handoverOdometerInvalid;

  /// No description provided for @handoverSignRequired.
  ///
  /// In en, this message translates to:
  /// **'Both customer and host must sign on the pads before vehicle departure.'**
  String get handoverSignRequired;

  /// No description provided for @handoverCertified.
  ///
  /// In en, this message translates to:
  /// **'Handover certified! Digital A4 rental contract generated.'**
  String get handoverCertified;

  /// No description provided for @handoverShopNameRequired.
  ///
  /// In en, this message translates to:
  /// **'The shop name could not be loaded. Retry the load before certifying the handover.'**
  String get handoverShopNameRequired;

  /// No description provided for @handoverCompleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Handover completion failed: {error}'**
  String handoverCompleteFailed(String error);

  /// No description provided for @handoverIssuing.
  ///
  /// In en, this message translates to:
  /// **'Issuing Digital Contract...'**
  String get handoverIssuing;

  /// No description provided for @handoverCertify.
  ///
  /// In en, this message translates to:
  /// **'Certify Handover & Generate Contract'**
  String get handoverCertify;

  /// No description provided for @handoverTelemetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Telemetry Inspection'**
  String get handoverTelemetryTitle;

  /// No description provided for @handoverOdometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer Reading (KM):'**
  String get handoverOdometerLabel;

  /// No description provided for @handoverOdometerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 45200'**
  String get handoverOdometerHint;

  /// No description provided for @handoverFuelLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Level Gauge:'**
  String get handoverFuelLabel;

  /// No description provided for @handoverFuelQuarter.
  ///
  /// In en, this message translates to:
  /// **'1/4 (25%)'**
  String get handoverFuelQuarter;

  /// No description provided for @handoverFuelHalf.
  ///
  /// In en, this message translates to:
  /// **'2/4 (50%)'**
  String get handoverFuelHalf;

  /// No description provided for @handoverFuelThreeQuarter.
  ///
  /// In en, this message translates to:
  /// **'3/4 (75%)'**
  String get handoverFuelThreeQuarter;

  /// No description provided for @handoverFuelFull.
  ///
  /// In en, this message translates to:
  /// **'4/4 (Full)'**
  String get handoverFuelFull;

  /// No description provided for @handoverSignaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dual Legal Endorsement & Signatures'**
  String get handoverSignaturesTitle;

  /// No description provided for @handoverCustomerSignature.
  ///
  /// In en, this message translates to:
  /// **'Customer / Hirer Digital Signature'**
  String get handoverCustomerSignature;

  /// No description provided for @handoverCustomerSignatureHint.
  ///
  /// In en, this message translates to:
  /// **'Certifies physical receipt of car & documents'**
  String get handoverCustomerSignatureHint;

  /// No description provided for @handoverHostSignature.
  ///
  /// In en, this message translates to:
  /// **'Showroom Host / Manager Signature'**
  String get handoverHostSignature;

  /// No description provided for @handoverHostSignatureHint.
  ///
  /// In en, this message translates to:
  /// **'Authorized release by showroom representative'**
  String get handoverHostSignatureHint;

  /// No description provided for @handoverClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get handoverClear;

  /// No description provided for @handoverDamageTitle.
  ///
  /// In en, this message translates to:
  /// **'Damage & Condition Notes'**
  String get handoverDamageTitle;

  /// No description provided for @handoverDamageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Note every scratch, dent or missing item now — this is what the return inspection compares against.'**
  String get handoverDamageSubtitle;

  /// No description provided for @handoverDamageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Scratch on right door'**
  String get handoverDamageHint;

  /// No description provided for @handoverAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get handoverAdd;

  /// No description provided for @handoverNotedAt.
  ///
  /// In en, this message translates to:
  /// **'Noted at handover: {notes}'**
  String handoverNotedAt(String notes);

  /// No description provided for @returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Return & Settlement'**
  String get returnTitle;

  /// No description provided for @returnTripAudit.
  ///
  /// In en, this message translates to:
  /// **'Trip Audit #{id}'**
  String returnTripAudit(String id);

  /// No description provided for @returnOdometerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the return odometer reading.'**
  String get returnOdometerInvalid;

  /// No description provided for @returnOdometerBelow.
  ///
  /// In en, this message translates to:
  /// **'The return reading cannot be below the handover reading ({odometer} KM).'**
  String returnOdometerBelow(int odometer);

  /// No description provided for @returnSettled.
  ///
  /// In en, this message translates to:
  /// **'Vehicle returned! Deposit settled — Rs. {refund} refunded.'**
  String returnSettled(String refund);

  /// No description provided for @returnFinalizeFailed.
  ///
  /// In en, this message translates to:
  /// **'Finalizing return failed: {error}'**
  String returnFinalizeFailed(String error);

  /// No description provided for @returnTelemetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Telemetry Inspection'**
  String get returnTelemetryTitle;

  /// No description provided for @returnNewDamageTitle.
  ///
  /// In en, this message translates to:
  /// **'New Damage Found at Return'**
  String get returnNewDamageTitle;

  /// No description provided for @returnNewDamageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only damage that was not noted at handover — this is what the charge below covers.'**
  String get returnNewDamageSubtitle;

  /// No description provided for @returnDamageChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Damage charge (Rs.)'**
  String get returnDamageChargeLabel;

  /// No description provided for @returnDamageChargeHint.
  ///
  /// In en, this message translates to:
  /// **'0 if nothing new was found'**
  String get returnDamageChargeHint;

  /// No description provided for @returnFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing Settlement...'**
  String get returnFinalizing;

  /// No description provided for @returnFinalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize Return & Settle Deposit'**
  String get returnFinalize;

  /// No description provided for @returnReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit & Return Balance Settlement'**
  String get returnReceiptTitle;

  /// No description provided for @returnReceiptTotalKm.
  ///
  /// In en, this message translates to:
  /// **'Total Kilometers Driven'**
  String get returnReceiptTotalKm;

  /// No description provided for @returnReceiptAllowance.
  ///
  /// In en, this message translates to:
  /// **'Allowed KM Allowance'**
  String get returnReceiptAllowance;

  /// No description provided for @returnReceiptExcessPenalty.
  ///
  /// In en, this message translates to:
  /// **'Excess KM Penalty ({excess} km × Rs. {rate})'**
  String returnReceiptExcessPenalty(int excess, String rate);

  /// No description provided for @returnReceiptFuelDeficit.
  ///
  /// In en, this message translates to:
  /// **'Fuel Level Deficit'**
  String get returnReceiptFuelDeficit;

  /// No description provided for @returnReceiptOvertime.
  ///
  /// In en, this message translates to:
  /// **'Late Overtime Fee'**
  String get returnReceiptOvertime;

  /// No description provided for @returnReceiptDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage Found at Return'**
  String get returnReceiptDamage;

  /// No description provided for @returnReceiptDepositHeld.
  ///
  /// In en, this message translates to:
  /// **'Initial Security Deposit Held'**
  String get returnReceiptDepositHeld;

  /// No description provided for @returnReceiptTotalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Total Incident / Penalty Deductions'**
  String get returnReceiptTotalDeductions;

  /// No description provided for @returnReceiptDeductionsAmount.
  ///
  /// In en, this message translates to:
  /// **'- Rs. {amount}'**
  String returnReceiptDeductionsAmount(String amount);

  /// No description provided for @returnReceiptNetRefund.
  ///
  /// In en, this message translates to:
  /// **'Net Refund to Customer'**
  String get returnReceiptNetRefund;

  /// No description provided for @returnPerKmActualFare.
  ///
  /// In en, this message translates to:
  /// **'Per-km fare (actual km)'**
  String get returnPerKmActualFare;

  /// No description provided for @returnPerKmExtraDue.
  ///
  /// In en, this message translates to:
  /// **'Extra fare due'**
  String get returnPerKmExtraDue;

  /// No description provided for @returnPerKmRefundDue.
  ///
  /// In en, this message translates to:
  /// **'Fare refund due'**
  String get returnPerKmRefundDue;

  /// No description provided for @contractTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Rental Contract'**
  String get contractTitle;

  /// No description provided for @contractLegalRef.
  ///
  /// In en, this message translates to:
  /// **'Legal Agreement Ref: #{id}'**
  String contractLegalRef(String id);

  /// No description provided for @contractSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get contractSharePdf;

  /// No description provided for @contractPrintPdf.
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get contractPrintPdf;

  /// No description provided for @contractPdfUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The agreement PDF is not available yet.'**
  String get contractPdfUnavailable;

  /// No description provided for @contractNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Agreement not available yet'**
  String get contractNotAvailable;

  /// No description provided for @contractShareText.
  ///
  /// In en, this message translates to:
  /// **'Rental agreement #{id}'**
  String contractShareText(String id);

  /// No description provided for @contractScanVerify.
  ///
  /// In en, this message translates to:
  /// **'Scan to verify this agreement — the page shows the booking, the shop and the signed PDF.'**
  String get contractScanVerify;

  /// No description provided for @contractProceedReturn.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Return & Settlement'**
  String get contractProceedReturn;

  /// No description provided for @contractProceedReturnHint.
  ///
  /// In en, this message translates to:
  /// **'Available once the car is handed over'**
  String get contractProceedReturnHint;

  /// No description provided for @contractAgencyLine.
  ///
  /// In en, this message translates to:
  /// **'Govt. Registered Commercial Motor Car Rental Agency'**
  String get contractAgencyLine;

  /// No description provided for @contractCertifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'RENTAL AGREEMENT'**
  String get contractCertifiedTitle;

  /// No description provided for @contractFieldAgreementNo.
  ///
  /// In en, this message translates to:
  /// **'Agreement No:'**
  String get contractFieldAgreementNo;

  /// No description provided for @contractFieldHirer.
  ///
  /// In en, this message translates to:
  /// **'Hirer / Customer:'**
  String get contractFieldHirer;

  /// No description provided for @contractFieldContact.
  ///
  /// In en, this message translates to:
  /// **'Customer Contact:'**
  String get contractFieldContact;

  /// No description provided for @contractFieldCnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC:'**
  String get contractFieldCnic;

  /// No description provided for @contractFieldVehicle.
  ///
  /// In en, this message translates to:
  /// **'Rented Vehicle:'**
  String get contractFieldVehicle;

  /// No description provided for @contractFieldPackage.
  ///
  /// In en, this message translates to:
  /// **'Package Tier:'**
  String get contractFieldPackage;

  /// No description provided for @contractFieldOdometer.
  ///
  /// In en, this message translates to:
  /// **'Departure Odometer:'**
  String get contractFieldOdometer;

  /// No description provided for @contractFieldFuel.
  ///
  /// In en, this message translates to:
  /// **'Handover Fuel Gauge:'**
  String get contractFieldFuel;

  /// No description provided for @contractFieldTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Rental Paid:'**
  String get contractFieldTotalPaid;

  /// No description provided for @contractFieldDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit:'**
  String get contractFieldDeposit;

  /// No description provided for @contractWalkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get contractWalkInCustomer;

  /// No description provided for @contractNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get contractNotProvided;

  /// No description provided for @contractChauffeur.
  ///
  /// In en, this message translates to:
  /// **'Chauffeur'**
  String get contractChauffeur;

  /// No description provided for @contractDepositRefundable.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount} (refundable)'**
  String contractDepositRefundable(String amount);

  /// No description provided for @contractTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Terms & Conditions (Pakistan Jurisdiction):'**
  String get contractTermsTitle;

  /// No description provided for @contractTerm1.
  ///
  /// In en, this message translates to:
  /// **'1. The vehicle shall be used within city limits unless an out-city rate has been agreed.'**
  String get contractTerm1;

  /// No description provided for @contractTerm2.
  ///
  /// In en, this message translates to:
  /// **'2. Traffic challans, e-tickets and fuel consumed are sole liability of the hirer.'**
  String get contractTerm2;

  /// No description provided for @contractTerm3.
  ///
  /// In en, this message translates to:
  /// **'3. Any default will result in immediate non-bailable FIR and National Tribunal Blacklist listing.'**
  String get contractTerm3;

  /// No description provided for @contractHirerSignature.
  ///
  /// In en, this message translates to:
  /// **'Hirer Signature'**
  String get contractHirerSignature;

  /// No description provided for @contractSignedOnPad.
  ///
  /// In en, this message translates to:
  /// **'Signed on the pad'**
  String get contractSignedOnPad;

  /// No description provided for @contractHostSignature.
  ///
  /// In en, this message translates to:
  /// **'Host Seal & Signature'**
  String get contractHostSignature;

  /// No description provided for @contractAuthorizedManager.
  ///
  /// In en, this message translates to:
  /// **'Authorized Agency Manager'**
  String get contractAuthorizedManager;

  /// No description provided for @paymentVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment Proof'**
  String get paymentVerificationTitle;

  /// No description provided for @paymentVerificationBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id}'**
  String paymentVerificationBooking(String id);

  /// No description provided for @paymentVerificationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed — booking #{id} is paid.'**
  String paymentVerificationConfirmed(String id);

  /// No description provided for @paymentVerificationConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Confirmation failed: {error}'**
  String paymentVerificationConfirmFailed(String error);

  /// No description provided for @paymentVerificationRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this proof?'**
  String get paymentVerificationRejectTitle;

  /// No description provided for @paymentVerificationRejectNote.
  ///
  /// In en, this message translates to:
  /// **'The customer sees this reason and can upload a new proof.'**
  String get paymentVerificationRejectNote;

  /// No description provided for @paymentVerificationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get paymentVerificationReasonLabel;

  /// No description provided for @paymentVerificationReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Screenshot is unreadable'**
  String get paymentVerificationReasonHint;

  /// No description provided for @paymentVerificationRejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject Proof'**
  String get paymentVerificationRejectButton;

  /// No description provided for @paymentVerificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Proof rejected — the customer can upload a new one.'**
  String get paymentVerificationRejected;

  /// No description provided for @paymentVerificationRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Rejection failed: {error}'**
  String paymentVerificationRejectFailed(String error);

  /// No description provided for @paymentVerificationTotalRent.
  ///
  /// In en, this message translates to:
  /// **'Total rent'**
  String get paymentVerificationTotalRent;

  /// No description provided for @paymentVerificationAdvanceDue.
  ///
  /// In en, this message translates to:
  /// **'Advance due'**
  String get paymentVerificationAdvanceDue;

  /// No description provided for @paymentVerificationAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance paid'**
  String get paymentVerificationAdvancePaid;

  /// No description provided for @paymentVerificationTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get paymentVerificationTransactionId;

  /// No description provided for @paymentVerificationScreenshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment screenshot'**
  String get paymentVerificationScreenshotTitle;

  /// No description provided for @paymentVerificationProofUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Proof image unavailable — ask the customer to resend it.'**
  String get paymentVerificationProofUnavailable;

  /// No description provided for @proofImageOpenFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Open proof image fullscreen'**
  String get proofImageOpenFullscreen;

  /// No description provided for @paymentVerificationNoScreenshot.
  ///
  /// In en, this message translates to:
  /// **'No screenshot attached.'**
  String get paymentVerificationNoScreenshot;

  /// No description provided for @paymentVerificationPreviouslyRejected.
  ///
  /// In en, this message translates to:
  /// **'Previously rejected: {reason}'**
  String paymentVerificationPreviouslyRejected(String reason);

  /// No description provided for @paymentVerificationConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get paymentVerificationConfirming;

  /// No description provided for @manualBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Booking Wizard'**
  String get manualBookingTitle;

  /// No description provided for @walkInBookingButton.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Booking'**
  String get walkInBookingButton;

  /// No description provided for @manualBookingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showroom Counter Direct Issue'**
  String get manualBookingSubtitle;

  /// No description provided for @manualBookingCustomerSection.
  ///
  /// In en, this message translates to:
  /// **'Customer KYC Details'**
  String get manualBookingCustomerSection;

  /// No description provided for @manualBookingGuarantorSection.
  ///
  /// In en, this message translates to:
  /// **'Guarantor (optional)'**
  String get manualBookingGuarantorSection;

  /// No description provided for @manualBookingVehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Package Selection'**
  String get manualBookingVehicleSection;

  /// No description provided for @manualBookingCompleteDetails.
  ///
  /// In en, this message translates to:
  /// **'Please complete all customer details.'**
  String get manualBookingCompleteDetails;

  /// No description provided for @manualBookingSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Please select a vehicle and package.'**
  String get manualBookingSelectVehicle;

  /// No description provided for @manualBookingBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'This CNIC is blacklisted — walk-in booking refused.'**
  String get manualBookingBlacklisted;

  /// No description provided for @manualBookingRegistered.
  ///
  /// In en, this message translates to:
  /// **'Walk-in booking #{id} registered!'**
  String manualBookingRegistered(String id);

  /// No description provided for @manualBookingAdvanceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid advance amount.'**
  String get manualBookingAdvanceInvalid;

  /// No description provided for @manualBookingCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking creation failed: {error}'**
  String manualBookingCreateFailed(String error);

  /// No description provided for @manualBookingCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating Walk-in Record...'**
  String get manualBookingCreating;

  /// No description provided for @manualBookingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Proceed to Handover'**
  String get manualBookingConfirm;

  /// No description provided for @manualBookingCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Full Name'**
  String get manualBookingCustomerName;

  /// No description provided for @manualBookingNadraCnic.
  ///
  /// In en, this message translates to:
  /// **'NADRA CNIC'**
  String get manualBookingNadraCnic;

  /// No description provided for @manualBookingSelectVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Select Showroom Vehicle'**
  String get manualBookingSelectVehicleHint;

  /// No description provided for @manualBookingSelectVehicleFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a vehicle first to see its packages.'**
  String get manualBookingSelectVehicleFirst;

  /// No description provided for @manualBookingNoPackages.
  ///
  /// In en, this message translates to:
  /// **'This vehicle has no packages enabled.'**
  String get manualBookingNoPackages;

  /// No description provided for @manualBookingPackageChip.
  ///
  /// In en, this message translates to:
  /// **'{label} • Rs. {price}'**
  String manualBookingPackageChip(String label, String price);

  /// No description provided for @manualBookingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: Rs. {total}'**
  String manualBookingTotal(String total);

  /// No description provided for @manualBookingDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit (Rs.)'**
  String get manualBookingDepositLabel;

  /// No description provided for @manualBookingGuarantorNotFound.
  ///
  /// In en, this message translates to:
  /// **'No saved customer with that CNIC — add them below.'**
  String get manualBookingGuarantorNotFound;

  /// No description provided for @manualBookingGuarantorBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'This CNIC is blacklisted and cannot be a guarantor.'**
  String get manualBookingGuarantorBlacklisted;

  /// No description provided for @manualBookingGuarantorRequired.
  ///
  /// In en, this message translates to:
  /// **'Name, phone and CNIC are required for a guarantor.'**
  String get manualBookingGuarantorRequired;

  /// No description provided for @manualBookingGuarantorRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove guarantor'**
  String get manualBookingGuarantorRemove;

  /// No description provided for @manualBookingGuarantorSearch.
  ///
  /// In en, this message translates to:
  /// **'Search guarantor by CNIC'**
  String get manualBookingGuarantorSearch;

  /// No description provided for @manualBookingGuarantorFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get manualBookingGuarantorFind;

  /// No description provided for @manualBookingGuarantorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved customers yet.'**
  String get manualBookingGuarantorEmpty;

  /// No description provided for @manualBookingGuarantorHide.
  ///
  /// In en, this message translates to:
  /// **'Hide new guarantor'**
  String get manualBookingGuarantorHide;

  /// No description provided for @manualBookingGuarantorAdd.
  ///
  /// In en, this message translates to:
  /// **'Add new guarantor'**
  String get manualBookingGuarantorAdd;

  /// No description provided for @manualBookingGuarantorName.
  ///
  /// In en, this message translates to:
  /// **'Guarantor full name'**
  String get manualBookingGuarantorName;

  /// No description provided for @manualBookingGuarantorCnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC number'**
  String get manualBookingGuarantorCnic;

  /// No description provided for @manualBookingGuarantorRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship (e.g. Father, Brother, Friend)'**
  String get manualBookingGuarantorRelationship;

  /// No description provided for @manualBookingGuarantorSave.
  ///
  /// In en, this message translates to:
  /// **'Save & Select Guarantor'**
  String get manualBookingGuarantorSave;

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Booking QR'**
  String get qrScanTitle;

  /// No description provided for @qrScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the customer’s booking code'**
  String get qrScanSubtitle;

  /// No description provided for @qrOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get qrOpen;

  /// No description provided for @qrScanOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get qrScanOpenSettings;

  /// No description provided for @qrCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is off — RentalHub cannot scan QR codes.'**
  String get qrCameraDenied;

  /// No description provided for @qrCameraDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera in the app settings, or type the booking id below.'**
  String get qrCameraDeniedHint;

  /// No description provided for @qrCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable — {detail}'**
  String qrCameraUnavailable(String detail);

  /// No description provided for @qrCameraUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Type the booking id below instead.'**
  String get qrCameraUnavailableHint;

  /// No description provided for @qrCameraSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Settings — open the app settings and allow the camera, then try again.'**
  String get qrCameraSettingsError;

  /// No description provided for @qrTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Torch on'**
  String get qrTorchOn;

  /// No description provided for @qrTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Torch off'**
  String get qrTorchOff;

  /// No description provided for @proofPickerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo picker — check the camera / photo permission and try again.'**
  String get proofPickerPermissionDenied;

  /// No description provided for @qrNoBooking.
  ///
  /// In en, this message translates to:
  /// **'No booking found for #{id}.'**
  String qrNoBooking(String id);

  /// No description provided for @qrOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the booking: {error}'**
  String qrOpenFailed(String error);

  /// No description provided for @qrNotBookingCode.
  ///
  /// In en, this message translates to:
  /// **'This is not a RentalHub booking code.'**
  String get qrNotBookingCode;

  /// No description provided for @qrTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Or type the booking id, e.g. RH-…'**
  String get qrTypeHint;

  /// No description provided for @onboardingCurrentGps.
  ///
  /// In en, this message translates to:
  /// **'Current GPS ({lat}, {lng})'**
  String onboardingCurrentGps(String lat, String lng);

  /// No description provided for @onboardingShopNameShort.
  ///
  /// In en, this message translates to:
  /// **'Shop name must be at least 3 characters.'**
  String get onboardingShopNameShort;

  /// No description provided for @onboardingAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid showroom address.'**
  String get onboardingAddressInvalid;

  /// No description provided for @onboardingPayoutRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enable at least one payout method.'**
  String get onboardingPayoutRequired;

  /// No description provided for @onboardingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Showroom profile submitted for verification!'**
  String get onboardingSubmitted;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String onboardingStepOf(int step);

  /// No description provided for @onboardingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Shop for Verification'**
  String get onboardingSubmit;

  /// No description provided for @onboardingNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get onboardingNextStep;

  /// No description provided for @onboardingHeaderShop.
  ///
  /// In en, this message translates to:
  /// **'Shop Registration'**
  String get onboardingHeaderShop;

  /// No description provided for @onboardingHeaderLocation.
  ///
  /// In en, this message translates to:
  /// **'Location & Map Pin'**
  String get onboardingHeaderLocation;

  /// No description provided for @onboardingHeaderPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout Accounts'**
  String get onboardingHeaderPayout;

  /// No description provided for @onboardingHeaderKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC & Verification'**
  String get onboardingHeaderKyc;

  /// No description provided for @onboardingHeaderSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted'**
  String get onboardingHeaderSubmitted;

  /// No description provided for @onboardingSubtitleShop.
  ///
  /// In en, this message translates to:
  /// **'Business identity and contact details'**
  String get onboardingSubtitleShop;

  /// No description provided for @onboardingSubtitleLocation.
  ///
  /// In en, this message translates to:
  /// **'Physical address and geo-coordinates'**
  String get onboardingSubtitleLocation;

  /// No description provided for @onboardingSubtitlePayout.
  ///
  /// In en, this message translates to:
  /// **'JazzCash, EasyPaisa or Pakistani Bank'**
  String get onboardingSubtitlePayout;

  /// No description provided for @onboardingSubtitleKyc.
  ///
  /// In en, this message translates to:
  /// **'Shop banner, 3 fleet photos & CNIC'**
  String get onboardingSubtitleKyc;

  /// No description provided for @onboardingSubtitleSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review status and fleet management'**
  String get onboardingSubtitleSubmitted;

  /// No description provided for @onboardingChangeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Shop Logo'**
  String get onboardingChangeLogo;

  /// No description provided for @onboardingUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Shop Logo / Storefront'**
  String get onboardingUploadLogo;

  /// No description provided for @onboardingShopLegalName.
  ///
  /// In en, this message translates to:
  /// **'Shop Registered Legal Name'**
  String get onboardingShopLegalName;

  /// No description provided for @onboardingShopNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Al-Falah Rent a Car'**
  String get onboardingShopNameHint;

  /// No description provided for @onboardingOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Full Name (as on CNIC)'**
  String get onboardingOwnerName;

  /// No description provided for @onboardingOwnerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed Raza'**
  String get onboardingOwnerNameHint;

  /// No description provided for @onboardingOwnerCnic.
  ///
  /// In en, this message translates to:
  /// **'Owner CNIC Number'**
  String get onboardingOwnerCnic;

  /// No description provided for @onboardingShopPhone.
  ///
  /// In en, this message translates to:
  /// **'Shop Landline / Alt Phone'**
  String get onboardingShopPhone;

  /// No description provided for @onboardingOperatingHours.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get onboardingOperatingHours;

  /// No description provided for @onboardingHours9to10.
  ///
  /// In en, this message translates to:
  /// **'9:00 AM - 10:00 PM'**
  String get onboardingHours9to10;

  /// No description provided for @onboardingHours8toMidnight.
  ///
  /// In en, this message translates to:
  /// **'8:00 AM - Midnight'**
  String get onboardingHours8toMidnight;

  /// No description provided for @onboardingHours24x7.
  ///
  /// In en, this message translates to:
  /// **'24 Hours / 7 Days'**
  String get onboardingHours24x7;

  /// No description provided for @onboardingHours10to8.
  ///
  /// In en, this message translates to:
  /// **'10:00 AM - 8:00 PM'**
  String get onboardingHours10to8;

  /// No description provided for @onboardingSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select Your City'**
  String get onboardingSelectCity;

  /// No description provided for @onboardingPinOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pin Showroom On Map'**
  String get onboardingPinOnMap;

  /// No description provided for @onboardingLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get onboardingLocating;

  /// No description provided for @onboardingUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use Current GPS'**
  String get onboardingUseGps;

  /// No description provided for @onboardingTapToPin.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on map to pin showroom ({lat}, {lng})'**
  String onboardingTapToPin(String lat, String lng);

  /// No description provided for @onboardingShopAddress.
  ///
  /// In en, this message translates to:
  /// **'Physical Showroom Address'**
  String get onboardingShopAddress;

  /// No description provided for @onboardingAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Shop number, plaza, street, sector / commercial area'**
  String get onboardingAddressHint;

  /// No description provided for @onboardingPayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout Accounts & Settlement'**
  String get onboardingPayoutTitle;

  /// No description provided for @onboardingPayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select at least one payout channel to receive rental bookings and customer advance deposits.'**
  String get onboardingPayoutSubtitle;

  /// No description provided for @onboardingJazzCashTitle.
  ///
  /// In en, this message translates to:
  /// **'JazzCash Mobile Account'**
  String get onboardingJazzCashTitle;

  /// No description provided for @onboardingJazzCashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant mobile wallet payout'**
  String get onboardingJazzCashSubtitle;

  /// No description provided for @onboardingEasyPaisaTitle.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa Wallet Account'**
  String get onboardingEasyPaisaTitle;

  /// No description provided for @onboardingEasyPaisaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant digital wallet payout'**
  String get onboardingEasyPaisaSubtitle;

  /// No description provided for @onboardingJazzCashNumber.
  ///
  /// In en, this message translates to:
  /// **'JazzCash Mobile Number'**
  String get onboardingJazzCashNumber;

  /// No description provided for @onboardingEasyPaisaNumber.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa Mobile Number'**
  String get onboardingEasyPaisaNumber;

  /// No description provided for @onboardingBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Commercial Bank'**
  String get onboardingBankTitle;

  /// No description provided for @onboardingBankSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1-Link / IBAN direct bank settlement'**
  String get onboardingBankSubtitle;

  /// No description provided for @onboardingSelectBank.
  ///
  /// In en, this message translates to:
  /// **'Select Bank Name'**
  String get onboardingSelectBank;

  /// No description provided for @onboardingAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number / IBAN'**
  String get onboardingAccountNumber;

  /// No description provided for @onboardingIbanHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. PK36MEZN0001234567890123'**
  String get onboardingIbanHint;

  /// No description provided for @onboardingAccountTitleBusiness.
  ///
  /// In en, this message translates to:
  /// **'Account Title (Business / Owner)'**
  String get onboardingAccountTitleBusiness;

  /// No description provided for @onboardingAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Title'**
  String get onboardingAccountTitle;

  /// No description provided for @onboardingTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Raza'**
  String get onboardingTitleHint;

  /// No description provided for @onboardingStepShopDetails.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get onboardingStepShopDetails;

  /// No description provided for @onboardingStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get onboardingStepLocation;

  /// No description provided for @onboardingStepPayouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get onboardingStepPayouts;

  /// No description provided for @onboardingStepKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC Docs'**
  String get onboardingStepKyc;

  /// No description provided for @onboardingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Application Submitted!'**
  String get onboardingApprovalTitle;

  /// No description provided for @onboardingApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your shop profile and KYC credentials have been routed to the Super Admin desk. You will receive SMS & WhatsApp verification within 2 to 4 business hours.'**
  String get onboardingApprovalMessage;

  /// No description provided for @onboardingFleetReady.
  ///
  /// In en, this message translates to:
  /// **'Fleet Catalog Ready'**
  String get onboardingFleetReady;

  /// No description provided for @onboardingFleetReadyHint.
  ///
  /// In en, this message translates to:
  /// **'You can start adding your cars, setting 1h/3h/6h/24h rates and photos right now.'**
  String get onboardingFleetReadyHint;

  /// No description provided for @onboardingManageFleet.
  ///
  /// In en, this message translates to:
  /// **'Manage Fleet & Add Vehicles'**
  String get onboardingManageFleet;

  /// No description provided for @onboardingHeaderBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Header Showcase Banner'**
  String get onboardingHeaderBannerTitle;

  /// No description provided for @onboardingHeaderBannerHint.
  ///
  /// In en, this message translates to:
  /// **'Upload photo from camera or gallery. Appears at the top of your public profile.'**
  String get onboardingHeaderBannerHint;

  /// No description provided for @onboardingHeaderBannerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shop Header Banner Photo'**
  String get onboardingHeaderBannerPhoto;

  /// No description provided for @onboardingFleetPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Showroom Fleet Photos (3 Required)'**
  String get onboardingFleetPhotosTitle;

  /// No description provided for @onboardingFleetPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Upload authentic photos of cars parked at your showroom.'**
  String get onboardingFleetPhotosHint;

  /// No description provided for @onboardingFleetCar1.
  ///
  /// In en, this message translates to:
  /// **'Fleet Car 1'**
  String get onboardingFleetCar1;

  /// No description provided for @onboardingFleetCar2.
  ///
  /// In en, this message translates to:
  /// **'Fleet Car 2'**
  String get onboardingFleetCar2;

  /// No description provided for @onboardingFleetCar3.
  ///
  /// In en, this message translates to:
  /// **'Fleet Car 3'**
  String get onboardingFleetCar3;

  /// No description provided for @onboardingIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner Identity & Tax Verification'**
  String get onboardingIdentityTitle;

  /// No description provided for @onboardingIdentityHint.
  ///
  /// In en, this message translates to:
  /// **'Mandatory compliance for showroom verification.'**
  String get onboardingIdentityHint;

  /// No description provided for @onboardingCnicFront.
  ///
  /// In en, this message translates to:
  /// **'CNIC Front Photo'**
  String get onboardingCnicFront;

  /// No description provided for @onboardingCnicFrontHint.
  ///
  /// In en, this message translates to:
  /// **'Daylight photo of owner CNIC front'**
  String get onboardingCnicFrontHint;

  /// No description provided for @onboardingCnicBack.
  ///
  /// In en, this message translates to:
  /// **'CNIC Back Photo'**
  String get onboardingCnicBack;

  /// No description provided for @onboardingCnicBackHint.
  ///
  /// In en, this message translates to:
  /// **'Daylight photo showing permanent address'**
  String get onboardingCnicBackHint;

  /// No description provided for @onboardingNtn.
  ///
  /// In en, this message translates to:
  /// **'FBR NTN Certificate / Business Registration'**
  String get onboardingNtn;

  /// No description provided for @onboardingNtnHint.
  ///
  /// In en, this message translates to:
  /// **'Verified filer certificate or showroom deed'**
  String get onboardingNtnHint;

  /// No description provided for @onboardingSelfie.
  ///
  /// In en, this message translates to:
  /// **'Owner Live Selfie Holding CNIC (Front Camera Only)'**
  String get onboardingSelfie;

  /// No description provided for @onboardingSelfieHint.
  ///
  /// In en, this message translates to:
  /// **'Instant live biometric selfie capture'**
  String get onboardingSelfieHint;

  /// No description provided for @onboardingDocReady.
  ///
  /// In en, this message translates to:
  /// **'Ready ✓'**
  String get onboardingDocReady;

  /// No description provided for @onboardingDocUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get onboardingDocUpload;

  /// No description provided for @onboardingDocRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get onboardingDocRemove;

  /// No description provided for @onboardingTapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload'**
  String get onboardingTapToUpload;

  /// No description provided for @onboardingOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get onboardingOptional;

  /// No description provided for @disputesOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complaints from your customers'**
  String get disputesOwnerSubtitle;

  /// No description provided for @disputesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String disputesFilterAll(int count);

  /// No description provided for @disputesFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open ({count})'**
  String disputesFilterOpen(int count);

  /// No description provided for @disputesFilterInReview.
  ///
  /// In en, this message translates to:
  /// **'In review ({count})'**
  String disputesFilterInReview(int count);

  /// No description provided for @disputesFilterResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved ({count})'**
  String disputesFilterResolved(int count);

  /// No description provided for @disputesNoneOpen.
  ///
  /// In en, this message translates to:
  /// **'No open disputes.'**
  String get disputesNoneOpen;

  /// No description provided for @disputesNoneInReview.
  ///
  /// In en, this message translates to:
  /// **'No in-review disputes.'**
  String get disputesNoneInReview;

  /// No description provided for @disputesNoneResolved.
  ///
  /// In en, this message translates to:
  /// **'No resolved disputes.'**
  String get disputesNoneResolved;

  /// No description provided for @disputesFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get disputesFallbackTitle;

  /// No description provided for @disputesBookingLine.
  ///
  /// In en, this message translates to:
  /// **'Booking {id} • {name}'**
  String disputesBookingLine(String id, String name);

  /// No description provided for @disputesNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description given.'**
  String get disputesNoDescription;

  /// No description provided for @disputesSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get disputesSaving;

  /// No description provided for @disputesUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update this dispute. Try again.'**
  String get disputesUpdateError;

  /// No description provided for @disputesMarkInReview.
  ///
  /// In en, this message translates to:
  /// **'Mark in review'**
  String get disputesMarkInReview;

  /// No description provided for @disputesMarkResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get disputesMarkResolved;

  /// No description provided for @disputesResolvedNote.
  ///
  /// In en, this message translates to:
  /// **'Resolved — no further action needed.'**
  String get disputesResolvedNote;

  /// No description provided for @disputesMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get disputesMonthJan;

  /// No description provided for @disputesMonthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get disputesMonthFeb;

  /// No description provided for @disputesMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get disputesMonthMar;

  /// No description provided for @disputesMonthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get disputesMonthApr;

  /// No description provided for @disputesMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get disputesMonthMay;

  /// No description provided for @disputesMonthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get disputesMonthJun;

  /// No description provided for @disputesMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get disputesMonthJul;

  /// No description provided for @disputesMonthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get disputesMonthAug;

  /// No description provided for @disputesMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get disputesMonthSep;

  /// No description provided for @disputesMonthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get disputesMonthOct;

  /// No description provided for @disputesMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get disputesMonthNov;

  /// No description provided for @disputesMonthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get disputesMonthDec;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What needs your attention'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not mark notifications as read. Please try again.'**
  String get notificationsMarkReadError;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications. Check your connection and try again.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @subscriptionUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {tier}'**
  String subscriptionUpgradeTo(String tier);

  /// No description provided for @subscriptionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get subscriptionClose;

  /// No description provided for @subscriptionTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer Rs. {price} via Raast / IBAN to activate instant showroom accreditation.'**
  String subscriptionTransfer(String price);

  /// No description provided for @subscriptionTrxLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer Transaction ID / Reference'**
  String get subscriptionTrxLabel;

  /// No description provided for @subscriptionTrxHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. TRX-998822'**
  String get subscriptionTrxHint;

  /// No description provided for @subscriptionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Upgrade Verification'**
  String get subscriptionSubmit;

  /// No description provided for @subscriptionEnterTrx.
  ///
  /// In en, this message translates to:
  /// **'Please enter transaction ID'**
  String get subscriptionEnterTrx;

  /// No description provided for @subscriptionRequested.
  ///
  /// In en, this message translates to:
  /// **'Upgrade requested! Super Admin review in progress.'**
  String get subscriptionRequested;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Showroom Membership Plans'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grow Your Showroom Fleet with RentalHub'**
  String get subscriptionSubtitle;

  /// No description provided for @subscriptionTierStarter.
  ///
  /// In en, this message translates to:
  /// **'Starter Freemium'**
  String get subscriptionTierStarter;

  /// No description provided for @subscriptionTierPro.
  ///
  /// In en, this message translates to:
  /// **'Pro Showroom'**
  String get subscriptionTierPro;

  /// No description provided for @subscriptionTierEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Fleet'**
  String get subscriptionTierEnterprise;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get subscriptionPerMonth;

  /// No description provided for @subscriptionForeverFree.
  ///
  /// In en, this message translates to:
  /// **'Forever Free'**
  String get subscriptionForeverFree;

  /// No description provided for @subscriptionFeatureMax3.
  ///
  /// In en, this message translates to:
  /// **'Max 3 Showroom Vehicles'**
  String get subscriptionFeatureMax3;

  /// No description provided for @subscriptionFeatureAgreements.
  ///
  /// In en, this message translates to:
  /// **'Standard Digital Agreements'**
  String get subscriptionFeatureAgreements;

  /// No description provided for @subscriptionFeatureVerification.
  ///
  /// In en, this message translates to:
  /// **'Customer Verification Check'**
  String get subscriptionFeatureVerification;

  /// No description provided for @subscriptionFeatureUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Fleet Vehicles'**
  String get subscriptionFeatureUnlimited;

  /// No description provided for @subscriptionFeatureRadar.
  ///
  /// In en, this message translates to:
  /// **'Real-time shared blacklist radar'**
  String get subscriptionFeatureRadar;

  /// No description provided for @subscriptionFeatureWhatsappInvoicing.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Automated Invoicing & Pass'**
  String get subscriptionFeatureWhatsappInvoicing;

  /// No description provided for @subscriptionFeaturePricingMatrix.
  ///
  /// In en, this message translates to:
  /// **'Custom Multi-tier Pricing Matrix'**
  String get subscriptionFeaturePricingMatrix;

  /// No description provided for @subscriptionFeatureMultiBranch.
  ///
  /// In en, this message translates to:
  /// **'Multi-branch Fleet Synchronization'**
  String get subscriptionFeatureMultiBranch;

  /// No description provided for @subscriptionFeatureManager.
  ///
  /// In en, this message translates to:
  /// **'Dedicated Account Manager'**
  String get subscriptionFeatureManager;

  /// No description provided for @subscriptionFeatureGps.
  ///
  /// In en, this message translates to:
  /// **'GPS Telematics API Integration'**
  String get subscriptionFeatureGps;

  /// No description provided for @subscriptionFeatureTribunal.
  ///
  /// In en, this message translates to:
  /// **'Priority Dispute Tribunal Hearings'**
  String get subscriptionFeatureTribunal;

  /// No description provided for @subscriptionMostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get subscriptionMostPopular;

  /// No description provided for @subscriptionCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get subscriptionCurrentPlan;

  /// No description provided for @subscriptionActivePlan.
  ///
  /// In en, this message translates to:
  /// **'Active Plan'**
  String get subscriptionActivePlan;

  /// No description provided for @whatsappLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Alert Dispatches'**
  String get whatsappLogsTitle;

  /// No description provided for @whatsappLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transactional Messaging Gateway • Live'**
  String get whatsappLogsSubtitle;

  /// No description provided for @whatsappLogsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get whatsappLogsDelivered;

  /// No description provided for @whatsappLogsRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get whatsappLogsRead;

  /// No description provided for @whatsappLogsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get whatsappLogsFailed;

  /// No description provided for @whatsappLogsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No WhatsApp messages sent yet'**
  String get whatsappLogsEmpty;

  /// No description provided for @whatsappLogsResent.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp notification re-dispatched via Meta Cloud API!'**
  String get whatsappLogsResent;

  /// No description provided for @whatsappLogsResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get whatsappLogsResend;

  /// No description provided for @onboardingWhatsappBusinessNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Business Number'**
  String get onboardingWhatsappBusinessNumber;

  /// No description provided for @disputesOwnerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No disputes yet — customer disputes for your showroom will appear here.'**
  String get disputesOwnerEmpty;

  /// No description provided for @manualBookingGuarantorPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get manualBookingGuarantorPhone;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get navShops;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get navSupport;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get navFleet;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navRequests;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @syncOfflineWithPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You\'re offline — 1 change will sync when you\'re back online} other{You\'re offline — {count} changes will sync when you\'re back online}}'**
  String syncOfflineWithPending(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — changes will sync when you\'re back online'**
  String get syncOffline;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change pending sync} other{{count} changes pending sync}}'**
  String syncPending(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change failed to sync — will retry} other{{count} changes failed to sync — will retry}}'**
  String syncFailed(int count);

  /// No description provided for @syncFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Sync failed — will retry'**
  String get syncFailedShort;

  /// No description provided for @syncFailedBanner.
  ///
  /// In en, this message translates to:
  /// **'Sync failed — tap to review'**
  String get syncFailedBanner;

  /// No description provided for @syncDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync details'**
  String get syncDetailsTitle;

  /// No description provided for @syncDetailsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncDetailsFailed;

  /// No description provided for @syncDetailsAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {count}'**
  String syncDetailsAttempts(int count);

  /// No description provided for @syncRetryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get syncRetryNow;

  /// No description provided for @syncDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscard;

  /// No description provided for @syncDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this change?'**
  String get syncDiscardTitle;

  /// No description provided for @syncDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'{kind} • {entity}\nIt will not sync.'**
  String syncDiscardBody(String kind, String entity);

  /// No description provided for @syncKindSavedChange.
  ///
  /// In en, this message translates to:
  /// **'Saved change'**
  String get syncKindSavedChange;

  /// No description provided for @syncKindFileUpload.
  ///
  /// In en, this message translates to:
  /// **'File upload'**
  String get syncKindFileUpload;

  /// No description provided for @syncKindHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover'**
  String get syncKindHandover;

  /// No description provided for @syncNoPending.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending'**
  String get syncNoPending;

  /// No description provided for @syncPendingShort.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get syncPendingShort;

  /// No description provided for @syncAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All changes synced'**
  String get syncAllSynced;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonShowValue.
  ///
  /// In en, this message translates to:
  /// **'Show value'**
  String get commonShowValue;

  /// No description provided for @commonHideValue.
  ///
  /// In en, this message translates to:
  /// **'Hide value'**
  String get commonHideValue;

  /// No description provided for @commonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonGoBack;

  /// No description provided for @headerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String headerGreeting(String name);

  /// No description provided for @headerGreetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Hi there'**
  String get headerGreetingFallback;

  /// No description provided for @headerUrduGreeting.
  ///
  /// In en, this message translates to:
  /// **'اسلام علیکم'**
  String get headerUrduGreeting;

  /// No description provided for @mediaSelectSource.
  ///
  /// In en, this message translates to:
  /// **'Select Media Source'**
  String get mediaSelectSource;

  /// No description provided for @mediaTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo (Back Camera)'**
  String get mediaTakePhoto;

  /// No description provided for @mediaTakePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Use device camera'**
  String get mediaTakePhotoHint;

  /// No description provided for @mediaChooseGalleryHint.
  ///
  /// In en, this message translates to:
  /// **'Pick existing photo or screenshot'**
  String get mediaChooseGalleryHint;

  /// No description provided for @mediaRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get mediaRemovePhoto;

  /// No description provided for @mediaRemovePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Clear this uploaded image'**
  String get mediaRemovePhotoHint;

  /// No description provided for @signatureAutoSign.
  ///
  /// In en, this message translates to:
  /// **'Auto Sign'**
  String get signatureAutoSign;

  /// No description provided for @signatureDrawArea.
  ///
  /// In en, this message translates to:
  /// **'Signature drawing area'**
  String get signatureDrawArea;

  /// No description provided for @signatureDrawHint.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature with your finger'**
  String get signatureDrawHint;

  /// No description provided for @signatureSignHere.
  ///
  /// In en, this message translates to:
  /// **'Sign here on screen ({name})'**
  String signatureSignHere(String name);

  /// No description provided for @signatureSignedBy.
  ///
  /// In en, this message translates to:
  /// **'Signed by: {name}'**
  String signatureSignedBy(String name);

  /// No description provided for @signatureNadraValidated.
  ///
  /// In en, this message translates to:
  /// **'Signature captured'**
  String get signatureNadraValidated;

  /// No description provided for @badgeNadraVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get badgeNadraVerified;

  /// No description provided for @fuelGaugeLabel.
  ///
  /// In en, this message translates to:
  /// **'Calibrated 8-Segment Fuel Level'**
  String get fuelGaugeLabel;

  /// No description provided for @fuelGaugeSetLevel.
  ///
  /// In en, this message translates to:
  /// **'Set fuel level to {n} of 8'**
  String fuelGaugeSetLevel(int n);

  /// No description provided for @damageSchematicTitle.
  ///
  /// In en, this message translates to:
  /// **'4-Quadrant Exterior Inspection Schematic'**
  String get damageSchematicTitle;

  /// No description provided for @damageMarksLogged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Mark Logged} other{{count} Marks Logged}}'**
  String damageMarksLogged(int count);

  /// No description provided for @damageTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any vehicle quadrant below to pin/unpin pre-existing scratches or dents:'**
  String get damageTapHint;

  /// No description provided for @blacklistScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC above to run an instant real-time scan against the RentalHub shared blacklist.'**
  String get blacklistScanPrompt;

  /// No description provided for @blacklistCriticalAlert.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL ALERT: BLACKLISTED CITIZEN'**
  String get blacklistCriticalAlert;

  /// No description provided for @blacklistIncidentRef.
  ///
  /// In en, this message translates to:
  /// **'Incident Ref: {id}'**
  String blacklistIncidentRef(String id);

  /// No description provided for @blacklistReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String blacklistReason(String reason);

  /// No description provided for @blacklistReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported By: {shop}'**
  String blacklistReportedBy(String shop);

  /// No description provided for @blacklistDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline / Refuse Service'**
  String get blacklistDecline;

  /// No description provided for @blacklistCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'No blacklist record found'**
  String get blacklistCleanTitle;

  /// No description provided for @blacklistCleanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zero active defaults or tribunal complaints on file.'**
  String get blacklistCleanSubtitle;

  /// No description provided for @blacklistDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Blacklisted — details unavailable, refer to tribunal'**
  String get blacklistDetailsUnavailable;

  /// No description provided for @blacklistProceed.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get blacklistProceed;

  /// No description provided for @cnicVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'CNIC Check'**
  String get cnicVerifyTitle;

  /// No description provided for @cnicScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan CNIC / Barcode'**
  String get cnicScanTooltip;

  /// No description provided for @cnicVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify CNIC & Blacklist'**
  String get cnicVerifyButton;

  /// No description provided for @cnicChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking RentalHub blacklist...'**
  String get cnicChecking;

  /// No description provided for @noDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'No booking in progress.'**
  String get noDraftTitle;

  /// No description provided for @noDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick a car and a package first — the review screen needs the booking details from there.'**
  String get noDraftMessage;

  /// No description provided for @noDraftBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse shops'**
  String get noDraftBrowse;

  /// No description provided for @routeBookingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking {id} was not found.'**
  String routeBookingNotFound(String id);

  /// No description provided for @routeVehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {id} was not found.'**
  String routeVehicleNotFound(String id);

  /// No description provided for @fuelGaugeBars.
  ///
  /// In en, this message translates to:
  /// **'{active} / 8 Bars ({percent}%)'**
  String fuelGaugeBars(int active, int percent);

  /// No description provided for @kycWizardStepCnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get kycWizardStepCnic;

  /// No description provided for @kycWizardStepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get kycWizardStepPhoto;

  /// No description provided for @kycWizardStepDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs & Sign'**
  String get kycWizardStepDocs;

  /// No description provided for @kycWizardStepGuarantor.
  ///
  /// In en, this message translates to:
  /// **'Guarantor'**
  String get kycWizardStepGuarantor;

  /// No description provided for @kycWizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get kycWizardNext;

  /// No description provided for @kycWizardScanFront.
  ///
  /// In en, this message translates to:
  /// **'Scan CNIC front'**
  String get kycWizardScanFront;

  /// No description provided for @kycWizardScanBack.
  ///
  /// In en, this message translates to:
  /// **'Scan CNIC back'**
  String get kycWizardScanBack;

  /// No description provided for @kycWizardFrontScanned.
  ///
  /// In en, this message translates to:
  /// **'Front scanned'**
  String get kycWizardFrontScanned;

  /// No description provided for @kycWizardBackScanned.
  ///
  /// In en, this message translates to:
  /// **'Back scanned'**
  String get kycWizardBackScanned;

  /// No description provided for @kycWizardFatherName.
  ///
  /// In en, this message translates to:
  /// **'Father name'**
  String get kycWizardFatherName;

  /// No description provided for @kycWizardDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get kycWizardDateOfBirth;

  /// No description provided for @kycWizardCnicExpiry.
  ///
  /// In en, this message translates to:
  /// **'CNIC expiry'**
  String get kycWizardCnicExpiry;

  /// No description provided for @kycWizardAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get kycWizardAddress;

  /// No description provided for @kycWizardWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get kycWizardWhatsappNumber;

  /// No description provided for @kycWizardManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Or enter the details manually below'**
  String get kycWizardManualEntry;

  /// No description provided for @kycWizardBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'This CNIC is blacklisted and cannot be added.'**
  String get kycWizardBlacklisted;

  /// No description provided for @kycWizardLivePhoto.
  ///
  /// In en, this message translates to:
  /// **'Live photo'**
  String get kycWizardLivePhoto;

  /// No description provided for @kycWizardFaceHint.
  ///
  /// In en, this message translates to:
  /// **'Take a clear photo of the customer\'s face'**
  String get kycWizardFaceHint;

  /// No description provided for @kycWizardRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get kycWizardRetake;

  /// No description provided for @kycWizardThumbprint.
  ///
  /// In en, this message translates to:
  /// **'Thumbprint'**
  String get kycWizardThumbprint;

  /// No description provided for @kycWizardThumbHint.
  ///
  /// In en, this message translates to:
  /// **'Photograph the right thumb'**
  String get kycWizardThumbHint;

  /// No description provided for @kycWizardPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'A photo is required to continue'**
  String get kycWizardPhotoRequired;

  /// No description provided for @kycWizardFingerprints.
  ///
  /// In en, this message translates to:
  /// **'Fingerprints'**
  String get kycWizardFingerprints;

  /// No description provided for @kycWizardLeftHand.
  ///
  /// In en, this message translates to:
  /// **'Left hand — 4 fingers'**
  String get kycWizardLeftHand;

  /// No description provided for @kycWizardRightHand.
  ///
  /// In en, this message translates to:
  /// **'Right hand — 4 fingers'**
  String get kycWizardRightHand;

  /// No description provided for @kycWizardFingerHint.
  ///
  /// In en, this message translates to:
  /// **'Hold 4 fingers steady under the rear camera'**
  String get kycWizardFingerHint;

  /// No description provided for @kycWizardFingerScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get kycWizardFingerScan;

  /// No description provided for @kycWizardFingerCaptured.
  ///
  /// In en, this message translates to:
  /// **'4 fingers captured'**
  String get kycWizardFingerCaptured;

  /// No description provided for @kycWizardFingerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint licence is not set up yet. Ask the shop owner to add the key.'**
  String get kycWizardFingerNotConfigured;

  /// No description provided for @kycWizardFingerRequired.
  ///
  /// In en, this message translates to:
  /// **'Fingerprints of both hands are required to continue'**
  String get kycWizardFingerRequired;

  /// No description provided for @kycWizardRelationPickFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a guarantor above to set the relation'**
  String get kycWizardRelationPickFirst;

  /// No description provided for @kycWizardGalleryFront.
  ///
  /// In en, this message translates to:
  /// **'Front from gallery'**
  String get kycWizardGalleryFront;

  /// No description provided for @kycWizardGalleryBack.
  ///
  /// In en, this message translates to:
  /// **'Back from gallery'**
  String get kycWizardGalleryBack;

  /// No description provided for @kycWizardImageNotClear.
  ///
  /// In en, this message translates to:
  /// **'This photo is not clear enough — no information could be read. Please provide a sharp, high-resolution photo with good light.'**
  String get kycWizardImageNotClear;

  /// No description provided for @kycWizardRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get kycWizardRemoveImage;

  /// No description provided for @kycWizardLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving license'**
  String get kycWizardLicense;

  /// No description provided for @kycWizardLicenseFront.
  ///
  /// In en, this message translates to:
  /// **'License front'**
  String get kycWizardLicenseFront;

  /// No description provided for @kycWizardLicenseBack.
  ///
  /// In en, this message translates to:
  /// **'License back'**
  String get kycWizardLicenseBack;

  /// No description provided for @kycWizardLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get kycWizardLicenseNumber;

  /// No description provided for @kycWizardLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'License expiry'**
  String get kycWizardLicenseExpiry;

  /// No description provided for @kycWizardUtilityBill.
  ///
  /// In en, this message translates to:
  /// **'Utility bill (proof of address)'**
  String get kycWizardUtilityBill;

  /// No description provided for @kycWizardExtraDocs.
  ///
  /// In en, this message translates to:
  /// **'Extra documents (optional)'**
  String get kycWizardExtraDocs;

  /// No description provided for @kycWizardAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get kycWizardAddPhoto;

  /// No description provided for @kycWizardSignature.
  ///
  /// In en, this message translates to:
  /// **'Customer signature'**
  String get kycWizardSignature;

  /// No description provided for @kycWizardSignatureClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get kycWizardSignatureClear;

  /// No description provided for @kycWizardAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the rental terms'**
  String get kycWizardAgreeTerms;

  /// No description provided for @kycWizardViewTerms.
  ///
  /// In en, this message translates to:
  /// **'View Terms'**
  String get kycWizardViewTerms;

  /// No description provided for @kycWizardSearchGuarantor.
  ///
  /// In en, this message translates to:
  /// **'Search existing customers'**
  String get kycWizardSearchGuarantor;

  /// No description provided for @kycWizardRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation with customer'**
  String get kycWizardRelation;

  /// No description provided for @kycWizardRelationFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get kycWizardRelationFriend;

  /// No description provided for @kycWizardRelationFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get kycWizardRelationFamily;

  /// No description provided for @kycWizardRelationColleague.
  ///
  /// In en, this message translates to:
  /// **'Colleague'**
  String get kycWizardRelationColleague;

  /// No description provided for @kycWizardRelationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kycWizardRelationOther;

  /// No description provided for @kycWizardGuarantorOnFile.
  ///
  /// In en, this message translates to:
  /// **'Signature & thumbprint on file — fetched automatically'**
  String get kycWizardGuarantorOnFile;

  /// No description provided for @kycWizardKycComplete.
  ///
  /// In en, this message translates to:
  /// **'KYC complete: CNIC, Photo, Thumb, License, Signature'**
  String get kycWizardKycComplete;

  /// No description provided for @kycWizardStepIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required items on this step'**
  String get kycWizardStepIncomplete;

  /// No description provided for @kycWizardPhotosPending.
  ///
  /// In en, this message translates to:
  /// **'Saved — some photos will upload when you\'re back online'**
  String get kycWizardPhotosPending;

  /// No description provided for @kycWizardUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get kycWizardUploadFailed;

  /// No description provided for @kycWizardGuarantorOptional.
  ///
  /// In en, this message translates to:
  /// **'Guarantor is optional — you can save without one'**
  String get kycWizardGuarantorOptional;

  /// No description provided for @kycWizardExtraSkipped.
  ///
  /// In en, this message translates to:
  /// **'Saved — some extra documents couldn\'t upload while offline'**
  String get kycWizardExtraSkipped;

  /// No description provided for @bookingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone, car or booking #'**
  String get bookingSearchHint;

  /// No description provided for @bookingEmptyRejected.
  ///
  /// In en, this message translates to:
  /// **'No rejected requests'**
  String get bookingEmptyRejected;

  /// No description provided for @bookingDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String bookingDaysCount(int count);

  /// No description provided for @bookingFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare breakdown'**
  String get bookingFareTitle;

  /// No description provided for @bookingFarePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get bookingFarePickup;

  /// No description provided for @bookingFareReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get bookingFareReturn;

  /// No description provided for @bookingFareDailyRate.
  ///
  /// In en, this message translates to:
  /// **'Daily rate'**
  String get bookingFareDailyRate;

  /// No description provided for @bookingFareDailyRateTimes.
  ///
  /// In en, this message translates to:
  /// **'Daily rate × {count} days'**
  String bookingFareDailyRateTimes(int count);

  /// No description provided for @bookingFarePackagePrice.
  ///
  /// In en, this message translates to:
  /// **'Package price'**
  String get bookingFarePackagePrice;

  /// No description provided for @bookingFareTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingFareTotal;

  /// No description provided for @bookingFareAdvanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Advance required'**
  String get bookingFareAdvanceRequired;

  /// No description provided for @bookingFareAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance paid'**
  String get bookingFareAdvancePaid;

  /// No description provided for @bookingFareRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get bookingFareRemaining;

  /// No description provided for @bookingChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you accept'**
  String get bookingChecklistTitle;

  /// No description provided for @bookingCheckKyc.
  ///
  /// In en, this message translates to:
  /// **'Customer KYC documents on file'**
  String get bookingCheckKyc;

  /// No description provided for @bookingCheckCar.
  ///
  /// In en, this message translates to:
  /// **'Car available'**
  String get bookingCheckCar;

  /// No description provided for @bookingCheckAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance received'**
  String get bookingCheckAdvance;

  /// No description provided for @bookingConfirmTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Terms'**
  String get bookingConfirmTermsTitle;

  /// No description provided for @bookingTermCondition.
  ///
  /// In en, this message translates to:
  /// **'Car Condition'**
  String get bookingTermCondition;

  /// No description provided for @bookingTermFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Level'**
  String get bookingTermFuel;

  /// No description provided for @bookingTermMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get bookingTermMileage;

  /// No description provided for @bookingTermDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get bookingTermDocuments;

  /// No description provided for @bookingTermsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Tick all four items to confirm the booking.'**
  String get bookingTermsIncomplete;

  /// No description provided for @bookingConvertToManual.
  ///
  /// In en, this message translates to:
  /// **'Convert to manual entry'**
  String get bookingConvertToManual;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingConfirmedHandoverScheduled.
  ///
  /// In en, this message translates to:
  /// **'Handover scheduled {date}'**
  String bookingConfirmedHandoverScheduled(String date);

  /// No description provided for @bookingConfirmedStartHandover.
  ///
  /// In en, this message translates to:
  /// **'Start Handover'**
  String get bookingConfirmedStartHandover;

  /// No description provided for @bookingConfirmedViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View Booking'**
  String get bookingConfirmedViewBooking;

  /// No description provided for @bookingConfirmedMessageCustomer.
  ///
  /// In en, this message translates to:
  /// **'Message Customer'**
  String get bookingConfirmedMessageCustomer;

  /// No description provided for @bookingConfirmedWhatsappMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum {name}, your booking for {vehicle} is confirmed. Pickup: {date}. Total: Rs. {total}. Thank you!'**
  String bookingConfirmedWhatsappMessage(
      String name, String vehicle, String date, String total);

  /// No description provided for @bookingConfirmedWhatsappFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get bookingConfirmedWhatsappFailed;

  /// No description provided for @manualBookingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get manualBookingNext;

  /// No description provided for @manualBookingReturnAfterPickup.
  ///
  /// In en, this message translates to:
  /// **'Return must be after pickup.'**
  String get manualBookingReturnAfterPickup;

  /// No description provided for @manualBookingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Fare'**
  String get manualBookingConfirmTitle;

  /// No description provided for @manualBookingConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get manualBookingConfirmBooking;

  /// No description provided for @contractTerm4.
  ///
  /// In en, this message translates to:
  /// **'4. Fuel shall be returned at the same level as at handover.'**
  String get contractTerm4;

  /// No description provided for @contractTerm5.
  ///
  /// In en, this message translates to:
  /// **'5. Late return is charged per hour or per day as per the agreed package.'**
  String get contractTerm5;

  /// No description provided for @contractTerm6.
  ///
  /// In en, this message translates to:
  /// **'6. Damage is charged as per inspection at return.'**
  String get contractTerm6;

  /// No description provided for @contractTerm7.
  ///
  /// In en, this message translates to:
  /// **'7. The owner is not liable for personal belongings left in the vehicle.'**
  String get contractTerm7;

  /// No description provided for @contractTerm8.
  ///
  /// In en, this message translates to:
  /// **'8. This agreement is governed by the laws of Pakistan.'**
  String get contractTerm8;

  /// No description provided for @contractTerm9.
  ///
  /// In en, this message translates to:
  /// **'9. The security deposit is refunded after inspection at return, less any damage or extra-kilometre charges.'**
  String get contractTerm9;

  /// No description provided for @contractTerm10.
  ///
  /// In en, this message translates to:
  /// **'10. Both parties agree to the terms above.'**
  String get contractTerm10;

  /// No description provided for @contractFieldAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance:'**
  String get contractFieldAdvance;

  /// No description provided for @contractFieldRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining:'**
  String get contractFieldRemaining;

  /// No description provided for @contractFieldPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate:'**
  String get contractFieldPlate;

  /// No description provided for @contractGuarantorSignature.
  ///
  /// In en, this message translates to:
  /// **'Guarantor Signature'**
  String get contractGuarantorSignature;

  /// No description provided for @contractGuarantorPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get contractGuarantorPending;

  /// No description provided for @contractDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get contractDownloadPdf;

  /// No description provided for @contractPdfDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Agreement PDF saved: {file}'**
  String contractPdfDownloaded(String file);

  /// No description provided for @contractPdfDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the agreement PDF: {error}'**
  String contractPdfDownloadFailed(String error);

  /// No description provided for @handoverPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Exterior Photos'**
  String get handoverPhotosTitle;

  /// No description provided for @handoverPhotoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get handoverPhotoUploading;

  /// No description provided for @handoverDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents Given'**
  String get handoverDocumentsTitle;

  /// No description provided for @handoverDocumentRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get handoverDocumentRegistration;

  /// No description provided for @handoverDocumentInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get handoverDocumentInsurance;

  /// No description provided for @handoverAccessoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get handoverAccessoriesTitle;

  /// No description provided for @handoverAccessorySpareTyre.
  ///
  /// In en, this message translates to:
  /// **'Spare Tyre'**
  String get handoverAccessorySpareTyre;

  /// No description provided for @handoverAccessoryJack.
  ///
  /// In en, this message translates to:
  /// **'Jack'**
  String get handoverAccessoryJack;

  /// No description provided for @handoverAccessoryToolKit.
  ///
  /// In en, this message translates to:
  /// **'Tool Kit'**
  String get handoverAccessoryToolKit;

  /// No description provided for @handoverKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Keys Handed Over'**
  String get handoverKeysTitle;

  /// No description provided for @returnLandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Return & Settlement'**
  String get returnLandingTitle;

  /// No description provided for @returnLandingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id} • {customer} — {vehicle}'**
  String returnLandingSummary(String id, String customer, String vehicle);

  /// No description provided for @returnLandingDueBack.
  ///
  /// In en, this message translates to:
  /// **'Return due'**
  String get returnLandingDueBack;

  /// No description provided for @returnLandingStart.
  ///
  /// In en, this message translates to:
  /// **'Start Return Inspection'**
  String get returnLandingStart;

  /// No description provided for @returnConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Condition'**
  String get returnConditionTitle;

  /// No description provided for @returnConditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get returnConditionGood;

  /// No description provided for @returnConditionMinorDamage.
  ///
  /// In en, this message translates to:
  /// **'Minor damage'**
  String get returnConditionMinorDamage;

  /// No description provided for @returnConditionRecordDamage.
  ///
  /// In en, this message translates to:
  /// **'Record Damage'**
  String get returnConditionRecordDamage;

  /// No description provided for @returnFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare Summary'**
  String get returnFareTitle;

  /// No description provided for @returnFareRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get returnFareRent;

  /// No description provided for @returnFareAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance Paid'**
  String get returnFareAdvancePaid;

  /// No description provided for @returnFareRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get returnFareRemaining;

  /// No description provided for @returnFareTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total Due'**
  String get returnFareTotalDue;

  /// No description provided for @returnPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get returnPaymentTitle;

  /// No description provided for @returnPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get returnPaymentCash;

  /// No description provided for @returnPaymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get returnPaymentBankTransfer;

  /// No description provided for @returnPaymentJazzCash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get returnPaymentJazzCash;

  /// No description provided for @returnPaymentEasyPaisa.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa'**
  String get returnPaymentEasyPaisa;

  /// No description provided for @returnPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Received'**
  String get returnPaymentAmountLabel;

  /// No description provided for @returnPaymentAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 16000'**
  String get returnPaymentAmountHint;

  /// No description provided for @returnPaymentMarkReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark Payment Received'**
  String get returnPaymentMarkReceived;

  /// No description provided for @returnPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get returnPaymentReceived;

  /// No description provided for @returnPaymentUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get returnPaymentUndo;

  /// No description provided for @returnPaymentRecordExtraCharges.
  ///
  /// In en, this message translates to:
  /// **'Record Extra Charges'**
  String get returnPaymentRecordExtraCharges;

  /// No description provided for @returnReceiptExtraCharges.
  ///
  /// In en, this message translates to:
  /// **'Extra Charges'**
  String get returnReceiptExtraCharges;

  /// No description provided for @damageTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Damage'**
  String get damageTitle;

  /// No description provided for @damageAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get damageAddPhoto;

  /// No description provided for @damageDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get damageDescriptionLabel;

  /// No description provided for @damageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Scratch on the rear bumper'**
  String get damageDescriptionHint;

  /// No description provided for @damageDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe the damage.'**
  String get damageDescriptionRequired;

  /// No description provided for @damageRepairCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Repair Cost'**
  String get damageRepairCostLabel;

  /// No description provided for @damageRepairCostHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5000'**
  String get damageRepairCostHint;

  /// No description provided for @damageDeductFromDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deduct from Deposit'**
  String get damageDeductFromDeposit;

  /// No description provided for @damageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get damageSave;

  /// No description provided for @damageSaved.
  ///
  /// In en, this message translates to:
  /// **'Damage report saved.'**
  String get damageSaved;

  /// No description provided for @damageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the damage report. Please try again.'**
  String get damageSaveFailed;

  /// No description provided for @extraChargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Extra Charges'**
  String get extraChargeTitle;

  /// No description provided for @extraChargeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Charge Type'**
  String get extraChargeTypeLabel;

  /// No description provided for @extraChargeTypeLateReturn.
  ///
  /// In en, this message translates to:
  /// **'Late Return'**
  String get extraChargeTypeLateReturn;

  /// No description provided for @extraChargeTypeExtraKm.
  ///
  /// In en, this message translates to:
  /// **'Extra KM'**
  String get extraChargeTypeExtraKm;

  /// No description provided for @extraChargeTypeDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get extraChargeTypeDamage;

  /// No description provided for @extraChargeTypeCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get extraChargeTypeCleaning;

  /// No description provided for @extraChargeAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get extraChargeAmountLabel;

  /// No description provided for @extraChargeAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2000'**
  String get extraChargeAmountHint;

  /// No description provided for @extraChargeRemarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get extraChargeRemarksLabel;

  /// No description provided for @extraChargeRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Returned 3 hours late'**
  String get extraChargeRemarksHint;

  /// No description provided for @extraChargeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Charge'**
  String get extraChargeAdd;

  /// No description provided for @extraChargeAdded.
  ///
  /// In en, this message translates to:
  /// **'Charge added.'**
  String get extraChargeAdded;

  /// No description provided for @extraChargeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the charge. Please try again.'**
  String get extraChargeSaveFailed;

  /// No description provided for @extraChargeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved extra charges. Please try again.'**
  String get extraChargeLoadError;

  /// No description provided for @extraChargeAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount greater than zero.'**
  String get extraChargeAmountRequired;

  /// No description provided for @extraChargeSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Charges'**
  String get extraChargeSavedTitle;

  /// No description provided for @rentalStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'On the Road'**
  String get rentalStartedTitle;

  /// No description provided for @rentalStartedBanner.
  ///
  /// In en, this message translates to:
  /// **'Rental Started'**
  String get rentalStartedBanner;

  /// No description provided for @rentalStartedBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id}'**
  String rentalStartedBooking(String id);

  /// No description provided for @rentalStartedReturnDue.
  ///
  /// In en, this message translates to:
  /// **'Return due {date}, {time}'**
  String rentalStartedReturnDue(String date, String time);

  /// No description provided for @rentalStartedViewAgreement.
  ///
  /// In en, this message translates to:
  /// **'View Agreement'**
  String get rentalStartedViewAgreement;

  /// No description provided for @rentalStartedMessageCustomer.
  ///
  /// In en, this message translates to:
  /// **'Message Customer'**
  String get rentalStartedMessageCustomer;

  /// No description provided for @rentalStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum {name}, your rental of {vehicle} has started. Please return it on time. — RentalHub'**
  String rentalStartedMessage(String name, String vehicle);

  /// No description provided for @rentalStartedNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number saved for this customer.'**
  String get rentalStartedNoPhone;

  /// No description provided for @rentalStartedWhatsappFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get rentalStartedWhatsappFailed;

  /// No description provided for @agreementSignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement Signed'**
  String get agreementSignedTitle;

  /// No description provided for @agreementSignedBanner.
  ///
  /// In en, this message translates to:
  /// **'Agreement Signed Successfully'**
  String get agreementSignedBanner;

  /// No description provided for @agreementSignedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The rental agreement has been signed by all parties.'**
  String get agreementSignedSubtitle;

  /// No description provided for @agreementSignedDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get agreementSignedDownloadPdf;

  /// No description provided for @agreementSignedShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get agreementSignedShare;

  /// No description provided for @agreementSignedSendCustomer.
  ///
  /// In en, this message translates to:
  /// **'Send to Customer'**
  String get agreementSignedSendCustomer;

  /// No description provided for @agreementSignedContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get agreementSignedContinue;

  /// No description provided for @agreementSignedSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum {name}, your rental agreement is ready: {url}'**
  String agreementSignedSendMessage(String name, String url);

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardQuickAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get dashboardQuickAddCustomer;

  /// No description provided for @dashboardQuickViewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get dashboardQuickViewReports;

  /// No description provided for @dashboardReturnsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No returns due in the next 7 days.'**
  String get dashboardReturnsEmpty;

  /// No description provided for @dashboardScheduleBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get dashboardScheduleBooking;

  /// No description provided for @dashboardScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for today.'**
  String get dashboardScheduleEmpty;

  /// No description provided for @dashboardScheduleHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover'**
  String get dashboardScheduleHandover;

  /// No description provided for @dashboardScheduleReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get dashboardScheduleReturn;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardTodayEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get dashboardTodayEarnings;

  /// No description provided for @dashboardTodaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get dashboardTodaySchedule;

  /// No description provided for @dashboardUpcomingReturns.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Returns'**
  String get dashboardUpcomingReturns;

  /// No description provided for @financeBookingNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BK-1234'**
  String get financeBookingNumberHint;

  /// No description provided for @financeBookingNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking #'**
  String get financeBookingNumberLabel;

  /// No description provided for @financeDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get financeDateLabel;

  /// No description provided for @financeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get financeFilterAll;

  /// No description provided for @financePaymentBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get financePaymentBank;

  /// No description provided for @financePaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get financePaymentCash;

  /// No description provided for @financePaymentEasyPaisa.
  ///
  /// In en, this message translates to:
  /// **'EasyPaisa'**
  String get financePaymentEasyPaisa;

  /// No description provided for @financePaymentJazzCash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get financePaymentJazzCash;

  /// No description provided for @financePaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get financePaymentMethodLabel;

  /// No description provided for @financeCategoryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get financeCategoryAdvance;

  /// No description provided for @financeCategoryWash.
  ///
  /// In en, this message translates to:
  /// **'Wash'**
  String get financeCategoryWash;

  /// No description provided for @financePnlDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get financePnlDaily;

  /// No description provided for @financePnlWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get financePnlWeekly;

  /// No description provided for @financePnlMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get financePnlMonthly;

  /// No description provided for @financePnlIncomeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Income Breakdown'**
  String get financePnlIncomeBreakdown;

  /// No description provided for @financePnlExpenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get financePnlExpenseBreakdown;

  /// No description provided for @financeCategoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get financeCategoriesAdd;

  /// No description provided for @financeCategoriesDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists.'**
  String get financeCategoriesDuplicate;

  /// No description provided for @financeCategoriesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get financeCategoriesAddTitle;

  /// No description provided for @financeCategoriesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get financeCategoriesDelete;

  /// No description provided for @financeCategoriesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the “{name}” category? Old ledger entries keep this category.'**
  String financeCategoriesDeleteMessage(String name);

  /// No description provided for @financeCategoriesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get financeCategoriesDeleteTitle;

  /// No description provided for @financeCategoriesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get financeCategoriesEdit;

  /// No description provided for @financeCategoriesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get financeCategoriesEditTitle;

  /// No description provided for @financeCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get financeCategoriesEmpty;

  /// No description provided for @financeCategoriesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get financeCategoriesNameLabel;

  /// No description provided for @financeCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income and expense categories for the ledger'**
  String get financeCategoriesSubtitle;

  /// No description provided for @financeCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Income & Expense Categories'**
  String get financeCategoriesTitle;

  /// No description provided for @financeSettingsAutoReceipt.
  ///
  /// In en, this message translates to:
  /// **'Auto-send WhatsApp receipt'**
  String get financeSettingsAutoReceipt;

  /// No description provided for @financeSettingsAutoReceiptNote.
  ///
  /// In en, this message translates to:
  /// **'Receipts are sent only after the WhatsApp Business setup (Phase I). Until then this only records your preference.'**
  String get financeSettingsAutoReceiptNote;

  /// No description provided for @financeSettingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get financeSettingsCurrency;

  /// No description provided for @financeSettingsCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'The app only trades in Pakistani Rupees (PKR).'**
  String get financeSettingsCurrencyNote;

  /// No description provided for @financeSettingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Finance settings are not available right now.'**
  String get financeSettingsEmpty;

  /// No description provided for @financeSettingsInvalidPercent.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid percentage number.'**
  String get financeSettingsInvalidPercent;

  /// No description provided for @financeSettingsPercentRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a percentage between 0 and 100.'**
  String get financeSettingsPercentRange;

  /// No description provided for @financeSettingsPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get financeSettingsPaymentMethods;

  /// No description provided for @financeSettingsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipt Settings'**
  String get financeSettingsReceipts;

  /// No description provided for @financeSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get financeSettingsSave;

  /// No description provided for @financeSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Finance settings saved.'**
  String get financeSettingsSaved;

  /// No description provided for @financeSettingsServiceCharge.
  ///
  /// In en, this message translates to:
  /// **'Service Charges (%)'**
  String get financeSettingsServiceCharge;

  /// No description provided for @financeSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Currency, charges, payment methods and receipts'**
  String get financeSettingsSubtitle;

  /// No description provided for @financeSettingsTax.
  ///
  /// In en, this message translates to:
  /// **'Tax (%)'**
  String get financeSettingsTax;

  /// No description provided for @financeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance Settings'**
  String get financeSettingsTitle;

  /// No description provided for @financeStatementColBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get financeStatementColBooking;

  /// No description provided for @financeStatementColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get financeStatementColDate;

  /// No description provided for @financeStatementColDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get financeStatementColDue;

  /// No description provided for @financeStatementColPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get financeStatementColPaid;

  /// No description provided for @financeStatementColRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get financeStatementColRent;

  /// No description provided for @financeStatementDownload.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get financeStatementDownload;

  /// No description provided for @financeStatementDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Statement PDF saved to your device.'**
  String get financeStatementDownloaded;

  /// No description provided for @financeStatementEmpty.
  ///
  /// In en, this message translates to:
  /// **'This customer has no bookings yet.'**
  String get financeStatementEmpty;

  /// No description provided for @financeStatementMessageRow.
  ///
  /// In en, this message translates to:
  /// **'#{booking} • {date} • Rent Rs. {rent} • Paid Rs. {paid} • Due Rs. {due}'**
  String financeStatementMessageRow(
      String booking, String date, String rent, String paid, String due);

  /// No description provided for @financeStatementMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'RentalHub statement for {name}:'**
  String financeStatementMessageTitle(String name);

  /// No description provided for @financeStatementMessageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total due: Rs. {amount}'**
  String financeStatementMessageTotal(String amount);

  /// No description provided for @financeStatementSend.
  ///
  /// In en, this message translates to:
  /// **'Send Statement (WhatsApp)'**
  String get financeStatementSend;

  /// No description provided for @financeStatementShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get financeStatementShare;

  /// No description provided for @financeStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Statement'**
  String get financeStatementTitle;

  /// No description provided for @financeStatementTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total Due'**
  String get financeStatementTotalDue;

  /// No description provided for @financeSummaryEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get financeSummaryEarnings;

  /// No description provided for @financeSummaryExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financeSummaryExpenses;

  /// No description provided for @financeSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get financeSummaryNet;

  /// No description provided for @financeTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get financeTabOverview;

  /// No description provided for @financeTabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get financeTabReports;

  /// No description provided for @financeTabTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get financeTabTransactions;

  /// No description provided for @financeViewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get financeViewReports;

  /// No description provided for @reportCarBookings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} booking} other{{count} bookings}}'**
  String reportCarBookings(int count);

  /// No description provided for @reportCarTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Car — Bookings — Earnings'**
  String get reportCarTableTitle;

  /// No description provided for @reportCarWise.
  ///
  /// In en, this message translates to:
  /// **'Car-wise Earnings'**
  String get reportCarWise;

  /// No description provided for @reportCarWiseHint.
  ///
  /// In en, this message translates to:
  /// **'Earnings for every car in the fleet'**
  String get reportCarWiseHint;

  /// No description provided for @reportCustomerHistory.
  ///
  /// In en, this message translates to:
  /// **'Customer History'**
  String get reportCustomerHistory;

  /// No description provided for @reportCustomerHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Bookings and spend per customer'**
  String get reportCustomerHistoryHint;

  /// No description provided for @reportCustomerTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer — Bookings — Spend'**
  String get reportCustomerTableTitle;

  /// No description provided for @reportEarningsLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Earnings — last 6 months'**
  String get reportEarningsLast6Months;

  /// No description provided for @reportMonthlyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Monthly Earnings Report'**
  String get reportMonthlyEarnings;

  /// No description provided for @reportMonthlyEarningsHint.
  ///
  /// In en, this message translates to:
  /// **'Revenue by month, as a bar chart'**
  String get reportMonthlyEarningsHint;

  /// No description provided for @reportNoCars.
  ///
  /// In en, this message translates to:
  /// **'No cars in the fleet yet.'**
  String get reportNoCars;

  /// No description provided for @reportNoCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customer bookings in this period.'**
  String get reportNoCustomers;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriod;

  /// No description provided for @reportShare.
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get reportShare;

  /// No description provided for @reportShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the report. Please try again.'**
  String get reportShareFailed;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings, cars and customers'**
  String get reportSubtitle;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportTitle;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetAllData;

  /// No description provided for @resetAllHint.
  ///
  /// In en, this message translates to:
  /// **'Bookings, customers, cars, finance records and staff for this shop.'**
  String get resetAllHint;

  /// No description provided for @resetBookings.
  ///
  /// In en, this message translates to:
  /// **'Reset Bookings'**
  String get resetBookings;

  /// No description provided for @resetBookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Deletes all bookings for this shop.'**
  String get resetBookingsHint;

  /// No description provided for @resetCars.
  ///
  /// In en, this message translates to:
  /// **'Reset Cars'**
  String get resetCars;

  /// No description provided for @resetCarsHint.
  ///
  /// In en, this message translates to:
  /// **'Deletes all vehicles for this shop.'**
  String get resetCarsHint;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will permanently delete {what} for this shop. This cannot be undone.'**
  String resetConfirmMessage(String what);

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset data?'**
  String get resetConfirmTitle;

  /// No description provided for @resetCustomers.
  ///
  /// In en, this message translates to:
  /// **'Reset Customers'**
  String get resetCustomers;

  /// No description provided for @resetCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Deletes all customers for this shop.'**
  String get resetCustomersHint;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} records.'**
  String resetDone(String count);

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Reset failed. Check your connection and try again.'**
  String get resetFailed;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this shop\'s data — carefully'**
  String get resetSubtitle;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Options'**
  String get resetTitle;

  /// No description provided for @resetWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: resetting deletes data permanently. Only reset what you mean to lose. The shop itself and its finance settings are kept.'**
  String get resetWarning;

  /// No description provided for @resetYesReset.
  ///
  /// In en, this message translates to:
  /// **'Yes, Reset'**
  String get resetYesReset;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmBody;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, Sign Out'**
  String get signOutConfirmYes;

  /// No description provided for @signOutSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign In Again'**
  String get signOutSignInAgain;

  /// No description provided for @signOutSignedOutBody.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out. Sign in again to continue managing your showroom.'**
  String get signOutSignedOutBody;

  /// No description provided for @signOutSignedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out'**
  String get signOutSignedOutTitle;

  /// No description provided for @staffAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get staffAdd;

  /// No description provided for @staffAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Staff Member'**
  String get staffAddTitle;

  /// No description provided for @staffDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove staff member'**
  String get staffDelete;

  /// No description provided for @staffDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this staff member. Please try again.'**
  String get staffDeleteFailed;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No staff yet — add your first team member.'**
  String get staffEmpty;

  /// No description provided for @staffNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffNameLabel;

  /// No description provided for @staffPermissionAddCars.
  ///
  /// In en, this message translates to:
  /// **'Add Cars'**
  String get staffPermissionAddCars;

  /// No description provided for @staffPermissionManageFinance.
  ///
  /// In en, this message translates to:
  /// **'Manage Finance'**
  String get staffPermissionManageFinance;

  /// No description provided for @staffPermissionViewBookings.
  ///
  /// In en, this message translates to:
  /// **'View Bookings'**
  String get staffPermissionViewBookings;

  /// No description provided for @staffPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get staffPhoneLabel;

  /// No description provided for @staffRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRoleLabel;

  /// No description provided for @staffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Team members and their permissions'**
  String get staffSubtitle;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff & Roles'**
  String get staffTitle;

  /// No description provided for @onboardingStepOfFive.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 5'**
  String onboardingStepOfFive(int step);

  /// No description provided for @onboardingHeaderReview.
  ///
  /// In en, this message translates to:
  /// **'Review Application'**
  String get onboardingHeaderReview;

  /// No description provided for @onboardingSubtitleReview.
  ///
  /// In en, this message translates to:
  /// **'Check everything before submitting'**
  String get onboardingSubtitleReview;

  /// No description provided for @onboardingStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get onboardingStepReview;

  /// No description provided for @onboardingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your application'**
  String get onboardingReviewTitle;

  /// No description provided for @onboardingReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check the details below. You can go back to change anything before submitting.'**
  String get onboardingReviewHint;

  /// No description provided for @onboardingReviewShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get onboardingReviewShopName;

  /// No description provided for @onboardingReviewOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get onboardingReviewOwnerName;

  /// No description provided for @onboardingReviewCnic.
  ///
  /// In en, this message translates to:
  /// **'Owner CNIC'**
  String get onboardingReviewCnic;

  /// No description provided for @onboardingReviewWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get onboardingReviewWhatsapp;

  /// No description provided for @onboardingReviewPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get onboardingReviewPhone;

  /// No description provided for @onboardingReviewOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get onboardingReviewOpeningHours;

  /// No description provided for @onboardingReviewShopLogo.
  ///
  /// In en, this message translates to:
  /// **'Shop logo'**
  String get onboardingReviewShopLogo;

  /// No description provided for @onboardingReviewAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get onboardingReviewAddress;

  /// No description provided for @onboardingReviewCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get onboardingReviewCity;

  /// No description provided for @onboardingReviewNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents attached yet'**
  String get onboardingReviewNoDocuments;

  /// No description provided for @onboardingReviewCnicFront.
  ///
  /// In en, this message translates to:
  /// **'CNIC front'**
  String get onboardingReviewCnicFront;

  /// No description provided for @onboardingReviewCnicBack.
  ///
  /// In en, this message translates to:
  /// **'CNIC back'**
  String get onboardingReviewCnicBack;

  /// No description provided for @onboardingReviewSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie with CNIC'**
  String get onboardingReviewSelfie;

  /// No description provided for @onboardingReviewNtn.
  ///
  /// In en, this message translates to:
  /// **'NTN document'**
  String get onboardingReviewNtn;

  /// No description provided for @onboardingReviewShopPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shop photo'**
  String get onboardingReviewShopPhoto;

  /// No description provided for @onboardingReviewFleetPhoto1.
  ///
  /// In en, this message translates to:
  /// **'Fleet photo 1'**
  String get onboardingReviewFleetPhoto1;

  /// No description provided for @onboardingReviewFleetPhoto2.
  ///
  /// In en, this message translates to:
  /// **'Fleet photo 2'**
  String get onboardingReviewFleetPhoto2;

  /// No description provided for @onboardingReviewFleetPhoto3.
  ///
  /// In en, this message translates to:
  /// **'Fleet photo 3'**
  String get onboardingReviewFleetPhoto3;

  /// No description provided for @onboardingApprovalWithin24h.
  ///
  /// In en, this message translates to:
  /// **'Usually approved within 24 hours'**
  String get onboardingApprovalWithin24h;

  /// No description provided for @onboardingTimelineSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get onboardingTimelineSubmitted;

  /// No description provided for @onboardingTimelineSubmittedHint.
  ///
  /// In en, this message translates to:
  /// **'Your application was received'**
  String get onboardingTimelineSubmittedHint;

  /// No description provided for @onboardingTimelineUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get onboardingTimelineUnderReview;

  /// No description provided for @onboardingTimelineUnderReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Our team is checking your details'**
  String get onboardingTimelineUnderReviewHint;

  /// No description provided for @onboardingTimelineApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get onboardingTimelineApproved;

  /// No description provided for @onboardingTimelineApprovedHint.
  ///
  /// In en, this message translates to:
  /// **'Your shop goes live after approval'**
  String get onboardingTimelineApprovedHint;

  /// No description provided for @onboardingContactAdminWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin on WhatsApp'**
  String get onboardingContactAdminWhatsapp;

  /// No description provided for @onboardingAdminWhatsappMissing.
  ///
  /// In en, this message translates to:
  /// **'Admin WhatsApp is not set up yet. Please try again later.'**
  String get onboardingAdminWhatsappMissing;

  /// No description provided for @onboardingAdminWhatsappFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get onboardingAdminWhatsappFailed;

  /// No description provided for @pricingPackageMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Package (30 Days)'**
  String get pricingPackageMonthly;

  /// No description provided for @addVehicleRateMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Package (30 Days)'**
  String get addVehicleRateMonthly;

  /// No description provided for @ratesViewEstimate.
  ///
  /// In en, this message translates to:
  /// **'View estimated rates'**
  String get ratesViewEstimate;

  /// No description provided for @pricingPerKmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Per KM Pricing?'**
  String get pricingPerKmQuestion;

  /// No description provided for @pricingPerKmQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Charge for kilometres beyond the package limit'**
  String get pricingPerKmQuestionHint;

  /// No description provided for @ratesCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Rates'**
  String get ratesCustomTitle;

  /// No description provided for @ratesCustomAdd.
  ///
  /// In en, this message translates to:
  /// **'Add rate'**
  String get ratesCustomAdd;

  /// No description provided for @ratesCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom rates yet. Add one for a period the standard packages do not cover.'**
  String get ratesCustomEmpty;

  /// No description provided for @ratesCustomAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add custom rate'**
  String get ratesCustomAddTitle;

  /// No description provided for @ratesCustomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate name'**
  String get ratesCustomNameLabel;

  /// No description provided for @ratesCustomNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Airport transfer'**
  String get ratesCustomNameHint;

  /// No description provided for @ratesCustomPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get ratesCustomPriceLabel;

  /// No description provided for @ratesCustomPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get ratesCustomPeriodLabel;

  /// No description provided for @ratesCustomPeriodHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get ratesCustomPeriodHourly;

  /// No description provided for @ratesCustomPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get ratesCustomPeriodDaily;

  /// No description provided for @ratesCustomPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get ratesCustomPeriodWeekly;

  /// No description provided for @ratesCustomPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get ratesCustomPeriodMonthly;

  /// No description provided for @ratesCustomDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete rate'**
  String get ratesCustomDelete;

  /// No description provided for @ratesCustomInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and a price greater than zero.'**
  String get ratesCustomInvalid;

  /// No description provided for @pkgMonthlyPackage.
  ///
  /// In en, this message translates to:
  /// **'Monthly Package'**
  String get pkgMonthlyPackage;

  /// No description provided for @pkgMonthlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Thirty days, one price'**
  String get pkgMonthlyDesc;

  /// No description provided for @fleetOnRentUntil.
  ///
  /// In en, this message translates to:
  /// **'On Rent until {date}'**
  String fleetOnRentUntil(String date);

  /// No description provided for @fleetActiveRentals.
  ///
  /// In en, this message translates to:
  /// **'{count} active rentals'**
  String fleetActiveRentals(int count);

  /// No description provided for @fleetSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get fleetSchedule;

  /// No description provided for @fleetEditRent.
  ///
  /// In en, this message translates to:
  /// **'Edit Rent'**
  String get fleetEditRent;

  /// No description provided for @fleetUpdatePrice.
  ///
  /// In en, this message translates to:
  /// **'Update Price'**
  String get fleetUpdatePrice;

  /// No description provided for @fleetShopSettings.
  ///
  /// In en, this message translates to:
  /// **'Shop Settings'**
  String get fleetShopSettings;

  /// No description provided for @shopProfileOwnerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get shopProfileOwnerUnknown;

  /// No description provided for @fleetAddBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop approval pending'**
  String get fleetAddBlockedTitle;

  /// No description provided for @fleetAddBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your shop is still under review. You can add vehicles once your shop is approved — usually within 24 hours.'**
  String get fleetAddBlockedBody;

  /// No description provided for @fleetAddBlockedViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get fleetAddBlockedViewStatus;

  /// No description provided for @fareTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare Table'**
  String get fareTableTitle;

  /// No description provided for @fareTabInCity.
  ///
  /// In en, this message translates to:
  /// **'In-City'**
  String get fareTabInCity;

  /// No description provided for @fareTabOutCity.
  ///
  /// In en, this message translates to:
  /// **'Out-City'**
  String get fareTabOutCity;

  /// No description provided for @fareTabHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get fareTabHourly;

  /// No description provided for @fareTabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get fareTabMonthly;

  /// No description provided for @fareFreeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Default Free delivery'**
  String get fareFreeDelivery;

  /// No description provided for @fareKmIncluded.
  ///
  /// In en, this message translates to:
  /// **'{km} km included'**
  String fareKmIncluded(int km);

  /// No description provided for @fareOutCityDaily.
  ///
  /// In en, this message translates to:
  /// **'Out-City day rate: {rate}'**
  String fareOutCityDaily(String rate);

  /// No description provided for @fareNoRows.
  ///
  /// In en, this message translates to:
  /// **'No fares for this tab yet.'**
  String get fareNoRows;

  /// No description provided for @fareProceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get fareProceed;

  /// No description provided for @estimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated Rates'**
  String get estimateTitle;

  /// No description provided for @estimateCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated Rates'**
  String get estimateCardTitle;

  /// No description provided for @estimateInCityDay.
  ///
  /// In en, this message translates to:
  /// **'In-City / Day'**
  String get estimateInCityDay;

  /// No description provided for @estimateOutCityDay.
  ///
  /// In en, this message translates to:
  /// **'Out-City / Day'**
  String get estimateOutCityDay;

  /// No description provided for @estimateWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get estimateWeekly;

  /// No description provided for @estimateMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get estimateMonthly;

  /// No description provided for @estimateWithDriverSurcharge.
  ///
  /// In en, this message translates to:
  /// **'With-driver surcharge'**
  String get estimateWithDriverSurcharge;

  /// No description provided for @estimatePerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String estimatePerDay(String amount);

  /// No description provided for @estimateDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get estimateDeposit;

  /// No description provided for @estimateHint.
  ///
  /// In en, this message translates to:
  /// **'Estimates use your current rates. Change them in the rate matrix.'**
  String get estimateHint;

  /// No description provided for @estimateGoToMyCars.
  ///
  /// In en, this message translates to:
  /// **'Go to My Cars'**
  String get estimateGoToMyCars;

  /// No description provided for @vehiclePublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Published'**
  String get vehiclePublishedTitle;

  /// No description provided for @vehiclePublishedHeading.
  ///
  /// In en, this message translates to:
  /// **'Your {vehicle} has been successfully published'**
  String vehiclePublishedHeading(String vehicle);

  /// No description provided for @vehiclePublishedLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Listing link copied'**
  String get vehiclePublishedLinkCopied;

  /// No description provided for @vehiclePublishedShareText.
  ///
  /// In en, this message translates to:
  /// **'Rent {vehicle} for {rate} / day on RentalHub: {link}'**
  String vehiclePublishedShareText(String vehicle, String rate, String link);

  /// No description provided for @vehiclePublishedViewInApp.
  ///
  /// In en, this message translates to:
  /// **'View in App'**
  String get vehiclePublishedViewInApp;

  /// No description provided for @vehiclePublishedCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get vehiclePublishedCopyLink;

  /// No description provided for @vehiclePublishedShareListing.
  ///
  /// In en, this message translates to:
  /// **'Share Listing'**
  String get vehiclePublishedShareListing;

  /// No description provided for @vehiclePublishedAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Publish another car'**
  String get vehiclePublishedAddAnother;

  /// No description provided for @vehicleDetailDailyRate.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String vehicleDetailDailyRate(String amount);

  /// No description provided for @vehicleDetailSeats.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String vehicleDetailSeats(int count);

  /// No description provided for @vehicleDetailRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get vehicleDetailRatesTitle;

  /// No description provided for @vehicleDetailDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get vehicleDetailDeposit;

  /// No description provided for @vehicleDetailFareTable.
  ///
  /// In en, this message translates to:
  /// **'Fare table'**
  String get vehicleDetailFareTable;

  /// No description provided for @vehicleDetailBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get vehicleDetailBookingsTitle;

  /// No description provided for @vehicleDetailNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings for this car yet.'**
  String get vehicleDetailNoBookings;

  /// No description provided for @vehicleDetailManageRates.
  ///
  /// In en, this message translates to:
  /// **'Manage rates'**
  String get vehicleDetailManageRates;

  /// No description provided for @vehicleDetailCalendar.
  ///
  /// In en, this message translates to:
  /// **'Booking calendar'**
  String get vehicleDetailCalendar;

  /// No description provided for @vehicleDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get vehicleDetailEdit;

  /// No description provided for @shopSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Settings'**
  String get shopSettingsTitle;

  /// No description provided for @shopSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your shop name and details'**
  String get shopSettingsSubtitle;

  /// No description provided for @shopSettingsShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopSettingsShopName;

  /// No description provided for @shopSettingsOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get shopSettingsOwnerName;

  /// No description provided for @shopSettingsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get shopSettingsPhone;

  /// No description provided for @shopSettingsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shopSettingsAddress;

  /// No description provided for @shopSettingsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get shopSettingsCity;

  /// No description provided for @shopSettingsOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get shopSettingsOpeningHours;

  /// No description provided for @shopSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save shop settings'**
  String get shopSettingsSave;

  /// No description provided for @shopSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Shop settings saved'**
  String get shopSettingsSaved;

  /// No description provided for @shopSettingsNameShort.
  ///
  /// In en, this message translates to:
  /// **'Enter a shop name of at least 3 characters.'**
  String get shopSettingsNameShort;

  /// No description provided for @shopSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save shop settings: {error}'**
  String shopSettingsSaveFailed(String error);

  /// No description provided for @shopSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load shop settings.'**
  String get shopSettingsLoadError;

  /// No description provided for @shopSettingsPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Pakistani mobile number (03XX-XXXXXXX or +92 3XX XXXXXXX).'**
  String get shopSettingsPhoneInvalid;

  /// No description provided for @shopSettingsHoursHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9:00 AM – 9:00 PM'**
  String get shopSettingsHoursHint;

  /// No description provided for @shopSettingsHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter opening hours like 9:00 AM – 9:00 PM.'**
  String get shopSettingsHoursInvalid;

  /// No description provided for @fleetCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Schedule'**
  String get fleetCalendarTitle;

  /// No description provided for @fleetCalendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get fleetCalendarPrevMonth;

  /// No description provided for @fleetCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get fleetCalendarNextMonth;

  /// No description provided for @fleetCalendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the fleet calendar.'**
  String get fleetCalendarLoadError;

  /// No description provided for @fleetCalendarEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cars in your fleet yet'**
  String get fleetCalendarEmptyTitle;

  /// No description provided for @fleetCalendarEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a car to see its schedule here.'**
  String get fleetCalendarEmptyMessage;

  /// No description provided for @fleetCalendarBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get fleetCalendarBooked;

  /// No description provided for @fleetCalendarAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get fleetCalendarAvailable;

  /// No description provided for @vehicleReviewDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery & Collection'**
  String get vehicleReviewDelivery;

  /// No description provided for @vehicleReviewDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get vehicleReviewDiscounts;

  /// No description provided for @vehicleReviewInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance & Protection'**
  String get vehicleReviewInsurance;

  /// No description provided for @vehicleReviewYourEarning.
  ///
  /// In en, this message translates to:
  /// **'Your Earning'**
  String get vehicleReviewYourEarning;

  /// No description provided for @subscriptionChoosePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get subscriptionChoosePlanTitle;

  /// No description provided for @subscriptionChoosePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grow your rental business'**
  String get subscriptionChoosePlanSubtitle;

  /// No description provided for @subscriptionBillingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionBillingMonthly;

  /// No description provided for @subscriptionBillingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionBillingYearly;

  /// No description provided for @subscriptionYearlySave.
  ///
  /// In en, this message translates to:
  /// **'Save 17%'**
  String get subscriptionYearlySave;

  /// No description provided for @subscriptionPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subscriptionPlanFree;

  /// No description provided for @subscriptionPlanPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get subscriptionPlanPro;

  /// No description provided for @subscriptionPlanBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get subscriptionPlanBusiness;

  /// No description provided for @subscriptionFreeCars.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 cars'**
  String get subscriptionFreeCars;

  /// No description provided for @subscriptionFreeBookings.
  ///
  /// In en, this message translates to:
  /// **'Basic bookings'**
  String get subscriptionFreeBookings;

  /// No description provided for @subscriptionFreeBranding.
  ///
  /// In en, this message translates to:
  /// **'Gaari branding'**
  String get subscriptionFreeBranding;

  /// No description provided for @subscriptionFreeLogins.
  ///
  /// In en, this message translates to:
  /// **'1 login'**
  String get subscriptionFreeLogins;

  /// No description provided for @subscriptionProCars.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 cars'**
  String get subscriptionProCars;

  /// No description provided for @subscriptionProKyc.
  ///
  /// In en, this message translates to:
  /// **'Customer KYC'**
  String get subscriptionProKyc;

  /// No description provided for @subscriptionProStamp.
  ///
  /// In en, this message translates to:
  /// **'Own shop stamp'**
  String get subscriptionProStamp;

  /// No description provided for @subscriptionProAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts & reports'**
  String get subscriptionProAccounts;

  /// No description provided for @subscriptionProListing.
  ///
  /// In en, this message translates to:
  /// **'Priority listing'**
  String get subscriptionProListing;

  /// No description provided for @subscriptionProTrial.
  ///
  /// In en, this message translates to:
  /// **'14-day trial'**
  String get subscriptionProTrial;

  /// No description provided for @subscriptionBusinessCars.
  ///
  /// In en, this message translates to:
  /// **'Unlimited cars'**
  String get subscriptionBusinessCars;

  /// No description provided for @subscriptionBusinessStaff.
  ///
  /// In en, this message translates to:
  /// **'5 staff logins'**
  String get subscriptionBusinessStaff;

  /// No description provided for @subscriptionBusinessReports.
  ///
  /// In en, this message translates to:
  /// **'Advanced reports'**
  String get subscriptionBusinessReports;

  /// No description provided for @subscriptionBusinessExport.
  ///
  /// In en, this message translates to:
  /// **'PDF & Excel export'**
  String get subscriptionBusinessExport;

  /// No description provided for @subscriptionBusinessBadge.
  ///
  /// In en, this message translates to:
  /// **'Featured badge'**
  String get subscriptionBusinessBadge;

  /// No description provided for @subscriptionBusinessSupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get subscriptionBusinessSupport;

  /// No description provided for @subscriptionExamplePrices.
  ///
  /// In en, this message translates to:
  /// **'Example prices — final pricing to be decided'**
  String get subscriptionExamplePrices;

  /// No description provided for @subscriptionViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get subscriptionViewDetails;

  /// No description provided for @subscriptionMySubscription.
  ///
  /// In en, this message translates to:
  /// **'My subscription'**
  String get subscriptionMySubscription;

  /// No description provided for @subscriptionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your subscription. Please try again.'**
  String get subscriptionLoadError;

  /// No description provided for @subscriptionPlayNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Google Play billing is not connected yet'**
  String get subscriptionPlayNotConnected;

  /// No description provided for @subscriptionPlayNotConnectedNote.
  ///
  /// In en, this message translates to:
  /// **'Play Console setup is still pending. You can subscribe by bank transfer below — nothing is charged through Google Play.'**
  String get subscriptionPlayNotConnectedNote;

  /// No description provided for @subscriptionPayByBank.
  ///
  /// In en, this message translates to:
  /// **'Pay by bank transfer — Google Play billing arrives once the Play Console setup is done'**
  String get subscriptionPayByBank;

  /// No description provided for @subscriptionTrialNote.
  ///
  /// In en, this message translates to:
  /// **'Your 14-day free trial starts after the admin approves your bank-transfer request.'**
  String get subscriptionTrialNote;

  /// No description provided for @subscriptionStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 14-day free trial'**
  String get subscriptionStartTrial;

  /// No description provided for @subscriptionManageInPlay.
  ///
  /// In en, this message translates to:
  /// **'Manage in Google Play'**
  String get subscriptionManageInPlay;

  /// No description provided for @subscriptionManageInPlayNote.
  ///
  /// In en, this message translates to:
  /// **'Available once Google Play billing is connected.'**
  String get subscriptionManageInPlayNote;

  /// No description provided for @subscriptionCarsUsed.
  ///
  /// In en, this message translates to:
  /// **'Cars used'**
  String get subscriptionCarsUsed;

  /// No description provided for @subscriptionStaffLogins.
  ///
  /// In en, this message translates to:
  /// **'Staff logins'**
  String get subscriptionStaffLogins;

  /// No description provided for @subscriptionBillingHistory.
  ///
  /// In en, this message translates to:
  /// **'Billing history'**
  String get subscriptionBillingHistory;

  /// No description provided for @subscriptionBillingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subscription payments yet'**
  String get subscriptionBillingEmpty;

  /// No description provided for @subscriptionPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending admin review'**
  String get subscriptionPendingReview;

  /// No description provided for @subscriptionStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get subscriptionStatusApproved;

  /// No description provided for @subscriptionStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get subscriptionStatusRejected;

  /// No description provided for @subscriptionStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get subscriptionStatusPending;

  /// No description provided for @subscriptionTrialActive.
  ///
  /// In en, this message translates to:
  /// **'Free trial active'**
  String get subscriptionTrialActive;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// No description provided for @subscriptionTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get subscriptionTrialEnds;

  /// No description provided for @subscriptionNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next billing date'**
  String get subscriptionNextBilling;

  /// No description provided for @subscriptionPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get subscriptionPaymentMethod;

  /// No description provided for @subscriptionNoPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'No payment method on file'**
  String get subscriptionNoPaymentMethod;

  /// No description provided for @subscriptionReceiptNote.
  ///
  /// In en, this message translates to:
  /// **'Receipts will be sent to your Google account email once Google Play billing is connected.'**
  String get subscriptionReceiptNote;

  /// No description provided for @subscriptionGoToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to dashboard'**
  String get subscriptionGoToDashboard;

  /// No description provided for @subscriptionChangePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get subscriptionChangePlan;

  /// No description provided for @subscriptionCarLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Car limit reached'**
  String get subscriptionCarLimitTitle;

  /// No description provided for @subscriptionCarLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} plan allows {limit} cars. Upgrade to Business to add unlimited cars and staff.'**
  String subscriptionCarLimitBody(String plan, String limit);

  /// No description provided for @subscriptionUpgradeToBusiness.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Business'**
  String get subscriptionUpgradeToBusiness;

  /// No description provided for @subscriptionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get subscriptionNotNow;

  /// No description provided for @subscriptionPaymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment issue · account on hold'**
  String get subscriptionPaymentIssue;

  /// No description provided for @subscriptionPaymentIssueBody.
  ///
  /// In en, this message translates to:
  /// **'Update your payment method, or pay by bank transfer. Your data is kept.'**
  String get subscriptionPaymentIssueBody;

  /// No description provided for @subscriptionDowngradeNote.
  ///
  /// In en, this message translates to:
  /// **'If it is not fixed, you move to Free. Your data is kept; extra cars are hidden from listing.'**
  String get subscriptionDowngradeNote;

  /// No description provided for @subscriptionTrialTerms.
  ///
  /// In en, this message translates to:
  /// **'Free for 14 days, then billed monthly through Google Play. Auto-renews until cancelled; cancel in Google Play > Subscriptions at least 24 hours before the trial ends.'**
  String get subscriptionTrialTerms;

  /// No description provided for @subscriptionBilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed every month'**
  String get subscriptionBilledMonthly;

  /// No description provided for @subscriptionPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get subscriptionPerYear;

  /// No description provided for @subscriptionPlaySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Play purchase'**
  String get subscriptionPlaySheetTitle;

  /// No description provided for @subscriptionPlayTodayFree.
  ///
  /// In en, this message translates to:
  /// **'Today: free for 14 days'**
  String get subscriptionPlayTodayFree;

  /// No description provided for @subscriptionPlayThen.
  ///
  /// In en, this message translates to:
  /// **'Then billed monthly'**
  String get subscriptionPlayThen;

  /// No description provided for @subscriptionFreePlanNote.
  ///
  /// In en, this message translates to:
  /// **'You are on the Free plan'**
  String get subscriptionFreePlanNote;

  /// No description provided for @subscriptionCurrentTier.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get subscriptionCurrentTier;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Credits'**
  String get creditsTitle;

  /// No description provided for @creditsBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit balance'**
  String get creditsBalance;

  /// No description provided for @creditsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credits yet'**
  String get creditsEmpty;

  /// No description provided for @creditsOneMessage.
  ///
  /// In en, this message translates to:
  /// **'1 message = 1 credit · credits never expire'**
  String get creditsOneMessage;

  /// No description provided for @creditsAutoMessages.
  ///
  /// In en, this message translates to:
  /// **'Auto messages'**
  String get creditsAutoMessages;

  /// No description provided for @creditsAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Messages send automatically only once WhatsApp is connected.'**
  String get creditsAutoNote;

  /// No description provided for @creditsToggleBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking request & approval'**
  String get creditsToggleBooking;

  /// No description provided for @creditsToggleAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance payment receipt'**
  String get creditsToggleAdvance;

  /// No description provided for @creditsTogglePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup reminder'**
  String get creditsTogglePickup;

  /// No description provided for @creditsTogglePickupNote.
  ///
  /// In en, this message translates to:
  /// **'2 hours before pickup'**
  String get creditsTogglePickupNote;

  /// No description provided for @creditsToggleAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement PDF at handover'**
  String get creditsToggleAgreement;

  /// No description provided for @creditsToggleReturn.
  ///
  /// In en, this message translates to:
  /// **'Return reminder & late warning'**
  String get creditsToggleReturn;

  /// No description provided for @creditsToggleDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit refunded'**
  String get creditsToggleDeposit;

  /// No description provided for @creditsToggleDues.
  ///
  /// In en, this message translates to:
  /// **'Dues reminder'**
  String get creditsToggleDues;

  /// No description provided for @creditsToggleDuesNote.
  ///
  /// In en, this message translates to:
  /// **'Every 3 days until paid'**
  String get creditsToggleDuesNote;

  /// No description provided for @creditsBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy credits'**
  String get creditsBuy;

  /// No description provided for @creditsBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy credits'**
  String get creditsBuyTitle;

  /// No description provided for @creditsPackBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get creditsPackBestValue;

  /// No description provided for @creditsPerMessage.
  ///
  /// In en, this message translates to:
  /// **'per message'**
  String get creditsPerMessage;

  /// No description provided for @creditsFreeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Free credits every month'**
  String get creditsFreeMonthly;

  /// No description provided for @creditsFreePlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan — 10 messages'**
  String get creditsFreePlanFree;

  /// No description provided for @creditsFreePlanPro.
  ///
  /// In en, this message translates to:
  /// **'Pro plan — 30 credits'**
  String get creditsFreePlanPro;

  /// No description provided for @creditsFreePlanBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business plan — 100 credits'**
  String get creditsFreePlanBusiness;

  /// No description provided for @creditsBuyPack.
  ///
  /// In en, this message translates to:
  /// **'Buy this pack'**
  String get creditsBuyPack;

  /// No description provided for @creditsPayByBank.
  ///
  /// In en, this message translates to:
  /// **'Pay by bank transfer — Google Play billing arrives once the Play Console setup is done'**
  String get creditsPayByBank;

  /// No description provided for @creditsRequestSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get creditsRequestSubmittedTitle;

  /// No description provided for @creditsRequestSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Credits will be added after payment verification.'**
  String get creditsRequestSubmittedBody;

  /// No description provided for @creditsAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits added'**
  String get creditsAddedTitle;

  /// No description provided for @creditsAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment was verified and the credits were added to your balance.'**
  String get creditsAddedBody;

  /// No description provided for @creditsPreviousBalance.
  ///
  /// In en, this message translates to:
  /// **'Previous balance'**
  String get creditsPreviousBalance;

  /// No description provided for @creditsNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance'**
  String get creditsNewBalance;

  /// No description provided for @creditsPack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get creditsPack;

  /// No description provided for @creditsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get creditsPrice;

  /// No description provided for @creditsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get creditsDone;

  /// No description provided for @creditsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Message history'**
  String get creditsHistoryTitle;

  /// No description provided for @creditsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get creditsSent;

  /// No description provided for @creditsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get creditsDelivered;

  /// No description provided for @creditsRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get creditsRead;

  /// No description provided for @creditsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No WhatsApp messages sent yet'**
  String get creditsHistoryEmpty;

  /// No description provided for @creditsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get creditsFilterAll;

  /// No description provided for @creditsFilterBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get creditsFilterBookings;

  /// No description provided for @creditsFilterReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get creditsFilterReminders;

  /// No description provided for @creditsFilterReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get creditsFilterReceipts;

  /// No description provided for @creditsUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages used'**
  String get creditsUsedLabel;

  /// No description provided for @creditsFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free credits this month'**
  String get creditsFreeLabel;

  /// No description provided for @creditsTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Template preview — Booking confirmation'**
  String get creditsTemplateTitle;

  /// No description provided for @creditsTemplateNote.
  ///
  /// In en, this message translates to:
  /// **'Templates are approved by WhatsApp. Customer name, car, time and amount are filled in automatically.'**
  String get creditsTemplateNote;

  /// No description provided for @creditsSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test to my number'**
  String get creditsSendTest;

  /// No description provided for @creditsSendTestDisabled.
  ///
  /// In en, this message translates to:
  /// **'Available once WhatsApp is connected.'**
  String get creditsSendTestDisabled;

  /// No description provided for @creditsZeroTitle.
  ///
  /// In en, this message translates to:
  /// **'No credits left'**
  String get creditsZeroTitle;

  /// No description provided for @creditsZeroBody.
  ///
  /// In en, this message translates to:
  /// **'The pickup reminder was not sent automatically. Buy credits, or send it yourself from your own WhatsApp.'**
  String get creditsZeroBody;

  /// No description provided for @creditsZeroBanner.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp credits: 0 left'**
  String get creditsZeroBanner;

  /// No description provided for @creditsZeroBannerNote.
  ///
  /// In en, this message translates to:
  /// **'You were alerted at 10 credits'**
  String get creditsZeroBannerNote;

  /// No description provided for @creditsSendViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send via my WhatsApp'**
  String get creditsSendViaWhatsapp;

  /// No description provided for @creditsViaWhatsappNote.
  ///
  /// In en, this message translates to:
  /// **'Your WhatsApp opens with the message already written. You just tap send.'**
  String get creditsViaWhatsappNote;

  /// No description provided for @creditsViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View message history'**
  String get creditsViewHistory;

  /// No description provided for @creditsViewTemplates.
  ///
  /// In en, this message translates to:
  /// **'View templates'**
  String get creditsViewTemplates;

  /// No description provided for @customerDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Profile'**
  String get customerDetailTitle;

  /// No description provided for @customerDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found'**
  String get customerDetailNotFound;

  /// No description provided for @customerDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This customer could not be found.'**
  String get customerDetailNotFoundMessage;

  /// No description provided for @customerDetailKycTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC status'**
  String get customerDetailKycTitle;

  /// No description provided for @customerDetailKycOnFile.
  ///
  /// In en, this message translates to:
  /// **'KYC documents are on file for this customer.'**
  String get customerDetailKycOnFile;

  /// No description provided for @customerDetailKycNotOnFile.
  ///
  /// In en, this message translates to:
  /// **'No KYC record on file — this customer is known only from bookings.'**
  String get customerDetailKycNotOnFile;

  /// No description provided for @customerDetailDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents & photo'**
  String get customerDetailDocuments;

  /// No description provided for @customerDetailNoDocument.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get customerDetailNoDocument;

  /// No description provided for @customerDetailProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get customerDetailProfilePhoto;

  /// No description provided for @customerDetailCnicFront.
  ///
  /// In en, this message translates to:
  /// **'CNIC front'**
  String get customerDetailCnicFront;

  /// No description provided for @customerDetailCnicBack.
  ///
  /// In en, this message translates to:
  /// **'CNIC back'**
  String get customerDetailCnicBack;

  /// No description provided for @customerDetailLicenseFront.
  ///
  /// In en, this message translates to:
  /// **'License front'**
  String get customerDetailLicenseFront;

  /// No description provided for @customerDetailLicenseBack.
  ///
  /// In en, this message translates to:
  /// **'License back'**
  String get customerDetailLicenseBack;

  /// No description provided for @customerDetailSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get customerDetailSignature;

  /// No description provided for @customerDetailFingerprints.
  ///
  /// In en, this message translates to:
  /// **'Fingerprints on file'**
  String get customerDetailFingerprints;

  /// No description provided for @customerDetailFingerprintsNone.
  ///
  /// In en, this message translates to:
  /// **'No fingerprints on file'**
  String get customerDetailFingerprintsNone;

  /// No description provided for @customerDetailFingerprintsLeft.
  ///
  /// In en, this message translates to:
  /// **'Left hand'**
  String get customerDetailFingerprintsLeft;

  /// No description provided for @customerDetailFingerprintsRight.
  ///
  /// In en, this message translates to:
  /// **'Right hand'**
  String get customerDetailFingerprintsRight;

  /// No description provided for @customerDetailRentalHistory.
  ///
  /// In en, this message translates to:
  /// **'Rental history'**
  String get customerDetailRentalHistory;

  /// No description provided for @customerDetailTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get customerDetailTotalSpent;

  /// No description provided for @customerDetailTotalDues.
  ///
  /// In en, this message translates to:
  /// **'Outstanding dues'**
  String get customerDetailTotalDues;

  /// No description provided for @customerDetailNotBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Not blacklisted'**
  String get customerDetailNotBlacklisted;

  /// No description provided for @customerDetailApprovalPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get customerDetailApprovalPending;

  /// No description provided for @customerDetailApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve profile'**
  String get customerDetailApprove;

  /// No description provided for @customerDetailReject.
  ///
  /// In en, this message translates to:
  /// **'Reject profile'**
  String get customerDetailReject;

  /// No description provided for @customerDetailRejectReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get customerDetailRejectReasonTitle;

  /// No description provided for @customerDetailRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Write the reason…'**
  String get customerDetailRejectReasonHint;

  /// No description provided for @customerDetailRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required to reject a profile'**
  String get customerDetailRejectReasonRequired;

  /// No description provided for @customerDetailRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get customerDetailRejectConfirm;

  /// No description provided for @customerDetailApprovalFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this customer\'s approval. Please try again.'**
  String get customerDetailApprovalFailed;

  /// No description provided for @customerAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer added'**
  String get customerAddedTitle;

  /// No description provided for @customerAddedReady.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s profile is ready — you can now start a booking.'**
  String customerAddedReady(String name);

  /// No description provided for @customerAddedStartBooking.
  ///
  /// In en, this message translates to:
  /// **'Start Booking'**
  String get customerAddedStartBooking;

  /// No description provided for @customerAddedViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get customerAddedViewProfile;

  /// No description provided for @customersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customersFilterAll;

  /// No description provided for @customersFilterRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get customersFilterRegular;

  /// No description provided for @customersFilterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get customersFilterNew;

  /// No description provided for @customersFilterFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get customersFilterFlagged;

  /// No description provided for @customersBadgeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get customersBadgeRegular;

  /// No description provided for @customersBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get customersBadgeNew;

  /// No description provided for @customersViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get customersViewProfile;

  /// No description provided for @returnRefundDeposit.
  ///
  /// In en, this message translates to:
  /// **'Refund Deposit'**
  String get returnRefundDeposit;

  /// No description provided for @returnRefundRecorded.
  ///
  /// In en, this message translates to:
  /// **'Deposit refund of Rs. {amount} recorded.'**
  String returnRefundRecorded(String amount);

  /// No description provided for @returnRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the deposit refund. Please try again.'**
  String get returnRefundFailed;

  /// No description provided for @returnRecordingRefund.
  ///
  /// In en, this message translates to:
  /// **'Recording refund…'**
  String get returnRecordingRefund;

  /// No description provided for @returnCloseBooking.
  ///
  /// In en, this message translates to:
  /// **'Complete & Close Booking'**
  String get returnCloseBooking;

  /// No description provided for @contractFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare Breakdown'**
  String get contractFareTitle;

  /// No description provided for @contractFareDailyRate.
  ///
  /// In en, this message translates to:
  /// **'Daily Rate'**
  String get contractFareDailyRate;

  /// No description provided for @contractFareRentalDays.
  ///
  /// In en, this message translates to:
  /// **'Rental Days'**
  String get contractFareRentalDays;

  /// No description provided for @contractFareDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String contractFareDays(int days);

  /// No description provided for @contractFareTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Rent'**
  String get contractFareTotal;

  /// No description provided for @contractAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms above'**
  String get contractAgreeTerms;

  /// No description provided for @contractAgreeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your agreement choice. Please try again.'**
  String get contractAgreeSaveFailed;

  /// No description provided for @contractGuarantorTitle.
  ///
  /// In en, this message translates to:
  /// **'Guarantor / Witness Signature'**
  String get contractGuarantorTitle;

  /// No description provided for @contractGuarantorHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the guarantor to sign in the box below.'**
  String get contractGuarantorHint;

  /// No description provided for @contractSignAgreement.
  ///
  /// In en, this message translates to:
  /// **'Sign Agreement'**
  String get contractSignAgreement;

  /// No description provided for @contractSigning.
  ///
  /// In en, this message translates to:
  /// **'Signing…'**
  String get contractSigning;

  /// No description provided for @contractAgreementSigned.
  ///
  /// In en, this message translates to:
  /// **'Agreement fully signed'**
  String get contractAgreementSigned;

  /// No description provided for @contractSignFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the signature. Please try again.'**
  String get contractSignFailed;

  /// No description provided for @contractShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Agreement'**
  String get contractShareTitle;

  /// No description provided for @contractShareWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contractShareWhatsapp;

  /// No description provided for @contractShareEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contractShareEmail;

  /// No description provided for @contractSharePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get contractSharePrint;

  /// No description provided for @contractShareNote.
  ///
  /// In en, this message translates to:
  /// **'The agreement file is shared to the app you choose. Nothing is sent automatically.'**
  String get contractShareNote;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authLegalIntro.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get authLegalIntro;

  /// No description provided for @authLegalAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get authLegalAnd;

  /// No description provided for @legalTermsBody.
  ///
  /// In en, this message translates to:
  /// **'RentalHub Terms of Service\n\n1. What RentalHub is\nRentalHub is a car rental marketplace in Pakistan that connects vehicle owners (shops) with customers. Owners list their vehicles and set their own rates; customers book through the app.\n\n2. Your account\nYou are responsible for keeping your sign-in details safe and for everything done with your account. Give true information about yourself, your shop and your vehicles.\n\n3. Bookings and payments\nBooking prices are set by the vehicle owner. Payments, advances and security deposits follow the terms shown at booking time. A booking can be cancelled under the cancellation terms shown for that booking.\n\n4. Your responsibilities\nOwners must keep their vehicles roadworthy, insured and legally registered, and must honour confirmed bookings. Customers must return vehicles on time, in the condition received, and pay any agreed extra charges for damage, late return or extra kilometres.\n\n5. Prohibited use\nDo not use RentalHub for anything unlawful, do not list a vehicle you do not have the right to rent out, and do not share another person\'s personal information without their permission.\n\n6. Liability\nRentalHub provides the marketplace and the booking tools. Owners and customers are responsible for their own vehicles, driving and agreements with each other. To the extent allowed by law, RentalHub is not liable for loss or damage arising from a rental between an owner and a customer.\n\n7. Changes and contact\nWe may update these terms and will show the current version in the app. Questions: contact RentalHub support from the Help section in the app.'**
  String get legalTermsBody;

  /// No description provided for @legalPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'RentalHub Privacy Policy\n\n1. What we collect\nWe collect the information you give us: your name, phone number, email address, CNIC details and documents, shop details, vehicle details and photos, booking and payment records, and messages you send through the app. We also collect basic technical information such as device type and app usage needed to run the service.\n\n2. How we use it\nWe use your information to run RentalHub: to create and verify accounts, list vehicles, process bookings and payments, prevent fraud and blacklisted rentals, and to contact you about your bookings and your shop.\n\n3. How we share it\nWe share your information only as needed to run the service: with the other party to your booking (owner or customer), with payment providers to process payments, and with the authorities when the law requires it. We do not sell your personal information.\n\n4. Photos and documents\nCNIC photos, selfies, licences and shop photos are used only for verification and for the rental record. They are not used for face matching and are not shared publicly.\n\n5. How long we keep it\nWe keep your information while your account is active and for as long as needed for bookings, payments, disputes and legal records. You can ask us to delete your account and its personal information from the Help section, subject to records we must keep by law.\n\n6. Your choices\nYou can update your profile and shop details in the app, and you can turn app notifications on or off in Settings.\n\n7. Contact\nQuestions about your data: contact RentalHub support from the Help section in the app.'**
  String get legalPrivacyBody;

  /// No description provided for @onboardingSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get onboardingSubmitForReview;

  /// No description provided for @onboardingDocRequired.
  ///
  /// In en, this message translates to:
  /// **'{document} is required before submitting.'**
  String onboardingDocRequired(String document);

  /// No description provided for @addVehicleCityRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'In-City / Out-City Day Rates'**
  String get addVehicleCityRatesTitle;

  /// No description provided for @addVehicleCityRatesHint.
  ///
  /// In en, this message translates to:
  /// **'Prefilled from your full-day rate. Change either rate if trips outside the city cost more.'**
  String get addVehicleCityRatesHint;

  /// No description provided for @addVehicleInCityDayRate.
  ///
  /// In en, this message translates to:
  /// **'In-City Day Rate'**
  String get addVehicleInCityDayRate;

  /// No description provided for @addVehicleInCityDayRateHint.
  ///
  /// In en, this message translates to:
  /// **'Same-city bookings, per day'**
  String get addVehicleInCityDayRateHint;

  /// No description provided for @addVehicleOutCityDayRate.
  ///
  /// In en, this message translates to:
  /// **'Out-City Day Rate'**
  String get addVehicleOutCityDayRate;

  /// No description provided for @addVehicleOutCityDayRateHint.
  ///
  /// In en, this message translates to:
  /// **'Trips outside the city, per day'**
  String get addVehicleOutCityDayRateHint;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with Customers'**
  String get shareTitle;

  /// No description provided for @shareStepOfTwo.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 2'**
  String shareStepOfTwo(int step);

  /// No description provided for @shareChoosePrice.
  ///
  /// In en, this message translates to:
  /// **'Choose a price to share'**
  String get shareChoosePrice;

  /// No description provided for @shareWithCustomersText.
  ///
  /// In en, this message translates to:
  /// **'Rent {vehicle} for {rate} ({period}) on RentalHub: {link}'**
  String shareWithCustomersText(
      String vehicle, String rate, String period, String link);

  /// No description provided for @shareLinkNote.
  ///
  /// In en, this message translates to:
  /// **'The web listing page behind this link is not live yet.'**
  String get shareLinkNote;

  /// No description provided for @rateMatrixInCityTitle.
  ///
  /// In en, this message translates to:
  /// **'In-City Rent Rates'**
  String get rateMatrixInCityTitle;

  /// No description provided for @rateMatrixOutCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Out-City Rent Rates'**
  String get rateMatrixOutCityTitle;

  /// No description provided for @settingsNotifyBookingRequests.
  ///
  /// In en, this message translates to:
  /// **'Booking requests'**
  String get settingsNotifyBookingRequests;

  /// No description provided for @settingsNotifyPaymentProofs.
  ///
  /// In en, this message translates to:
  /// **'Payment proofs'**
  String get settingsNotifyPaymentProofs;

  /// No description provided for @settingsNotifyHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover'**
  String get settingsNotifyHandover;

  /// No description provided for @settingsNotifyReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get settingsNotifyReturns;

  /// No description provided for @settingsNotifyMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance reminders'**
  String get settingsNotifyMaintenance;

  /// No description provided for @reportDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get reportDownloadPdf;

  /// No description provided for @reportDownloadPdfSaved.
  ///
  /// In en, this message translates to:
  /// **'Report PDF saved to your device.'**
  String get reportDownloadPdfSaved;

  /// No description provided for @carEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Package rates'**
  String get carEditorTitle;

  /// No description provided for @carEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save package'**
  String get carEditorSave;

  /// No description provided for @carEditorSaved.
  ///
  /// In en, this message translates to:
  /// **'Rates saved'**
  String get carEditorSaved;

  /// No description provided for @outCityRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Out-of-city rules'**
  String get outCityRulesTitle;

  /// No description provided for @outCityRulesSave.
  ///
  /// In en, this message translates to:
  /// **'Save rules'**
  String get outCityRulesSave;

  /// No description provided for @outCityRulesSaved.
  ///
  /// In en, this message translates to:
  /// **'Rules saved'**
  String get outCityRulesSaved;

  /// No description provided for @outCityTripCharges.
  ///
  /// In en, this message translates to:
  /// **'Trip charges'**
  String get outCityTripCharges;

  /// No description provided for @outCityRulesAppliesAll.
  ///
  /// In en, this message translates to:
  /// **'Applies to all packages'**
  String get outCityRulesAppliesAll;

  /// No description provided for @outCityBoundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Home city boundary'**
  String get outCityBoundaryTitle;

  /// No description provided for @outCityBoundaryCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get outCityBoundaryCity;

  /// No description provided for @outCityBoundaryRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius (km)'**
  String get outCityBoundaryRadius;

  /// No description provided for @editVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit car details'**
  String get editVehicleTitle;

  /// No description provided for @editVehicleSave.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get editVehicleSave;

  /// No description provided for @editVehicleSaved.
  ///
  /// In en, this message translates to:
  /// **'Car details saved'**
  String get editVehicleSaved;

  /// No description provided for @editVehicleStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get editVehicleStatus;

  /// No description provided for @outCityModePerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get outCityModePerDay;

  /// No description provided for @outCityModePerKm.
  ///
  /// In en, this message translates to:
  /// **'Per km'**
  String get outCityModePerKm;

  /// No description provided for @outCityModeFixedRoute.
  ///
  /// In en, this message translates to:
  /// **'Fixed route'**
  String get outCityModeFixedRoute;

  /// No description provided for @outCityPricingMode.
  ///
  /// In en, this message translates to:
  /// **'Pricing mode'**
  String get outCityPricingMode;

  /// No description provided for @outCityPerKmRate.
  ///
  /// In en, this message translates to:
  /// **'Per-km rate (Rs/km)'**
  String get outCityPerKmRate;

  /// No description provided for @outCityFixedRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed route'**
  String get outCityFixedRouteLabel;

  /// No description provided for @outCityFixedRouteNone.
  ///
  /// In en, this message translates to:
  /// **'No fixed route selected'**
  String get outCityFixedRouteNone;

  /// No description provided for @outCityFixedRouteChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a fixed route'**
  String get outCityFixedRouteChoose;

  /// No description provided for @farePerKmUnit.
  ///
  /// In en, this message translates to:
  /// **'{rate} / km'**
  String farePerKmUnit(String rate);

  /// No description provided for @fareFixedRoute.
  ///
  /// In en, this message translates to:
  /// **'Fixed route: {route}'**
  String fareFixedRoute(String route);

  /// No description provided for @farePerKmEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated on {km} km — final total on actual km at return'**
  String farePerKmEstimate(int km);

  /// No description provided for @outCityNightStay.
  ///
  /// In en, this message translates to:
  /// **'Driver night stay (per night)'**
  String get outCityNightStay;

  /// No description provided for @outCityNightStayCap.
  ///
  /// In en, this message translates to:
  /// **'Charged for each night away from the home city'**
  String get outCityNightStayCap;

  /// No description provided for @outCityTolls.
  ///
  /// In en, this message translates to:
  /// **'Tolls & parking'**
  String get outCityTolls;

  /// No description provided for @outCityTollsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Paid by customer'**
  String get outCityTollsCustomer;

  /// No description provided for @outCityTollsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included in rent'**
  String get outCityTollsIncluded;

  /// No description provided for @bookingFareNightStay.
  ///
  /// In en, this message translates to:
  /// **'Driver night stay ({nights} nights)'**
  String bookingFareNightStay(int nights);

  /// No description provided for @bookingFareTollsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Tolls & parking — paid by customer'**
  String get bookingFareTollsCustomer;

  /// No description provided for @bookingFareTollsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Tolls & parking — included in rent'**
  String get bookingFareTollsIncluded;

  /// No description provided for @outCityMapOffline.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable offline'**
  String get outCityMapOffline;

  /// No description provided for @outCityMapNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Shop location not set — boundary shown as text'**
  String get outCityMapNoLocation;

  /// No description provided for @shops_title.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops_title;

  /// No description provided for @shops_showMap.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get shops_showMap;

  /// No description provided for @shops_showList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get shops_showList;

  /// No description provided for @shops_allCities.
  ///
  /// In en, this message translates to:
  /// **'All cities'**
  String get shops_allCities;

  /// No description provided for @shops_unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get shops_unverified;

  /// No description provided for @shops_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shops match these filters'**
  String get shops_emptyTitle;

  /// No description provided for @shops_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different city or filter.'**
  String get shops_emptySubtitle;

  /// No description provided for @shops_mapOffline.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable offline — the list still works'**
  String get shops_mapOffline;

  /// No description provided for @shops_chooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose a city to browse shops'**
  String get shops_chooseCity;

  /// No description provided for @shops_noPinNote.
  ///
  /// In en, this message translates to:
  /// **'Shops without a saved location appear in the list only'**
  String get shops_noPinNote;

  /// No description provided for @home2_kpiActive.
  ///
  /// In en, this message translates to:
  /// **'Active bookings'**
  String get home2_kpiActive;

  /// No description provided for @home2_kpiWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get home2_kpiWallet;

  /// No description provided for @home2_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get home2_support;

  /// No description provided for @home2_kycNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get home2_kycNotStarted;

  /// KYC documents completed, e.g. 2 of 4 documents ready
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} documents ready'**
  String home2_kycProgress(Object done, Object total);

  /// No description provided for @home2_kycView.
  ///
  /// In en, this message translates to:
  /// **'View documents'**
  String get home2_kycView;

  /// No description provided for @home2_recentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent bookings'**
  String get home2_recentBookings;

  /// No description provided for @home2_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get home2_upcoming;

  /// No description provided for @home2_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get home2_viewAll;

  /// No description provided for @home2_noBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get home2_noBookings;

  /// No description provided for @home2_noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing coming up'**
  String get home2_noUpcoming;

  /// No description provided for @home2_paymentOverdue.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue'**
  String get home2_paymentOverdue;

  /// No description provided for @home2_paymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get home2_paymentDue;

  /// No description provided for @admin2_displayUnverifiedShops.
  ///
  /// In en, this message translates to:
  /// **'Display unverified shops'**
  String get admin2_displayUnverifiedShops;

  /// No description provided for @admin2_displayUnverifiedShopsHint.
  ///
  /// In en, this message translates to:
  /// **'When off, unverified shops are hidden from the Shops tab.'**
  String get admin2_displayUnverifiedShopsHint;

  /// No description provided for @admin2_allowBookingsFromUnverifiedShops.
  ///
  /// In en, this message translates to:
  /// **'Allow bookings from unverified shops'**
  String get admin2_allowBookingsFromUnverifiedShops;

  /// No description provided for @admin2_allowBookingsFromUnverifiedShopsHint.
  ///
  /// In en, this message translates to:
  /// **'When off, customers cannot book from unverified shops.'**
  String get admin2_allowBookingsFromUnverifiedShopsHint;

  /// No description provided for @admin2_unverifiedBookingsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Bookings from unverified shops are currently disabled by the platform.'**
  String get admin2_unverifiedBookingsDisabled;

  /// No description provided for @admin2_apkDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Android app (APK)'**
  String get admin2_apkDownloadTitle;

  /// No description provided for @admin2_apkDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest release build published by CI.'**
  String get admin2_apkDownloadSubtitle;

  /// No description provided for @admin2_apkVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get admin2_apkVersion;

  /// No description provided for @admin2_apkBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get admin2_apkBuild;

  /// No description provided for @admin2_apkUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get admin2_apkUpdated;

  /// No description provided for @admin2_apkDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download APK'**
  String get admin2_apkDownloadButton;

  /// No description provided for @admin2_apkDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Download link'**
  String get admin2_apkDownloadLink;

  /// No description provided for @admin2_apkNoBuild.
  ///
  /// In en, this message translates to:
  /// **'No build published yet'**
  String get admin2_apkNoBuild;

  /// No description provided for @admin2_apkNoBuildHint.
  ///
  /// In en, this message translates to:
  /// **'The APK appears here after CI publishes a release build.'**
  String get admin2_apkNoBuildHint;

  /// No description provided for @admin2_apkLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the latest build.'**
  String get admin2_apkLoadFailed;

  /// No description provided for @admin2_apkLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking for the latest build…'**
  String get admin2_apkLoading;

  /// No description provided for @admin2_apkDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the download link.'**
  String get admin2_apkDownloadFailed;

  /// No description provided for @admin2_apkSuperAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only super admins can download the APK'**
  String get admin2_apkSuperAdminOnly;

  /// No description provided for @admin2_apkSuperAdminOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a super admin for the latest build.'**
  String get admin2_apkSuperAdminOnlyHint;

  /// No description provided for @adminKycReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Review'**
  String get adminKycReviewTitle;

  /// No description provided for @adminKycReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer identity documents waiting for a decision'**
  String get adminKycReviewSubtitle;

  /// No description provided for @adminKycReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending KYC submissions'**
  String get adminKycReviewEmpty;

  /// No description provided for @adminKycReviewEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Every customer submission has been decided.'**
  String get adminKycReviewEmptyHint;

  /// No description provided for @adminKycReviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the KYC queue.'**
  String get adminKycReviewLoadFailed;

  /// No description provided for @adminKycReviewNotFound.
  ///
  /// In en, this message translates to:
  /// **'Submission not found.'**
  String get adminKycReviewNotFound;

  /// No description provided for @adminKycReviewNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'Only super admins and operations can review KYC'**
  String get adminKycReviewNotPermitted;

  /// No description provided for @adminKycReviewNotPermittedHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a super admin or operations admin to review this submission.'**
  String get adminKycReviewNotPermittedHint;

  /// No description provided for @adminNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'Your admin role does not allow this action.'**
  String get adminNotPermitted;

  /// No description provided for @adminKycReviewApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminKycReviewApprove;

  /// No description provided for @adminKycReviewReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminKycReviewReject;

  /// No description provided for @adminKycReviewReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required to reject — the customer sees it)'**
  String get adminKycReviewReasonLabel;

  /// No description provided for @adminKycReviewReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required to reject — the customer sees it.'**
  String get adminKycReviewReasonRequired;

  /// No description provided for @adminKycReviewDecisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Decision saved.'**
  String get adminKycReviewDecisionSaved;

  /// No description provided for @adminKycReviewDecisionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server — try again.'**
  String get adminKycReviewDecisionFailed;

  /// No description provided for @adminKycReviewLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get adminKycReviewLicenseNumber;

  /// No description provided for @adminKycReviewLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'License expiry'**
  String get adminKycReviewLicenseExpiry;

  /// No description provided for @adminKycReviewCnicNumber.
  ///
  /// In en, this message translates to:
  /// **'CNIC number'**
  String get adminKycReviewCnicNumber;

  /// No description provided for @adminKycReviewSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on'**
  String get adminKycReviewSubmittedOn;

  /// No description provided for @kyc2_qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get kyc2_qrCode;

  /// No description provided for @kyc2_qrRead.
  ///
  /// In en, this message translates to:
  /// **'QR code saved.'**
  String get kyc2_qrRead;

  /// No description provided for @kyc2_licenseUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the license number from that photo — please type it.'**
  String get kyc2_licenseUnreadable;

  /// No description provided for @appealTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeal blacklist listing'**
  String get appealTitle;

  /// No description provided for @appealButton.
  ///
  /// In en, this message translates to:
  /// **'Appeal blacklist decision'**
  String get appealButton;

  /// No description provided for @appealIntro.
  ///
  /// In en, this message translates to:
  /// **'If you believe this listing is a mistake, you can ask the tribunal to review it.'**
  String get appealIntro;

  /// No description provided for @appealReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for appeal'**
  String get appealReasonLabel;

  /// No description provided for @appealReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why this listing should be reviewed…'**
  String get appealReasonHint;

  /// No description provided for @appealReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write a reason for your appeal.'**
  String get appealReasonRequired;

  /// No description provided for @appealSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit appeal'**
  String get appealSubmit;

  /// No description provided for @appealSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appeal submitted. The tribunal will review it.'**
  String get appealSuccess;

  /// No description provided for @appealError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit the appeal. Please try again.'**
  String get appealError;

  /// No description provided for @appealRecordNotFound.
  ///
  /// In en, this message translates to:
  /// **'No blacklist record was found for this CNIC.'**
  String get appealRecordNotFound;

  /// No description provided for @anncTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get anncTitle;

  /// No description provided for @anncLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading announcement…'**
  String get anncLoading;

  /// No description provided for @anncNotFound.
  ///
  /// In en, this message translates to:
  /// **'This announcement is no longer available.'**
  String get anncNotFound;

  /// No description provided for @anncLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the announcement. Please try again.'**
  String get anncLoadError;

  /// No description provided for @couldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open the dialer.'**
  String get couldNotOpenDialer;

  /// No description provided for @countdownPickupReached.
  ///
  /// In en, this message translates to:
  /// **'Pickup time reached'**
  String get countdownPickupReached;

  /// No description provided for @countdownReturnReached.
  ///
  /// In en, this message translates to:
  /// **'Return time reached'**
  String get countdownReturnReached;

  /// No description provided for @countdownTimeReached.
  ///
  /// In en, this message translates to:
  /// **'Time reached'**
  String get countdownTimeReached;

  /// No description provided for @kycRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String kycRejectionReason(String reason);

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get onboardingNameHint;

  /// No description provided for @pickerPastTime.
  ///
  /// In en, this message translates to:
  /// **'That time has already passed. Please pick a later time.'**
  String get pickerPastTime;

  /// No description provided for @rateSelectBoth.
  ///
  /// In en, this message translates to:
  /// **'Please rate both the shop and the vehicle.'**
  String get rateSelectBoth;

  /// No description provided for @reviewDraftMissing.
  ///
  /// In en, this message translates to:
  /// **'Booking details are missing. Please start again.'**
  String get reviewDraftMissing;

  /// No description provided for @reviewSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to submit this booking.'**
  String get reviewSignInRequired;

  /// No description provided for @reviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit the booking. Please try again.'**
  String get reviewSubmitFailed;

  /// No description provided for @shopLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this showroom.'**
  String get shopLoadFailed;

  /// No description provided for @shopNoPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number for this shop.'**
  String get shopNoPhoneNumber;

  /// No description provided for @shopWhatsappHello.
  ///
  /// In en, this message translates to:
  /// **'Hello {shopName}, I found your listing on RentalHub.'**
  String shopWhatsappHello(String shopName);

  /// No description provided for @signInRequiredGeneric.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get signInRequiredGeneric;

  /// No description provided for @statusProofRejected.
  ///
  /// In en, this message translates to:
  /// **'Proof rejected'**
  String get statusProofRejected;

  /// No description provided for @tripOutCityFixedRouteLine.
  ///
  /// In en, this message translates to:
  /// **'Out-of-city: fixed route price'**
  String get tripOutCityFixedRouteLine;

  /// No description provided for @tripOutCityPerDayLine.
  ///
  /// In en, this message translates to:
  /// **'Out-of-city: {rate} / day'**
  String tripOutCityPerDayLine(String rate);

  /// No description provided for @tripOutCityPerKmLine.
  ///
  /// In en, this message translates to:
  /// **'Out-of-city: {rate} / km'**
  String tripOutCityPerKmLine(String rate);

  /// No description provided for @vehicleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this vehicle.'**
  String get vehicleLoadFailed;

  /// No description provided for @manualBookingWhatsappToggle.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp confirmation'**
  String get manualBookingWhatsappToggle;

  /// No description provided for @admin2_signInFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Try again.'**
  String get admin2_signInFailedGeneric;

  /// No description provided for @admin2_signInWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get admin2_signInWrongCredentials;

  /// No description provided for @admin2_signInAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Ask a super admin for help.'**
  String get admin2_signInAccountDisabled;

  /// No description provided for @admin2_signInTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many sign-in attempts. Try again later.'**
  String get admin2_signInTooManyAttempts;

  /// No description provided for @admin2_signInNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get admin2_signInNoConnection;

  /// No description provided for @admin2_signInInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get admin2_signInInvalidEmail;

  /// No description provided for @admin2_showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get admin2_showPassword;

  /// No description provided for @admin2_hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get admin2_hidePassword;

  /// No description provided for @admin2_blacklistReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report to blacklist?'**
  String get admin2_blacklistReportTitle;

  /// No description provided for @admin2_blacklistReportBody.
  ///
  /// In en, this message translates to:
  /// **'This blocks the customer platform-wide. Give the reason — the tribunal judges the case on it.'**
  String get admin2_blacklistReportBody;

  /// No description provided for @admin2_blacklistReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get admin2_blacklistReasonLabel;

  /// No description provided for @admin2_blacklistReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required to report a customer.'**
  String get admin2_blacklistReasonRequired;

  /// No description provided for @admin2_blacklistReportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get admin2_blacklistReportConfirm;

  /// No description provided for @admin2_watchlistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get admin2_watchlistAdd;

  /// No description provided for @admin2_watchlistRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist'**
  String get admin2_watchlistRemove;

  /// No description provided for @admin2_ticketRepliesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the replies.'**
  String get admin2_ticketRepliesLoadFailed;

  /// No description provided for @admin2_suspendReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (shown in the audit log)'**
  String get admin2_suspendReasonLabel;

  /// No description provided for @admin2_callFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the dialer.'**
  String get admin2_callFailed;

  /// No description provided for @admin2_whatsappOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get admin2_whatsappOpenFailed;

  /// No description provided for @admin2_menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get admin2_menu;

  /// No description provided for @admin2_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get admin2_confirm;

  /// No description provided for @admin2_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get admin2_approve;

  /// No description provided for @admin2_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get admin2_reject;

  /// No description provided for @admin2_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get admin2_yes;

  /// No description provided for @admin2_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get admin2_no;

  /// No description provided for @admin2_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get admin2_save;

  /// No description provided for @admin2_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get admin2_saving;

  /// No description provided for @admin2_serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server.'**
  String get admin2_serverUnreachable;

  /// No description provided for @admin2_serverUnreachableRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server — try again.'**
  String get admin2_serverUnreachableRetry;

  /// No description provided for @admin2_reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get admin2_reasonRequired;

  /// No description provided for @admin2_decisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Decision saved.'**
  String get admin2_decisionSaved;

  /// No description provided for @admin2_none.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get admin2_none;

  /// No description provided for @admin2_withDriver.
  ///
  /// In en, this message translates to:
  /// **'With driver'**
  String get admin2_withDriver;

  /// No description provided for @admin2_selfDrive.
  ///
  /// In en, this message translates to:
  /// **'Self drive'**
  String get admin2_selfDrive;

  /// No description provided for @admin2_suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get admin2_suspended;

  /// No description provided for @admin2_hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get admin2_hidden;

  /// No description provided for @admin2_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get admin2_open;

  /// No description provided for @admin2_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get admin2_closed;

  /// No description provided for @admin2_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get admin2_resolved;

  /// No description provided for @admin2_inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get admin2_inProgress;

  /// No description provided for @admin2_escalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get admin2_escalated;

  /// No description provided for @admin2_requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get admin2_requested;

  /// No description provided for @admin2_paymentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted'**
  String get admin2_paymentSubmitted;

  /// No description provided for @admin2_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get admin2_paid;

  /// No description provided for @admin2_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get admin2_completed;

  /// No description provided for @admin2_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get admin2_cancelled;

  /// No description provided for @admin2_inReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get admin2_inReview;

  /// No description provided for @admin2_roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get admin2_roleSuperAdmin;

  /// No description provided for @admin2_roleOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get admin2_roleOperations;

  /// No description provided for @admin2_roleSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get admin2_roleSupport;

  /// No description provided for @admin2_roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin2_roleAdmin;

  /// No description provided for @admin2_navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get admin2_navDashboard;

  /// No description provided for @admin2_navShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get admin2_navShops;

  /// No description provided for @admin2_navApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get admin2_navApprovals;

  /// No description provided for @admin2_navCars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get admin2_navCars;

  /// No description provided for @admin2_navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get admin2_navCustomers;

  /// No description provided for @admin2_navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get admin2_navBookings;

  /// No description provided for @admin2_navDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get admin2_navDisputes;

  /// No description provided for @admin2_navReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get admin2_navReviews;

  /// No description provided for @admin2_navSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get admin2_navSupport;

  /// No description provided for @admin2_navAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get admin2_navAnnouncements;

  /// No description provided for @admin2_navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get admin2_navReports;

  /// No description provided for @admin2_navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get admin2_navSettings;

  /// No description provided for @admin2_navApkDownload.
  ///
  /// In en, this message translates to:
  /// **'APK Download'**
  String get admin2_navApkDownload;

  /// No description provided for @admin2_navBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Blacklist'**
  String get admin2_navBlacklist;

  /// No description provided for @admin2_navAdminTeam.
  ///
  /// In en, this message translates to:
  /// **'Admin Team'**
  String get admin2_navAdminTeam;

  /// No description provided for @admin2_navActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get admin2_navActivityLog;

  /// No description provided for @admin2_navSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get admin2_navSubscriptions;

  /// No description provided for @admin2_sidebarSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'SIGNED IN AS ADMIN'**
  String get admin2_sidebarSignedInAs;

  /// No description provided for @admin2_loginEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password.'**
  String get admin2_loginEmailPassword;

  /// No description provided for @admin2_loginEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get admin2_loginEnterCode;

  /// No description provided for @admin2_loginSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get admin2_loginSignedIn;

  /// No description provided for @admin2_loginFormTitle.
  ///
  /// In en, this message translates to:
  /// **'RentalHub Admin'**
  String get admin2_loginFormTitle;

  /// No description provided for @admin2_loginFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your admin account.'**
  String get admin2_loginFormSubtitle;

  /// No description provided for @admin2_loginFormEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get admin2_loginFormEmail;

  /// No description provided for @admin2_loginFormPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get admin2_loginFormPassword;

  /// No description provided for @admin2_loginFormSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get admin2_loginFormSigningIn;

  /// No description provided for @admin2_loginFormSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get admin2_loginFormSignIn;

  /// No description provided for @admin2_loginNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'Not an admin account'**
  String get admin2_loginNotAdmin;

  /// No description provided for @admin2_loginNoRole.
  ///
  /// In en, this message translates to:
  /// **'This account has no admin role. Sign out and sign in with an admin account, or ask a super admin to grant you one.'**
  String get admin2_loginNoRole;

  /// No description provided for @admin2_loginUseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get admin2_loginUseDifferent;

  /// No description provided for @admin2_totpSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up two-factor authentication'**
  String get admin2_totpSetupTitle;

  /// No description provided for @admin2_totpVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your authenticator code'**
  String get admin2_totpVerifyTitle;

  /// No description provided for @admin2_totpSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with your authenticator app, then enter the 6-digit code it shows to confirm.'**
  String get admin2_totpSetupHint;

  /// No description provided for @admin2_totpEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is on for this account. Enter the 6-digit code from your authenticator app.'**
  String get admin2_totpEnabledHint;

  /// No description provided for @admin2_totpManualKey.
  ///
  /// In en, this message translates to:
  /// **'Manual setup key: {key}'**
  String admin2_totpManualKey(String key);

  /// No description provided for @admin2_totpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get admin2_totpCodeLabel;

  /// No description provided for @admin2_totpChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get admin2_totpChecking;

  /// No description provided for @admin2_totpConfirmSetup.
  ///
  /// In en, this message translates to:
  /// **'Confirm and finish setup'**
  String get admin2_totpConfirmSetup;

  /// No description provided for @admin2_totpVerifySignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify and sign in'**
  String get admin2_totpVerifySignIn;

  /// No description provided for @admin2_subscriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plans, trials and platform revenue'**
  String get admin2_subscriptionsSubtitle;

  /// No description provided for @admin2_subscriptionsBody.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions arrive in Phase F, gated on the Play Console setup (plan D1).'**
  String get admin2_subscriptionsBody;

  /// No description provided for @admin2_dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The platform at a glance, counted live'**
  String get admin2_dashboardSubtitle;

  /// No description provided for @admin2_dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the dashboard.'**
  String get admin2_dashboardLoadFailed;

  /// No description provided for @admin2_dashboardDisputesTitle.
  ///
  /// In en, this message translates to:
  /// **'Open disputes need a decision'**
  String get admin2_dashboardDisputesTitle;

  /// No description provided for @admin2_dashboardOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String admin2_dashboardOpenCount(Object count);

  /// No description provided for @admin2_dashboardDisputesHint.
  ///
  /// In en, this message translates to:
  /// **'Open the disputes centre to decide them.'**
  String get admin2_dashboardDisputesHint;

  /// No description provided for @admin2_dashboardTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Support tickets waiting'**
  String get admin2_dashboardTicketsTitle;

  /// No description provided for @admin2_dashboardTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Open the tickets inbox to reply.'**
  String get admin2_dashboardTicketsHint;

  /// No description provided for @admin2_dashboardKpiShops.
  ///
  /// In en, this message translates to:
  /// **'Registered shops'**
  String get admin2_dashboardKpiShops;

  /// No description provided for @admin2_dashboardKpiLiveCount.
  ///
  /// In en, this message translates to:
  /// **'Live count'**
  String get admin2_dashboardKpiLiveCount;

  /// No description provided for @admin2_dashboardKpiBookings.
  ///
  /// In en, this message translates to:
  /// **'Active bookings'**
  String get admin2_dashboardKpiBookings;

  /// No description provided for @admin2_dashboardKpiBookingsNote.
  ///
  /// In en, this message translates to:
  /// **'Approved, paid or active'**
  String get admin2_dashboardKpiBookingsNote;

  /// No description provided for @admin2_dashboardKpiDisputes.
  ///
  /// In en, this message translates to:
  /// **'Open disputes'**
  String get admin2_dashboardKpiDisputes;

  /// No description provided for @admin2_dashboardKpiDisputesNote.
  ///
  /// In en, this message translates to:
  /// **'Awaiting a decision'**
  String get admin2_dashboardKpiDisputesNote;

  /// No description provided for @admin2_dashboardKpiTickets.
  ///
  /// In en, this message translates to:
  /// **'Open support tickets'**
  String get admin2_dashboardKpiTickets;

  /// No description provided for @admin2_dashboardKpiTicketsNote.
  ///
  /// In en, this message translates to:
  /// **'Awaiting a reply'**
  String get admin2_dashboardKpiTicketsNote;

  /// No description provided for @admin2_shopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every showroom on the platform'**
  String get admin2_shopsSubtitle;

  /// No description provided for @admin2_shopsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by shop, city, or owner…'**
  String get admin2_shopsSearchHint;

  /// No description provided for @admin2_shopsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the shops.'**
  String get admin2_shopsLoadFailed;

  /// No description provided for @admin2_shopsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shops match'**
  String get admin2_shopsEmptyTitle;

  /// No description provided for @admin2_shopsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The list reads the shops collection.'**
  String get admin2_shopsEmptyHint;

  /// No description provided for @admin2_shopsPlanLine.
  ///
  /// In en, this message translates to:
  /// **'Plan {plan}'**
  String admin2_shopsPlanLine(String plan);

  /// No description provided for @admin2_approvalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Approvals'**
  String get admin2_approvalsTitle;

  /// No description provided for @admin2_approvalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applications waiting for a decision'**
  String get admin2_approvalsSubtitle;

  /// No description provided for @admin2_approvalsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the shop approvals.'**
  String get admin2_approvalsLoadFailed;

  /// No description provided for @admin2_approvalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending applications'**
  String get admin2_approvalsEmptyTitle;

  /// No description provided for @admin2_approvalsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Every shop has been decided.'**
  String get admin2_approvalsEmptyHint;

  /// No description provided for @admin2_approvalsChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist {done}/6'**
  String admin2_approvalsChecklist(Object done);

  /// No description provided for @admin2_shopDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop detail'**
  String get admin2_shopDetailTitle;

  /// No description provided for @admin2_shopDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan, fleet, bookings and admin actions'**
  String get admin2_shopDetailSubtitle;

  /// No description provided for @admin2_shopDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this shop.'**
  String get admin2_shopDetailLoadFailed;

  /// No description provided for @admin2_shopDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Shop not found.'**
  String get admin2_shopDetailNotFound;

  /// No description provided for @admin2_shopDetailSuspended.
  ///
  /// In en, this message translates to:
  /// **'Shop suspended.'**
  String get admin2_shopDetailSuspended;

  /// No description provided for @admin2_shopDetailSuspensionLifted.
  ///
  /// In en, this message translates to:
  /// **'Suspension lifted.'**
  String get admin2_shopDetailSuspensionLifted;

  /// No description provided for @admin2_shopDetailPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get admin2_shopDetailPlan;

  /// No description provided for @admin2_shopDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get admin2_shopDetailStatus;

  /// No description provided for @admin2_shopDetailLifetimeBookings.
  ///
  /// In en, this message translates to:
  /// **'Lifetime bookings'**
  String get admin2_shopDetailLifetimeBookings;

  /// No description provided for @admin2_shopDetailRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get admin2_shopDetailRating;

  /// No description provided for @admin2_shopDetailSuspensionReason.
  ///
  /// In en, this message translates to:
  /// **'Suspension reason: {reason}'**
  String admin2_shopDetailSuspensionReason(String reason);

  /// No description provided for @admin2_shopDetailKycDocs.
  ///
  /// In en, this message translates to:
  /// **'KYC documents'**
  String get admin2_shopDetailKycDocs;

  /// No description provided for @admin2_shopDetailNoneUploaded.
  ///
  /// In en, this message translates to:
  /// **'None uploaded yet.'**
  String get admin2_shopDetailNoneUploaded;

  /// No description provided for @admin2_shopDetailBankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank / wallet accounts'**
  String get admin2_shopDetailBankAccounts;

  /// No description provided for @admin2_shopDetailNoneOnFile.
  ///
  /// In en, this message translates to:
  /// **'None on file.'**
  String get admin2_shopDetailNoneOnFile;

  /// No description provided for @admin2_shopDetailContact.
  ///
  /// In en, this message translates to:
  /// **'{city} • {address}\nOwner: {owner} • {phone}'**
  String admin2_shopDetailContact(
      String city, String address, String owner, String phone);

  /// No description provided for @admin2_suspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this shop?'**
  String get admin2_suspendTitle;

  /// No description provided for @admin2_suspendLiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Lift the suspension?'**
  String get admin2_suspendLiftTitle;

  /// No description provided for @admin2_customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every customer on the platform'**
  String get admin2_customersSubtitle;

  /// No description provided for @admin2_customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, or CNIC…'**
  String get admin2_customersSearchHint;

  /// No description provided for @admin2_customersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the customers.'**
  String get admin2_customersLoadFailed;

  /// No description provided for @admin2_customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers match'**
  String get admin2_customersEmptyTitle;

  /// No description provided for @admin2_customersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The list reads the customers collection.'**
  String get admin2_customersEmptyHint;

  /// No description provided for @admin2_customerDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer detail'**
  String get admin2_customerDetailTitle;

  /// No description provided for @admin2_customerDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trust score, KYC, trips and admin actions'**
  String get admin2_customerDetailSubtitle;

  /// No description provided for @admin2_customerDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this customer.'**
  String get admin2_customerDetailLoadFailed;

  /// No description provided for @admin2_customerDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found.'**
  String get admin2_customerDetailNotFound;

  /// No description provided for @admin2_customerDetailNoCnic.
  ///
  /// In en, this message translates to:
  /// **'No CNIC on file — a blacklist entry needs one.'**
  String get admin2_customerDetailNoCnic;

  /// No description provided for @admin2_customerDetailAdminReport.
  ///
  /// In en, this message translates to:
  /// **'Admin report'**
  String get admin2_customerDetailAdminReport;

  /// No description provided for @admin2_customerDetailAdminReportNote.
  ///
  /// In en, this message translates to:
  /// **'Reported by an admin from the customer detail screen.'**
  String get admin2_customerDetailAdminReportNote;

  /// No description provided for @admin2_customerDetailReported.
  ///
  /// In en, this message translates to:
  /// **'Customer reported to the blacklist.'**
  String get admin2_customerDetailReported;

  /// No description provided for @admin2_customerDetailBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Blacklisted'**
  String get admin2_customerDetailBlacklisted;

  /// No description provided for @admin2_customerDetailBookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get admin2_customerDetailBookingHistory;

  /// No description provided for @admin2_customerDetailNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet.'**
  String get admin2_customerDetailNoBookings;

  /// No description provided for @admin2_customerDetailGuarantors.
  ///
  /// In en, this message translates to:
  /// **'Guarantors'**
  String get admin2_customerDetailGuarantors;

  /// No description provided for @admin2_customerDetailAdminNotes.
  ///
  /// In en, this message translates to:
  /// **'Admin notes'**
  String get admin2_customerDetailAdminNotes;

  /// No description provided for @admin2_customerDetailNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get admin2_customerDetailNoNotes;

  /// No description provided for @admin2_customerDetailWatchlistAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added to the watchlist.'**
  String get admin2_customerDetailWatchlistAdded;

  /// No description provided for @admin2_customerDetailContact.
  ///
  /// In en, this message translates to:
  /// **'{phone} • CNIC {cnic} • Source: {source}'**
  String admin2_customerDetailContact(String phone, String cnic, String source);

  /// No description provided for @admin2_tribunalTitle.
  ///
  /// In en, this message translates to:
  /// **'Blacklist tribunal'**
  String get admin2_tribunalTitle;

  /// No description provided for @admin2_tribunalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'National Rental Fraud & Blacklist Tribunal'**
  String get admin2_tribunalSubtitle;

  /// No description provided for @admin2_tribunalSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Central arbitration bench for inter-showroom disputes'**
  String get admin2_tribunalSubtitle2;

  /// No description provided for @admin2_tribunalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the blacklist cases.'**
  String get admin2_tribunalLoadFailed;

  /// No description provided for @admin2_tribunalEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No blacklist cases'**
  String get admin2_tribunalEmptyTitle;

  /// No description provided for @admin2_tribunalEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tribunal records will appear here.'**
  String get admin2_tribunalEmptyHint;

  /// No description provided for @admin2_tribunalActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE BLACKLIST'**
  String get admin2_tribunalActive;

  /// No description provided for @admin2_tribunalReversed.
  ///
  /// In en, this message translates to:
  /// **'REVERSED / CLEARED'**
  String get admin2_tribunalReversed;

  /// No description provided for @admin2_tribunalCaseLine.
  ///
  /// In en, this message translates to:
  /// **'{id} • CNIC: {cnic}'**
  String admin2_tribunalCaseLine(String id, String cnic);

  /// No description provided for @admin2_tribunalReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String admin2_tribunalReason(String reason);

  /// No description provided for @admin2_tribunalReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by Showroom: {shop}'**
  String admin2_tribunalReportedBy(String shop);

  /// No description provided for @admin2_tribunalReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal Justification: {reason}'**
  String admin2_tribunalReversal(String reason);

  /// No description provided for @admin2_tribunalDecideAppeal.
  ///
  /// In en, this message translates to:
  /// **'Decide appeal — Keep or Remove'**
  String get admin2_tribunalDecideAppeal;

  /// No description provided for @admin2_tribunalAppealLine.
  ///
  /// In en, this message translates to:
  /// **'Appeal: {status} — {reason}'**
  String admin2_tribunalAppealLine(String status, String reason);

  /// No description provided for @admin2_disputesTitle.
  ///
  /// In en, this message translates to:
  /// **'Disputes centre'**
  String get admin2_disputesTitle;

  /// No description provided for @admin2_disputesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Third side of every dispute — 72 h SLA'**
  String get admin2_disputesSubtitle;

  /// No description provided for @admin2_disputesSlaUnknown.
  ///
  /// In en, this message translates to:
  /// **'SLA unknown'**
  String get admin2_disputesSlaUnknown;

  /// No description provided for @admin2_disputesSlaOverdue.
  ///
  /// In en, this message translates to:
  /// **'SLA overdue by {hours}h'**
  String admin2_disputesSlaOverdue(Object hours);

  /// No description provided for @admin2_disputesSlaLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h of SLA left'**
  String admin2_disputesSlaLeft(Object hours);

  /// No description provided for @admin2_disputesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the disputes.'**
  String get admin2_disputesLoadFailed;

  /// No description provided for @admin2_disputesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No disputes'**
  String get admin2_disputesEmptyTitle;

  /// No description provided for @admin2_disputesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The centre reads the disputes collection.'**
  String get admin2_disputesEmptyHint;

  /// No description provided for @admin2_reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews moderation'**
  String get admin2_reviewsTitle;

  /// No description provided for @admin2_reviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Abusive, fake and revenge queues'**
  String get admin2_reviewsSubtitle;

  /// No description provided for @admin2_reviewsFilterAbusive.
  ///
  /// In en, this message translates to:
  /// **'Abusive'**
  String get admin2_reviewsFilterAbusive;

  /// No description provided for @admin2_reviewsFilterFake.
  ///
  /// In en, this message translates to:
  /// **'Fake'**
  String get admin2_reviewsFilterFake;

  /// No description provided for @admin2_reviewsReasonFake.
  ///
  /// In en, this message translates to:
  /// **'Fake review'**
  String get admin2_reviewsReasonFake;

  /// No description provided for @admin2_reviewsFilterRevenge.
  ///
  /// In en, this message translates to:
  /// **'Revenge'**
  String get admin2_reviewsFilterRevenge;

  /// No description provided for @admin2_reviewsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get admin2_reviewsFilterClear;

  /// No description provided for @admin2_reviewsMarkAs.
  ///
  /// In en, this message translates to:
  /// **'Mark as {status}?'**
  String admin2_reviewsMarkAs(String status);

  /// No description provided for @admin2_reviewsReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (stored with the decision)'**
  String get admin2_reviewsReasonLabel;

  /// No description provided for @admin2_reviewsMarked.
  ///
  /// In en, this message translates to:
  /// **'Review marked as {status}.'**
  String admin2_reviewsMarked(String status);

  /// No description provided for @admin2_reviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the reviews.'**
  String get admin2_reviewsLoadFailed;

  /// No description provided for @admin2_reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews in this queue.'**
  String get admin2_reviewsEmpty;

  /// No description provided for @admin2_reviewKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get admin2_reviewKeep;

  /// No description provided for @admin2_reviewHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get admin2_reviewHide;

  /// No description provided for @admin2_reviewAskToEdit.
  ///
  /// In en, this message translates to:
  /// **'Ask to edit'**
  String get admin2_reviewAskToEdit;

  /// No description provided for @admin2_reviewWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get admin2_reviewWarn;

  /// No description provided for @admin2_reviewModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation: {status}'**
  String admin2_reviewModeration(String status);

  /// No description provided for @admin2_reviewCardRatings.
  ///
  /// In en, this message translates to:
  /// **'Shop {shop}/5 • Car {car}/5 • Owner: punctuality {punctuality}, care {care}, behaviour {behaviour}'**
  String admin2_reviewCardRatings(String shop, String car, String punctuality,
      String care, String behaviour);

  /// No description provided for @admin2_ticketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Support tickets'**
  String get admin2_ticketsTitle;

  /// No description provided for @admin2_ticketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The inbox the customer plan promised'**
  String get admin2_ticketsSubtitle;

  /// No description provided for @admin2_ticketsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the tickets.'**
  String get admin2_ticketsLoadFailed;

  /// No description provided for @admin2_ticketsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tickets'**
  String get admin2_ticketsEmptyTitle;

  /// No description provided for @admin2_ticketsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The inbox reads the support_tickets collection.'**
  String get admin2_ticketsEmptyHint;

  /// No description provided for @admin2_slaUnknownDate.
  ///
  /// In en, this message translates to:
  /// **'SLA: filed date unknown'**
  String get admin2_slaUnknownDate;

  /// No description provided for @admin2_slaBreached.
  ///
  /// In en, this message translates to:
  /// **'SLA breached by {hours}h'**
  String admin2_slaBreached(Object hours);

  /// No description provided for @admin2_slaLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h of {total}h SLA left'**
  String admin2_slaLeft(Object hours, Object total);

  /// No description provided for @admin2_ticketQuickReply1.
  ///
  /// In en, this message translates to:
  /// **'Thanks for reaching out — we are looking into this and will update you here.'**
  String get admin2_ticketQuickReply1;

  /// No description provided for @admin2_ticketQuickReply2.
  ///
  /// In en, this message translates to:
  /// **'Could you share the booking ID and a photo of the issue?'**
  String get admin2_ticketQuickReply2;

  /// No description provided for @admin2_ticketQuickReply3.
  ///
  /// In en, this message translates to:
  /// **'This has been resolved. Please let us know if it comes back.'**
  String get admin2_ticketQuickReply3;

  /// No description provided for @admin2_ticketStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Ticket {status}.'**
  String admin2_ticketStatusDone(String status);

  /// No description provided for @admin2_ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket {id}'**
  String admin2_ticketTitle(String id);

  /// No description provided for @admin2_ticketOpenCustomer.
  ///
  /// In en, this message translates to:
  /// **'Open the customer'**
  String get admin2_ticketOpenCustomer;

  /// No description provided for @admin2_ticketReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get admin2_ticketReplies;

  /// No description provided for @admin2_ticketNoReplies.
  ///
  /// In en, this message translates to:
  /// **'No replies yet.'**
  String get admin2_ticketNoReplies;

  /// No description provided for @admin2_ticketQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get admin2_ticketQuickReplies;

  /// No description provided for @admin2_ticketReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply to the customer…'**
  String get admin2_ticketReplyHint;

  /// No description provided for @admin2_ticketSendReply.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get admin2_ticketSendReply;

  /// No description provided for @admin2_ticketInternalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal notes (the customer never sees these)'**
  String get admin2_ticketInternalNotes;

  /// No description provided for @admin2_ticketAddNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add an internal note…'**
  String get admin2_ticketAddNoteHint;

  /// No description provided for @admin2_ticketAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get admin2_ticketAdd;

  /// No description provided for @admin2_ticketEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get admin2_ticketEscalate;

  /// No description provided for @admin2_ticketClose.
  ///
  /// In en, this message translates to:
  /// **'Close ticket'**
  String get admin2_ticketClose;

  /// No description provided for @admin2_anncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcasts to owners and customers'**
  String get admin2_anncSubtitle;

  /// No description provided for @admin2_anncNew.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get admin2_anncNew;

  /// No description provided for @admin2_anncLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the announcements.'**
  String get admin2_anncLoadFailed;

  /// No description provided for @admin2_anncEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get admin2_anncEmptyTitle;

  /// No description provided for @admin2_anncEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create the first one above.'**
  String get admin2_anncEmptyHint;

  /// No description provided for @admin2_anncSent.
  ///
  /// In en, this message translates to:
  /// **'Sent.'**
  String get admin2_anncSent;

  /// No description provided for @admin2_anncSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Functions server — try again.'**
  String get admin2_anncSendFailed;

  /// No description provided for @admin2_anncSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test'**
  String get admin2_anncSendTest;

  /// No description provided for @admin2_anncSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get admin2_anncSendNow;

  /// No description provided for @admin2_anncStats.
  ///
  /// In en, this message translates to:
  /// **'Sent {sent} • Delivered {delivered} • Opened {opened}'**
  String admin2_anncStats(Object sent, Object delivered, Object opened);

  /// No description provided for @admin2_anncFormEnRequired.
  ///
  /// In en, this message translates to:
  /// **'The English title and body are required.'**
  String get admin2_anncFormEnRequired;

  /// No description provided for @admin2_anncFormUrRequired.
  ///
  /// In en, this message translates to:
  /// **'The Urdu title and body are required too (rulebook §5.5).'**
  String get admin2_anncFormUrRequired;

  /// No description provided for @admin2_anncFormSaved.
  ///
  /// In en, this message translates to:
  /// **'Announcement saved.'**
  String get admin2_anncFormSaved;

  /// No description provided for @admin2_anncFormTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get admin2_anncFormTitleEn;

  /// No description provided for @admin2_anncFormTitleUr.
  ///
  /// In en, this message translates to:
  /// **'Title (Urdu)'**
  String get admin2_anncFormTitleUr;

  /// No description provided for @admin2_anncFormBodyEn.
  ///
  /// In en, this message translates to:
  /// **'Body (English)'**
  String get admin2_anncFormBodyEn;

  /// No description provided for @admin2_anncFormBodyUr.
  ///
  /// In en, this message translates to:
  /// **'Body (Urdu)'**
  String get admin2_anncFormBodyUr;

  /// No description provided for @admin2_anncFormAudienceRole.
  ///
  /// In en, this message translates to:
  /// **'Audience — role'**
  String get admin2_anncFormAudienceRole;

  /// No description provided for @admin2_anncFormEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get admin2_anncFormEveryone;

  /// No description provided for @admin2_anncFormOwners.
  ///
  /// In en, this message translates to:
  /// **'Owners'**
  String get admin2_anncFormOwners;

  /// No description provided for @admin2_anncFormCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get admin2_anncFormCustomers;

  /// No description provided for @admin2_anncFormAudienceCity.
  ///
  /// In en, this message translates to:
  /// **'Audience — city'**
  String get admin2_anncFormAudienceCity;

  /// No description provided for @admin2_anncFormAllCities.
  ///
  /// In en, this message translates to:
  /// **'All cities'**
  String get admin2_anncFormAllCities;

  /// No description provided for @admin2_anncFormAudiencePlan.
  ///
  /// In en, this message translates to:
  /// **'Audience — plan'**
  String get admin2_anncFormAudiencePlan;

  /// No description provided for @admin2_anncFormAllPlans.
  ///
  /// In en, this message translates to:
  /// **'All plans'**
  String get admin2_anncFormAllPlans;

  /// No description provided for @admin2_anncFormFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get admin2_anncFormFree;

  /// No description provided for @admin2_anncFormPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get admin2_anncFormPro;

  /// No description provided for @admin2_anncFormBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get admin2_anncFormBusiness;

  /// No description provided for @admin2_anncFormChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get admin2_anncFormChannel;

  /// No description provided for @admin2_anncFormPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get admin2_anncFormPush;

  /// No description provided for @admin2_anncFormWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp (waits for the Meta token, D2)'**
  String get admin2_anncFormWhatsapp;

  /// No description provided for @admin2_anncFormBoth.
  ///
  /// In en, this message translates to:
  /// **'Push + WhatsApp'**
  String get admin2_anncFormBoth;

  /// No description provided for @admin2_anncFormSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get admin2_anncFormSchedule;

  /// No description provided for @admin2_anncFormPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time'**
  String get admin2_anncFormPickDate;

  /// No description provided for @admin2_anncFormScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {when}'**
  String admin2_anncFormScheduled(String when);

  /// No description provided for @admin2_anncFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save announcement'**
  String get admin2_anncFormSave;

  /// No description provided for @admin2_activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every admin action, newest first — immutable'**
  String get admin2_activitySubtitle;

  /// No description provided for @admin2_activityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the activity log.'**
  String get admin2_activityLoadFailed;

  /// No description provided for @admin2_activityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No audit entries yet'**
  String get admin2_activityEmptyTitle;

  /// No description provided for @admin2_activityEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Admin actions will appear here as they happen.'**
  String get admin2_activityEmptyHint;

  /// No description provided for @admin2_activitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by action, admin, or target…'**
  String get admin2_activitySearchHint;

  /// No description provided for @admin2_activityExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get admin2_activityExportCsv;

  /// No description provided for @admin2_activityCsvFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the CSV file.'**
  String get admin2_activityCsvFailed;

  /// No description provided for @admin2_teamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who can run the platform, and with what role'**
  String get admin2_teamSubtitle;

  /// No description provided for @admin2_teamLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the admin team.'**
  String get admin2_teamLoadFailed;

  /// No description provided for @admin2_teamViewOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a super admin can invite, reset two-factor authentication, or revoke a role. You can view the team.'**
  String get admin2_teamViewOnly;

  /// No description provided for @admin2_teamEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get admin2_teamEmailInvalid;

  /// No description provided for @admin2_teamInviteLog.
  ///
  /// In en, this message translates to:
  /// **'Invited {email} as {role} (48 h expiry).'**
  String admin2_teamInviteLog(String email, String role);

  /// No description provided for @admin2_teamInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {email}.'**
  String admin2_teamInviteSent(String email);

  /// No description provided for @admin2_teamInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the invite.'**
  String get admin2_teamInviteFailed;

  /// No description provided for @admin2_teamActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete that action.'**
  String get admin2_teamActionFailed;

  /// No description provided for @admin2_teamResetTotpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset two-factor authentication?'**
  String get admin2_teamResetTotpTitle;

  /// No description provided for @admin2_teamResetTotpBody.
  ///
  /// In en, this message translates to:
  /// **'{email} will have to enrol TOTP again on their next login.'**
  String admin2_teamResetTotpBody(String email);

  /// No description provided for @admin2_teamTotpResetLog.
  ///
  /// In en, this message translates to:
  /// **'TOTP reset for {email}.'**
  String admin2_teamTotpResetLog(String email);

  /// No description provided for @admin2_teamRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this admin role?'**
  String get admin2_teamRevokeTitle;

  /// No description provided for @admin2_teamRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'{email} will lose admin access and become a customer account.'**
  String admin2_teamRevokeBody(String email);

  /// No description provided for @admin2_teamWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this invite?'**
  String get admin2_teamWithdrawTitle;

  /// No description provided for @admin2_teamWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'{email} will no longer be able to accept it.'**
  String admin2_teamWithdrawBody(String email);

  /// No description provided for @admin2_teamInviteWithdrawnLog.
  ///
  /// In en, this message translates to:
  /// **'Invite withdrawn for {email}.'**
  String admin2_teamInviteWithdrawnLog(String email);

  /// No description provided for @admin2_teamInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Invite an admin'**
  String get admin2_teamInviteButton;

  /// No description provided for @admin2_teamInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending invites'**
  String get admin2_teamInvitesTitle;

  /// No description provided for @admin2_teamInvitesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending invites.'**
  String get admin2_teamInvitesEmpty;

  /// No description provided for @admin2_teamMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get admin2_teamMembersTitle;

  /// No description provided for @admin2_teamMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No admins found — the team list reads the users who hold an admin role.'**
  String get admin2_teamMembersEmpty;

  /// No description provided for @admin2_teamInviteEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get admin2_teamInviteEmail;

  /// No description provided for @admin2_teamInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Invites expire after 48 hours. The invitee creates their account first, then a super admin grants the role.'**
  String get admin2_teamInviteHint;

  /// No description provided for @admin2_teamInviteSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get admin2_teamInviteSending;

  /// No description provided for @admin2_teamInviteSend.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get admin2_teamInviteSend;

  /// No description provided for @admin2_teamInviteWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get admin2_teamInviteWithdraw;

  /// No description provided for @admin2_team2faOn.
  ///
  /// In en, this message translates to:
  /// **'2FA on'**
  String get admin2_team2faOn;

  /// No description provided for @admin2_team2faOff.
  ///
  /// In en, this message translates to:
  /// **'2FA off'**
  String get admin2_team2faOff;

  /// No description provided for @admin2_teamReset2fa.
  ///
  /// In en, this message translates to:
  /// **'Reset 2FA'**
  String get admin2_teamReset2fa;

  /// No description provided for @admin2_teamRevokeRole.
  ///
  /// In en, this message translates to:
  /// **'Revoke role'**
  String get admin2_teamRevokeRole;

  /// No description provided for @admin2_teamResetTotpMenu.
  ///
  /// In en, this message translates to:
  /// **'Reset two-factor authentication'**
  String get admin2_teamResetTotpMenu;

  /// No description provided for @admin2_teamRevokeMenu.
  ///
  /// In en, this message translates to:
  /// **'Revoke admin role'**
  String get admin2_teamRevokeMenu;

  /// No description provided for @admin2_settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cities & settings'**
  String get admin2_settingsTitle;

  /// No description provided for @admin2_settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The platform defaults, in one document'**
  String get admin2_settingsSubtitle;

  /// No description provided for @admin2_settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the platform settings.'**
  String get admin2_settingsLoadFailed;

  /// No description provided for @admin2_settingsNumbersInvalid.
  ///
  /// In en, this message translates to:
  /// **'Advance %, deposit and late grace must be numbers.'**
  String get admin2_settingsNumbersInvalid;

  /// No description provided for @admin2_settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Platform settings saved.'**
  String get admin2_settingsSaved;

  /// No description provided for @admin2_settingsCities.
  ///
  /// In en, this message translates to:
  /// **'Live cities (comma-separated)'**
  String get admin2_settingsCities;

  /// No description provided for @admin2_settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Car categories (comma-separated)'**
  String get admin2_settingsCategories;

  /// No description provided for @admin2_settingsAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance %'**
  String get admin2_settingsAdvance;

  /// No description provided for @admin2_settingsDeposit.
  ///
  /// In en, this message translates to:
  /// **'Default deposit (Rs.)'**
  String get admin2_settingsDeposit;

  /// No description provided for @admin2_settingsGrace.
  ///
  /// In en, this message translates to:
  /// **'Late grace (minutes)'**
  String get admin2_settingsGrace;

  /// No description provided for @admin2_settingsSupportHours.
  ///
  /// In en, this message translates to:
  /// **'Support hours'**
  String get admin2_settingsSupportHours;

  /// No description provided for @admin2_settingsAgreementTerms.
  ///
  /// In en, this message translates to:
  /// **'Default agreement terms'**
  String get admin2_settingsAgreementTerms;

  /// No description provided for @admin2_settingsMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get admin2_settingsMaintenance;

  /// No description provided for @admin2_settingsMaintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'When on, the app shows a maintenance notice at startup.'**
  String get admin2_settingsMaintenanceHint;

  /// No description provided for @admin2_settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get admin2_settingsSave;

  /// No description provided for @admin2_shopAppReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required — the owner sees it.'**
  String get admin2_shopAppReasonRequired;

  /// No description provided for @admin2_shopAppChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist — {done} of 6 complete'**
  String admin2_shopAppChecklist(Object done);

  /// No description provided for @admin2_shopAppKycDocs.
  ///
  /// In en, this message translates to:
  /// **'KYC documents on file'**
  String get admin2_shopAppKycDocs;

  /// No description provided for @admin2_shopAppFleetPhotos.
  ///
  /// In en, this message translates to:
  /// **'Fleet photos'**
  String get admin2_shopAppFleetPhotos;

  /// No description provided for @admin2_shopAppReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required to ask for more info or reject — the owner sees it)'**
  String get admin2_shopAppReasonLabel;

  /// No description provided for @admin2_shopAppCallOwner.
  ///
  /// In en, this message translates to:
  /// **'Call owner'**
  String get admin2_shopAppCallOwner;

  /// No description provided for @admin2_shopAppAskInfo.
  ///
  /// In en, this message translates to:
  /// **'Ask for more info'**
  String get admin2_shopAppAskInfo;

  /// No description provided for @admin2_shopAppOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner: {owner} • {phone} • CNIC {cnic}'**
  String admin2_shopAppOwner(String owner, String phone, String cnic);

  /// No description provided for @admin2_shopActionMessageOwner.
  ///
  /// In en, this message translates to:
  /// **'Message owner'**
  String get admin2_shopActionMessageOwner;

  /// No description provided for @admin2_shopActionHello.
  ///
  /// In en, this message translates to:
  /// **'Hello from RentalHub admin regarding {shop}.'**
  String admin2_shopActionHello(String shop);

  /// No description provided for @admin2_shopActionNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number on file for this shop.'**
  String get admin2_shopActionNoPhone;

  /// No description provided for @admin2_shopActionLift.
  ///
  /// In en, this message translates to:
  /// **'Lift suspension'**
  String get admin2_shopActionLift;

  /// No description provided for @admin2_shopActionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend shop'**
  String get admin2_shopActionSuspend;

  /// No description provided for @admin2_custActionAddNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add an admin note…'**
  String get admin2_custActionAddNoteHint;

  /// No description provided for @admin2_custActionAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get admin2_custActionAddNote;

  /// No description provided for @admin2_custActionBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Report to blacklist'**
  String get admin2_custActionBlacklist;

  /// No description provided for @admin2_trustTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust score'**
  String get admin2_trustTitle;

  /// No description provided for @admin2_trustKycLine.
  ///
  /// In en, this message translates to:
  /// **'KYC: {status} • {trips} completed trip(s) • '**
  String admin2_trustKycLine(String status, Object trips);

  /// No description provided for @admin2_trustOwnerRating.
  ///
  /// In en, this message translates to:
  /// **'Owner rating: {rating}'**
  String admin2_trustOwnerRating(String rating);

  /// No description provided for @admin2_trustBase.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get admin2_trustBase;

  /// No description provided for @admin2_trustTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get admin2_trustTrips;

  /// No description provided for @admin2_trustRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get admin2_trustRatings;

  /// No description provided for @admin2_trustPunctuality.
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get admin2_trustPunctuality;

  /// No description provided for @admin2_trustConduct.
  ///
  /// In en, this message translates to:
  /// **'Conduct'**
  String get admin2_trustConduct;

  /// No description provided for @admin2_fleetPhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'View photo full screen'**
  String get admin2_fleetPhotoTooltip;

  /// No description provided for @admin2_fleetPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo could not be loaded.'**
  String get admin2_fleetPhotoFailed;

  /// No description provided for @admin2_disputeSlaBreached.
  ///
  /// In en, this message translates to:
  /// **'SLA breached by {hours}h — decide now'**
  String admin2_disputeSlaBreached(Object hours);

  /// No description provided for @admin2_disputeSlaLeft.
  ///
  /// In en, this message translates to:
  /// **'SLA: {hours}h left of 72h'**
  String admin2_disputeSlaLeft(Object hours);

  /// No description provided for @admin2_disputeAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the decision amount in rupees (0 is allowed).'**
  String get admin2_disputeAmountHint;

  /// No description provided for @admin2_disputeNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'An admin note is required with the decision.'**
  String get admin2_disputeNoteRequired;

  /// No description provided for @admin2_disputeDecided.
  ///
  /// In en, this message translates to:
  /// **'Dispute decided.'**
  String get admin2_disputeDecided;

  /// No description provided for @admin2_disputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute {id}'**
  String admin2_disputeTitle(String id);

  /// No description provided for @admin2_disputeBookingLine.
  ///
  /// In en, this message translates to:
  /// **'Booking {booking} • {status} • {sla}'**
  String admin2_disputeBookingLine(String booking, String status, String sla);

  /// No description provided for @admin2_disputeCustomerStatement.
  ///
  /// In en, this message translates to:
  /// **'Customer statement'**
  String get admin2_disputeCustomerStatement;

  /// No description provided for @admin2_disputeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String admin2_disputeCategory(String category);

  /// No description provided for @admin2_disputeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String admin2_disputeCustomer(String name);

  /// No description provided for @admin2_disputeShopSide.
  ///
  /// In en, this message translates to:
  /// **'Shop side — the booking record'**
  String get admin2_disputeShopSide;

  /// No description provided for @admin2_disputeBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking: {id}'**
  String admin2_disputeBookingLabel(String id);

  /// No description provided for @admin2_disputeShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop: {id}'**
  String admin2_disputeShopLabel(String id);

  /// No description provided for @admin2_disputeNoShopStatement.
  ///
  /// In en, this message translates to:
  /// **'The shop has no written statement on file — the decision uses the booking, handover and deposit records.'**
  String get admin2_disputeNoShopStatement;

  /// No description provided for @admin2_disputeDecisionHeading.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get admin2_disputeDecisionHeading;

  /// No description provided for @admin2_disputeFullCustomer.
  ///
  /// In en, this message translates to:
  /// **'Full refund to customer'**
  String get admin2_disputeFullCustomer;

  /// No description provided for @admin2_disputePartial.
  ///
  /// In en, this message translates to:
  /// **'Partial — split'**
  String get admin2_disputePartial;

  /// No description provided for @admin2_disputeFullOwner.
  ///
  /// In en, this message translates to:
  /// **'Full to owner (claim upheld)'**
  String get admin2_disputeFullOwner;

  /// No description provided for @admin2_disputeAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision amount (Rs.)'**
  String get admin2_disputeAmountLabel;

  /// No description provided for @admin2_disputeNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin note — why this decision (both sides see it)'**
  String get admin2_disputeNoteLabel;

  /// No description provided for @admin2_appealReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required — it is stored with the decision.'**
  String get admin2_appealReasonRequired;

  /// No description provided for @admin2_appealKept.
  ///
  /// In en, this message translates to:
  /// **'Flag kept — appeal denied.'**
  String get admin2_appealKept;

  /// No description provided for @admin2_appealRemoved.
  ///
  /// In en, this message translates to:
  /// **'Flag removed.'**
  String get admin2_appealRemoved;

  /// No description provided for @admin2_appealDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Tribunal Blacklist Appeal'**
  String get admin2_appealDialogTitle;

  /// No description provided for @admin2_appealEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence: {count} file(s) on record'**
  String admin2_appealEvidence(Object count);

  /// No description provided for @admin2_appealDecisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision reason (mandatory):'**
  String get admin2_appealDecisionLabel;

  /// No description provided for @admin2_appealDecisionHint.
  ///
  /// In en, this message translates to:
  /// **'Why is the flag kept or removed?'**
  String get admin2_appealDecisionHint;

  /// No description provided for @admin2_appealKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep flag'**
  String get admin2_appealKeep;

  /// No description provided for @admin2_appealRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove flag'**
  String get admin2_appealRemove;

  /// No description provided for @admin2_bookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every booking on the platform'**
  String get admin2_bookingsSubtitle;

  /// No description provided for @admin2_bookingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by booking, customer, car, or shop…'**
  String get admin2_bookingsSearchHint;

  /// No description provided for @admin2_bookingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the bookings.'**
  String get admin2_bookingsLoadFailed;

  /// No description provided for @admin2_bookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings match'**
  String get admin2_bookingsEmptyTitle;

  /// No description provided for @admin2_bookingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The list reads the bookings collection.'**
  String get admin2_bookingsEmptyHint;

  /// No description provided for @admin2_bookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking detail'**
  String get admin2_bookingDetailTitle;

  /// No description provided for @admin2_bookingDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle, money, handover and messages'**
  String get admin2_bookingDetailSubtitle;

  /// No description provided for @admin2_bookingDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this booking.'**
  String get admin2_bookingDetailLoadFailed;

  /// No description provided for @admin2_bookingDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking not found.'**
  String get admin2_bookingDetailNotFound;

  /// No description provided for @admin2_bookingDetailShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the booking summary.'**
  String get admin2_bookingDetailShareFailed;

  /// No description provided for @admin2_bookingDetailDownloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get admin2_bookingDetailDownloadAll;

  /// No description provided for @admin2_bookingDetailAmounts.
  ///
  /// In en, this message translates to:
  /// **'Amounts'**
  String get admin2_bookingDetailAmounts;

  /// No description provided for @admin2_bookingDetailAdvanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Advance required: {amount}'**
  String admin2_bookingDetailAdvanceRequired(String amount);

  /// No description provided for @admin2_bookingDetailAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance paid: {amount}'**
  String admin2_bookingDetailAdvancePaid(String amount);

  /// No description provided for @admin2_bookingDetailRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance: {amount}'**
  String admin2_bookingDetailRemaining(String amount);

  /// No description provided for @admin2_bookingDetailTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction: {id}'**
  String admin2_bookingDetailTransaction(String id);

  /// No description provided for @admin2_bookingDetailPaymentDeposit.
  ///
  /// In en, this message translates to:
  /// **'Payment & deposit'**
  String get admin2_bookingDetailPaymentDeposit;

  /// No description provided for @admin2_bookingDetailPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Payment proof: {url}'**
  String admin2_bookingDetailPaymentProof(String url);

  /// No description provided for @admin2_bookingDetailNoDeposit.
  ///
  /// In en, this message translates to:
  /// **'No deposit record.'**
  String get admin2_bookingDetailNoDeposit;

  /// No description provided for @admin2_bookingDetailDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit {amount} — {status}'**
  String admin2_bookingDetailDeposit(String amount, String status);

  /// No description provided for @admin2_bookingDetailAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get admin2_bookingDetailAgreement;

  /// No description provided for @admin2_bookingDetailAgreementOnFile.
  ///
  /// In en, this message translates to:
  /// **'Agreement PDF on file — tap to open.'**
  String get admin2_bookingDetailAgreementOnFile;

  /// No description provided for @admin2_bookingDetailNoAgreement.
  ///
  /// In en, this message translates to:
  /// **'No agreement PDF on file.'**
  String get admin2_bookingDetailNoAgreement;

  /// No description provided for @admin2_bookingDetailOpenAgreement.
  ///
  /// In en, this message translates to:
  /// **'Open agreement PDF'**
  String get admin2_bookingDetailOpenAgreement;

  /// No description provided for @admin2_bookingDetailPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the PDF link.'**
  String get admin2_bookingDetailPdfFailed;

  /// No description provided for @admin2_bookingDetailHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover'**
  String get admin2_bookingDetailHandover;

  /// No description provided for @admin2_bookingDetailNoHandover.
  ///
  /// In en, this message translates to:
  /// **'No handover record.'**
  String get admin2_bookingDetailNoHandover;

  /// No description provided for @admin2_bookingDetailOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer at pickup: {km} km'**
  String admin2_bookingDetailOdometer(Object km);

  /// No description provided for @admin2_bookingDetailFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel: {level}'**
  String admin2_bookingDetailFuel(String level);

  /// No description provided for @admin2_bookingDetailDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage notes: {notes}'**
  String admin2_bookingDetailDamage(String notes);

  /// No description provided for @admin2_bookingDetailDispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get admin2_bookingDetailDispute;

  /// No description provided for @admin2_bookingDetailStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String admin2_bookingDetailStatusLine(String status);

  /// No description provided for @admin2_bookingDetailMeta.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} • Trip: {trip} • Package: {package} • {drive}'**
  String admin2_bookingDetailMeta(
      String status, String trip, String package, String drive);

  /// No description provided for @admin2_bookingDetailHandoverSummary.
  ///
  /// In en, this message translates to:
  /// **'odometer {km} km, fuel {fuel}, damage: {damage}'**
  String admin2_bookingDetailHandoverSummary(
      Object km, String fuel, String damage);

  /// No description provided for @admin2_bookingDetailMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages log'**
  String get admin2_bookingDetailMessages;

  /// No description provided for @admin2_bookingDetailNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No notifications recorded for this booking.'**
  String get admin2_bookingDetailNoMessages;

  /// No description provided for @admin2_carsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every vehicle listing, with its review state'**
  String get admin2_carsSubtitle;

  /// No description provided for @admin2_carsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by car or plate number…'**
  String get admin2_carsSearchHint;

  /// No description provided for @admin2_carsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the cars.'**
  String get admin2_carsLoadFailed;

  /// No description provided for @admin2_carsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cars match'**
  String get admin2_carsEmptyTitle;

  /// No description provided for @admin2_carsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The list reads the vehicles collection.'**
  String get admin2_carsEmptyHint;

  /// No description provided for @admin2_carReviewReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required to hide or reject a listing.'**
  String get admin2_carReviewReasonRequired;

  /// No description provided for @admin2_carReviewDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily (24 h)'**
  String get admin2_carReviewDaily;

  /// No description provided for @admin2_carReviewOutCityDaily.
  ///
  /// In en, this message translates to:
  /// **'Out-of-city daily'**
  String get admin2_carReviewOutCityDaily;

  /// No description provided for @admin2_carReviewNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get admin2_carReviewNotSet;

  /// No description provided for @admin2_carReviewWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly rate'**
  String get admin2_carReviewWeekly;

  /// No description provided for @admin2_carReviewDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get admin2_carReviewDeposit;

  /// No description provided for @admin2_carReviewTracker.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get admin2_carReviewTracker;

  /// No description provided for @admin2_carReviewInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance policy'**
  String get admin2_carReviewInsurance;

  /// No description provided for @admin2_carReviewChassis.
  ///
  /// In en, this message translates to:
  /// **'Chassis'**
  String get admin2_carReviewChassis;

  /// No description provided for @admin2_carReviewEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get admin2_carReviewEngine;

  /// No description provided for @admin2_carReviewMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get admin2_carReviewMileage;

  /// No description provided for @admin2_carReviewNotListed.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get admin2_carReviewNotListed;

  /// No description provided for @admin2_carReviewReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required to hide or reject — stored with the decision)'**
  String get admin2_carReviewReasonLabel;

  /// No description provided for @admin2_carReviewSpecs.
  ///
  /// In en, this message translates to:
  /// **'Plate {plate} • {category} • {transmission} • {fuel} • {seats} seats\nStatus: {status} • Current review: {review}'**
  String admin2_carReviewSpecs(
      String plate,
      String category,
      String transmission,
      String fuel,
      Object seats,
      String status,
      String review);

  /// No description provided for @admin2_carReviewLastDecision.
  ///
  /// In en, this message translates to:
  /// **'Last decision: {reason}'**
  String admin2_carReviewLastDecision(String reason);

  /// No description provided for @admin2_reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'KPIs for a date range, with CSV and PDF export'**
  String get admin2_reportsSubtitle;

  /// No description provided for @admin2_reportsFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get admin2_reportsFrom;

  /// No description provided for @admin2_reportsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get admin2_reportsTo;

  /// No description provided for @admin2_reportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the report.'**
  String get admin2_reportsLoadFailed;

  /// No description provided for @admin2_reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data for this range'**
  String get admin2_reportsEmptyTitle;

  /// No description provided for @admin2_reportsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The report reads the live collections.'**
  String get admin2_reportsEmptyHint;

  /// No description provided for @admin2_reportsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Booking revenue'**
  String get admin2_reportsRevenue;

  /// No description provided for @admin2_reportsIncome.
  ///
  /// In en, this message translates to:
  /// **'Finance income'**
  String get admin2_reportsIncome;

  /// No description provided for @admin2_reportsExpense.
  ///
  /// In en, this message translates to:
  /// **'Finance expense'**
  String get admin2_reportsExpense;

  /// No description provided for @admin2_reportsNewCustomers.
  ///
  /// In en, this message translates to:
  /// **'New customers'**
  String get admin2_reportsNewCustomers;

  /// No description provided for @admin2_reportsDisputesOpen.
  ///
  /// In en, this message translates to:
  /// **'Disputes open'**
  String get admin2_reportsDisputesOpen;

  /// No description provided for @admin2_reportsDisputesResolved.
  ///
  /// In en, this message translates to:
  /// **'Disputes resolved'**
  String get admin2_reportsDisputesResolved;

  /// No description provided for @admin2_reportsByCity.
  ///
  /// In en, this message translates to:
  /// **'Bookings by city'**
  String get admin2_reportsByCity;

  /// No description provided for @admin2_reportsNone.
  ///
  /// In en, this message translates to:
  /// **'None in this range.'**
  String get admin2_reportsNone;

  /// No description provided for @admin2_reportsTopShops.
  ///
  /// In en, this message translates to:
  /// **'Top shops'**
  String get admin2_reportsTopShops;

  /// No description provided for @admin2_reportsTopShopsLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count} bookings'**
  String admin2_reportsTopShopsLine(String name, Object count);

  /// No description provided for @admin2_reportsIncomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by category'**
  String get admin2_reportsIncomeByCategory;

  /// No description provided for @admin2_reportsExpenseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense by category'**
  String get admin2_reportsExpenseByCategory;

  /// No description provided for @admin2_slaBreachedMinutes.
  ///
  /// In en, this message translates to:
  /// **'SLA breached by {minutes}m'**
  String admin2_slaBreachedMinutes(Object minutes);

  /// No description provided for @admin2_slaBreachedHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'SLA breached by {hours}h {minutes}m'**
  String admin2_slaBreachedHoursMinutes(Object hours, Object minutes);

  /// No description provided for @admin2_slaLeftMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m of {total}h SLA left'**
  String admin2_slaLeftMinutes(Object minutes, Object total);

  /// No description provided for @adminAuditLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get adminAuditLoadMore;

  /// No description provided for @adminAuditShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {count}'**
  String adminAuditShowing(int count);

  /// No description provided for @adminAuditMatching.
  ///
  /// In en, this message translates to:
  /// **'{count} matching entries'**
  String adminAuditMatching(int count);

  /// No description provided for @adminAuditSearchTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by message or customer ID…'**
  String get adminAuditSearchTicketsHint;

  /// No description provided for @adminAuditCnicAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminAuditCnicAll;

  /// No description provided for @adminAuditCnicOnFile.
  ///
  /// In en, this message translates to:
  /// **'CNIC on file'**
  String get adminAuditCnicOnFile;

  /// No description provided for @adminAuditCnicMissing.
  ///
  /// In en, this message translates to:
  /// **'CNIC missing'**
  String get adminAuditCnicMissing;

  /// No description provided for @adminAuditTrustStored.
  ///
  /// In en, this message translates to:
  /// **'Stored trust {score}'**
  String adminAuditTrustStored(String score);

  /// No description provided for @adminAuditBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Blacklisted'**
  String get adminAuditBlacklisted;

  /// No description provided for @adminAuditWatchlisted.
  ///
  /// In en, this message translates to:
  /// **'Watchlisted'**
  String get adminAuditWatchlisted;

  /// No description provided for @adminAuditFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get adminAuditFilterAction;

  /// No description provided for @adminAuditFilterActor.
  ///
  /// In en, this message translates to:
  /// **'Admin email'**
  String get adminAuditFilterActor;

  /// No description provided for @adminAuditFilterFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get adminAuditFilterFrom;

  /// No description provided for @adminAuditFilterTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get adminAuditFilterTo;

  /// No description provided for @adminAuditClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get adminAuditClearFilters;

  /// No description provided for @adminAuditAllActions.
  ///
  /// In en, this message translates to:
  /// **'All actions'**
  String get adminAuditAllActions;

  /// No description provided for @adminAuditInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'The From date must be on or before the To date.'**
  String get adminAuditInvalidRange;

  /// No description provided for @adminAuditExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get adminAuditExportPdf;

  /// No description provided for @adminAuditPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the PDF file.'**
  String get adminAuditPdfFailed;

  /// No description provided for @adminAuditPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Shops waiting for approval'**
  String get adminAuditPendingApprovals;

  /// No description provided for @adminAuditPendingApprovalsHint.
  ///
  /// In en, this message translates to:
  /// **'Open the approvals queue to decide them.'**
  String get adminAuditPendingApprovalsHint;

  /// No description provided for @adminAuditCredits.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp credits'**
  String get adminAuditCredits;

  /// No description provided for @adminAuditCreditsNone.
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get adminAuditCreditsNone;

  /// No description provided for @adminAuditLinkedShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get adminAuditLinkedShop;

  /// No description provided for @adminAuditLinkedBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get adminAuditLinkedBooking;

  /// No description provided for @adminAuditStoredScore.
  ///
  /// In en, this message translates to:
  /// **'Previously stored: {score} — the live score above is authoritative'**
  String adminAuditStoredScore(String score);

  /// No description provided for @adminAuditKycNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'KYC not submitted'**
  String get adminAuditKycNotSubmitted;

  /// No description provided for @adminAuditKycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC pending review'**
  String get adminAuditKycPending;

  /// No description provided for @adminAuditKycVerified.
  ///
  /// In en, this message translates to:
  /// **'KYC verified'**
  String get adminAuditKycVerified;

  /// No description provided for @adminAuditKycRejected.
  ///
  /// In en, this message translates to:
  /// **'KYC rejected'**
  String get adminAuditKycRejected;

  /// No description provided for @adminAuditFirstMatches.
  ///
  /// In en, this message translates to:
  /// **'First {count} matches'**
  String adminAuditFirstMatches(int count);

  /// No description provided for @admin2_ownerNotListed.
  ///
  /// In en, this message translates to:
  /// **'Owner not listed'**
  String get admin2_ownerNotListed;

  /// No description provided for @admin2_shopRating.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}'**
  String admin2_shopRating(String rating);

  /// No description provided for @admin2_shopDetailAccountType.
  ///
  /// In en, this message translates to:
  /// **'account'**
  String get admin2_shopDetailAccountType;

  /// No description provided for @admin2_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get admin2_loading;

  /// No description provided for @admin2_notOnFile.
  ///
  /// In en, this message translates to:
  /// **'not on file'**
  String get admin2_notOnFile;

  /// No description provided for @admin2_customerDetailWatchlistRemoved.
  ///
  /// In en, this message translates to:
  /// **'Customer removed from the watchlist.'**
  String get admin2_customerDetailWatchlistRemoved;

  /// No description provided for @admin2_disputesDecidedLine.
  ///
  /// In en, this message translates to:
  /// **'Decided: {decision}'**
  String admin2_disputesDecidedLine(String decision);

  /// No description provided for @admin2_disputeSave.
  ///
  /// In en, this message translates to:
  /// **'Save decision'**
  String get admin2_disputeSave;

  /// No description provided for @admin2_teamTotpOffBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} team member(s) have two-factor authentication off.'**
  String admin2_teamTotpOffBanner(Object count);

  /// No description provided for @admin2_teamTotpRemindAll.
  ///
  /// In en, this message translates to:
  /// **'Remind all'**
  String get admin2_teamTotpRemindAll;

  /// No description provided for @admin2_teamTotpReminderSent.
  ///
  /// In en, this message translates to:
  /// **'2FA reminders sent.'**
  String get admin2_teamTotpReminderSent;

  /// No description provided for @admin2_teamTotpReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the reminders.'**
  String get admin2_teamTotpReminderFailed;

  /// No description provided for @admin2_teamInviteSave.
  ///
  /// In en, this message translates to:
  /// **'Save invite'**
  String get admin2_teamInviteSave;

  /// No description provided for @admin2_teamInviteSaved.
  ///
  /// In en, this message translates to:
  /// **'Invite saved for {email}. No email is sent yet — share the accept link from the invite list.'**
  String admin2_teamInviteSaved(String email);

  /// No description provided for @admin2_teamInviteAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get admin2_teamInviteAccept;

  /// No description provided for @admin2_teamInviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy accept link'**
  String get admin2_teamInviteCopyLink;

  /// No description provided for @admin2_teamInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Accept link copied.'**
  String get admin2_teamInviteLinkCopied;

  /// No description provided for @admin2_teamInviteExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get admin2_teamInviteExpired;

  /// No description provided for @admin2_teamInviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String admin2_teamInviteExpires(String date);

  /// No description provided for @admin2_inviteAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept invite'**
  String get admin2_inviteAcceptTitle;

  /// No description provided for @admin2_inviteAcceptSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in as a super admin first.'**
  String get admin2_inviteAcceptSignIn;

  /// No description provided for @admin2_inviteAcceptNotSuper.
  ///
  /// In en, this message translates to:
  /// **'Only a super admin can grant an admin role.'**
  String get admin2_inviteAcceptNotSuper;

  /// No description provided for @admin2_inviteAcceptNoInvite.
  ///
  /// In en, this message translates to:
  /// **'No pending invite matches this link — it may have expired or already been accepted.'**
  String get admin2_inviteAcceptNoInvite;

  /// No description provided for @admin2_inviteAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the invite.'**
  String get admin2_inviteAcceptFailed;

  /// No description provided for @admin2_inviteAcceptGrantFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not grant the role.'**
  String get admin2_inviteAcceptGrantFailed;

  /// No description provided for @admin2_inviteAcceptGranted.
  ///
  /// In en, this message translates to:
  /// **'Role granted.'**
  String get admin2_inviteAcceptGranted;

  /// No description provided for @admin2_inviteAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Grant {role} to {email}?'**
  String admin2_inviteAcceptBody(String email, String role);

  /// No description provided for @admin2_inviteAcceptHint.
  ///
  /// In en, this message translates to:
  /// **'The invitee must already have an account. Granting gives them admin access immediately.'**
  String get admin2_inviteAcceptHint;

  /// No description provided for @admin2_inviteAcceptGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant role'**
  String get admin2_inviteAcceptGrant;

  /// No description provided for @admin2_inviteAcceptGranting.
  ///
  /// In en, this message translates to:
  /// **'Granting…'**
  String get admin2_inviteAcceptGranting;

  /// No description provided for @admin2_inviteAcceptBackToTeam.
  ///
  /// In en, this message translates to:
  /// **'Back to team'**
  String get admin2_inviteAcceptBackToTeam;

  /// No description provided for @admin2_settingsAdvanceRange.
  ///
  /// In en, this message translates to:
  /// **'Advance must be between 0 and 100.'**
  String get admin2_settingsAdvanceRange;

  /// No description provided for @admin2_settingsDepositNegative.
  ///
  /// In en, this message translates to:
  /// **'Deposit cannot be negative.'**
  String get admin2_settingsDepositNegative;

  /// No description provided for @admin2_settingsGraceNegative.
  ///
  /// In en, this message translates to:
  /// **'Late grace cannot be negative.'**
  String get admin2_settingsGraceNegative;

  /// No description provided for @admin2_settingsNoDocument.
  ///
  /// In en, this message translates to:
  /// **'No platform settings saved yet — showing defaults. Save to create them.'**
  String get admin2_settingsNoDocument;

  /// No description provided for @admin2_settingsUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get admin2_settingsUnsavedTitle;

  /// No description provided for @admin2_settingsUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. They will be lost if you leave.'**
  String get admin2_settingsUnsavedBody;

  /// No description provided for @admin2_settingsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Settings have not loaded yet — try again.'**
  String get admin2_settingsNotLoaded;

  /// No description provided for @admin2_tribunalReviewFlag.
  ///
  /// In en, this message translates to:
  /// **'Review flag'**
  String get admin2_tribunalReviewFlag;

  /// No description provided for @admin2_ticketLinkedBooking.
  ///
  /// In en, this message translates to:
  /// **'Linked booking'**
  String get admin2_ticketLinkedBooking;

  /// No description provided for @admin2_anncSentCount.
  ///
  /// In en, this message translates to:
  /// **'Sent {count}'**
  String admin2_anncSentCount(Object count);

  /// No description provided for @admin2_anncOpenedCount.
  ///
  /// In en, this message translates to:
  /// **'Opened {count}'**
  String admin2_anncOpenedCount(Object count);

  /// No description provided for @admin2_activityDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision: {decision}'**
  String admin2_activityDecision(String decision);

  /// No description provided for @admin2_trustRatingNone.
  ///
  /// In en, this message translates to:
  /// **'none yet'**
  String get admin2_trustRatingNone;

  /// No description provided for @admin2_trustKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC'**
  String get admin2_trustKyc;

  /// No description provided for @admin2_reportsBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get admin2_reportsBookings;

  /// No description provided for @admin2_reportsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get admin2_reportsCompleted;

  /// No description provided for @admin2_reportsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get admin2_reportsExportCsv;

  /// No description provided for @admin2_reportsCsvShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the CSV file.'**
  String get admin2_reportsCsvShareFailed;

  /// No description provided for @admin2_bookingsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get admin2_bookingsCustomer;

  /// No description provided for @admin2_bookingDetailDepositDeducted.
  ///
  /// In en, this message translates to:
  /// **'Deposit {amount} — {status} (deducted {deducted})'**
  String admin2_bookingDetailDepositDeducted(
      String amount, String status, String deducted);

  /// No description provided for @admin2_bookingDetailDisputeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String admin2_bookingDetailDisputeStatus(String status);

  /// No description provided for @admin2_bookingDetailDisputeDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision: {label}'**
  String admin2_bookingDetailDisputeDecision(String label);

  /// No description provided for @admin2_bookingDetailDisputeDecisionAmount.
  ///
  /// In en, this message translates to:
  /// **'Decision: {label} — {amount}'**
  String admin2_bookingDetailDisputeDecisionAmount(String label, String amount);

  /// No description provided for @admin2_carReviewHourly.
  ///
  /// In en, this message translates to:
  /// **'1 h / 3 h / 6 h'**
  String get admin2_carReviewHourly;

  /// No description provided for @admin2_carReviewMileageKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String admin2_carReviewMileageKm(Object km);

  /// No description provided for @admin2_carReviewMetaLine1.
  ///
  /// In en, this message translates to:
  /// **'Plate {plate} • {category} • {transmission} • {fuel} • {seats} seats'**
  String admin2_carReviewMetaLine1(String plate, String category,
      String transmission, String fuel, Object seats);

  /// No description provided for @admin2_carReviewMetaLine2.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} • Current review: {review}'**
  String admin2_carReviewMetaLine2(String status, String review);

  /// No description provided for @admin2_carReviewNotReviewed.
  ///
  /// In en, this message translates to:
  /// **'not reviewed yet'**
  String get admin2_carReviewNotReviewed;

  /// No description provided for @admin2_checklistShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name and address'**
  String get admin2_checklistShopName;

  /// No description provided for @admin2_checklistOwnerPhone.
  ///
  /// In en, this message translates to:
  /// **'Owner phone number'**
  String get admin2_checklistOwnerPhone;

  /// No description provided for @admin2_checklistOwnerCnic.
  ///
  /// In en, this message translates to:
  /// **'Owner CNIC on file'**
  String get admin2_checklistOwnerCnic;

  /// No description provided for @admin2_checklistKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC documents uploaded'**
  String get admin2_checklistKyc;

  /// No description provided for @admin2_checklistBank.
  ///
  /// In en, this message translates to:
  /// **'Bank / wallet account on file'**
  String get admin2_checklistBank;

  /// No description provided for @admin2_checklistFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet photos uploaded'**
  String get admin2_checklistFleet;

  /// No description provided for @admin2_disputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get admin2_disputed;

  /// No description provided for @admin2_inCity.
  ///
  /// In en, this message translates to:
  /// **'In city'**
  String get admin2_inCity;

  /// No description provided for @admin2_outCity.
  ///
  /// In en, this message translates to:
  /// **'Out of city'**
  String get admin2_outCity;

  /// No description provided for @admin2_bookingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking {id}'**
  String admin2_bookingSummaryTitle(String id);

  /// No description provided for @admin2_bookingSummaryStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} • Trip: {trip} ({kmLimit} km limit)'**
  String admin2_bookingSummaryStatusLine(
      String status, String trip, String kmLimit);

  /// No description provided for @admin2_bookingSummaryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {vehicle} ({plate})'**
  String admin2_bookingSummaryVehicle(String vehicle, String plate);

  /// No description provided for @admin2_bookingSummaryShop.
  ///
  /// In en, this message translates to:
  /// **'Shop: {shop} • Customer: {customer}'**
  String admin2_bookingSummaryShop(String shop, String customer);

  /// No description provided for @admin2_bookingSummaryPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {pickup} • Return: {returnTime}'**
  String admin2_bookingSummaryPickup(String pickup, String returnTime);

  /// No description provided for @admin2_bookingSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} • Advance required: {advanceRequired} • Paid: {paid} • Remaining: {remaining}'**
  String admin2_bookingSummaryTotal(
      String total, String advanceRequired, String paid, String remaining);

  /// No description provided for @admin2_bookingSummaryDepositNone.
  ///
  /// In en, this message translates to:
  /// **'Deposit: none'**
  String get admin2_bookingSummaryDepositNone;

  /// No description provided for @admin2_bookingSummaryDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit: {amount} ({status})'**
  String admin2_bookingSummaryDeposit(String amount, String status);

  /// No description provided for @admin2_bookingSummaryAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement PDF: {url}'**
  String admin2_bookingSummaryAgreement(String url);

  /// No description provided for @admin2_bookingSummaryHandoverNone.
  ///
  /// In en, this message translates to:
  /// **'Handover: none'**
  String get admin2_bookingSummaryHandoverNone;

  /// No description provided for @admin2_bookingSummaryHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover: odometer {odometer} km, fuel {fuel}, damage: {damage}'**
  String admin2_bookingSummaryHandover(
      Object odometer, String fuel, String damage);

  /// No description provided for @admin2_bookingPhotoOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo link.'**
  String get admin2_bookingPhotoOpenFailed;

  /// No description provided for @admin2_teamInviteSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get admin2_teamInviteSaving;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'Rentalhub is under maintenance right now. Please try again in a little while.'**
  String get maintenanceBody;

  /// No description provided for @maintenanceRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get maintenanceRetry;

  /// No description provided for @admin2_totpReminderLogin.
  ///
  /// In en, this message translates to:
  /// **'A super admin asked you to turn on two-factor authentication.'**
  String get admin2_totpReminderLogin;

  /// No description provided for @admin2_evidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get admin2_evidenceTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @admin2_teamResetTotpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset two-factor authentication'**
  String get admin2_teamResetTotpTooltip;

  /// No description provided for @admin2_teamRevokeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Revoke admin role'**
  String get admin2_teamRevokeTooltip;

  /// No description provided for @extraChargeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading saved extra charges…'**
  String get extraChargeLoading;

  /// No description provided for @kycWizardDateFormatError.
  ///
  /// In en, this message translates to:
  /// **'Enter the date as DD.MM.YYYY'**
  String get kycWizardDateFormatError;

  /// No description provided for @kycWizardMissingItem.
  ///
  /// In en, this message translates to:
  /// **'{item} is missing — please add it to continue'**
  String kycWizardMissingItem(String item);

  /// No description provided for @kycWizardSignatureMissing.
  ///
  /// In en, this message translates to:
  /// **'Please draw your signature before continuing'**
  String get kycWizardSignatureMissing;

  /// No description provided for @kycWizardTermsMissing.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the rental terms before continuing'**
  String get kycWizardTermsMissing;

  /// No description provided for @manualBookingLoadingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Loading fixed routes…'**
  String get manualBookingLoadingRoutes;

  /// No description provided for @mediaCameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera. Check the camera permission and try again.'**
  String get mediaCameraError;

  /// No description provided for @passNotValid.
  ///
  /// In en, this message translates to:
  /// **'This pass is not valid for pickup'**
  String get passNotValid;

  /// No description provided for @contractSignAgreementHint.
  ///
  /// In en, this message translates to:
  /// **'Add the guarantor signature to sign.'**
  String get contractSignAgreementHint;

  /// No description provided for @depositRefundTerms.
  ///
  /// In en, this message translates to:
  /// **'Deposit refunded after return inspection, minus damage and excess-km charges.'**
  String get depositRefundTerms;

  /// No description provided for @disputeLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String disputeLastUpdated(String date);

  /// No description provided for @handoverBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance due at handover'**
  String get handoverBalanceDue;

  /// No description provided for @handoverBalanceMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose how the balance was collected, or Not yet, before certifying.'**
  String get handoverBalanceMethodRequired;

  /// No description provided for @handoverBalanceNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get handoverBalanceNotYet;

  /// No description provided for @handoverFuelRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the fuel level before certifying.'**
  String get handoverFuelRequired;

  /// No description provided for @manualBookingLoadingVehicles.
  ///
  /// In en, this message translates to:
  /// **'Loading vehicles…'**
  String get manualBookingLoadingVehicles;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Check your connection and try again.'**
  String get profileLoadFailed;

  /// No description provided for @proofAdvanceCopied.
  ///
  /// In en, this message translates to:
  /// **'Advance amount copied to clipboard'**
  String get proofAdvanceCopied;

  /// No description provided for @proofCopyAdvance.
  ///
  /// In en, this message translates to:
  /// **'Copy advance amount'**
  String get proofCopyAdvance;

  /// No description provided for @proofMessageShop.
  ///
  /// In en, this message translates to:
  /// **'Message shop on WhatsApp'**
  String get proofMessageShop;

  /// No description provided for @returnAmountOwedByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Amount owed by customer: {amount}'**
  String returnAmountOwedByCustomer(String amount);

  /// No description provided for @returnCloseBookingHint.
  ///
  /// In en, this message translates to:
  /// **'Record the refund to close the booking.'**
  String get returnCloseBookingHint;

  /// No description provided for @returnFinalizeFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not finalize the return. Please try again.'**
  String get returnFinalizeFailedGeneric;

  /// No description provided for @returnOwedCollected.
  ///
  /// In en, this message translates to:
  /// **'Owed amount collected: {amount} via {method}'**
  String returnOwedCollected(String amount, String method);

  /// No description provided for @tripOutCityEstimate.
  ///
  /// In en, this message translates to:
  /// **'≈ {estimate} for {days} days × {km} km/day'**
  String tripOutCityEstimate(int days, String estimate, int km);

  /// No description provided for @shopFromPerDay.
  ///
  /// In en, this message translates to:
  /// **'from {rate}/day'**
  String shopFromPerDay(String rate);

  /// No description provided for @shops_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the shops.'**
  String get shops_loadFailed;

  /// No description provided for @shops_radiusChip.
  ///
  /// In en, this message translates to:
  /// **'Radius: {km} km'**
  String shops_radiusChip(String km);

  /// No description provided for @shops_searchCities.
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get shops_searchCities;

  /// No description provided for @dashboardNeedsReviewSplit.
  ///
  /// In en, this message translates to:
  /// **'{newCount} new · {proofCount} proof'**
  String dashboardNeedsReviewSplit(int newCount, int proofCount);

  /// No description provided for @dashboardNeedsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get dashboardNeedsReviewTitle;

  /// No description provided for @dashboardOldestWait.
  ///
  /// In en, this message translates to:
  /// **'Oldest wait: {wait}'**
  String dashboardOldestWait(String wait);

  /// No description provided for @dashboardQuickRequests.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get dashboardQuickRequests;

  /// No description provided for @fleetOutCityFixedRoute.
  ///
  /// In en, this message translates to:
  /// **'Out-city: fixed route'**
  String get fleetOutCityFixedRoute;

  /// No description provided for @fleetOutCityPerKm.
  ///
  /// In en, this message translates to:
  /// **'Out-city: per-km'**
  String get fleetOutCityPerKm;

  /// No description provided for @homeSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get homeSignInButton;

  /// No description provided for @priorTripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} prior trips'**
  String priorTripsCount(int count);

  /// No description provided for @requestsOldestProofWait.
  ///
  /// In en, this message translates to:
  /// **'Oldest proof wait: {wait}'**
  String requestsOldestProofWait(String wait);

  /// No description provided for @requestsWaitingTime.
  ///
  /// In en, this message translates to:
  /// **'Waiting {wait}'**
  String requestsWaitingTime(String wait);

  /// No description provided for @triageKycMissing.
  ///
  /// In en, this message translates to:
  /// **'KYC missing'**
  String get triageKycMissing;

  /// No description provided for @triageKycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC pending'**
  String get triageKycPending;

  /// No description provided for @triageKycRejected.
  ///
  /// In en, this message translates to:
  /// **'KYC rejected'**
  String get triageKycRejected;

  /// No description provided for @triageKycVerified.
  ///
  /// In en, this message translates to:
  /// **'KYC verified'**
  String get triageKycVerified;

  /// No description provided for @triageTrustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust {score}/5'**
  String triageTrustScore(String score);

  /// No description provided for @waitDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String waitDurationDays(int days, int hours);

  /// No description provided for @waitDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String waitDurationHm(int hours, int minutes);

  /// No description provided for @waitDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String waitDurationMinutes(int minutes);

  /// No description provided for @carPnlLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this car\'s profit and loss. Check your connection and try again.'**
  String get carPnlLoadError;

  /// No description provided for @cashClosingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load cash closing. Check your connection and try again.'**
  String get cashClosingLoadError;

  /// No description provided for @customerStatementLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this customer\'s statement. Check your connection and try again.'**
  String get customerStatementLoadError;

  /// No description provided for @disputesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load disputes. Check your connection and try again.'**
  String get disputesLoadError;

  /// No description provided for @financeCategoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load finance categories. Check your connection and try again.'**
  String get financeCategoriesLoadError;

  /// No description provided for @financeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your finances. Check your connection and try again.'**
  String get financeLoadError;

  /// No description provided for @financeSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load finance settings. Check your connection and try again.'**
  String get financeSettingsLoadError;

  /// No description provided for @reportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load reports. Check your connection and try again.'**
  String get reportsLoadError;

  /// No description provided for @staffRolesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load staff roles. Check your connection and try again.'**
  String get staffRolesLoadError;

  /// No description provided for @ticketPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {date}'**
  String ticketPickupDate(String date);

  /// No description provided for @whatsappCreditsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load WhatsApp credits. Check your connection and try again.'**
  String get whatsappCreditsLoadError;

  /// No description provided for @whatsappHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load WhatsApp history. Check your connection and try again.'**
  String get whatsappHistoryLoadError;

  /// No description provided for @currencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rs. '**
  String get currencyPrefix;

  /// No description provided for @pricingHintKmPerDay.
  ///
  /// In en, this message translates to:
  /// **'{km} km / day'**
  String pricingHintKmPerDay(int km);

  /// No description provided for @pricingHintPerHour.
  ///
  /// In en, this message translates to:
  /// **'{amount} / hour'**
  String pricingHintPerHour(String amount);

  /// No description provided for @paymentVerificationConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment — {amount}'**
  String paymentVerificationConfirmButton(String amount);

  /// No description provided for @returnCustomerOwes.
  ///
  /// In en, this message translates to:
  /// **'Customer owes {amount}'**
  String returnCustomerOwes(String amount);

  /// No description provided for @vehicleDepositCnic.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit: {amount} + Original NADRA CNIC guarantee required at pickup'**
  String vehicleDepositCnic(String amount);

  /// No description provided for @returnOwedRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the owed amount collection. Please try again.'**
  String get returnOwedRecordFailed;

  /// No description provided for @dashboardMonthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get dashboardMonthlyRevenue;

  /// No description provided for @dashboardActiveRentalsToday.
  ///
  /// In en, this message translates to:
  /// **'Active Rentals Today'**
  String get dashboardActiveRentalsToday;

  /// No description provided for @fleetHandoverQr.
  ///
  /// In en, this message translates to:
  /// **'Handover QR'**
  String get fleetHandoverQr;

  /// No description provided for @vehicleDetailEditVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit Vehicle'**
  String get vehicleDetailEditVehicle;

  /// No description provided for @vehicleDetailRatesPricing.
  ///
  /// In en, this message translates to:
  /// **'Rates & Pricing'**
  String get vehicleDetailRatesPricing;

  /// No description provided for @customerDetailKycDocumentsCount.
  ///
  /// In en, this message translates to:
  /// **'KYC Documents ({count}/{total} Uploaded)'**
  String customerDetailKycDocumentsCount(int count, int total);

  /// No description provided for @kycLeftFourFingers.
  ///
  /// In en, this message translates to:
  /// **'Left 4 Fingers'**
  String get kycLeftFourFingers;

  /// No description provided for @kycRightFourFingers.
  ///
  /// In en, this message translates to:
  /// **'Right 4 Fingers'**
  String get kycRightFourFingers;

  /// No description provided for @settingsShowroomOwner.
  ///
  /// In en, this message translates to:
  /// **'Showroom Owner'**
  String get settingsShowroomOwner;

  /// No description provided for @settingsSetUpShop.
  ///
  /// In en, this message translates to:
  /// **'Set Up Shop'**
  String get settingsSetUpShop;

  /// No description provided for @settingsAccountAlerts.
  ///
  /// In en, this message translates to:
  /// **'Account & Alerts'**
  String get settingsAccountAlerts;

  /// No description provided for @activeRentals.
  ///
  /// In en, this message translates to:
  /// **'Active Rentals'**
  String get activeRentals;

  /// No description provided for @settingsOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get settingsOperations;

  /// No description provided for @customersBookingTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} • {count, plural, =1{1 booking} other{{count} bookings}}'**
  String customersBookingTotal(String amount, int count);

  /// No description provided for @fleetReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get fleetReady;
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
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
