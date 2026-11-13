// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RentalHub Pakistan';

  @override
  String get appStartFailed =>
      'RentalHub couldn\'t start. Please restart the app and try again.';

  @override
  String get blacklist => 'Blacklist Reports';

  @override
  String get fixedRoutes => 'Fixed Routes';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'Urdu';

  @override
  String get notifications => 'Notifications';

  @override
  String get quickLinks => 'Quick links';

  @override
  String get settings => 'Shop Settings';

  @override
  String get settingsSubtitle => 'Language, theme and your showroom';

  @override
  String get shop => 'Your showroom';

  @override
  String get shopNotSet => 'Shop name not set yet';

  @override
  String get signOut => 'Sign Out';

  @override
  String get ownerSignOutError => 'Could not sign out. Please try again.';

  @override
  String get subscription => 'Subscription';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get whatsappLogs => 'WhatsApp Logs';

  @override
  String get finance => 'Finance';

  @override
  String get customerSettings => 'Settings & Preferences';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get whatsappNotifications => 'WhatsApp Notifications';

  @override
  String get appVersion => 'App Version';

  @override
  String get disputes => 'Disputes';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get sos => 'SOS';

  @override
  String get active => 'Active';

  @override
  String get filterAll => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get done => 'Done';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusOnTrip => 'On trip';

  @override
  String get statusProofSubmitted => 'Proof submitted';

  @override
  String get statusRequestSent => 'Request sent';

  @override
  String get statusPendingReview => 'Pending Review';

  @override
  String get inReview => 'In review';

  @override
  String get disputeOpen => 'Open';

  @override
  String get disputeResolved => 'Resolved';

  @override
  String get verified => 'Verified';

  @override
  String get available => 'Available';

  @override
  String get rentedOut => 'Rented Out';

  @override
  String get inMaintenance => 'In Maintenance';

  @override
  String get availableNow => 'Available Now';

  @override
  String get selfDrive => 'Self Drive';

  @override
  String get withDriver => 'With Driver';

  @override
  String get withChauffeur => 'With Chauffeur';

  @override
  String get selfDriveHyphen => 'Self-Drive';

  @override
  String get inCity => 'In city';

  @override
  String get outOfCity => 'Out of city';

  @override
  String get inCityHyphen => 'In-City';

  @override
  String get outOfCityHyphen => 'Out-of-City';

  @override
  String get supportUrgencyLow => 'Low';

  @override
  String get supportUrgencyMedium => 'Medium';

  @override
  String get supportUrgencyHigh => 'High — urgent';

  @override
  String get call => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get viewFleet => 'View Fleet';

  @override
  String get showroomLabel => 'Showroom';

  @override
  String get rentalCar => 'Rental Car';

  @override
  String get rentalShowroom => 'Rental Showroom';

  @override
  String get summaryVehicle => 'Vehicle';

  @override
  String get packageLabel => 'Package';

  @override
  String get pickupLabel => 'Pickup';

  @override
  String get summaryReturn => 'Return';

  @override
  String get summaryTotal => 'Total';

  @override
  String get summaryTrip => 'Trip';

  @override
  String get summaryMode => 'Mode';

  @override
  String get summaryPlate => 'Plate';

  @override
  String get summaryRemaining => 'Remaining';

  @override
  String get packageContinue => 'Continue';

  @override
  String get kycUpload => 'Upload';

  @override
  String get kycEncrypted => 'Encrypted';

  @override
  String get kycCustomer => 'Customer';

  @override
  String get walletLabel => 'Wallet';

  @override
  String get profileGuest => 'Guest';

  @override
  String get homeTitle => 'Find Verified Rental Shops';

  @override
  String get homeSwitchToMap => 'Switch to Interactive Map';

  @override
  String get homeFindingShops => 'Finding nearby shops…';

  @override
  String get homeNearbyShowrooms => 'Nearby Showrooms';

  @override
  String get homeMyLiveLocation => 'My Live Location';

  @override
  String get homeSwitchToList => 'Switch to List View';

  @override
  String get locationSetTitle => 'Set Rental Location';

  @override
  String get locationCenterPin => 'Center Location Pin';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Tap a city to explore.';

  @override
  String get locationEnableGps =>
      'Please enable GPS / Location Services on your device.';

  @override
  String get locationSelectCityManually => 'Select City Manually (Lahore)';

  @override
  String get locationAllowWhileUsing => 'Allow While Using App';

  @override
  String get locationEnablePrecise => 'Enable Precise Location';

  @override
  String get locationPermissionExplainer =>
      'RentalHub uses your real-time GPS coordinates to calculate road distances and discover verified rental showrooms within 1–5 km around you in Pakistan.';

  @override
  String get emptyRadarExpandHint =>
      'Expand your GPS discovery radius to 5 km to view accredited showrooms nearby.';

  @override
  String emptyRadarExpandToKm(int radius) {
    return 'Expand to $radius km';
  }

  @override
  String get emptyRadarNoShopsTitle => 'No rental shops near you yet';

  @override
  String get emptyRadarNoShopsSubtitle =>
      'Try a different area or browse all shops.';

  @override
  String get emptyRadarBrowseAll => 'Browse all shops';

  @override
  String get noShopsBanner =>
      'No verified showrooms within this radius yet. Try a wider radius.';

  @override
  String get radiusLabel => 'Radius:';

  @override
  String get quickBookCar => 'Book a Car';

  @override
  String get quickMyReservations => 'My Reservations';

  @override
  String get quickNearbyShops => 'Nearby Shops';

  @override
  String get shopCarsTitle => 'Available Fleet';

  @override
  String get shopCarsLoading => 'Loading available cars…';

  @override
  String get shopCarsLoadError =>
      'Could not load this showroom’s cars. Check your connection and try again.';

  @override
  String get shopCarsTryOther =>
      'Try a different category, or check back later.';

  @override
  String get shopSave => 'Save showroom';

  @override
  String get shopSaved => 'Saved';

  @override
  String get shopSaveError => 'Could not save this showroom.';

  @override
  String get shopSaveSignIn => 'Sign in to save showrooms.';

  @override
  String get shopNoCars => 'This shop has no cars listed yet.';

  @override
  String get shopCheckLater => 'Check back later, or browse other showrooms.';

  @override
  String get shopLoadingCars => 'Loading this showroom’s cars…';

  @override
  String get shopViewAllCars => 'View all cars with filters';

  @override
  String get vehicleCapacity => 'Capacity';

  @override
  String get vehicleFuelType => 'Fuel Type';

  @override
  String get vehicleMileage => 'Mileage';

  @override
  String get vehicleTransmission => 'Transmission';

  @override
  String get vehicleChoosePackage => 'Choose Rental Package';

  @override
  String get couldNotOpenWhatsapp => 'Could not open WhatsApp.';

  @override
  String get couldNotCall => 'Could not place the call.';

  @override
  String get shopNoWhatsapp => 'This shop has no WhatsApp number listed.';

  @override
  String get shopNoWhatsappShowroom =>
      'This showroom has no WhatsApp number listed.';

  @override
  String get bookingsTitle => 'My Reservations';

  @override
  String get bookingsLoading => 'Loading your reservations…';

  @override
  String get bookingsLoadError =>
      'Could not load your bookings. Check your connection and try again.';

  @override
  String get bookingsEmptyHint => 'Bookings you make will appear here.';

  @override
  String get bookingsPayAdvance => 'Pay Advance';

  @override
  String get bookingsViewPass => 'View Pass';

  @override
  String get bookingsRateTrip => 'Rate Trip';

  @override
  String get activeTripTitle => 'Active Trip';

  @override
  String get countdownToPickup => 'COUNTDOWN TO PICKUP';

  @override
  String get timeUntilReturn => 'TIME UNTIL RETURN';

  @override
  String get kmIncluded => 'KM included';

  @override
  String get returnDue => 'Return due';

  @override
  String get totalFare => 'Total fare';

  @override
  String get viewPickupPassQr => 'View Pickup Pass (QR)';

  @override
  String get viewPassQr => 'View Pass / QR';

  @override
  String get activeRentalCar => 'Active Rental Car';

  @override
  String get handoverAtPickup => 'Handover at Pickup';

  @override
  String get odometerAtPickup => 'Odometer at pickup';

  @override
  String get fuelAtPickup => 'Fuel at pickup';

  @override
  String get damageNoted => 'Damage noted';

  @override
  String get handoverPendingNote =>
      'The shop records the odometer and fuel level at handover — they will appear here once the car is handed over.';

  @override
  String get browseOtherShops => 'Browse other shops';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get fileDispute => 'File a dispute';

  @override
  String get rateThisTrip => 'Rate this trip';

  @override
  String get viewPickupPass => 'View pickup pass';

  @override
  String get summaryAdvancePaid => 'Advance paid';

  @override
  String get summaryAdvanceRequired => 'Advance required';

  @override
  String get summaryDriveMode => 'Drive mode';

  @override
  String get summaryPickupTime => 'Pickup Time';

  @override
  String get summaryReturnDue => 'Return Due';

  @override
  String get summaryPackageTier => 'Package Tier';

  @override
  String get summaryKmIncluded => 'KM Included';

  @override
  String get summarySecurityDeposit => 'Security Deposit';

  @override
  String get summaryTotalFare => 'Total Rental Fare';

  @override
  String get summaryAdvancePayable => 'Advance Payable';

  @override
  String get summaryBalanceAtHandover => 'Balance at Handover';

  @override
  String get walletTitle => 'Wallet & Security Escrow';

  @override
  String get walletActiveEscrow => 'Active Escrow & Advances';

  @override
  String get walletAdvancesPaid => 'Advances Paid';

  @override
  String get walletSecurityEscrow => 'Security Escrow';

  @override
  String get walletLedger => 'Transaction Ledger';

  @override
  String get walletHideAmount => 'Hide amount';

  @override
  String get walletShowAmount => 'Show amount';

  @override
  String get walletHideBalance => 'Hide balance';

  @override
  String get walletShowBalance => 'Show balance';

  @override
  String get walletEmptyHint => 'Advances and deposits will appear here.';

  @override
  String get walletLedgerEmptyHint =>
      'Advances you pay and deposits you leave will appear here.';

  @override
  String get walletLoadError =>
      'Could not load your wallet. Check your connection and try again.';

  @override
  String get walletLoading => 'Loading your wallet…';

  @override
  String get walletNoActivity => 'No wallet activity yet.';

  @override
  String get profileTotalTrips => 'Total Trips';

  @override
  String get profileTrustScore => 'Trust Score';

  @override
  String get profileLoading => 'Loading your profile…';

  @override
  String get profileNotSignedIn => 'Not signed in.';

  @override
  String get profileNotSignedInShort => 'Not signed in';

  @override
  String get profileSavedShops => 'Saved Showrooms';

  @override
  String get profileSavedShopsSubtitle => 'Bookmarked rental agencies';

  @override
  String get profileMyDocuments => 'My Documents (KYC)';

  @override
  String get profileKycSubtitle => 'CNIC Front/Back & Driving License';

  @override
  String get profileSettingsLanguage => 'Settings & Language';

  @override
  String get profileSettingsSubtitle => 'English / Urdu, Notifications';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editFullName => 'Full name';

  @override
  String get editPhone => 'Phone';

  @override
  String get editCnicOptional => 'CNIC (optional)';

  @override
  String get editEnterName => 'Please enter your name.';

  @override
  String get editSaveProfile => 'Save Profile';

  @override
  String get editSaving => 'Saving...';

  @override
  String get cnicLabel => 'CNIC';

  @override
  String get cnicHide => 'Hide CNIC';

  @override
  String get cnicShow => 'Show CNIC';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get reputationTitle => 'My Trust & Reputation';

  @override
  String get reputationShopRatings => 'Showroom Ratings of You';

  @override
  String get reputationEmpty =>
      'No showroom has rated you yet. Your reputation appears here after your first completed trip.';

  @override
  String get reputationVisibleNote =>
      'Showrooms see these ratings when they review your booking requests.';

  @override
  String get reputationPunctuality => 'On-Time Handover Punctuality';

  @override
  String get reputationVehicleCare => 'Vehicle Care & Cleanliness';

  @override
  String get reputationStaffBehavior => 'Staff Interaction & Behavior';

  @override
  String get reputationTrustScoreDash => 'Trust Score: —';

  @override
  String get disputesMyTitle => 'My Disputes';

  @override
  String get disputesEmpty => 'No disputes filed yet.';

  @override
  String get savedShopsEmpty => 'No saved showrooms yet.';

  @override
  String get savedShopsEmptyHint =>
      'Tap the heart on any showroom to save it here.';

  @override
  String get savedShopsRemove => 'Remove from saved';

  @override
  String get savedShopsRemoveError => 'Could not remove this showroom.';

  @override
  String get supportTitle => 'Help & Support Center';

  @override
  String get supportSearchHint => 'Search help';

  @override
  String get supportCallShop => 'Call your showroom';

  @override
  String get supportWhatsappShop => 'WhatsApp your showroom';

  @override
  String get supportNoBooking => 'No booking yet';

  @override
  String get supportNoBookingHint =>
      'No booking yet — the showroom contact appears here once you have a booking.';

  @override
  String get supportFileDispute => 'File a Formal Complaint / Dispute';

  @override
  String get supportDisputeHint =>
      'Overcharged or deposit withheld? File an arbitration claim.';

  @override
  String get supportFaqTitle => 'Frequently Asked Questions';

  @override
  String get supportFaqEmpty => 'No help topics match your search.';

  @override
  String get supportFaqEmptyHint =>
      'Try a different keyword, or ask your showroom directly.';

  @override
  String get supportSosTitle => 'Emergency SOS';

  @override
  String get supportSosSubtitle =>
      'Police 15 · Rescue 1122 — one-tap emergency help.';

  @override
  String get supportFaqQ1 => 'How does advance payment protect my booking?';

  @override
  String get supportFaqA1 =>
      'Your advance payment locks the vehicle exclusively for your scheduled time and guarantees showroom reservation. It is safely recorded and deducted from your final bill.';

  @override
  String get supportFaqQ2 => 'When is my security deposit returned?';

  @override
  String get supportFaqA2 =>
      'The deposit is settled at return handover. Any deduction for excess kilometres, fuel or damage is shown on the settlement, and the rest is released to you.';

  @override
  String get supportFaqQ3 => 'What happens if a vehicle breaks down?';

  @override
  String get supportFaqA3 =>
      'Roadside help depends on the showroom — ask yours when you pick up the car. For an emergency, use the Emergency SOS screen.';

  @override
  String get supportFaqQ4 => 'Can I take the rental car out of city?';

  @override
  String get supportFaqA4 =>
      'Yes, out-of-city packages are available. Select the \"Out of City\" tier or inform the showroom beforehand to ensure tracker clearance.';

  @override
  String get supportMessageTitle => 'Message Support';

  @override
  String get supportMessageLabel => 'What went wrong?';

  @override
  String get supportMessageHint =>
      'Tell us what went wrong. Our team will reach you on WhatsApp — replies do not appear in the app yet.';

  @override
  String get supportUrgencyLabel => 'How urgent is this?';

  @override
  String get supportSendMessage => 'Send Message';

  @override
  String get supportSending => 'Sending...';

  @override
  String get supportWriteFirst => 'Please write your message first.';

  @override
  String get supportMessageSent =>
      'Message sent. Our team will contact you on WhatsApp.';

  @override
  String get sosTitle => 'Emergency SOS Assistance';

  @override
  String get sosPress => 'Press SOS in Emergency';

  @override
  String get sosExplainer =>
      'The SOS button calls Police 15. You can also call Rescue 1122 or share your live location with your showroom.';

  @override
  String get sosCallPolice => 'Call Police 15';

  @override
  String get sosCallRescue => 'Call Rescue 1122';

  @override
  String get sosCallPoliceEmergency => 'Call Police Emergency 15';

  @override
  String get sosCallPoliceConfirm => 'Call Police 15?';

  @override
  String get sosCallPoliceConfirmHint =>
      'This dials the police emergency number (15). Use it only in a real emergency.';

  @override
  String get sosPoliceSubtitle => 'Direct Punjab & Federal Police helpline';

  @override
  String get sosRescueSubtitle => 'Ambulance, fire and rescue services';

  @override
  String get sosPolice => 'Police 15';

  @override
  String get sosRescue => 'Rescue 1122';

  @override
  String get sosShareLocation => 'Share Live Location via WhatsApp';

  @override
  String get sosSendToShop => 'Send your live location to your showroom';

  @override
  String get sosNoBookingHint =>
      'No booking yet — your live location is shared with your showroom once you have a booking.';

  @override
  String get sosLocationPermission =>
      'Location permission is needed to share your live location.';

  @override
  String get disputeTitle => 'File Complaint / Dispute';

  @override
  String get disputeDepositWithheld => 'Deposit Withheld';

  @override
  String get disputeOvercharge => 'Showroom Overcharge';

  @override
  String get disputeBreakdown => 'Vehicle Breakdown Delay';

  @override
  String get disputeDamagePenalty => 'Unfair Damage Penalty';

  @override
  String get disputeRudeStaff => 'Rude / Unprofessional Staff';

  @override
  String get disputeSelectCategory => 'Select Dispute Category';

  @override
  String get disputeBookingId => 'Booking ID / Reference';

  @override
  String get disputeBookingIdHint => 'E.g. RH-849201';

  @override
  String get disputeDetailsLabel => 'Detailed Explanation';

  @override
  String get disputeDetailsHint =>
      'Describe what happened with dates, amounts, and showroom staff names...';

  @override
  String get disputeRecordedNote =>
      'Your dispute is recorded and shared with the showroom for review. There is no fixed resolution time yet.';

  @override
  String get disputeEnterBookingId => 'Please enter your Booking ID.';

  @override
  String get disputeExplainIssue => 'Please explain the issue encountered.';

  @override
  String get disputeSubmit => 'Submit Claim';

  @override
  String get disputeSubmitting => 'Submitting Dispute...';

  @override
  String get disputeFiled =>
      'Dispute filed. The showroom can see it in their disputes inbox.';

  @override
  String disputeFiledAgo(String time) {
    return 'Filed $time ago';
  }

  @override
  String disputeSlaLeft(String time) {
    return '$time left';
  }

  @override
  String get disputeSavedOffline =>
      'Dispute saved on this device — it will reach the showroom once you are back online.';

  @override
  String get cancelReasonLabel => 'Reason for Cancellation';

  @override
  String get cancelTitle => 'Cancel Reservation';

  @override
  String get cancelConfirm => 'Confirm Cancellation';

  @override
  String get cancelCancelling => 'Cancelling...';

  @override
  String get cancelWhatHappens => 'What happens when you cancel';

  @override
  String get cancelNoAdvanceNote =>
      'No advance has been paid yet, so there is nothing to refund. No security deposit was collected: deposits are only taken at handover.';

  @override
  String get cancelDone => 'Reservation cancelled.';

  @override
  String get cancelReasonPlans => 'Change of travel plans';

  @override
  String get cancelReasonOtherVehicle => 'Found another vehicle';

  @override
  String get cancelReasonShopDelay => 'Showroom delay in approval';

  @override
  String get cancelReasonEmergency => 'Unexpected emergency';

  @override
  String get cancelReasonOther => 'Other reason';

  @override
  String get rateTitle => 'Rate Your Experience';

  @override
  String get rateVehicleCondition => 'Vehicle Condition & Cleanliness';

  @override
  String get rateVehicleHint =>
      'AC cooling, tires, interior, mechanical health';

  @override
  String get rateShopService => 'Showroom Service Quality';

  @override
  String get rateShopHint => 'Handover speed, staff behavior, transparency';

  @override
  String get rateFeedbackLabel => 'Additional Feedback (Optional)';

  @override
  String get rateFeedbackHint =>
      'Share any highlights or suggestions for future renters...';

  @override
  String get rateSubmit => 'Submit Trip Review';

  @override
  String get rateSubmitting => 'Submitting...';

  @override
  String get rateSaved => 'Thank you! Your review is saved for this trip.';

  @override
  String get rateAlreadyRated =>
      'You already rated this trip — your review is shown below.';

  @override
  String get rateSavedOffline =>
      'Saved on this device — it will sync when you are back online.';

  @override
  String get reviewTitle => 'Review Reservation';

  @override
  String get reviewSpecialInstructions => 'Special Instructions for Showroom';

  @override
  String get reviewInstructionsHint =>
      'E.g. Clean car required, airport terminal pickup...';

  @override
  String get reviewSendRequest => 'Send Request to Owner';

  @override
  String get reviewSending => 'Sending Request...';

  @override
  String get reviewSent => 'Reservation request sent to showroom!';

  @override
  String get approvedTitle => 'Booking Approved!';

  @override
  String get approvedReadyAdvance => 'Ready for Advance Payment';

  @override
  String get successTitle => 'Request Sent Successfully!';

  @override
  String get successTransmitted => 'Request Transmitted';

  @override
  String get successAdvanceDue => 'Advance Due Upon Approval:';

  @override
  String get successShopStatus => 'Showroom Status:';

  @override
  String get successMessageShop => 'Message Showroom on WhatsApp';

  @override
  String get successViewPayment => 'View Payment Details / Status';

  @override
  String get successBackToBookings => 'Return to My Bookings';

  @override
  String get paymentAccountsTitle => 'Showroom Payment Accounts';

  @override
  String get paymentAccountsDirect => 'Direct Transfer Channels';

  @override
  String get paymentBankTransfer => 'Bank Transfer';

  @override
  String get paymentJazzcash => 'JazzCash';

  @override
  String get paymentEasypaisa => 'EasyPaisa';

  @override
  String get paymentVerified => 'RentalHub Verified';

  @override
  String get paymentApprovedTitle => 'Reservation Request Approved!';

  @override
  String get paymentPayHint =>
      'Pay to the verified showroom accounts below and capture a screenshot of your transfer.';

  @override
  String get paymentNoAccounts =>
      'No payment accounts configured for this shop yet.';

  @override
  String get paymentAddAccountsNote =>
      'Add JazzCash, EasyPaisa or bank accounts in Shop Settings so customers know where to pay.';

  @override
  String get paymentLoading => 'Loading payment accounts…';

  @override
  String get paymentUploadProof => 'Upload Payment Proof & Receipt';

  @override
  String get proofSelectedCar => 'Selected Car';

  @override
  String get proofScreenshot => 'Proof Screenshot';

  @override
  String get proofTidLabel => 'Transaction Reference / TID';

  @override
  String get proofTidHint => 'Enter JazzCash / Bank TID (e.g. 892019281)';

  @override
  String get proofAttachFirst =>
      'Please attach your payment screenshot or receipt.';

  @override
  String get proofEnterTid => 'Please enter the transaction reference / TID.';

  @override
  String get proofSubmit => 'Submit Payment Proof';

  @override
  String get proofUploading => 'Uploading Proof...';

  @override
  String get proofSubmitted =>
      'Proof submitted! Waiting for showroom confirmation.';

  @override
  String get proofSubmittedOffline =>
      'Proof submitted! Receipt will sync when you are back online.';

  @override
  String get proofPrivateNote =>
      'Proof is uploaded to private storage. The showroom checks it and confirms your booking — there is no fixed waiting time.';

  @override
  String get passTitle => 'Pickup Countdown Pass';

  @override
  String get passDoneHome => 'Done • Back to Home';

  @override
  String get passRentalVehicle => 'Rental Vehicle';

  @override
  String get passPickupTarget => 'Pickup Target:';

  @override
  String get passShowQr => 'Present this QR Code to showroom staff at handover';

  @override
  String get countdownHours => 'HRS';

  @override
  String get countdownMinutes => 'MIN';

  @override
  String get countdownSeconds => 'SEC';

  @override
  String get packageSelectTitle => 'Select Rental Package';

  @override
  String get packageTiersTitle => 'Available Duration Tiers';

  @override
  String get pkg1h => '1-Hour City Commute';

  @override
  String get pkg3h => '3-Hour Quick Trip';

  @override
  String get pkg6h => '6-Hour Express';

  @override
  String get pkg12h => '12-Hour Half Day';

  @override
  String get pkgDaily => 'Daily 24-Hours';

  @override
  String get pkgWeeklyPackage => 'Weekly Package';

  @override
  String get pkg1hDesc => 'Quick city hops';

  @override
  String get pkg3hDesc => 'Airport drop/pickup & short commutes';

  @override
  String get pkg12hDesc => 'Ideal for city errands, weddings & meetings';

  @override
  String get pkg6hDesc => 'Half-day outings & events';

  @override
  String get pkgDailyDesc => 'Full day flexibility with grace return period';

  @override
  String get pkgWeeklyDesc => 'Seven days, one price';

  @override
  String get tripFixedRoutes => 'Fixed routes from this shop';

  @override
  String get tripTrackerNote =>
      'Tracker clearance required — the shop confirms it before pickup.';

  @override
  String get advanceNoticeTitle => 'Advance & Verification Notice';

  @override
  String get pickerPickupDate => 'Pickup Date';

  @override
  String get pickerPickupSchedule => 'Pickup Schedule';

  @override
  String get pickerDuration => 'Rental Duration';

  @override
  String get pickerIncreaseDays => 'Increase rental days';

  @override
  String get pickerDecreaseDays => 'Decrease rental days';

  @override
  String get proofCaptureCamera => 'Capture Camera';

  @override
  String get proofFromGallery => 'From Gallery';

  @override
  String get proofScreenshotReady => 'Screenshot Ready';

  @override
  String get proofScreenshotSupport =>
      'Support JPG, PNG receipt from banking app';

  @override
  String get proofUploadScreenshot => 'Upload Transfer Screenshot';

  @override
  String paymentProofPayTo(String account) {
    return 'Pay to: $account';
  }

  @override
  String get paymentAccountMobile => 'Account / Mobile';

  @override
  String get paymentAccountTitle => 'Account Title';

  @override
  String get paymentCopyNumber => 'Copy Number';

  @override
  String get paymentIban => 'IBAN Number';

  @override
  String get passCallShop => 'Call Shop';

  @override
  String get passDirections => 'Directions';

  @override
  String get passHandoverPoint => 'Showroom Handover Point';

  @override
  String get passViewAgreement => 'View Rental Agreement (PDF)';

  @override
  String get passAgreementHint =>
      'Your signed rental agreement will appear here after handover.';

  @override
  String get passNoLocation => 'This showroom has no location listed yet.';

  @override
  String get passNoPhone => 'This showroom has no phone number listed.';

  @override
  String get passOpenMapsError => 'Could not open Maps.';

  @override
  String get passOpenAgreementError => 'Could not open the agreement.';

  @override
  String get driverRequiresCnic => 'Requires CNIC + Deposit';

  @override
  String get driverVerifiedIncluded => 'Verified Driver Included';

  @override
  String get authWelcome => 'Welcome to RentalHub';

  @override
  String get authSignInSubtitle => 'Sign in to rent a car near you';

  @override
  String get authEmail => 'Email Address';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignInEmail => 'Sign In with Email';

  @override
  String get authSignedIn => 'Signed in successfully!';

  @override
  String get authSignedInGoogle => 'Signed in with Google!';

  @override
  String get authUnavailable =>
      'Authentication unavailable. Please try again later.';

  @override
  String get authValidEmail => 'Please enter a valid email address.';

  @override
  String get authPasswordLength => 'Password must be at least 6 characters.';

  @override
  String get authTagline =>
      'Pakistan Premier Car Rental & Fleet Ecosystem • خوش آمدید';

  @override
  String get authGoogle => 'Continue with Google';

  @override
  String get onboardingStep1 => 'Step 1: Your Profile';

  @override
  String get onboardingEnterContact => 'Enter your contact information';

  @override
  String get onboardingFullName => 'Full Name';

  @override
  String get onboardingWhatsappNumber => 'WhatsApp Number';

  @override
  String get onboardingValidPhone =>
      'Enter a valid 10-digit number starting with 3 (e.g. 300 1234567)';

  @override
  String get onboardingValidNamePhone =>
      'Please enter a valid full name and Pakistani WhatsApp number (+92 3XX or 03XX).';

  @override
  String get onboardingNameRequired => 'Full name is required';

  @override
  String get onboardingNameLength => 'Name must be at least 3 characters';

  @override
  String get onboardingPhoneRequired => 'WhatsApp number is required';

  @override
  String get onboardingContinueRole => 'Continue to Role Selection';

  @override
  String get onboardingProfileVerified => 'Profile details verified.';

  @override
  String get onboardingStep2 => 'Step 2: Account Role';

  @override
  String get roleSelectTitle => 'Select Permanent Account Role';

  @override
  String get roleSelectSubtitle => 'Choose how you want to use RentalHub';

  @override
  String get roleCustomer => 'Rent a Vehicle (Customer)';

  @override
  String get roleCustomerTitle => 'Customer (Rent a Vehicle)';

  @override
  String get roleCustomerDesc =>
      'Discover verified rental shops within 1–5 km, book Self-Drive or With-Driver packages.';

  @override
  String get roleOwner => 'Fleet Owner (Showroom)';

  @override
  String get roleOwnerTitle => 'List My Fleet (Shop Owner)';

  @override
  String get roleOwnerDesc =>
      'Register your showroom, manage fleet rates, digital handovers, and RentalHub\'s shared blacklist.';

  @override
  String get roleContinueCustomer => 'Continue as Customer';

  @override
  String get roleContinueOwner => 'Continue as Fleet Owner';

  @override
  String get roleReview => 'Review Selection';

  @override
  String get roleSecurityPolicy =>
      'Security Policy: Role selection is strictly one-way and immutable once confirmed.';

  @override
  String get roleLockProceed => 'Lock My Role & Proceed';

  @override
  String get roleConfirm => 'Confirm Permanent Role';

  @override
  String get stepperProfile => '1. Profile Info';

  @override
  String get stepperRole => '2. Select Role';

  @override
  String get avatarSelectPhoto => 'Select Profile Photo';

  @override
  String get avatarSetPicture => 'Set Profile Picture';

  @override
  String get avatarChangePhoto => 'Change profile photo';

  @override
  String get avatarTakePhoto => 'Take Photo';

  @override
  String get avatarFromGallery => 'Choose from Gallery';

  @override
  String get kycTitle => 'NADRA CNIC & Driving License KYC';

  @override
  String get kycSubmittedNote =>
      'KYC documents submitted — pending verification.';

  @override
  String get kycVaultNote => 'Private cPanel vault • شناختی کارڈ تصدیق';

  @override
  String get kycStatusSubmitted => 'Submitted — pending verification';

  @override
  String get kycStatusRejected => 'Rejected — please resubmit';

  @override
  String get kycCnicNumber => '13-Digit NADRA CNIC Number';

  @override
  String get kycCnicRead => 'CNIC number read from the card.';

  @override
  String get kycHighResHint => 'High-resolution scan with clear photo';

  @override
  String get kycCnicBack => 'NADRA CNIC — Back Side';

  @override
  String get kycCnicFront => 'NADRA CNIC — Front Side';

  @override
  String get kycAttachBoth =>
      'Please attach both front and back photos of your NADRA CNIC.';

  @override
  String get kycQrHint => 'QR code & address clearly visible';

  @override
  String get kycSelfDriveNote => 'Required for Self-Drive rental packages';

  @override
  String get kycScanCard => 'Scan CNIC card';

  @override
  String get kycScanning => 'Scanning card...';

  @override
  String get kycSubmit => 'Submit KYC Documents';

  @override
  String get kycUploading => 'Uploading...';

  @override
  String get kycLicense => 'Valid Pakistan Driving License (LTV/HTV)';

  @override
  String get kycFromGallery => 'Choose from gallery';

  @override
  String get kycTakePhoto => 'Take a photo';

  @override
  String get settingsPushSubtitle => 'Booking approvals and payment alerts';

  @override
  String get settingsWhatsappSubtitle => 'Agreement and handover receipts';

  @override
  String get settingsNotifNote =>
      'Notification preferences save to your profile once you have a customer record.';

  @override
  String get shopCategorySedan => 'Sedan';

  @override
  String get shopCategorySuv => 'SUV';

  @override
  String get shopCategoryHiace => 'Hiace';

  @override
  String get shopCategoryLuxury => 'Luxury';

  @override
  String get summaryWithDriver => 'With driver';

  @override
  String get summarySelfDrive => 'Self drive';

  @override
  String get summaryDeclinedPrefix => 'The shop declined this request: ';

  @override
  String get proofRejectedPrefix =>
      'Your payment proof was rejected — please upload a new one: ';

  @override
  String get cancellationReasonPrefix => 'Cancellation reason: ';

  @override
  String get proofWithShop =>
      'Your payment proof is with the shop. You will see the pickup pass here once it is verified.';

  @override
  String get kycScanUnreadable =>
      'Could not read a CNIC number from that photo — please type it.';

  @override
  String get trustKycVerified => 'KYC verified';

  @override
  String get trustKycPending => 'KYC pending';

  @override
  String get trustBlacklisted => 'Flagged on blacklist';

  @override
  String get trustNoBlacklist => 'No blacklist record';

  @override
  String get vehicleSelfDriveUrdu => 'سیلف ڈرائیو';

  @override
  String get vehicleWithDriverUrdu => 'ڈرائیور کے ساتھ';

  @override
  String get roleCustomerUrdu => 'گاڑی کرایہ پر لیں';

  @override
  String get roleOwnerUrdu => 'شوروم رجسٹر کریں';

  @override
  String get advanceNoticeWithDriver =>
      '• Chauffeur arrives at showroom/pickup point 15 mins early.\n• Advance payment confirms vehicle lock and fuel reservation.\n• Outstation overnight stay: Rs. 1,500/night driver food & lodge.';

  @override
  String get advanceNoticeSelfDrive =>
      '• Original NADRA CNIC & valid Driving License required at handover.\n• Advance confirms vehicle booking lock with showroom.\n• Refundable security deposit collected digitally or in cash at handover.';

  @override
  String get ticketShowCode =>
      'Show this code at the counter for handover — it opens your booking and its agreement.';

  @override
  String bookingsEmptyForTab(String tab) {
    return 'No $tab bookings found.';
  }

  @override
  String shopCarsNoneInCategory(String category) {
    return 'No $category vehicles available right now.';
  }

  @override
  String homeGpsActive(String area) {
    return '$area • GPS Active';
  }

  @override
  String mapTapMarker(String area) {
    return '$area • Tap marker to preview';
  }

  @override
  String mapGpsRadar(int km, int count) {
    return 'GPS Radar: $km km ($count Verified Shops)';
  }

  @override
  String mapShopDistance(String address, Object km) {
    return '$address • $km km away';
  }

  @override
  String mapShowShop(String name) {
    return 'Show $name';
  }

  @override
  String shopRatingLabel(Object rating) {
    return '★ $rating Rating';
  }

  @override
  String shopCarsReady(int count) {
    return '• $count Cars Ready';
  }

  @override
  String shopCarsAvailable(int count) {
    return '$count cars available';
  }

  @override
  String callingShop(String name) {
    return 'Calling $name...';
  }

  @override
  String callingShopNumber(String name, String phone) {
    return 'Calling $name ($phone)...';
  }

  @override
  String openingWhatsappShop(String name) {
    return 'Opening WhatsApp with $name...';
  }

  @override
  String vehicleSelfRate(String rate) {
    return 'Self: Rs. $rate/day';
  }

  @override
  String vehicleDriverRate(String rate) {
    return 'With Driver: Rs. $rate/day';
  }

  @override
  String vehicleSeats(int count) {
    return '$count Seats';
  }

  @override
  String vehicleShowroom(String name) {
    return 'Showroom: $name';
  }

  @override
  String vehicleDepositCnic(String amount) {
    return 'Security Deposit: Rs. $amount + Original NADRA CNIC guarantee required at pickup';
  }

  @override
  String vehicleDriverPackageDetail(String overtime, String outstation) {
    return 'Verified chauffeur included • Overtime: Rs. $overtime/hr • Outstation: +Rs. $outstation/day';
  }

  @override
  String vehicleSelectedMode(String mode) {
    return 'Selected: $mode. Advance deposit required.';
  }

  @override
  String vehicleWhatsappInterest(String shop, String vehicle, String plate) {
    return 'Hi $shop, I am interested in the $vehicle ($plate) on RentalHub.';
  }

  @override
  String bookNowWithRate(String rate) {
    return 'Book Now (Rs. $rate)';
  }

  @override
  String get vehicleManageRates => 'Manage rates';

  @override
  String bookingDetailTitle(String id) {
    return 'Booking $id';
  }

  @override
  String bookingShopLine(String shop, String id) {
    return '$shop • $id';
  }

  @override
  String activeTripShopLine(String shop, String plate) {
    return '$shop • $plate';
  }

  @override
  String activeTripPackageRental(String type) {
    return '$type rental';
  }

  @override
  String bookingIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String summaryPackageRental(String type) {
    return '$type Rental';
  }

  @override
  String summaryShowroom(String shop) {
    return 'Showroom: $shop';
  }

  @override
  String summaryOutOfCityTo(String city) {
    return 'Out of city → $city';
  }

  @override
  String summaryDepositAtHandover(String amount) {
    return 'Rs. $amount (at handover)';
  }

  @override
  String payAdvanceAmount(String amount) {
    return 'Pay advance (Rs. $amount)';
  }

  @override
  String shopNotFound(String id) {
    return 'Shop $id was not found.';
  }

  @override
  String vehicleNotFound(String id) {
    return 'Vehicle $id was not found.';
  }

  @override
  String locationFindCarsInCity(String city) {
    return 'Find Nearby Cars in $city';
  }

  @override
  String sosCallError(String label) {
    return 'Could not call $label.';
  }

  @override
  String sosLocationError(String error) {
    return 'Could not get your location: $error';
  }

  @override
  String sosEmergencyMessage(String url) {
    return 'EMERGENCY — I need help. My live location: $url';
  }

  @override
  String sosSendToShopNamed(String shop) {
    return 'Send your live location to $shop';
  }

  @override
  String supportWhatsappMessage(String shop) {
    return 'Hi $shop, I need help with my RentalHub booking.';
  }

  @override
  String disputeFileError(String error) {
    return 'Failed to file dispute: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Cancellation failed: $error';
  }

  @override
  String cancelAdvancePaid(String amount) {
    return 'You paid Rs. $amount advance directly to the showroom\'s account — the showroom decides the refund, so contact them about it. No security deposit was collected: deposits are only taken at handover.';
  }

  @override
  String rateSaveError(String error) {
    return 'Failed to save rating: $error';
  }

  @override
  String rateTripRef(String id) {
    return 'Trip Reference: $id';
  }

  @override
  String rateStarLabel(int star) {
    return 'Rate $star out of 5';
  }

  @override
  String editSaveError(String error) {
    return 'Could not save profile: $error';
  }

  @override
  String supportSendError(String error) {
    return 'Could not send your message: $error';
  }

  @override
  String proofSubmitError(String error) {
    return 'Failed to submit payment proof: $error';
  }

  @override
  String proofBookingId(String id) {
    return 'Booking ID: $id';
  }

  @override
  String reviewSubmitError(String error) {
    return 'Failed to submit booking: $error';
  }

  @override
  String successBody(String vehicle, String shop) {
    return 'Your reservation request for $vehicle has been delivered to $shop. Once approved, you will be notified to submit the advance deposit.';
  }

  @override
  String successReference(String id) {
    return 'Reference: $id';
  }

  @override
  String successWhatsapp(String shop, String id, String vehicle) {
    return 'Hi $shop, this is about my RentalHub booking $id ($vehicle).';
  }

  @override
  String paymentTransferToLock(String amount) {
    return 'Transfer Rs. $amount to lock your vehicle.';
  }

  @override
  String approvedPayToGuarantee(String amount) {
    return 'Pay Rs. $amount to guarantee pickup.';
  }

  @override
  String packageAdvanceDue(String amount) {
    return 'Advance Due: Rs. $amount';
  }

  @override
  String packageSecurityDeposit(String amount) {
    return 'Security Deposit: Rs. $amount';
  }

  @override
  String packageTotal(String amount) {
    return 'Total: Rs. $amount';
  }

  @override
  String tierAdvance(String amount) {
    return 'Advance: Rs. $amount';
  }

  @override
  String paymentCopied(String method) {
    return '$method account copied to clipboard';
  }

  @override
  String passShopNoAddress(String shop) {
    return '$shop — address not listed yet.';
  }

  @override
  String kycSelectedFile(String name) {
    return 'Selected: $name';
  }

  @override
  String kycScanError(String error) {
    return 'CNIC scan failed: $error';
  }

  @override
  String kycStatus(String label) {
    return 'KYC status: $label';
  }

  @override
  String avatarPickerError(String error) {
    return 'Could not open image picker: $error';
  }

  @override
  String onboardingSaveError(String error) {
    return 'Error saving profile: $error';
  }

  @override
  String roleSelectingNote(String role) {
    return 'You are selecting \"$role\". In accordance with National NADRA KYC policies, this role is locked permanently and cannot be changed later.';
  }

  @override
  String roleConfirmed(String role) {
    return 'Account role \"$role\" confirmed.';
  }

  @override
  String authCopyright(int year) {
    return '© $year RentalHub. All rights reserved.';
  }

  @override
  String reputationBasedOnReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count showroom reviews from your completed trips.',
      one: 'Based on 1 showroom review from your completed trips.',
    );
    return '$_temp0';
  }

  @override
  String reputationTrustScoreValue(String score) {
    return 'Trust Score: $score / 5.0';
  }

  @override
  String profileTrustScoreValue(String score) {
    return 'Trust Score: $score / 5.0';
  }

  @override
  String pickerDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String walletAdvancesEscrow(String adv, String esc) {
    return 'Advances Rs. $adv • Escrow Rs. $esc';
  }

  @override
  String ticketPickupDate(int day, int month, int year) {
    return 'Pickup: $day/$month/$year';
  }

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get activeTripTotalFare => 'Total Fare';

  @override
  String emptyRadarNoShops(int radiusKm) {
    return 'No Verified Shops Within $radiusKm km';
  }

  @override
  String get vehiclePerDay => '/ per day';

  @override
  String bookingTotalAmount(String amount) {
    return 'Total: Rs. $amount';
  }

  @override
  String get fleetTitle => 'Fleet Management';

  @override
  String get fleetSubtitle => 'Live Showroom';

  @override
  String get fleetSearchHint => 'Search by name or plate';

  @override
  String get fleetTotalFleet => 'Total Fleet';

  @override
  String fleetTotalCars(int count) {
    return '$count Cars';
  }

  @override
  String fleetAvailableReady(int count) {
    return '$count Ready';
  }

  @override
  String get fleetOnRent => 'On Rent';

  @override
  String fleetOnRentActive(int count) {
    return '$count Active';
  }

  @override
  String get fleetFilterAll => 'All';

  @override
  String get fleetFilterMaintenance => 'Maintenance';

  @override
  String fleetFilterChip(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get fleetLoading => 'Loading your fleet…';

  @override
  String fleetLoadError(String error) {
    return 'Could not load your fleet: $error';
  }

  @override
  String get fleetEmptyTitle => 'No vehicles yet — add your first car';

  @override
  String get fleetEmptyFilterTitle => 'No vehicles found in this filter';

  @override
  String get fleetEmptyMessage => 'Add a car to start taking bookings.';

  @override
  String get fleetEmptyFilterMessage => 'Try a different filter.';

  @override
  String get fleetAddVehicleNow => 'Add Vehicle Now';

  @override
  String get fleetDailySelfDriveRate => 'Daily Self-Drive Rate';

  @override
  String fleetDailyRate(String amount) {
    return 'Rs. $amount/day';
  }

  @override
  String get fleetEditRatesTooltip => 'Edit rates';

  @override
  String get fleetCalendarTooltip => 'Booking calendar';

  @override
  String fleetVehicleSpecs(String transmission, String fuelType, int seats) {
    return '$transmission • $fuelType • $seats Seats';
  }

  @override
  String get dashboardTitle => 'Showroom Revenue & Operations';

  @override
  String get dashboardMyShowroom => 'My Showroom';

  @override
  String get dashboardNotificationsTooltip => 'Notifications';

  @override
  String get dashboardSettingsTooltip => 'Shop settings';

  @override
  String get dashboardRefreshTooltip => 'Refresh';

  @override
  String get dashboardLoading => 'Loading your showroom…';

  @override
  String get dashboardLoadError =>
      'Could not load your dashboard. Check your connection and try again.';

  @override
  String get dashboardNoRevenueLastMonth => 'No revenue last month';

  @override
  String dashboardGrowthLabel(String value) {
    return '$value% vs last month';
  }

  @override
  String get dashboardNoCompletedTrips => 'No completed trips yet';

  @override
  String dashboardSettleRate(int percent) {
    return '$percent% deposits settled';
  }

  @override
  String get dashboardGrossRevenue => 'Gross Revenue (This Month)';

  @override
  String get dashboardActiveOnRent => 'Active on Rent';

  @override
  String get dashboardCompletedTrips => 'Completed Trips';

  @override
  String get dashboardRequestsWaiting => 'Requests Waiting';

  @override
  String get dashboardFleet => 'Fleet';

  @override
  String get dashboardOnTheRoad => 'On the road';

  @override
  String get dashboardNeedsReview => 'Needs your review';

  @override
  String get dashboardAvailableTotal => 'Available / total cars';

  @override
  String dashboardCarsCount(int count) {
    return '$count Cars';
  }

  @override
  String dashboardFinishedCount(int count) {
    return '$count Finished';
  }

  @override
  String get dashboardLedgerTitle => 'Completed Trip Ledger & Settlements';

  @override
  String get dashboardLedgerEmpty =>
      'No trips yet — bookings will appear here.';

  @override
  String get dashboardViewAllRequests => 'View all requests';

  @override
  String get dashboardLedgerVehicle => 'Vehicle';

  @override
  String get dashboardLedgerCustomer => 'Customer';

  @override
  String get dashboardQuickAddCar => 'Add Car';

  @override
  String get dashboardQuickScanQr => 'Scan QR';

  @override
  String get dashboardQuickNewBooking => 'New Booking';

  @override
  String get dashboardQuickFinance => 'Finance';

  @override
  String get requestsTitle => 'Booking Requests Triage';

  @override
  String requestsAwaitingReview(int count) {
    return '$count Requests Awaiting Review';
  }

  @override
  String get requestsScanQrTooltip => 'Scan booking QR';

  @override
  String get requestsRefreshTooltip => 'Refresh';

  @override
  String get requestsLoading => 'Loading booking requests…';

  @override
  String get requestsLoadError =>
      'Could not load booking requests. Check your connection and try again.';

  @override
  String get requestsFilterNew => 'New';

  @override
  String get requestsFilterProof => 'Proof';

  @override
  String requestsFilterChip(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get requestsEmptyProof => 'No payment proofs waiting for verification';

  @override
  String get requestsEmptyApproved =>
      'No approved bookings waiting for payment';

  @override
  String get requestsEmptyNew => 'No pending booking requests';

  @override
  String get requestsEmptyMessage =>
      'New requests will appear here for review.';

  @override
  String get requestsRejectTitle => 'Reject this request?';

  @override
  String get requestsRejectReasonLabel => 'Reason (required)';

  @override
  String get requestsRejectReasonHint =>
      'e.g. Vehicle is not available on those dates';

  @override
  String get requestsRejectButton => 'Reject Request';

  @override
  String requestsApproved(String id) {
    return 'Booking #$id approved! Payment instructions sent to customer.';
  }

  @override
  String requestsApprovalFailed(String error) {
    return 'Approval failed: $error';
  }

  @override
  String requestsRejected(String id) {
    return 'Booking #$id rejected.';
  }

  @override
  String requestsDeclineFailed(String error) {
    return 'Decline failed: $error';
  }

  @override
  String get requestsCustomerFallback => 'Customer';

  @override
  String get requestsRequestedCar => 'Requested Car';

  @override
  String get requestsWithChauffeur => 'With Chauffeur';

  @override
  String get requestsVerifyProof => 'Verify Payment Proof';

  @override
  String get requestsDecline => 'Decline';

  @override
  String get requestsApprovePay => 'Approve';

  @override
  String get requestsStatusRequested => 'Requested';

  @override
  String get calendarTitle => 'Booking Calendar';

  @override
  String get calendarFree => 'Free';

  @override
  String get calendarRequested => 'Requested';

  @override
  String get calendarConfirmed => 'Confirmed';

  @override
  String get calendarPast => 'Past';

  @override
  String get calendarTapDayHint => 'Tap a day to see its bookings.';

  @override
  String calendarBookingsOn(int day, int month, int year) {
    return 'Bookings on $day/$month/$year';
  }

  @override
  String get calendarNoBookingsDay => 'No bookings on this day.';

  @override
  String get calendarMonthJanuary => 'January';

  @override
  String get calendarMonthFebruary => 'February';

  @override
  String get calendarMonthMarch => 'March';

  @override
  String get calendarMonthApril => 'April';

  @override
  String get calendarMonthMay => 'May';

  @override
  String get calendarMonthJune => 'June';

  @override
  String get calendarMonthJuly => 'July';

  @override
  String get calendarMonthAugust => 'August';

  @override
  String get calendarMonthSeptember => 'September';

  @override
  String get calendarMonthOctober => 'October';

  @override
  String get calendarMonthNovember => 'November';

  @override
  String get calendarMonthDecember => 'December';

  @override
  String get calendarWeekdayMon => 'Mon';

  @override
  String get calendarWeekdayTue => 'Tue';

  @override
  String get calendarWeekdayWed => 'Wed';

  @override
  String get calendarWeekdayThu => 'Thu';

  @override
  String get calendarWeekdayFri => 'Fri';

  @override
  String get calendarWeekdaySat => 'Sat';

  @override
  String get calendarWeekdaySun => 'Sun';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarSelectDay(int day) {
    return 'Select day $day';
  }

  @override
  String get addVehicleModelRequired => 'Please specify vehicle model variant.';

  @override
  String get addVehiclePlateRequired =>
      'Registration plate number is required.';

  @override
  String addVehicleAdded(String name) {
    return '$name added to showroom fleet!';
  }

  @override
  String get addVehicleStep1Title => 'Add Vehicle - Specs';

  @override
  String get addVehicleStep2Title => 'Car Photos & Docs';

  @override
  String get addVehicleStep3Title => 'Rental Rates & Policy';

  @override
  String get addVehicleStep4Title => 'Review & Publish';

  @override
  String get addVehicleStep1Subtitle => 'Capacity, AC, features & specs';

  @override
  String get addVehicleStep2Subtitle => '4-angle photos, book & excise tax';

  @override
  String get addVehicleStep3Subtitle => 'Hourly rates, deposit & fuel policy';

  @override
  String get addVehicleStep4Subtitle => 'Verify vehicle details before listing';

  @override
  String addVehicleStepCounter(int step) {
    return 'Step $step of 4';
  }

  @override
  String get addVehicleConfirmPublish => 'Confirm & Publish Vehicle';

  @override
  String get addVehicleNextStep => 'Next Step';

  @override
  String get addVehicleStepperSpecs => 'Vehicle Specs';

  @override
  String get addVehicleStepperPhotos => 'Photos & Docs';

  @override
  String get addVehicleStepperRates => 'Rates & Policy';

  @override
  String get addVehicleStepperReview => 'Review';

  @override
  String get addVehicleMakeBrand => 'Make / Brand';

  @override
  String get addVehicleModelVariant => 'Model Variant';

  @override
  String get addVehicleModelHint => 'e.g. Corolla Altis 1.8 Grande';

  @override
  String get addVehicleManufacturingYear => 'Manufacturing Year';

  @override
  String get addVehicleExteriorColor => 'Exterior Color';

  @override
  String get addVehicleBodyCategory => 'Body Category';

  @override
  String get addVehicleRegistrationNumber => 'Vehicle Registration Number';

  @override
  String get addVehicleTransmission => 'Transmission';

  @override
  String get addVehicleAutomatic => 'Automatic';

  @override
  String get addVehicleManual => 'Manual';

  @override
  String get addVehicleFuelType => 'Fuel Type';

  @override
  String get addVehicleSeatingCapacity => 'Vehicle Seating Capacity';

  @override
  String addVehicleSeatsCount(int count) {
    return '$count Seats';
  }

  @override
  String get addVehicleAcTitle => 'Air Conditioning (Full AC)';

  @override
  String get addVehicleAcSubtitle => 'Vehicle equipped with working chilled AC';

  @override
  String get addVehicleExtraFeatures => 'Extra Features (Shown on Car Detail)';

  @override
  String get addVehicleExtraFeaturesHint =>
      'Select amenities included with this vehicle to attract more renters.';

  @override
  String get addVehiclePhotosTitle => 'Vehicle 4-Angle Photos';

  @override
  String get addVehiclePhotosHint =>
      'Upload photos using Camera or Gallery. Tap to change or remove.';

  @override
  String get addVehicleFrontPhotoRequired =>
      'A front photo is required before publishing this vehicle.';

  @override
  String get addVehiclePhotoFront => 'Front View';

  @override
  String get addVehiclePhotoRear => 'Rear View';

  @override
  String get addVehiclePhotoSide => 'Side Profile';

  @override
  String get addVehiclePhotoInterior => 'Interior & Dash';

  @override
  String get addVehicleLegalDocs => 'Legal Documents';

  @override
  String get addVehicleDocRegBook => 'Vehicle Registration Book / Smart Card';

  @override
  String get addVehicleDocRegBookHint => 'Original ownership document required';

  @override
  String get addVehicleDocTokenTax => 'Excise Token Tax Paid Receipt';

  @override
  String get addVehicleDocTokenTaxHint =>
      'Must be valid for current fiscal year';

  @override
  String get addVehicleDocInsurance =>
      'Insurance / Tracker Certificate (Optional)';

  @override
  String get addVehicleDocInsuranceHint =>
      'Provides verified VIP badge in search';

  @override
  String get addVehicleDurationPackages => 'Duration Packages (Hourly & Daily)';

  @override
  String get addVehicleDurationPackagesHint =>
      'Enable packages and edit rates in PKR per booking tier.';

  @override
  String get addVehicleRate1Hour => '1 Hour Rate';

  @override
  String get addVehicleRate3Hours => '3 Hours Rate';

  @override
  String get addVehicleRate6Hours => '6 Hours Rate';

  @override
  String get addVehicleRateFullDay => 'Full Day (24h) Rate';

  @override
  String get addVehicleRateWeekly => 'Weekly (7 Days) Rate';

  @override
  String get addVehicleServiceType => 'Service Type & Driver Options';

  @override
  String get addVehicleSelfDriveService => 'Self-Drive Service';

  @override
  String get addVehicleSelfDriveHint =>
      'Customer drives the vehicle themselves';

  @override
  String get addVehicleWithDriverService => 'With-Driver Service';

  @override
  String get addVehicleWithDriverHint => 'Shop provides experienced chauffeur';

  @override
  String get addVehicleDriverAllowance => 'Driver Daily Allowance:';

  @override
  String get addVehiclePerDaySuffix => '/day';

  @override
  String get addVehicleDepositPolicies => 'Security Deposit & Rental Policies';

  @override
  String get addVehicleSecurityDepositSelfDrive =>
      'Security Deposit (Self-Drive)';

  @override
  String get addVehicleSecurityDepositHint =>
      'Refunded on car return in clean condition';

  @override
  String get addVehicleAdvanceFee => 'Advance Booking Fee';

  @override
  String get addVehicleAdvanceHint => 'Required up front to lock slot';

  @override
  String get addVehicleExtraHourCharge => 'Extra Hour Overstay Charge';

  @override
  String get addVehicleExtraHourHint => 'Billed per hour past scheduled return';

  @override
  String get addVehiclePerHourSuffix => '/hr';

  @override
  String get addVehicleFuelPolicy => 'Fuel Policy';

  @override
  String get addVehicleFuelPolicyHint => 'Condition expected upon return';

  @override
  String get addVehicleReviewGear => 'Gear';

  @override
  String get addVehicleReviewAuto => 'Auto';

  @override
  String get addVehicleReviewFuel => 'Fuel';

  @override
  String get addVehicleReviewSeats => 'Seats';

  @override
  String get addVehicleReviewAc => 'AC';

  @override
  String get addVehicleReviewFullAc => 'Full AC';

  @override
  String get addVehicleReviewSelfDriveRate => 'Self-Drive Rate';

  @override
  String get addVehicleReviewWithDriverRate => 'With-Driver Rate';

  @override
  String get addVehicleReviewNotOffered => 'Not Offered';

  @override
  String addVehicleReviewDailyRate(String amount) {
    return 'Rs. $amount/day';
  }

  @override
  String addVehicleReviewOverstayRate(String amount) {
    return 'Rs. $amount/hr';
  }

  @override
  String get addVehicleReviewDeposit => 'Deposit';

  @override
  String get addVehicleReviewAdvance => 'Advance';

  @override
  String get addVehicleReviewOverstay => 'Overstay';

  @override
  String get addVehicleReviewBanner =>
      'This car will be immediately available in your fleet catalog and visible to nearby customers upon approval.';

  @override
  String get pricingDriveModeAvailability => 'Drive Mode Availability';

  @override
  String get pricingRentalPackages => 'Rental Packages';

  @override
  String get pricingPackagesHint =>
      'Switch a package off to hide it from customers.';

  @override
  String get pricingPolicyTitle => 'Pricing Policy';

  @override
  String get pricingSavedSuccess => 'Pricing matrix updated in showroom!';

  @override
  String pricingSaveFailed(String error) {
    return 'Failed to update rates: $error';
  }

  @override
  String get pricingTitle => 'Vehicle Pricing Matrix';

  @override
  String rateMatrixInvalidField(String field) {
    return 'Enter a valid number for $field';
  }

  @override
  String get pricingSaving => 'Saving Matrix...';

  @override
  String get pricingSave => 'Save Pricing Matrix';

  @override
  String get pricingUnsavedTitle => 'Discard unsaved prices?';

  @override
  String get pricingUnsavedBody => 'Your edited prices have not been saved.';

  @override
  String get unsavedChangesTitle => 'Discard unsaved changes?';

  @override
  String get unsavedChangesBody => 'Your changes have not been saved.';

  @override
  String get pricingSelfDriveAllowed => 'Self-Drive Allowed';

  @override
  String get pricingSelfDriveHint =>
      'Requires original NADRA CNIC + security deposit';

  @override
  String get pricingChauffeurAllowed => 'Chauffeur Service Allowed';

  @override
  String get pricingChauffeurHint => 'Showroom driver assigned to booking';

  @override
  String get pricingPackage1h => '1-Hour City Commute';

  @override
  String get pricingPackage3h => '3-Hour Airport / Quick Trip';

  @override
  String get pricingPackage6h => '6-Hour Express Rate';

  @override
  String get pricingPackage12h => '12-Hour Half Day';

  @override
  String get pricingPackage24h => 'In-City Daily (24h)';

  @override
  String get pricingPackageWeekly => 'Weekly Package (7 Days)';

  @override
  String pricingKmIncluded(int km) {
    return '$km km included';
  }

  @override
  String get pricingOutOfCityDaily => 'Out-of-City Daily (24h)';

  @override
  String get pricingOutOfCityDailyCap => '300 km included + tracker cleared';

  @override
  String get pricingWithDriverSurcharge => 'With-Driver Surcharge (per day)';

  @override
  String get pricingWithDriverSurchargeCap =>
      'Added on top of the package price';

  @override
  String get pricingSecurityDeposit => 'Security Deposit';

  @override
  String get pricingSecurityDepositCap => 'Refundable after return inspection';

  @override
  String get pricingAdvanceRequired => 'Advance Required';

  @override
  String get pricingAdvanceCap => 'Due before the booking is confirmed';

  @override
  String get pricingExtraHourCharge => 'Extra Hour Charge';

  @override
  String get pricingExtraHourCap => 'Charged for late returns';

  @override
  String get pricingExtraKmCharge => 'Extra KM Charge';

  @override
  String get pricingExtraKmCap => 'Charged beyond the included km';

  @override
  String get pricingOutOfCityKmAllowance =>
      'Out-of-City KM Allowance (per day)';

  @override
  String get pricingOutOfCityKmCap =>
      'Tracker clearance required beyond the city';

  @override
  String get pricingFuelPolicy => 'Fuel Policy';

  @override
  String get fixedRoutesTitle => 'Fixed Out-of-City Routes';

  @override
  String get fixedRoutesSubtitle => 'One fixed price per destination';

  @override
  String get fixedRoutesDeleteTooltip => 'Delete fixed route';

  @override
  String get fixedRoutesPriceRequired => 'Enter a fixed price above zero.';

  @override
  String get fixedRoutesSaveFailed =>
      'Could not save the fixed route. Please try again.';

  @override
  String get fixedRoutesDeleteFailed =>
      'Could not delete the fixed route. Please try again.';

  @override
  String get fixedRoutesDistanceRequired => 'Enter the distance in km.';

  @override
  String get fixedRoutesLoadError =>
      'Could not load your fixed routes. Check your connection and try again.';

  @override
  String get fixedRoutesEmpty =>
      'No fixed routes yet — add your first destination below.';

  @override
  String get fixedRouteDuplicate => 'This route already exists';

  @override
  String fixedRouteSummary(int km, String price) {
    return '$km km • Rs. $price fixed';
  }

  @override
  String fixedRouteChip(String city, String price) {
    return '$city • Rs. $price';
  }

  @override
  String get fixedRouteAddTitle => 'Add a route';

  @override
  String get fixedRouteFromCity => 'From (city)';

  @override
  String get fixedRouteToCity => 'To (city)';

  @override
  String get fixedRouteDistance => 'Distance (km)';

  @override
  String get fixedRoutePrice => 'Fixed price (Rs.)';

  @override
  String get fixedRouteAddButton => 'Add Fixed Route';

  @override
  String get fleetAddVehicle => 'Add Vehicle';

  @override
  String amountRs(String amount) {
    return 'Rs. $amount';
  }

  @override
  String get customersTitle => 'Customers';

  @override
  String customersCount(int count) {
    return '$count customers';
  }

  @override
  String get customersLoading => 'Loading…';

  @override
  String get customersLoadingMessage => 'Loading your customers…';

  @override
  String get customersSearchHint => 'Search name, phone or CNIC';

  @override
  String get customersLoadError =>
      'Could not load your customers. Check your connection and try again.';

  @override
  String get customersEmptyTitle => 'No customers yet';

  @override
  String get customersEmptyMessage => 'Scan a CNIC or take a walk-in booking.';

  @override
  String get customersScanCnic => 'Scan a CNIC';

  @override
  String get customersBlacklisted => 'Blacklisted';

  @override
  String customersBookingsLine(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings',
      one: '$count booking',
    );
    return '$_temp0 • Rs. $amount';
  }

  @override
  String get customersNoBookings =>
      'No bookings yet — saved from a CNIC scan or as a guarantor.';

  @override
  String get customersScanTitle => 'KYC & Blacklist Radar';

  @override
  String get addCustomerTitle => 'Add Customer';

  @override
  String get addCustomerName => 'Full name';

  @override
  String get addCustomerCnic => 'CNIC Number';

  @override
  String get addCustomerPhone => 'Phone number';

  @override
  String get addCustomerSaved => 'Customer saved';

  @override
  String get addCustomerSave => 'Save customer';

  @override
  String get addCustomerFullNameRequired => 'Full name is required';

  @override
  String get addCustomerHelper =>
      'Guarantor can be added later from the booking flow';

  @override
  String get customersScanSubtitle => 'RentalHub shared blacklist • Real-time';

  @override
  String get customersScanTribunalPolicy => 'Tribunal Policy';

  @override
  String get customersScanTribunalInfo =>
      'Every RentalHub shop shares fraud reports in one blacklist.';

  @override
  String get customersScanViewAll => 'View All Customers';

  @override
  String get customersScanInvalidCnic =>
      'Please enter a valid 13-digit Pakistani CNIC';

  @override
  String customersScanLookupFailed(String error) {
    return 'Verification lookup failed: $error';
  }

  @override
  String customersScanFailed(String error) {
    return 'CNIC scan failed: $error';
  }

  @override
  String get customersScanUnreadable =>
      'Couldn\'t read the card — type the CNIC manually.';

  @override
  String get customersScanDeclined =>
      'Customer flagged and declined entry into showroom.';

  @override
  String get customersScanFallbackReason =>
      'Reported in RentalHub\'s shared blacklist';

  @override
  String get customersScanFallbackDescription =>
      'Severe fraud / non-payment incident flagged.';

  @override
  String get customersRatingTitle => 'Customer Reputation & Review';

  @override
  String get customersRatingFallback => 'Customer Review';

  @override
  String get customersRatingFeedbackTitle => 'Customer Performance Feedback';

  @override
  String get customersRatingPunctuality => 'Return Punctuality & Timekeeping';

  @override
  String get customersRatingPunctualityHint =>
      'Vehicle returned as per agreed contract schedule';

  @override
  String get customersRatingCare => 'Vehicle Care & Cleanliness';

  @override
  String get customersRatingCareHint =>
      'Interior cleanliness and scratch-free return';

  @override
  String get customersRatingBehavior => 'Overall Behavior & Civility';

  @override
  String get customersRatingBehaviorHint =>
      'Professionalism and adherence to showroom policies';

  @override
  String get rateCustomerSelectStars => 'Select at least one star rating';

  @override
  String get customersRatingCommentHint =>
      'Add optional feedback notes for community showroom records...';

  @override
  String get customersRatingFlagTitle => 'Flag Customer to Shared Blacklist';

  @override
  String customersRatingFlagDescription(String reason) {
    return 'Customer flagged during return settlement for $reason.';
  }

  @override
  String get customersRatingFlagNoCnic =>
      'Needs the customer CNIC on this booking — none is recorded, so a report cannot be filed from here.';

  @override
  String get customersRatingFlagVisible =>
      'Other showrooms using RentalHub can see this report';

  @override
  String get customersRatingReasonLabel => 'Reason Category for Tribunal:';

  @override
  String get customersRatingReasonPayment =>
      'Payment Default / Refusal to Settle';

  @override
  String get customersRatingReasonBorder => 'Unauthorized Border Crossing';

  @override
  String get customersRatingReasonAbuse => 'Vehicle Abuse / Abandonment';

  @override
  String get customersRatingReasonFake => 'Fake Identity / Impersonation';

  @override
  String get customersRatingSubmitting => 'Recording Rating...';

  @override
  String get customersRatingSubmit => 'Submit Rating & Close Trip';

  @override
  String get customersRatingSavedOffline =>
      'Rating saved on this device — it will sync when you are back online.';

  @override
  String get customersRatingSavedBlacklisted =>
      'Rating saved and the customer was reported to the shared blacklist.';

  @override
  String get customersRatingSaved =>
      'Your rating of the customer has been saved.';

  @override
  String customersRatingSubmitFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get customersCnicReviewTitle => 'Review Scanned CNIC';

  @override
  String get customersCnicReviewSubtitle => 'Correct anything OCR misread';

  @override
  String get customersCnicFatherName => 'Father\'s Name';

  @override
  String get customersCnicNumber => 'CNIC Number';

  @override
  String get customersCnicDob => 'Date of Birth (dd.mm.yyyy)';

  @override
  String get cnicReviewDateInvalid => 'Enter the date as DD.MM.YYYY.';

  @override
  String get customersCnicExpiry => 'CNIC Expiry (dd.mm.yyyy)';

  @override
  String get customersCnicPhone => 'Phone Number';

  @override
  String get customersCnicAddress => 'Address (from back of card)';

  @override
  String get customersCnicScanBack => 'Scan Back of CNIC (address)';

  @override
  String get customersCnicSave => 'Save Customer & Check Blacklist';

  @override
  String get customersCnicNoAddress =>
      'No address read from the back of the card.';

  @override
  String customersCnicBackScanFailed(String error) {
    return 'Back scan failed: $error';
  }

  @override
  String get customersCnicNamePhoneRequired =>
      'Name and phone are required to save the customer.';

  @override
  String customersCnicSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get blacklistSubtitle => 'Shared with every shop • Tribunal reviewed';

  @override
  String get blacklistReportTitle => 'Report a customer';

  @override
  String get blacklistCustomerCnic => 'Customer CNIC';

  @override
  String get blacklistCustomerPhone => 'Customer phone';

  @override
  String get blacklistReasonLabel => 'Reason';

  @override
  String get blacklistReasonNonPayment => 'Non-payment';

  @override
  String get blacklistReasonCarDamage => 'Car damage';

  @override
  String get blacklistReasonLateReturn => 'Late return';

  @override
  String get blacklistReasonFraud => 'Fraud / fake documents';

  @override
  String get blacklistReasonImpoundment => 'Default & Car Impoundment';

  @override
  String get blacklistReasonOther => 'Other';

  @override
  String get blacklistWhatHappened => 'What happened? (dates, car, amount)';

  @override
  String get blacklistReportButton => 'Report to Blacklist';

  @override
  String blacklistMyReports(int count) {
    return 'My reports ($count)';
  }

  @override
  String get blacklistNoReports =>
      'No reports from this shop yet. Reports cannot be undone by the shop — only the tribunal admin can revert one.';

  @override
  String get blacklistEnterCnic =>
      'Enter the full 13-digit CNIC of the customer.';

  @override
  String get blacklistDescribe =>
      'Describe what happened — the tribunal reads this.';

  @override
  String get blacklistReported =>
      'Reported. The CNIC is now flagged for every shop.';

  @override
  String get blacklistLoadError =>
      'Could not load blacklist reports. Please try again.';

  @override
  String blacklistReportFailed(String error) {
    return 'Report failed: $error';
  }

  @override
  String get blacklistReverted => 'Reverted';

  @override
  String get financeSubtitle => 'Accounts, ledger and profit';

  @override
  String get financeThisMonth => 'This month';

  @override
  String get financeLastMonth => 'Last month';

  @override
  String get financeAllTime => 'All time';

  @override
  String financeNetAmount(String amount) {
    return 'Net Rs. $amount';
  }

  @override
  String financeMonthBreakdown(
      String bookings, String income, String expenses) {
    return 'Bookings Rs. $bookings • Other income Rs. $income • Expenses Rs. $expenses';
  }

  @override
  String get financeCustomerDues => 'Customer dues';

  @override
  String get financeCashClosing => 'Cash closing';

  @override
  String get financeCarPnl => 'Car P&L';

  @override
  String get financeIncome => 'Income';

  @override
  String get financeExpense => 'Expense';

  @override
  String get financeCategoryRent => 'Rent';

  @override
  String get financeCategoryFuel => 'Fuel';

  @override
  String get financeCategorySalary => 'Salary';

  @override
  String get financeCategoryPartnerShare => 'Partner share';

  @override
  String get financeCategoryDepositRefund => 'Deposit refund';

  @override
  String get financeCategoryLabel => 'Category';

  @override
  String get financeNoteOptional => 'Note (optional)';

  @override
  String financeLedgerAmount(String sign, String amount) {
    return '$sign Rs. $amount';
  }

  @override
  String get financeAccountTypeCash => 'Cash';

  @override
  String get financeAccountTypeBank => 'Bank';

  @override
  String get financeAccountTypeJazzCash => 'JazzCash';

  @override
  String get financeAccountTypeEasyPaisa => 'EasyPaisa';

  @override
  String get financeAccountTypeLabel => 'Type';

  @override
  String get financeAccountsTitle => 'Accounts';

  @override
  String get financeAccountsEmpty => 'No accounts yet';

  @override
  String get financeAddAccount => 'Add account';

  @override
  String get financeLedgerTitle => 'Ledger';

  @override
  String get financeAddEntry => 'Add entry';

  @override
  String get financeLedgerEmpty =>
      'No entries yet — record your first income or expense.';

  @override
  String get financeAccountFallback => 'Account';

  @override
  String get financeSecurityDeposits => 'Security Deposits';

  @override
  String get financeDepositsHeld => 'Held now';

  @override
  String get financeDepositsRefunded => 'Refunded in full';

  @override
  String get financeDepositsDeducted => 'Deducted at return';

  @override
  String financeDepositsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deposits',
      one: '$count deposit',
    );
    return '$_temp0';
  }

  @override
  String get financePartners => 'Partners';

  @override
  String get financeAddPartner => 'Add partner';

  @override
  String get financePartnersEmpty =>
      'No partners yet — add one to record their share.';

  @override
  String financePartnerShareLine(int percent) {
    return '$percent% of profit';
  }

  @override
  String get financeSaveAccount => 'Save account';

  @override
  String get financeAccountName => 'Account name';

  @override
  String get financeSavePartner => 'Save partner';

  @override
  String get financePartnerName => 'Partner name';

  @override
  String get financePartnerShare => 'Share (%)';

  @override
  String get financeAddTransfer => 'Add ledger entry';

  @override
  String get financeAmountRs => 'Amount (Rs.)';

  @override
  String get financeVehicleOptional => 'Vehicle (optional — for car P&L)';

  @override
  String get financeNoVehicle => 'No vehicle';

  @override
  String get financeNoteHint => 'e.g. driver salary — Ahmed';

  @override
  String get financeSaveEntry => 'Save entry';

  @override
  String get financeClosingExpected => 'Expected in till today';

  @override
  String financeClosingOpening(String opening, String difference) {
    return 'Opening Rs. $opening • Difference Rs. $difference';
  }

  @override
  String financeClosingCounted(String counted, String difference) {
    return 'Counted Rs. $counted • Diff Rs. $difference';
  }

  @override
  String get financePnlTitle => 'P&L Statement';

  @override
  String get financePnlBookingRevenue => 'Booking revenue';

  @override
  String get financePnlOtherIncome => 'Other income';

  @override
  String get financePnlExpenses => 'Expenses';

  @override
  String get financePnlNetProfit => 'Net profit';

  @override
  String get pnlLoss => 'Loss';

  @override
  String get financePnlExport => 'Export P&L as CSV (opens in Excel)';

  @override
  String get financeCarPnlSubtitle => 'One car, all its money';

  @override
  String get financeCarPnlNoCars => 'No cars in the fleet yet.';

  @override
  String get financeCarPnlTagged => 'Tagged entries';

  @override
  String get financeCarPnlNoTagged =>
      'Nothing tagged to this car yet — tag an entry in the ledger.';

  @override
  String financeCarPnlBreakdown(
      String revenue, String income, String expenses) {
    return 'Booking revenue Rs. $revenue • Other income Rs. $income • Expenses Rs. $expenses';
  }

  @override
  String get financeClosingSubtitle => 'Count the till, close the day';

  @override
  String get financeClosingCountedLabel => 'Counted cash (Rs.)';

  @override
  String get financeClosingSaving => 'Closing...';

  @override
  String get financeClosingButton => 'Close the day';

  @override
  String get financeClosingPast => 'Past closings';

  @override
  String get financeClosingEmpty => 'No closings yet.';

  @override
  String get financeClosingEnterCounted => 'Enter the counted cash first.';

  @override
  String financeClosingClosed(String difference) {
    return 'Day closed — difference Rs. $difference.';
  }

  @override
  String cashClosingShortBy(String amount) {
    return 'Short by Rs. $amount';
  }

  @override
  String cashClosingOverBy(String amount) {
    return 'Over by Rs. $amount';
  }

  @override
  String get financeDuesTitle => 'Customer Dues';

  @override
  String financeDuesOutstanding(String amount) {
    return 'Rs. $amount outstanding';
  }

  @override
  String get financeDuesEmpty => 'No outstanding dues. All clear.';

  @override
  String financeDuesBookingsLine(int count, String phone) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings',
      one: '$count booking',
    );
    return '$_temp0 • $phone';
  }

  @override
  String get financeDuesNoPhone => 'no phone';

  @override
  String financeDuesLastReminded(int day, int month, int year) {
    return 'Last reminded $day/$month/$year';
  }

  @override
  String financeDuesLastRemindedDate(String date) {
    return 'Last reminded $date';
  }

  @override
  String get financeDuesRemind => 'Remind on WhatsApp';

  @override
  String get financeDuesRemindAgain => 'Remind again on WhatsApp';

  @override
  String get financeDuesNoPhoneError => 'No phone number for this customer.';

  @override
  String financeDuesReminderMessage(String name, String due) {
    return 'Assalam-o-Alaikum $name, your RentalHub balance of Rs. $due is pending. Please clear it at your earliest convenience. Thank you!';
  }

  @override
  String get financeDuesWhatsappFailed => 'Could not open WhatsApp.';

  @override
  String get financeDuesReminderSent =>
      'WhatsApp opened — send the reminder from the chat.';

  @override
  String get financeDuesAutoNote =>
      'Automated WhatsApp reminders (every 3 days) need the WhatsApp Business setup — Phase I.';

  @override
  String get handoverTitle => 'Vehicle Handover & Inspection';

  @override
  String get handoverOdometerInvalid =>
      'Please enter a valid odometer reading.';

  @override
  String get handoverSignRequired =>
      'Both customer and host must sign on the pads before vehicle departure.';

  @override
  String get handoverCertified =>
      'Handover certified! Digital A4 rental contract generated.';

  @override
  String get handoverShopNameRequired =>
      'The shop name could not be loaded. Retry the load before certifying the handover.';

  @override
  String handoverCompleteFailed(String error) {
    return 'Handover completion failed: $error';
  }

  @override
  String get handoverIssuing => 'Issuing Digital Contract...';

  @override
  String get handoverCertify => 'Certify Handover & Generate Contract';

  @override
  String get handoverTelemetryTitle => 'Vehicle Telemetry Inspection';

  @override
  String get handoverOdometerLabel => 'Odometer Reading (KM):';

  @override
  String get handoverOdometerHint => 'e.g. 45200';

  @override
  String get handoverFuelLabel => 'Fuel Level Gauge:';

  @override
  String get handoverFuelQuarter => '1/4 (25%)';

  @override
  String get handoverFuelHalf => '2/4 (50%)';

  @override
  String get handoverFuelThreeQuarter => '3/4 (75%)';

  @override
  String get handoverFuelFull => '4/4 (Full)';

  @override
  String get handoverSignaturesTitle => 'Dual Legal Endorsement & Signatures';

  @override
  String get handoverCustomerSignature => 'Customer / Hirer Digital Signature';

  @override
  String get handoverCustomerSignatureHint =>
      'Certifies physical receipt of car & documents';

  @override
  String get handoverHostSignature => 'Showroom Host / Manager Signature';

  @override
  String get handoverHostSignatureHint =>
      'Authorized release by showroom representative';

  @override
  String get handoverClear => 'Clear';

  @override
  String get handoverDamageTitle => 'Damage & Condition Notes';

  @override
  String get handoverDamageSubtitle =>
      'Note every scratch, dent or missing item now — this is what the return inspection compares against.';

  @override
  String get handoverDamageHint => 'e.g. Scratch on right door';

  @override
  String get handoverAdd => 'Add';

  @override
  String handoverNotedAt(String notes) {
    return 'Noted at handover: $notes';
  }

  @override
  String get returnTitle => 'Vehicle Return & Settlement';

  @override
  String returnTripAudit(String id) {
    return 'Trip Audit #$id';
  }

  @override
  String get returnOdometerInvalid => 'Enter the return odometer reading.';

  @override
  String returnOdometerBelow(int odometer) {
    return 'The return reading cannot be below the handover reading ($odometer KM).';
  }

  @override
  String returnSettled(String refund) {
    return 'Vehicle returned! Deposit settled — Rs. $refund refunded.';
  }

  @override
  String returnCustomerOwes(String amount) {
    return 'Customer owes Rs. $amount';
  }

  @override
  String returnFinalizeFailed(String error) {
    return 'Finalizing return failed: $error';
  }

  @override
  String get returnTelemetryTitle => 'Return Telemetry Inspection';

  @override
  String get returnNewDamageTitle => 'New Damage Found at Return';

  @override
  String get returnNewDamageSubtitle =>
      'Only damage that was not noted at handover — this is what the charge below covers.';

  @override
  String get returnDamageChargeLabel => 'Damage charge (Rs.)';

  @override
  String get returnDamageChargeHint => '0 if nothing new was found';

  @override
  String get returnFinalizing => 'Finalizing Settlement...';

  @override
  String get returnFinalize => 'Finalize Return & Settle Deposit';

  @override
  String get returnReceiptTitle => 'Deposit & Return Balance Settlement';

  @override
  String get returnReceiptTotalKm => 'Total Kilometers Driven';

  @override
  String get returnReceiptAllowance => 'Allowed KM Allowance';

  @override
  String returnReceiptExcessPenalty(int excess, String rate) {
    return 'Excess KM Penalty ($excess km × Rs. $rate)';
  }

  @override
  String get returnReceiptFuelDeficit => 'Fuel Level Deficit';

  @override
  String get returnReceiptOvertime => 'Late Overtime Fee';

  @override
  String get returnReceiptDamage => 'Damage Found at Return';

  @override
  String get returnReceiptDepositHeld => 'Initial Security Deposit Held';

  @override
  String get returnReceiptTotalDeductions =>
      'Total Incident / Penalty Deductions';

  @override
  String returnReceiptDeductionsAmount(String amount) {
    return '- Rs. $amount';
  }

  @override
  String get returnReceiptNetRefund => 'Net Refund to Customer';

  @override
  String get returnPerKmActualFare => 'Per-km fare (actual km)';

  @override
  String get returnPerKmExtraDue => 'Extra fare due';

  @override
  String get returnPerKmRefundDue => 'Fare refund due';

  @override
  String get contractTitle => 'Digital Rental Contract';

  @override
  String contractLegalRef(String id) {
    return 'Legal Agreement Ref: #$id';
  }

  @override
  String get contractSharePdf => 'Share PDF';

  @override
  String get contractPrintPdf => 'Print PDF';

  @override
  String get contractPdfUnavailable =>
      'The agreement PDF is not available yet.';

  @override
  String get contractNotAvailable => 'Agreement not available yet';

  @override
  String contractShareText(String id) {
    return 'Rental agreement #$id';
  }

  @override
  String get contractScanVerify =>
      'Scan to verify this agreement — the page shows the booking, the shop and the signed PDF.';

  @override
  String get contractProceedReturn => 'Proceed to Return & Settlement';

  @override
  String get contractAgencyLine =>
      'Govt. Registered Commercial Motor Car Rental Agency';

  @override
  String get contractCertifiedTitle => 'RENTAL AGREEMENT';

  @override
  String get contractFieldAgreementNo => 'Agreement No:';

  @override
  String get contractFieldHirer => 'Hirer / Customer:';

  @override
  String get contractFieldContact => 'Customer Contact:';

  @override
  String get contractFieldCnic => 'CNIC:';

  @override
  String get contractFieldVehicle => 'Rented Vehicle:';

  @override
  String get contractFieldPackage => 'Package Tier:';

  @override
  String get contractFieldOdometer => 'Departure Odometer:';

  @override
  String get contractFieldFuel => 'Handover Fuel Gauge:';

  @override
  String get contractFieldTotalPaid => 'Total Rental Paid:';

  @override
  String get contractFieldDeposit => 'Security Deposit:';

  @override
  String get contractWalkInCustomer => 'Walk-in Customer';

  @override
  String get contractNotProvided => 'Not provided';

  @override
  String get contractChauffeur => 'Chauffeur';

  @override
  String contractDepositRefundable(String amount) {
    return 'Rs. $amount (refundable)';
  }

  @override
  String get contractTermsTitle =>
      'Legal Terms & Conditions (Pakistan Jurisdiction):';

  @override
  String get contractTerm1 =>
      '1. The vehicle shall be used within city limits unless an out-city rate has been agreed.';

  @override
  String get contractTerm2 =>
      '2. Traffic challans, e-tickets and fuel consumed are sole liability of the hirer.';

  @override
  String get contractTerm3 =>
      '3. Any default will result in immediate non-bailable FIR and National Tribunal Blacklist listing.';

  @override
  String get contractHirerSignature => 'Hirer Signature';

  @override
  String get contractSignedOnPad => 'Signed on the pad';

  @override
  String get contractHostSignature => 'Host Seal & Signature';

  @override
  String get contractAuthorizedManager => 'Authorized Agency Manager';

  @override
  String get paymentVerificationTitle => 'Verify Payment Proof';

  @override
  String paymentVerificationBooking(String id) {
    return 'Booking #$id';
  }

  @override
  String paymentVerificationConfirmed(String id) {
    return 'Payment confirmed — booking #$id is paid.';
  }

  @override
  String paymentVerificationConfirmFailed(String error) {
    return 'Confirmation failed: $error';
  }

  @override
  String get paymentVerificationRejectTitle => 'Reject this proof?';

  @override
  String get paymentVerificationRejectNote =>
      'The customer sees this reason and can upload a new proof.';

  @override
  String get paymentVerificationReasonLabel => 'Reason (required)';

  @override
  String get paymentVerificationReasonHint => 'e.g. Screenshot is unreadable';

  @override
  String get paymentVerificationRejectButton => 'Reject Proof';

  @override
  String get paymentVerificationRejected =>
      'Proof rejected — the customer can upload a new one.';

  @override
  String paymentVerificationRejectFailed(String error) {
    return 'Rejection failed: $error';
  }

  @override
  String get paymentVerificationTotalRent => 'Total rent';

  @override
  String get paymentVerificationAdvanceDue => 'Advance due';

  @override
  String get paymentVerificationAdvancePaid => 'Advance paid';

  @override
  String get paymentVerificationTransactionId => 'Transaction ID';

  @override
  String get paymentVerificationScreenshotTitle => 'Payment screenshot';

  @override
  String get paymentVerificationProofUnavailable =>
      'Proof image unavailable — ask the customer to resend it.';

  @override
  String get proofImageOpenFullscreen => 'Open proof image fullscreen';

  @override
  String get paymentVerificationNoScreenshot => 'No screenshot attached.';

  @override
  String paymentVerificationPreviouslyRejected(String reason) {
    return 'Previously rejected: $reason';
  }

  @override
  String get paymentVerificationConfirming => 'Confirming…';

  @override
  String paymentVerificationConfirmButton(String amount) {
    return 'Confirm Payment — Rs. $amount';
  }

  @override
  String get manualBookingTitle => 'Walk-in Booking Wizard';

  @override
  String get manualBookingSubtitle => 'Showroom Counter Direct Issue';

  @override
  String get manualBookingCustomerSection => 'Customer KYC Details';

  @override
  String get manualBookingGuarantorSection => 'Guarantor (optional)';

  @override
  String get manualBookingVehicleSection => 'Vehicle & Package Selection';

  @override
  String get manualBookingCompleteDetails =>
      'Please complete all customer details.';

  @override
  String get manualBookingSelectVehicle =>
      'Please select a vehicle and package.';

  @override
  String get manualBookingBlacklisted =>
      'This CNIC is blacklisted — walk-in booking refused.';

  @override
  String manualBookingRegistered(String id) {
    return 'Walk-in booking #$id registered!';
  }

  @override
  String get manualBookingAdvanceInvalid => 'Enter a valid advance amount.';

  @override
  String manualBookingCreateFailed(String error) {
    return 'Booking creation failed: $error';
  }

  @override
  String get manualBookingCreating => 'Creating Walk-in Record...';

  @override
  String get manualBookingConfirm => 'Confirm & Proceed to Handover';

  @override
  String get manualBookingCustomerName => 'Customer Full Name';

  @override
  String get manualBookingNadraCnic => 'NADRA CNIC';

  @override
  String get manualBookingSelectVehicleHint => 'Select Showroom Vehicle';

  @override
  String get manualBookingSelectVehicleFirst =>
      'Select a vehicle first to see its packages.';

  @override
  String get manualBookingNoPackages => 'This vehicle has no packages enabled.';

  @override
  String manualBookingPackageChip(String label, String price) {
    return '$label • Rs. $price';
  }

  @override
  String manualBookingTotal(String total) {
    return 'Total: Rs. $total';
  }

  @override
  String get manualBookingDepositLabel => 'Security Deposit (Rs.)';

  @override
  String get manualBookingGuarantorNotFound =>
      'No saved customer with that CNIC — add them below.';

  @override
  String get manualBookingGuarantorBlacklisted =>
      'This CNIC is blacklisted and cannot be a guarantor.';

  @override
  String get manualBookingGuarantorRequired =>
      'Name, phone and CNIC are required for a guarantor.';

  @override
  String get manualBookingGuarantorRemove => 'Remove guarantor';

  @override
  String get manualBookingGuarantorSearch => 'Search guarantor by CNIC';

  @override
  String get manualBookingGuarantorFind => 'Find';

  @override
  String get manualBookingGuarantorEmpty => 'No saved customers yet.';

  @override
  String get manualBookingGuarantorHide => 'Hide new guarantor';

  @override
  String get manualBookingGuarantorAdd => 'Add new guarantor';

  @override
  String get manualBookingGuarantorName => 'Guarantor full name';

  @override
  String get manualBookingGuarantorCnic => 'CNIC number';

  @override
  String get manualBookingGuarantorRelationship =>
      'Relationship (e.g. Father, Brother, Friend)';

  @override
  String get manualBookingGuarantorSave => 'Save & Select Guarantor';

  @override
  String get qrScanTitle => 'Scan Booking QR';

  @override
  String get qrScanSubtitle =>
      'Point the camera at the customer’s booking code';

  @override
  String get qrOpen => 'Open';

  @override
  String get qrScanOpenSettings => 'Open settings';

  @override
  String get qrCameraDenied =>
      'Camera permission is off — RentalHub cannot scan QR codes.';

  @override
  String get qrCameraDeniedHint =>
      'Allow the camera in the app settings, or type the booking id below.';

  @override
  String qrCameraUnavailable(String detail) {
    return 'Camera unavailable — $detail';
  }

  @override
  String get qrCameraUnavailableHint => 'Type the booking id below instead.';

  @override
  String get qrCameraSettingsError =>
      'Could not open Settings — open the app settings and allow the camera, then try again.';

  @override
  String get qrTorchOn => 'Torch on';

  @override
  String get qrTorchOff => 'Torch off';

  @override
  String get proofPickerPermissionDenied =>
      'Could not open the photo picker — check the camera / photo permission and try again.';

  @override
  String qrNoBooking(String id) {
    return 'No booking found for #$id.';
  }

  @override
  String qrOpenFailed(String error) {
    return 'Could not open the booking: $error';
  }

  @override
  String get qrNotBookingCode => 'This is not a RentalHub booking code.';

  @override
  String get qrTypeHint => 'Or type the booking id, e.g. RH-…';

  @override
  String onboardingCurrentGps(String lat, String lng) {
    return 'Current GPS ($lat, $lng)';
  }

  @override
  String get onboardingShopNameShort =>
      'Shop name must be at least 3 characters.';

  @override
  String get onboardingAddressInvalid =>
      'Please enter a valid showroom address.';

  @override
  String get onboardingPayoutRequired =>
      'Please enable at least one payout method.';

  @override
  String get onboardingSubmitted =>
      'Showroom profile submitted for verification!';

  @override
  String onboardingStepOf(int step) {
    return 'Step $step of 4';
  }

  @override
  String get onboardingSubmit => 'Submit Shop for Verification';

  @override
  String get onboardingNextStep => 'Next Step';

  @override
  String get onboardingHeaderShop => 'Shop Registration';

  @override
  String get onboardingHeaderLocation => 'Location & Map Pin';

  @override
  String get onboardingHeaderPayout => 'Payout Accounts';

  @override
  String get onboardingHeaderKyc => 'KYC & Verification';

  @override
  String get onboardingHeaderSubmitted => 'Application Submitted';

  @override
  String get onboardingSubtitleShop => 'Business identity and contact details';

  @override
  String get onboardingSubtitleLocation =>
      'Physical address and geo-coordinates';

  @override
  String get onboardingSubtitlePayout =>
      'JazzCash, EasyPaisa or Pakistani Bank';

  @override
  String get onboardingSubtitleKyc => 'Shop banner, 3 fleet photos & CNIC';

  @override
  String get onboardingSubtitleSubmitted =>
      'Review status and fleet management';

  @override
  String get onboardingChangeLogo => 'Change Shop Logo';

  @override
  String get onboardingUploadLogo => 'Upload Shop Logo / Storefront';

  @override
  String get onboardingShopLegalName => 'Shop Registered Legal Name';

  @override
  String get onboardingShopNameHint => 'e.g. Al-Falah Rent a Car';

  @override
  String get onboardingOwnerName => 'Owner Full Name (as on CNIC)';

  @override
  String get onboardingOwnerNameHint => 'e.g. Ahmed Raza';

  @override
  String get onboardingOwnerCnic => 'Owner CNIC Number';

  @override
  String get onboardingShopPhone => 'Shop Landline / Alt Phone';

  @override
  String get onboardingOperatingHours => 'Operating Hours';

  @override
  String get onboardingHours9to10 => '9:00 AM - 10:00 PM';

  @override
  String get onboardingHours8toMidnight => '8:00 AM - Midnight';

  @override
  String get onboardingHours24x7 => '24 Hours / 7 Days';

  @override
  String get onboardingHours10to8 => '10:00 AM - 8:00 PM';

  @override
  String get onboardingSelectCity => 'Select Your City';

  @override
  String get onboardingPinOnMap => 'Pin Showroom On Map';

  @override
  String get onboardingLocating => 'Locating...';

  @override
  String get onboardingUseGps => 'Use Current GPS';

  @override
  String onboardingTapToPin(String lat, String lng) {
    return 'Tap anywhere on map to pin showroom ($lat, $lng)';
  }

  @override
  String get onboardingShopAddress => 'Physical Showroom Address';

  @override
  String get onboardingAddressHint =>
      'Shop number, plaza, street, sector / commercial area';

  @override
  String get onboardingPayoutTitle => 'Payout Accounts & Settlement';

  @override
  String get onboardingPayoutSubtitle =>
      'Select at least one payout channel to receive rental bookings and customer advance deposits.';

  @override
  String get onboardingJazzCashTitle => 'JazzCash Mobile Account';

  @override
  String get onboardingJazzCashSubtitle => 'Instant mobile wallet payout';

  @override
  String get onboardingEasyPaisaTitle => 'EasyPaisa Wallet Account';

  @override
  String get onboardingEasyPaisaSubtitle => 'Instant digital wallet payout';

  @override
  String get onboardingJazzCashNumber => 'JazzCash Mobile Number';

  @override
  String get onboardingEasyPaisaNumber => 'EasyPaisa Mobile Number';

  @override
  String get onboardingBankTitle => 'Direct Commercial Bank';

  @override
  String get onboardingBankSubtitle => '1-Link / IBAN direct bank settlement';

  @override
  String get onboardingSelectBank => 'Select Bank Name';

  @override
  String get onboardingAccountNumber => 'Account Number / IBAN';

  @override
  String get onboardingIbanHint => 'e.g. PK36MEZN0001234567890123';

  @override
  String get onboardingAccountTitleBusiness =>
      'Account Title (Business / Owner)';

  @override
  String get onboardingAccountTitle => 'Account Title';

  @override
  String get onboardingTitleHint => 'Ahmed Raza';

  @override
  String get onboardingStepShopDetails => 'Shop Details';

  @override
  String get onboardingStepLocation => 'Location';

  @override
  String get onboardingStepPayouts => 'Payouts';

  @override
  String get onboardingStepKyc => 'KYC Docs';

  @override
  String get onboardingApprovalTitle => 'Shop Application Submitted!';

  @override
  String get onboardingApprovalMessage =>
      'Your shop profile and KYC credentials have been routed to the Super Admin desk. You will receive SMS & WhatsApp verification within 2 to 4 business hours.';

  @override
  String get onboardingFleetReady => 'Fleet Catalog Ready';

  @override
  String get onboardingFleetReadyHint =>
      'You can start adding your cars, setting 1h/3h/6h/24h rates and photos right now.';

  @override
  String get onboardingManageFleet => 'Manage Fleet & Add Vehicles';

  @override
  String get onboardingHeaderBannerTitle => 'Shop Header Showcase Banner';

  @override
  String get onboardingHeaderBannerHint =>
      'Upload photo from camera or gallery. Appears at the top of your public profile.';

  @override
  String get onboardingHeaderBannerPhoto => 'Shop Header Banner Photo';

  @override
  String get onboardingFleetPhotosTitle => 'Showroom Fleet Photos (3 Required)';

  @override
  String get onboardingFleetPhotosHint =>
      'Upload authentic photos of cars parked at your showroom.';

  @override
  String get onboardingFleetCar1 => 'Fleet Car 1';

  @override
  String get onboardingFleetCar2 => 'Fleet Car 2';

  @override
  String get onboardingFleetCar3 => 'Fleet Car 3';

  @override
  String get onboardingIdentityTitle => 'Owner Identity & Tax Verification';

  @override
  String get onboardingIdentityHint =>
      'Mandatory compliance for showroom verification.';

  @override
  String get onboardingCnicFront => 'CNIC Front Photo';

  @override
  String get onboardingCnicFrontHint => 'Daylight photo of owner CNIC front';

  @override
  String get onboardingCnicBack => 'CNIC Back Photo';

  @override
  String get onboardingCnicBackHint =>
      'Daylight photo showing permanent address';

  @override
  String get onboardingNtn => 'FBR NTN Certificate / Business Registration';

  @override
  String get onboardingNtnHint => 'Verified filer certificate or showroom deed';

  @override
  String get onboardingSelfie =>
      'Owner Live Selfie Holding CNIC (Front Camera Only)';

  @override
  String get onboardingSelfieHint => 'Instant live biometric selfie capture';

  @override
  String get onboardingDocReady => 'Ready ✓';

  @override
  String get onboardingDocUpload => 'Upload';

  @override
  String get onboardingDocRemove => 'Remove';

  @override
  String get onboardingTapToUpload => 'Tap to Upload';

  @override
  String get onboardingOptional => 'Optional';

  @override
  String get disputesOwnerSubtitle => 'Complaints from your customers';

  @override
  String disputesFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String disputesFilterOpen(int count) {
    return 'Open ($count)';
  }

  @override
  String disputesFilterInReview(int count) {
    return 'In review ($count)';
  }

  @override
  String disputesFilterResolved(int count) {
    return 'Resolved ($count)';
  }

  @override
  String get disputesNoneOpen => 'No open disputes.';

  @override
  String get disputesNoneInReview => 'No in-review disputes.';

  @override
  String get disputesNoneResolved => 'No resolved disputes.';

  @override
  String get disputesFallbackTitle => 'Dispute';

  @override
  String disputesBookingLine(String id, String name) {
    return 'Booking $id • $name';
  }

  @override
  String get disputesNoDescription => 'No description given.';

  @override
  String get disputesSaving => 'Saving…';

  @override
  String get disputesUpdateError => 'Could not update this dispute. Try again.';

  @override
  String get disputesMarkInReview => 'Mark in review';

  @override
  String get disputesMarkResolved => 'Mark resolved';

  @override
  String get disputesResolvedNote => 'Resolved — no further action needed.';

  @override
  String get disputesMonthJan => 'Jan';

  @override
  String get disputesMonthFeb => 'Feb';

  @override
  String get disputesMonthMar => 'Mar';

  @override
  String get disputesMonthApr => 'Apr';

  @override
  String get disputesMonthMay => 'May';

  @override
  String get disputesMonthJun => 'Jun';

  @override
  String get disputesMonthJul => 'Jul';

  @override
  String get disputesMonthAug => 'Aug';

  @override
  String get disputesMonthSep => 'Sep';

  @override
  String get disputesMonthOct => 'Oct';

  @override
  String get disputesMonthNov => 'Nov';

  @override
  String get disputesMonthDec => 'Dec';

  @override
  String get notificationsSubtitle => 'What needs your attention';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsMarkReadError =>
      'Could not mark notifications as read. Please try again.';

  @override
  String get notificationsLoadError =>
      'Could not load notifications. Check your connection and try again.';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String subscriptionUpgradeTo(String tier) {
    return 'Upgrade to $tier';
  }

  @override
  String get subscriptionClose => 'Close';

  @override
  String subscriptionTransfer(String price) {
    return 'Transfer Rs. $price via Raast / IBAN to activate instant showroom accreditation.';
  }

  @override
  String get subscriptionTrxLabel => 'Bank Transfer Transaction ID / Reference';

  @override
  String get subscriptionTrxHint => 'e.g. TRX-998822';

  @override
  String get subscriptionSubmit => 'Submit Upgrade Verification';

  @override
  String get subscriptionEnterTrx => 'Please enter transaction ID';

  @override
  String get subscriptionRequested =>
      'Upgrade requested! Super Admin review in progress.';

  @override
  String get subscriptionTitle => 'Showroom Membership Plans';

  @override
  String get subscriptionSubtitle => 'Grow Your Showroom Fleet with RentalHub';

  @override
  String get subscriptionTierStarter => 'Starter Freemium';

  @override
  String get subscriptionTierPro => 'Pro Showroom';

  @override
  String get subscriptionTierEnterprise => 'Enterprise Fleet';

  @override
  String get subscriptionPerMonth => '/ month';

  @override
  String get subscriptionForeverFree => 'Forever Free';

  @override
  String get subscriptionFeatureMax3 => 'Max 3 Showroom Vehicles';

  @override
  String get subscriptionFeatureAgreements => 'Standard Digital Agreements';

  @override
  String get subscriptionFeatureVerification => 'Customer Verification Check';

  @override
  String get subscriptionFeatureUnlimited => 'Unlimited Fleet Vehicles';

  @override
  String get subscriptionFeatureRadar => 'Real-time shared blacklist radar';

  @override
  String get subscriptionFeatureWhatsappInvoicing =>
      'WhatsApp Automated Invoicing & Pass';

  @override
  String get subscriptionFeaturePricingMatrix =>
      'Custom Multi-tier Pricing Matrix';

  @override
  String get subscriptionFeatureMultiBranch =>
      'Multi-branch Fleet Synchronization';

  @override
  String get subscriptionFeatureManager => 'Dedicated Account Manager';

  @override
  String get subscriptionFeatureGps => 'GPS Telematics API Integration';

  @override
  String get subscriptionFeatureTribunal =>
      'Priority Dispute Tribunal Hearings';

  @override
  String get subscriptionMostPopular => 'MOST POPULAR';

  @override
  String get subscriptionCurrentPlan => 'CURRENT PLAN';

  @override
  String get subscriptionActivePlan => 'Active Plan';

  @override
  String get whatsappLogsTitle => 'WhatsApp Alert Dispatches';

  @override
  String get whatsappLogsSubtitle => 'Transactional Messaging Gateway • Live';

  @override
  String get whatsappLogsDelivered => 'Delivered';

  @override
  String get whatsappLogsRead => 'Read';

  @override
  String get whatsappLogsFailed => 'Failed';

  @override
  String get whatsappLogsEmpty => 'No WhatsApp messages sent yet';

  @override
  String get whatsappLogsResent =>
      'WhatsApp notification re-dispatched via Meta Cloud API!';

  @override
  String get whatsappLogsResend => 'Resend';

  @override
  String get onboardingWhatsappBusinessNumber => 'WhatsApp Business Number';

  @override
  String get disputesOwnerEmpty =>
      'No disputes yet — customer disputes for your showroom will appear here.';

  @override
  String get manualBookingGuarantorPhone => 'Phone number';

  @override
  String get navHome => 'Home';

  @override
  String get navShops => 'Shops';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navSupport => 'Support';

  @override
  String get navProfile => 'Profile';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navFleet => 'Fleet';

  @override
  String get navRequests => 'Requests';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navSettings => 'Settings';

  @override
  String syncOfflineWithPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You\'re offline — $count changes will sync when you\'re back online',
      one: 'You\'re offline — 1 change will sync when you\'re back online',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline =>
      'You\'re offline — changes will sync when you\'re back online';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes pending sync',
      one: '1 change pending sync',
    );
    return '$_temp0';
  }

  @override
  String syncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes failed to sync — will retry',
      one: '1 change failed to sync — will retry',
    );
    return '$_temp0';
  }

  @override
  String get syncFailedShort => 'Sync failed — will retry';

  @override
  String get syncFailedBanner => 'Sync failed — tap to review';

  @override
  String get syncDetailsTitle => 'Sync details';

  @override
  String get syncDetailsFailed => 'Failed';

  @override
  String syncDetailsAttempts(int count) {
    return 'Attempts: $count';
  }

  @override
  String get syncRetryNow => 'Retry now';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncDiscardTitle => 'Discard this change?';

  @override
  String syncDiscardBody(String kind, String entity) {
    return '$kind • $entity\nIt will not sync.';
  }

  @override
  String get syncKindSavedChange => 'Saved change';

  @override
  String get syncKindFileUpload => 'File upload';

  @override
  String get syncKindHandover => 'Handover';

  @override
  String get syncNoPending => 'Nothing pending';

  @override
  String get syncPendingShort => 'Pending sync';

  @override
  String get syncAllSynced => 'All changes synced';

  @override
  String get syncTitle => 'Sync';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonShowValue => 'Show value';

  @override
  String get commonHideValue => 'Hide value';

  @override
  String get commonGoBack => 'Go back';

  @override
  String headerGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get headerGreetingFallback => 'Hi there';

  @override
  String get headerUrduGreeting => 'اسلام علیکم';

  @override
  String get mediaSelectSource => 'Select Media Source';

  @override
  String get mediaTakePhoto => 'Take Photo (Back Camera)';

  @override
  String get mediaTakePhotoHint => 'Use device camera';

  @override
  String get mediaChooseGalleryHint => 'Pick existing photo or screenshot';

  @override
  String get mediaRemovePhoto => 'Remove Photo';

  @override
  String get mediaRemovePhotoHint => 'Clear this uploaded image';

  @override
  String get signatureAutoSign => 'Auto Sign';

  @override
  String get signatureDrawArea => 'Signature drawing area';

  @override
  String get signatureDrawHint => 'Draw your signature with your finger';

  @override
  String signatureSignHere(String name) {
    return 'Sign here on screen ($name)';
  }

  @override
  String signatureSignedBy(String name) {
    return 'Signed by: $name';
  }

  @override
  String get signatureNadraValidated => 'Signature captured';

  @override
  String get badgeNadraVerified => 'Verified';

  @override
  String get fuelGaugeLabel => 'Calibrated 8-Segment Fuel Level';

  @override
  String fuelGaugeSetLevel(int n) {
    return 'Set fuel level to $n of 8';
  }

  @override
  String get damageSchematicTitle => '4-Quadrant Exterior Inspection Schematic';

  @override
  String damageMarksLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Marks Logged',
      one: '1 Mark Logged',
    );
    return '$_temp0';
  }

  @override
  String get damageTapHint =>
      'Tap any vehicle quadrant below to pin/unpin pre-existing scratches or dents:';

  @override
  String get blacklistScanPrompt =>
      'Enter CNIC above to run an instant real-time scan against the RentalHub shared blacklist.';

  @override
  String get blacklistCriticalAlert => 'CRITICAL ALERT: BLACKLISTED CITIZEN';

  @override
  String blacklistIncidentRef(String id) {
    return 'Incident Ref: $id';
  }

  @override
  String blacklistReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String blacklistReportedBy(String shop) {
    return 'Reported By: $shop';
  }

  @override
  String get blacklistDecline => 'Decline / Refuse Service';

  @override
  String get blacklistCleanTitle => 'No blacklist record found';

  @override
  String get blacklistCleanSubtitle =>
      'Zero active defaults or tribunal complaints on file.';

  @override
  String get blacklistDetailsUnavailable =>
      'Blacklisted — details unavailable, refer to tribunal';

  @override
  String get blacklistProceed => 'Add Customer';

  @override
  String get cnicVerifyTitle => 'CNIC Check';

  @override
  String get cnicScanTooltip => 'Scan CNIC / Barcode';

  @override
  String get cnicVerifyButton => 'Verify CNIC & Blacklist';

  @override
  String get cnicChecking => 'Checking RentalHub blacklist...';

  @override
  String get noDraftTitle => 'No booking in progress.';

  @override
  String get noDraftMessage =>
      'Pick a car and a package first — the review screen needs the booking details from there.';

  @override
  String get noDraftBrowse => 'Browse shops';

  @override
  String routeBookingNotFound(String id) {
    return 'Booking $id was not found.';
  }

  @override
  String routeVehicleNotFound(String id) {
    return 'Vehicle $id was not found.';
  }

  @override
  String fuelGaugeBars(int active, int percent) {
    return '$active / 8 Bars ($percent%)';
  }

  @override
  String get kycWizardStepCnic => 'CNIC';

  @override
  String get kycWizardStepPhoto => 'Photo';

  @override
  String get kycWizardStepDocs => 'Docs & Sign';

  @override
  String get kycWizardStepGuarantor => 'Guarantor';

  @override
  String get kycWizardNext => 'Next';

  @override
  String get kycWizardScanFront => 'Scan CNIC front';

  @override
  String get kycWizardScanBack => 'Scan CNIC back';

  @override
  String get kycWizardFrontScanned => 'Front scanned';

  @override
  String get kycWizardBackScanned => 'Back scanned';

  @override
  String get kycWizardFatherName => 'Father name';

  @override
  String get kycWizardDateOfBirth => 'Date of birth';

  @override
  String get kycWizardCnicExpiry => 'CNIC expiry';

  @override
  String get kycWizardAddress => 'Address';

  @override
  String get kycWizardWhatsappNumber => 'WhatsApp number';

  @override
  String get kycWizardManualEntry => 'Or enter the details manually below';

  @override
  String get kycWizardBlacklisted =>
      'This CNIC is blacklisted and cannot be added.';

  @override
  String get kycWizardLivePhoto => 'Live photo';

  @override
  String get kycWizardFaceHint => 'Take a clear photo of the customer\'s face';

  @override
  String get kycWizardRetake => 'Retake';

  @override
  String get kycWizardThumbprint => 'Thumbprint';

  @override
  String get kycWizardThumbHint => 'Photograph the right thumb';

  @override
  String get kycWizardPhotoRequired => 'A photo is required to continue';

  @override
  String get kycWizardLicense => 'Driving license';

  @override
  String get kycWizardLicenseFront => 'License front';

  @override
  String get kycWizardLicenseBack => 'License back';

  @override
  String get kycWizardLicenseNumber => 'License number';

  @override
  String get kycWizardLicenseExpiry => 'License expiry';

  @override
  String get kycWizardUtilityBill => 'Utility bill (proof of address)';

  @override
  String get kycWizardExtraDocs => 'Extra documents (optional)';

  @override
  String get kycWizardAddPhoto => 'Add photo';

  @override
  String get kycWizardSignature => 'Customer signature';

  @override
  String get kycWizardSignatureClear => 'Clear';

  @override
  String get kycWizardAgreeTerms => 'I agree to the rental terms';

  @override
  String get kycWizardViewTerms => 'View Terms';

  @override
  String get kycWizardSearchGuarantor => 'Search existing customers';

  @override
  String get kycWizardRelation => 'Relation with customer';

  @override
  String get kycWizardRelationFriend => 'Friend';

  @override
  String get kycWizardRelationFamily => 'Family';

  @override
  String get kycWizardRelationColleague => 'Colleague';

  @override
  String get kycWizardRelationOther => 'Other';

  @override
  String get kycWizardGuarantorOnFile =>
      'Signature & thumbprint on file — fetched automatically';

  @override
  String get kycWizardKycComplete =>
      'KYC complete: CNIC, Photo, Thumb, License, Signature';

  @override
  String get kycWizardStepIncomplete =>
      'Please complete all required items on this step';

  @override
  String get kycWizardPhotosPending =>
      'Saved — some photos will upload when you\'re back online';

  @override
  String get kycWizardUploadFailed => 'Photo upload failed';

  @override
  String get kycWizardGuarantorOptional =>
      'Guarantor is optional — you can save without one';

  @override
  String get kycWizardExtraSkipped =>
      'Saved — some extra documents couldn\'t upload while offline';

  @override
  String get bookingSearchHint => 'Search name, phone, car or booking #';

  @override
  String get bookingEmptyRejected => 'No rejected requests';

  @override
  String bookingDaysCount(int count) {
    return '$count days';
  }

  @override
  String get bookingFareTitle => 'Fare breakdown';

  @override
  String get bookingFarePickup => 'Pickup';

  @override
  String get bookingFareReturn => 'Return';

  @override
  String get bookingFareDailyRate => 'Daily rate';

  @override
  String bookingFareDailyRateTimes(int count) {
    return 'Daily rate × $count days';
  }

  @override
  String get bookingFarePackagePrice => 'Package price';

  @override
  String get bookingFareTotal => 'Total';

  @override
  String get bookingFareAdvanceRequired => 'Advance required';

  @override
  String get bookingFareAdvancePaid => 'Advance paid';

  @override
  String get bookingFareRemaining => 'Remaining';

  @override
  String get bookingChecklistTitle => 'Before you accept';

  @override
  String get bookingCheckKyc => 'Customer KYC documents on file';

  @override
  String get bookingCheckCar => 'Car available';

  @override
  String get bookingCheckAdvance => 'Advance received';

  @override
  String get bookingConfirmTermsTitle => 'Confirm Terms';

  @override
  String get bookingTermCondition => 'Car Condition';

  @override
  String get bookingTermFuel => 'Fuel Level';

  @override
  String get bookingTermMileage => 'Mileage';

  @override
  String get bookingTermDocuments => 'Documents';

  @override
  String get bookingTermsIncomplete =>
      'Tick all four items to confirm the booking.';

  @override
  String get bookingConvertToManual => 'Convert to manual entry';

  @override
  String get bookingConfirmedTitle => 'Booking Confirmed';

  @override
  String bookingConfirmedHandoverScheduled(String date) {
    return 'Handover scheduled $date';
  }

  @override
  String get bookingConfirmedStartHandover => 'Start Handover';

  @override
  String get bookingConfirmedViewBooking => 'View Booking';

  @override
  String get bookingConfirmedMessageCustomer => 'Message Customer';

  @override
  String bookingConfirmedWhatsappMessage(
      String name, String vehicle, String date, String total) {
    return 'Assalam-o-Alaikum $name, your booking for $vehicle is confirmed. Pickup: $date. Total: Rs. $total. Thank you!';
  }

  @override
  String get bookingConfirmedWhatsappFailed => 'Could not open WhatsApp.';

  @override
  String get manualBookingNext => 'Next';

  @override
  String get manualBookingReturnAfterPickup => 'Return must be after pickup.';

  @override
  String get manualBookingConfirmTitle => 'Review Fare';

  @override
  String get manualBookingConfirmBooking => 'Confirm Booking';

  @override
  String get contractTerm4 =>
      '4. Fuel shall be returned at the same level as at handover.';

  @override
  String get contractTerm5 =>
      '5. Late return is charged per hour or per day as per the agreed package.';

  @override
  String get contractTerm6 =>
      '6. Damage is charged as per inspection at return.';

  @override
  String get contractTerm7 =>
      '7. The owner is not liable for personal belongings left in the vehicle.';

  @override
  String get contractTerm8 =>
      '8. This agreement is governed by the laws of Pakistan.';

  @override
  String get contractTerm9 =>
      '9. The security deposit is refunded after inspection at return, less any damage or extra-kilometre charges.';

  @override
  String get contractTerm10 => '10. Both parties agree to the terms above.';

  @override
  String get contractFieldAdvance => 'Advance:';

  @override
  String get contractFieldRemaining => 'Remaining:';

  @override
  String get contractFieldPlate => 'Plate:';

  @override
  String get contractGuarantorSignature => 'Guarantor Signature';

  @override
  String get contractGuarantorPending => 'Pending';

  @override
  String get contractDownloadPdf => 'Download PDF';

  @override
  String contractPdfDownloaded(String file) {
    return 'Agreement PDF saved: $file';
  }

  @override
  String contractPdfDownloadFailed(String error) {
    return 'Could not save the agreement PDF: $error';
  }

  @override
  String get handoverPhotosTitle => 'Exterior Photos';

  @override
  String get handoverPhotoFront => 'Front';

  @override
  String get handoverPhotoBack => 'Back';

  @override
  String get handoverPhotoLeft => 'Left';

  @override
  String get handoverPhotoRight => 'Right';

  @override
  String get handoverPhotoUploading => 'Uploading…';

  @override
  String get handoverDocumentsTitle => 'Documents Given';

  @override
  String get handoverDocumentRegistration => 'Registration';

  @override
  String get handoverDocumentInsurance => 'Insurance';

  @override
  String get handoverAccessoriesTitle => 'Accessories';

  @override
  String get handoverAccessorySpareTyre => 'Spare Tyre';

  @override
  String get handoverAccessoryJack => 'Jack';

  @override
  String get handoverAccessoryToolKit => 'Tool Kit';

  @override
  String get handoverKeysTitle => 'Keys Handed Over';

  @override
  String get returnLandingTitle => 'Return & Settlement';

  @override
  String returnLandingSummary(String id, String customer, String vehicle) {
    return 'Booking #$id • $customer — $vehicle';
  }

  @override
  String get returnLandingDueBack => 'Return due';

  @override
  String get returnLandingStart => 'Start Return Inspection';

  @override
  String get returnConditionTitle => 'Vehicle Condition';

  @override
  String get returnConditionGood => 'Good';

  @override
  String get returnConditionMinorDamage => 'Minor damage';

  @override
  String get returnConditionRecordDamage => 'Record Damage';

  @override
  String get returnFareTitle => 'Fare Summary';

  @override
  String get returnFareRent => 'Rent';

  @override
  String get returnFareAdvancePaid => 'Advance Paid';

  @override
  String get returnFareRemaining => 'Remaining';

  @override
  String get returnFareTotalDue => 'Total Due';

  @override
  String get returnPaymentTitle => 'Payment Received';

  @override
  String get returnPaymentCash => 'Cash';

  @override
  String get returnPaymentBankTransfer => 'Bank Transfer';

  @override
  String get returnPaymentJazzCash => 'JazzCash';

  @override
  String get returnPaymentEasyPaisa => 'EasyPaisa';

  @override
  String get returnPaymentAmountLabel => 'Amount Received';

  @override
  String get returnPaymentAmountHint => 'e.g. 16000';

  @override
  String get returnPaymentMarkReceived => 'Mark Payment Received';

  @override
  String get returnPaymentReceived => 'Payment Received';

  @override
  String get returnPaymentUndo => 'Undo';

  @override
  String get returnPaymentRecordExtraCharges => 'Record Extra Charges';

  @override
  String get returnReceiptExtraCharges => 'Extra Charges';

  @override
  String get damageTitle => 'Record Damage';

  @override
  String get damageAddPhoto => 'Add Photo';

  @override
  String get damageDescriptionLabel => 'Description';

  @override
  String get damageDescriptionHint => 'e.g. Scratch on the rear bumper';

  @override
  String get damageDescriptionRequired => 'Please describe the damage.';

  @override
  String get damageRepairCostLabel => 'Repair Cost';

  @override
  String get damageRepairCostHint => 'e.g. 5000';

  @override
  String get damageDeductFromDeposit => 'Deduct from Deposit';

  @override
  String get damageSave => 'Save';

  @override
  String get damageSaved => 'Damage report saved.';

  @override
  String get damageSaveFailed =>
      'Could not save the damage report. Please try again.';

  @override
  String get extraChargeTitle => 'Record Extra Charges';

  @override
  String get extraChargeTypeLabel => 'Charge Type';

  @override
  String get extraChargeTypeLateReturn => 'Late Return';

  @override
  String get extraChargeTypeExtraKm => 'Extra KM';

  @override
  String get extraChargeTypeDamage => 'Damage';

  @override
  String get extraChargeTypeCleaning => 'Cleaning';

  @override
  String get extraChargeAmountLabel => 'Amount';

  @override
  String get extraChargeAmountHint => 'e.g. 2000';

  @override
  String get extraChargeRemarksLabel => 'Remarks';

  @override
  String get extraChargeRemarksHint => 'e.g. Returned 3 hours late';

  @override
  String get extraChargeAdd => 'Add Charge';

  @override
  String get extraChargeAdded => 'Charge added.';

  @override
  String get extraChargeSaveFailed =>
      'Could not save the charge. Please try again.';

  @override
  String get extraChargeLoadError =>
      'Could not load saved extra charges. Please try again.';

  @override
  String get extraChargeAmountRequired =>
      'Please enter an amount greater than zero.';

  @override
  String get extraChargeSavedTitle => 'Saved Charges';

  @override
  String get rentalStartedTitle => 'On the Road';

  @override
  String get rentalStartedBanner => 'Rental Started';

  @override
  String rentalStartedBooking(String id) {
    return 'Booking #$id';
  }

  @override
  String rentalStartedReturnDue(String date, String time) {
    return 'Return due $date, $time';
  }

  @override
  String get rentalStartedViewAgreement => 'View Agreement';

  @override
  String get rentalStartedMessageCustomer => 'Message Customer';

  @override
  String rentalStartedMessage(String name, String vehicle) {
    return 'Assalam-o-Alaikum $name, your rental of $vehicle has started. Please return it on time. — RentalHub';
  }

  @override
  String get rentalStartedNoPhone => 'No phone number saved for this customer.';

  @override
  String get rentalStartedWhatsappFailed => 'Could not open WhatsApp.';

  @override
  String get agreementSignedTitle => 'Agreement Signed';

  @override
  String get agreementSignedBanner => 'Agreement Signed Successfully';

  @override
  String get agreementSignedSubtitle =>
      'The rental agreement has been signed by all parties.';

  @override
  String get agreementSignedDownloadPdf => 'Download PDF';

  @override
  String get agreementSignedShare => 'Share';

  @override
  String get agreementSignedSendCustomer => 'Send to Customer';

  @override
  String get agreementSignedContinue => 'Continue';

  @override
  String agreementSignedSendMessage(String name, String url) {
    return 'Assalam-o-Alaikum $name, your rental agreement is ready: $url';
  }

  @override
  String dashboardGreeting(String name) {
    return 'Assalam-o-Alaikum, $name';
  }

  @override
  String get dashboardQuickAddCustomer => 'Add Customer';

  @override
  String get dashboardQuickViewReports => 'View Reports';

  @override
  String get dashboardReturnsEmpty => 'No returns due in the next 7 days.';

  @override
  String get dashboardScheduleBooking => 'Booking';

  @override
  String get dashboardScheduleEmpty => 'Nothing scheduled for today.';

  @override
  String get dashboardScheduleHandover => 'Handover';

  @override
  String get dashboardScheduleReturn => 'Return';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardTodayEarnings => 'Today\'s Earnings';

  @override
  String get dashboardTodaySchedule => 'Today\'s Schedule';

  @override
  String get dashboardUpcomingReturns => 'Upcoming Returns';

  @override
  String get financeBookingNumberHint => 'e.g. BK-1234';

  @override
  String get financeBookingNumberLabel => 'Booking #';

  @override
  String get financeDateLabel => 'Date';

  @override
  String get financeFilterAll => 'All';

  @override
  String get financePaymentBank => 'Bank Transfer';

  @override
  String get financePaymentCash => 'Cash';

  @override
  String get financePaymentEasyPaisa => 'EasyPaisa';

  @override
  String get financePaymentJazzCash => 'JazzCash';

  @override
  String get financePaymentMethodLabel => 'Payment method';

  @override
  String get financeCategoryAdvance => 'Advance';

  @override
  String get financeCategoryWash => 'Wash';

  @override
  String get financePnlDaily => 'Daily';

  @override
  String get financePnlWeekly => 'Weekly';

  @override
  String get financePnlMonthly => 'Monthly';

  @override
  String get financePnlIncomeBreakdown => 'Income Breakdown';

  @override
  String get financePnlExpenseBreakdown => 'Expense Breakdown';

  @override
  String get financeCategoriesAdd => 'Add Category';

  @override
  String get financeCategoriesDuplicate =>
      'A category with this name already exists.';

  @override
  String get financeCategoriesAddTitle => 'Add Category';

  @override
  String get financeCategoriesDelete => 'Delete';

  @override
  String financeCategoriesDeleteMessage(String name) {
    return 'Delete the “$name” category? Old ledger entries keep this category.';
  }

  @override
  String get financeCategoriesDeleteTitle => 'Delete Category';

  @override
  String get financeCategoriesEdit => 'Edit';

  @override
  String get financeCategoriesEditTitle => 'Edit Category';

  @override
  String get financeCategoriesEmpty => 'No categories yet.';

  @override
  String get financeCategoriesNameLabel => 'Category name';

  @override
  String get financeCategoriesSubtitle =>
      'Income and expense categories for the ledger';

  @override
  String get financeCategoriesTitle => 'Income & Expense Categories';

  @override
  String get financeSettingsAutoReceipt => 'Auto-send WhatsApp receipt';

  @override
  String get financeSettingsAutoReceiptNote =>
      'Receipts are sent only after the WhatsApp Business setup (Phase I). Until then this only records your preference.';

  @override
  String get financeSettingsCurrency => 'Default Currency';

  @override
  String get financeSettingsCurrencyNote =>
      'The app only trades in Pakistani Rupees (PKR).';

  @override
  String get financeSettingsEmpty =>
      'Finance settings are not available right now.';

  @override
  String get financeSettingsInvalidPercent =>
      'Enter a valid percentage number.';

  @override
  String get financeSettingsPercentRange =>
      'Enter a percentage between 0 and 100.';

  @override
  String get financeSettingsPaymentMethods => 'Payment Methods';

  @override
  String get financeSettingsReceipts => 'Receipt Settings';

  @override
  String get financeSettingsSave => 'Save Settings';

  @override
  String get financeSettingsSaved => 'Finance settings saved.';

  @override
  String get financeSettingsServiceCharge => 'Service Charges (%)';

  @override
  String get financeSettingsSubtitle =>
      'Currency, charges, payment methods and receipts';

  @override
  String get financeSettingsTax => 'Tax (%)';

  @override
  String get financeSettingsTitle => 'Finance Settings';

  @override
  String get financeStatementColBooking => 'Booking';

  @override
  String get financeStatementColDate => 'Date';

  @override
  String get financeStatementColDue => 'Due';

  @override
  String get financeStatementColPaid => 'Paid';

  @override
  String get financeStatementColRent => 'Rent';

  @override
  String get financeStatementDownload => 'Download PDF';

  @override
  String get financeStatementDownloaded =>
      'Statement PDF saved to your device.';

  @override
  String get financeStatementEmpty => 'This customer has no bookings yet.';

  @override
  String financeStatementMessageRow(
      String booking, String date, String rent, String paid, String due) {
    return '#$booking • $date • Rent Rs. $rent • Paid Rs. $paid • Due Rs. $due';
  }

  @override
  String financeStatementMessageTitle(String name) {
    return 'RentalHub statement for $name:';
  }

  @override
  String financeStatementMessageTotal(String amount) {
    return 'Total due: Rs. $amount';
  }

  @override
  String get financeStatementSend => 'Send Statement (WhatsApp)';

  @override
  String get financeStatementShare => 'Share';

  @override
  String get financeStatementTitle => 'Customer Statement';

  @override
  String get financeStatementTotalDue => 'Total Due';

  @override
  String get financeSummaryEarnings => 'Earnings';

  @override
  String get financeSummaryExpenses => 'Expenses';

  @override
  String get financeSummaryNet => 'Net';

  @override
  String get financeTabOverview => 'Overview';

  @override
  String get financeTabReports => 'Reports';

  @override
  String get financeTabTransactions => 'Transactions';

  @override
  String get financeViewReports => 'View Reports';

  @override
  String reportCarBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings',
      one: '$count booking',
    );
    return '$_temp0';
  }

  @override
  String get reportCarTableTitle => 'Car — Bookings — Earnings';

  @override
  String get reportCarWise => 'Car-wise Earnings';

  @override
  String get reportCarWiseHint => 'Earnings for every car in the fleet';

  @override
  String get reportCustomerHistory => 'Customer History';

  @override
  String get reportCustomerHistoryHint => 'Bookings and spend per customer';

  @override
  String get reportCustomerTableTitle => 'Customer — Bookings — Spend';

  @override
  String get reportEarningsLast6Months => 'Earnings — last 6 months';

  @override
  String get reportMonthlyEarnings => 'Monthly Earnings Report';

  @override
  String get reportMonthlyEarningsHint => 'Revenue by month, as a bar chart';

  @override
  String get reportNoCars => 'No cars in the fleet yet.';

  @override
  String get reportNoCustomers => 'No customer bookings in this period.';

  @override
  String get reportPeriod => 'Period';

  @override
  String get reportShare => 'Share Report';

  @override
  String get reportShareFailed =>
      'Could not share the report. Please try again.';

  @override
  String get reportSubtitle => 'Earnings, cars and customers';

  @override
  String get reportTitle => 'Reports';

  @override
  String get resetAction => 'Reset';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get resetAllHint =>
      'Bookings, customers, cars, finance records and staff for this shop.';

  @override
  String get resetBookings => 'Reset Bookings';

  @override
  String get resetBookingsHint => 'Deletes all bookings for this shop.';

  @override
  String get resetCars => 'Reset Cars';

  @override
  String get resetCarsHint => 'Deletes all vehicles for this shop.';

  @override
  String resetConfirmMessage(String what) {
    return 'Are you sure? This will permanently delete $what for this shop. This cannot be undone.';
  }

  @override
  String get resetConfirmTitle => 'Reset data?';

  @override
  String get resetCustomers => 'Reset Customers';

  @override
  String get resetCustomersHint => 'Deletes all customers for this shop.';

  @override
  String resetDone(String count) {
    return 'Deleted $count records.';
  }

  @override
  String get resetFailed =>
      'Reset failed. Check your connection and try again.';

  @override
  String get resetSubtitle => 'Delete this shop\'s data — carefully';

  @override
  String get resetTitle => 'Reset Options';

  @override
  String get resetWarning =>
      'Warning: resetting deletes data permanently. Only reset what you mean to lose. The shop itself and its finance settings are kept.';

  @override
  String get resetYesReset => 'Yes, Reset';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmYes => 'Yes, Sign Out';

  @override
  String get signOutSignInAgain => 'Sign In Again';

  @override
  String get signOutSignedOutBody =>
      'You have been signed out. Sign in again to continue managing your showroom.';

  @override
  String get signOutSignedOutTitle => 'You have been signed out';

  @override
  String get staffAdd => 'Add Staff';

  @override
  String get staffAddTitle => 'Add Staff Member';

  @override
  String get staffDelete => 'Remove staff member';

  @override
  String get staffDeleteFailed =>
      'Could not remove this staff member. Please try again.';

  @override
  String get staffEmpty => 'No staff yet — add your first team member.';

  @override
  String get staffNameLabel => 'Name';

  @override
  String get staffPermissionAddCars => 'Add Cars';

  @override
  String get staffPermissionManageFinance => 'Manage Finance';

  @override
  String get staffPermissionViewBookings => 'View Bookings';

  @override
  String get staffPhoneLabel => 'Phone';

  @override
  String get staffRoleLabel => 'Role';

  @override
  String get staffSubtitle => 'Team members and their permissions';

  @override
  String get staffTitle => 'Staff & Roles';

  @override
  String onboardingStepOfFive(int step) {
    return 'Step $step of 5';
  }

  @override
  String get onboardingHeaderReview => 'Review Application';

  @override
  String get onboardingSubtitleReview => 'Check everything before submitting';

  @override
  String get onboardingStepReview => 'Review';

  @override
  String get onboardingReviewTitle => 'Review your application';

  @override
  String get onboardingReviewHint =>
      'Check the details below. You can go back to change anything before submitting.';

  @override
  String get onboardingReviewShopName => 'Shop name';

  @override
  String get onboardingReviewOwnerName => 'Owner name';

  @override
  String get onboardingReviewCnic => 'Owner CNIC';

  @override
  String get onboardingReviewWhatsapp => 'WhatsApp number';

  @override
  String get onboardingReviewPhone => 'Phone number';

  @override
  String get onboardingReviewOpeningHours => 'Opening hours';

  @override
  String get onboardingReviewShopLogo => 'Shop logo';

  @override
  String get onboardingReviewAddress => 'Address';

  @override
  String get onboardingReviewCity => 'City';

  @override
  String get onboardingReviewNoDocuments => 'No documents attached yet';

  @override
  String get onboardingReviewCnicFront => 'CNIC front';

  @override
  String get onboardingReviewCnicBack => 'CNIC back';

  @override
  String get onboardingReviewSelfie => 'Selfie with CNIC';

  @override
  String get onboardingReviewNtn => 'NTN document';

  @override
  String get onboardingReviewShopPhoto => 'Shop photo';

  @override
  String get onboardingReviewFleetPhoto1 => 'Fleet photo 1';

  @override
  String get onboardingReviewFleetPhoto2 => 'Fleet photo 2';

  @override
  String get onboardingReviewFleetPhoto3 => 'Fleet photo 3';

  @override
  String get onboardingApprovalWithin24h => 'Usually approved within 24 hours';

  @override
  String get onboardingTimelineSubmitted => 'Submitted';

  @override
  String get onboardingTimelineSubmittedHint => 'Your application was received';

  @override
  String get onboardingTimelineUnderReview => 'Under Review';

  @override
  String get onboardingTimelineUnderReviewHint =>
      'Our team is checking your details';

  @override
  String get onboardingTimelineApproved => 'Approved';

  @override
  String get onboardingTimelineApprovedHint =>
      'Your shop goes live after approval';

  @override
  String get onboardingContactAdminWhatsapp => 'Contact Admin on WhatsApp';

  @override
  String get onboardingAdminWhatsappMissing =>
      'Admin WhatsApp is not set up yet. Please try again later.';

  @override
  String get onboardingAdminWhatsappFailed => 'Could not open WhatsApp.';

  @override
  String get pricingPackageMonthly => 'Monthly Package (30 Days)';

  @override
  String get addVehicleRateMonthly => 'Monthly Package (30 Days)';

  @override
  String get ratesViewEstimate => 'View estimated rates';

  @override
  String get pricingPerKmQuestion => 'Per KM Pricing?';

  @override
  String get pricingPerKmQuestionHint =>
      'Charge for kilometres beyond the package limit';

  @override
  String get ratesCustomTitle => 'Custom Rates';

  @override
  String get ratesCustomAdd => 'Add rate';

  @override
  String get ratesCustomEmpty =>
      'No custom rates yet. Add one for a period the standard packages do not cover.';

  @override
  String get ratesCustomAddTitle => 'Add custom rate';

  @override
  String get ratesCustomNameLabel => 'Rate name';

  @override
  String get ratesCustomNameHint => 'e.g. Airport transfer';

  @override
  String get ratesCustomPriceLabel => 'Price';

  @override
  String get ratesCustomPeriodLabel => 'Period';

  @override
  String get ratesCustomPeriodHourly => 'Hourly';

  @override
  String get ratesCustomPeriodDaily => 'Daily';

  @override
  String get ratesCustomPeriodWeekly => 'Weekly';

  @override
  String get ratesCustomPeriodMonthly => 'Monthly';

  @override
  String get ratesCustomDelete => 'Delete rate';

  @override
  String get ratesCustomInvalid =>
      'Enter a name and a price greater than zero.';

  @override
  String get pkgMonthlyPackage => 'Monthly Package';

  @override
  String get pkgMonthlyDesc => 'Thirty days, one price';

  @override
  String fleetOnRentUntil(String date) {
    return 'On Rent until $date';
  }

  @override
  String fleetActiveRentals(int count) {
    return '$count active rentals';
  }

  @override
  String get fleetSchedule => 'Schedule';

  @override
  String get fleetEditRent => 'Edit Rent';

  @override
  String get fleetUpdatePrice => 'Update Price';

  @override
  String get fleetShopSettings => 'Shop Settings';

  @override
  String get shopProfileOwnerUnknown => 'Owner';

  @override
  String get fleetAddBlockedTitle => 'Shop approval pending';

  @override
  String get fleetAddBlockedBody =>
      'Your shop is still under review. You can add vehicles once your shop is approved — usually within 24 hours.';

  @override
  String get fleetAddBlockedViewStatus => 'View status';

  @override
  String get fareTableTitle => 'Fare Table';

  @override
  String get fareTabInCity => 'In-City';

  @override
  String get fareTabOutCity => 'Out-City';

  @override
  String get fareTabHourly => 'Hourly';

  @override
  String get fareTabMonthly => 'Monthly';

  @override
  String get fareFreeDelivery => 'Default Free delivery';

  @override
  String fareKmIncluded(int km) {
    return '$km km included';
  }

  @override
  String fareOutCityDaily(String rate) {
    return 'Out-City day rate: $rate';
  }

  @override
  String get fareNoRows => 'No fares for this tab yet.';

  @override
  String get fareProceed => 'Proceed';

  @override
  String get estimateTitle => 'Estimated Rates';

  @override
  String get estimateCardTitle => 'Estimated Rates';

  @override
  String get estimateInCityDay => 'In-City / Day';

  @override
  String get estimateOutCityDay => 'Out-City / Day';

  @override
  String get estimateWeekly => 'Weekly';

  @override
  String get estimateMonthly => 'Monthly';

  @override
  String get estimateWithDriverSurcharge => 'With-driver surcharge';

  @override
  String estimatePerDay(String amount) {
    return '$amount / day';
  }

  @override
  String get estimateDeposit => 'Security deposit';

  @override
  String get estimateHint =>
      'Estimates use your current rates. Change them in the rate matrix.';

  @override
  String get estimateGoToMyCars => 'Go to My Cars';

  @override
  String get vehiclePublishedTitle => 'Car Published';

  @override
  String vehiclePublishedHeading(String vehicle) {
    return 'Your $vehicle has been successfully published';
  }

  @override
  String get vehiclePublishedLinkCopied => 'Listing link copied';

  @override
  String vehiclePublishedShareText(String vehicle, String rate, String link) {
    return 'Rent $vehicle for $rate / day on RentalHub: $link';
  }

  @override
  String get vehiclePublishedViewInApp => 'View in App';

  @override
  String get vehiclePublishedCopyLink => 'Copy Link';

  @override
  String get vehiclePublishedShareListing => 'Share Listing';

  @override
  String get vehiclePublishedAddAnother => 'Publish another car';

  @override
  String vehicleDetailDailyRate(String amount) {
    return '$amount / day';
  }

  @override
  String vehicleDetailSeats(int count) {
    return '$count seats';
  }

  @override
  String get vehicleDetailRatesTitle => 'Rates';

  @override
  String get vehicleDetailDeposit => 'Security deposit';

  @override
  String get vehicleDetailFareTable => 'Fare table';

  @override
  String get vehicleDetailBookingsTitle => 'Bookings';

  @override
  String get vehicleDetailNoBookings => 'No bookings for this car yet.';

  @override
  String get vehicleDetailManageRates => 'Manage rates';

  @override
  String get vehicleDetailCalendar => 'Booking calendar';

  @override
  String get vehicleDetailEdit => 'Edit';

  @override
  String get shopSettingsTitle => 'Shop Settings';

  @override
  String get shopSettingsSubtitle => 'Your shop name and details';

  @override
  String get shopSettingsShopName => 'Shop name';

  @override
  String get shopSettingsOwnerName => 'Owner name';

  @override
  String get shopSettingsPhone => 'Phone number';

  @override
  String get shopSettingsAddress => 'Address';

  @override
  String get shopSettingsCity => 'City';

  @override
  String get shopSettingsOpeningHours => 'Opening hours';

  @override
  String get shopSettingsSave => 'Save shop settings';

  @override
  String get shopSettingsSaved => 'Shop settings saved';

  @override
  String get shopSettingsNameShort =>
      'Enter a shop name of at least 3 characters.';

  @override
  String shopSettingsSaveFailed(String error) {
    return 'Could not save shop settings: $error';
  }

  @override
  String get shopSettingsLoadError => 'Could not load shop settings.';

  @override
  String get shopSettingsPhoneInvalid =>
      'Enter a valid Pakistani mobile number (03XX-XXXXXXX or +92 3XX XXXXXXX).';

  @override
  String get shopSettingsHoursHint => 'e.g. 9:00 AM – 9:00 PM';

  @override
  String get shopSettingsHoursInvalid =>
      'Enter opening hours like 9:00 AM – 9:00 PM.';

  @override
  String get fleetCalendarTitle => 'Fleet Schedule';

  @override
  String get fleetCalendarPrevMonth => 'Previous month';

  @override
  String get fleetCalendarNextMonth => 'Next month';

  @override
  String get fleetCalendarLoadError => 'Could not load the fleet calendar.';

  @override
  String get fleetCalendarEmptyTitle => 'No cars in your fleet yet';

  @override
  String get fleetCalendarEmptyMessage => 'Add a car to see its schedule here.';

  @override
  String get fleetCalendarBooked => 'Booked';

  @override
  String get fleetCalendarAvailable => 'Available';

  @override
  String get vehicleReviewDelivery => 'Delivery & Collection';

  @override
  String get vehicleReviewDiscounts => 'Discounts';

  @override
  String get vehicleReviewInsurance => 'Insurance & Protection';

  @override
  String get vehicleReviewYourEarning => 'Your Earning';

  @override
  String get subscriptionChoosePlanTitle => 'Choose a plan';

  @override
  String get subscriptionChoosePlanSubtitle => 'Grow your rental business';

  @override
  String get subscriptionBillingMonthly => 'Monthly';

  @override
  String get subscriptionBillingYearly => 'Yearly';

  @override
  String get subscriptionYearlySave => 'Save 17%';

  @override
  String get subscriptionPlanFree => 'Free';

  @override
  String get subscriptionPlanPro => 'Pro';

  @override
  String get subscriptionPlanBusiness => 'Business';

  @override
  String get subscriptionFreeCars => 'Up to 3 cars';

  @override
  String get subscriptionFreeBookings => 'Basic bookings';

  @override
  String get subscriptionFreeBranding => 'Gaari branding';

  @override
  String get subscriptionFreeLogins => '1 login';

  @override
  String get subscriptionProCars => 'Up to 10 cars';

  @override
  String get subscriptionProKyc => 'Customer KYC';

  @override
  String get subscriptionProStamp => 'Own shop stamp';

  @override
  String get subscriptionProAccounts => 'Accounts & reports';

  @override
  String get subscriptionProListing => 'Priority listing';

  @override
  String get subscriptionProTrial => '14-day trial';

  @override
  String get subscriptionBusinessCars => 'Unlimited cars';

  @override
  String get subscriptionBusinessStaff => '5 staff logins';

  @override
  String get subscriptionBusinessReports => 'Advanced reports';

  @override
  String get subscriptionBusinessExport => 'PDF & Excel export';

  @override
  String get subscriptionBusinessBadge => 'Featured badge';

  @override
  String get subscriptionBusinessSupport => 'Priority support';

  @override
  String get subscriptionExamplePrices =>
      'Example prices — final pricing to be decided';

  @override
  String get subscriptionViewDetails => 'View details';

  @override
  String get subscriptionMySubscription => 'My subscription';

  @override
  String get subscriptionLoadError =>
      'Could not load your subscription. Please try again.';

  @override
  String get subscriptionPlayNotConnected =>
      'Google Play billing is not connected yet';

  @override
  String get subscriptionPlayNotConnectedNote =>
      'Play Console setup is still pending. You can subscribe by bank transfer below — nothing is charged through Google Play.';

  @override
  String get subscriptionPayByBank =>
      'Pay by bank transfer — Google Play billing arrives once the Play Console setup is done';

  @override
  String get subscriptionTrialNote =>
      'Your 14-day free trial starts after the admin approves your bank-transfer request.';

  @override
  String get subscriptionStartTrial => 'Start 14-day free trial';

  @override
  String get subscriptionManageInPlay => 'Manage in Google Play';

  @override
  String get subscriptionManageInPlayNote =>
      'Available once Google Play billing is connected.';

  @override
  String get subscriptionCarsUsed => 'Cars used';

  @override
  String get subscriptionStaffLogins => 'Staff logins';

  @override
  String get subscriptionBillingHistory => 'Billing history';

  @override
  String get subscriptionBillingEmpty => 'No subscription payments yet';

  @override
  String get subscriptionPendingReview => 'Pending admin review';

  @override
  String get subscriptionStatusApproved => 'Approved';

  @override
  String get subscriptionStatusRejected => 'Rejected';

  @override
  String get subscriptionStatusPending => 'Pending';

  @override
  String get subscriptionTrialActive => 'Free trial active';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionTrialEnds => 'Trial ends';

  @override
  String get subscriptionNextBilling => 'Next billing date';

  @override
  String get subscriptionPaymentMethod => 'Payment method';

  @override
  String get subscriptionNoPaymentMethod => 'No payment method on file';

  @override
  String get subscriptionReceiptNote =>
      'Receipts will be sent to your Google account email once Google Play billing is connected.';

  @override
  String get subscriptionGoToDashboard => 'Go to dashboard';

  @override
  String get subscriptionChangePlan => 'Change plan';

  @override
  String get subscriptionCarLimitTitle => 'Car limit reached';

  @override
  String subscriptionCarLimitBody(String plan, String limit) {
    return 'Your $plan plan allows $limit cars. Upgrade to Business to add unlimited cars and staff.';
  }

  @override
  String get subscriptionUpgradeToBusiness => 'Upgrade to Business';

  @override
  String get subscriptionNotNow => 'Not now';

  @override
  String get subscriptionPaymentIssue => 'Payment issue · account on hold';

  @override
  String get subscriptionPaymentIssueBody =>
      'Update your payment method, or pay by bank transfer. Your data is kept.';

  @override
  String get subscriptionDowngradeNote =>
      'If it is not fixed, you move to Free. Your data is kept; extra cars are hidden from listing.';

  @override
  String get subscriptionTrialTerms =>
      'Free for 14 days, then billed monthly through Google Play. Auto-renews until cancelled; cancel in Google Play > Subscriptions at least 24 hours before the trial ends.';

  @override
  String get subscriptionBilledMonthly => 'Billed every month';

  @override
  String get subscriptionPerYear => '/ year';

  @override
  String get subscriptionPlaySheetTitle => 'Google Play purchase';

  @override
  String get subscriptionPlayTodayFree => 'Today: free for 14 days';

  @override
  String get subscriptionPlayThen => 'Then billed monthly';

  @override
  String get subscriptionFreePlanNote => 'You are on the Free plan';

  @override
  String get subscriptionCurrentTier => 'Current plan';

  @override
  String get creditsTitle => 'WhatsApp Credits';

  @override
  String get creditsBalance => 'Credit balance';

  @override
  String get creditsEmpty => 'No credits yet';

  @override
  String get creditsOneMessage => '1 message = 1 credit · credits never expire';

  @override
  String get creditsAutoMessages => 'Auto messages';

  @override
  String get creditsAutoNote =>
      'Messages send automatically only once WhatsApp is connected.';

  @override
  String get creditsToggleBooking => 'Booking request & approval';

  @override
  String get creditsToggleAdvance => 'Advance payment receipt';

  @override
  String get creditsTogglePickup => 'Pickup reminder';

  @override
  String get creditsTogglePickupNote => '2 hours before pickup';

  @override
  String get creditsToggleAgreement => 'Agreement PDF at handover';

  @override
  String get creditsToggleReturn => 'Return reminder & late warning';

  @override
  String get creditsToggleDeposit => 'Deposit refunded';

  @override
  String get creditsToggleDues => 'Dues reminder';

  @override
  String get creditsToggleDuesNote => 'Every 3 days until paid';

  @override
  String get creditsBuy => 'Buy credits';

  @override
  String get creditsBuyTitle => 'Buy credits';

  @override
  String get creditsPackBestValue => 'Best value';

  @override
  String get creditsPerMessage => 'per message';

  @override
  String get creditsFreeMonthly => 'Free credits every month';

  @override
  String get creditsFreePlanFree => 'Free plan — 10 messages';

  @override
  String get creditsFreePlanPro => 'Pro plan — 30 credits';

  @override
  String get creditsFreePlanBusiness => 'Business plan — 100 credits';

  @override
  String get creditsBuyPack => 'Buy this pack';

  @override
  String get creditsPayByBank =>
      'Pay by bank transfer — Google Play billing arrives once the Play Console setup is done';

  @override
  String get creditsRequestSubmittedTitle => 'Request submitted';

  @override
  String get creditsRequestSubmittedBody =>
      'Credits will be added after payment verification.';

  @override
  String get creditsAddedTitle => 'Credits added';

  @override
  String get creditsAddedBody =>
      'Your payment was verified and the credits were added to your balance.';

  @override
  String get creditsPreviousBalance => 'Previous balance';

  @override
  String get creditsNewBalance => 'New balance';

  @override
  String get creditsPack => 'Pack';

  @override
  String get creditsPrice => 'Price';

  @override
  String get creditsDone => 'Done';

  @override
  String get creditsHistoryTitle => 'Message history';

  @override
  String get creditsSent => 'Sent';

  @override
  String get creditsDelivered => 'Delivered';

  @override
  String get creditsRead => 'Read';

  @override
  String get creditsHistoryEmpty => 'No WhatsApp messages sent yet';

  @override
  String get creditsFilterAll => 'All';

  @override
  String get creditsFilterBookings => 'Bookings';

  @override
  String get creditsFilterReminders => 'Reminders';

  @override
  String get creditsFilterReceipts => 'Receipts';

  @override
  String get creditsUsedLabel => 'Messages used';

  @override
  String get creditsFreeLabel => 'Free credits this month';

  @override
  String get creditsTemplateTitle => 'Template preview — Booking confirmation';

  @override
  String get creditsTemplateNote =>
      'Templates are approved by WhatsApp. Customer name, car, time and amount are filled in automatically.';

  @override
  String get creditsSendTest => 'Send test to my number';

  @override
  String get creditsSendTestDisabled => 'Available once WhatsApp is connected.';

  @override
  String get creditsZeroTitle => 'No credits left';

  @override
  String get creditsZeroBody =>
      'The pickup reminder was not sent automatically. Buy credits, or send it yourself from your own WhatsApp.';

  @override
  String get creditsZeroBanner => 'WhatsApp credits: 0 left';

  @override
  String get creditsZeroBannerNote => 'You were alerted at 10 credits';

  @override
  String get creditsSendViaWhatsapp => 'Send via my WhatsApp';

  @override
  String get creditsViaWhatsappNote =>
      'Your WhatsApp opens with the message already written. You just tap send.';

  @override
  String get creditsViewHistory => 'View message history';

  @override
  String get creditsViewTemplates => 'View templates';

  @override
  String get customerDetailTitle => 'Customer Profile';

  @override
  String get customerDetailNotFound => 'Customer not found';

  @override
  String get customerDetailNotFoundMessage =>
      'This customer could not be found.';

  @override
  String get customerDetailKycTitle => 'KYC status';

  @override
  String get customerDetailKycOnFile =>
      'KYC documents are on file for this customer.';

  @override
  String get customerDetailKycNotOnFile =>
      'No KYC record on file — this customer is known only from bookings.';

  @override
  String get customerDetailDocuments => 'Documents & photo';

  @override
  String get customerDetailNoDocument => 'Not provided';

  @override
  String get customerDetailProfilePhoto => 'Profile photo';

  @override
  String get customerDetailCnicFront => 'CNIC front';

  @override
  String get customerDetailCnicBack => 'CNIC back';

  @override
  String get customerDetailLicenseFront => 'License front';

  @override
  String get customerDetailLicenseBack => 'License back';

  @override
  String get customerDetailSignature => 'Signature';

  @override
  String get customerDetailRentalHistory => 'Rental history';

  @override
  String get customerDetailTotalSpent => 'Total spent';

  @override
  String get customerDetailTotalDues => 'Outstanding dues';

  @override
  String get customerDetailNotBlacklisted => 'Not blacklisted';

  @override
  String get customerDetailApprovalPending => 'Pending review';

  @override
  String get customerDetailApprove => 'Approve profile';

  @override
  String get customerDetailReject => 'Reject profile';

  @override
  String get customerDetailRejectReasonTitle => 'Reason for rejection';

  @override
  String get customerDetailRejectReasonHint => 'Write the reason…';

  @override
  String get customerDetailRejectReasonRequired =>
      'A reason is required to reject a profile';

  @override
  String get customerDetailRejectConfirm => 'Reject';

  @override
  String get customerDetailApprovalFailed =>
      'Could not update this customer\'s approval. Please try again.';

  @override
  String get customerAddedTitle => 'Customer added';

  @override
  String customerAddedReady(String name) {
    return '$name\'s profile is ready — you can now start a booking.';
  }

  @override
  String get customerAddedStartBooking => 'Start Booking';

  @override
  String get customerAddedViewProfile => 'View Profile';

  @override
  String get customersFilterAll => 'All';

  @override
  String get customersFilterRegular => 'Regular';

  @override
  String get customersFilterNew => 'New';

  @override
  String get customersFilterFlagged => 'Flagged';

  @override
  String get customersBadgeRegular => 'Regular';

  @override
  String get customersBadgeNew => 'New';

  @override
  String get customersViewProfile => 'View Profile';

  @override
  String get returnRefundDeposit => 'Refund Deposit';

  @override
  String returnRefundRecorded(String amount) {
    return 'Deposit refund of Rs. $amount recorded.';
  }

  @override
  String get returnRefundFailed =>
      'Could not record the deposit refund. Please try again.';

  @override
  String get returnRecordingRefund => 'Recording refund…';

  @override
  String get returnCloseBooking => 'Complete & Close Booking';

  @override
  String get contractFareTitle => 'Fare Breakdown';

  @override
  String get contractFareDailyRate => 'Daily Rate';

  @override
  String get contractFareRentalDays => 'Rental Days';

  @override
  String contractFareDays(int days) {
    return '$days days';
  }

  @override
  String get contractFareTotal => 'Total Rent';

  @override
  String get contractAgreeTerms => 'I agree to the terms above';

  @override
  String get contractAgreeSaveFailed =>
      'Could not save your agreement choice. Please try again.';

  @override
  String get contractGuarantorTitle => 'Guarantor / Witness Signature';

  @override
  String get contractGuarantorHint =>
      'Ask the guarantor to sign in the box below.';

  @override
  String get contractSignAgreement => 'Sign Agreement';

  @override
  String get contractSigning => 'Signing…';

  @override
  String get contractAgreementSigned => 'Agreement fully signed';

  @override
  String get contractSignFailed =>
      'Could not save the signature. Please try again.';

  @override
  String get contractShareTitle => 'Share Agreement';

  @override
  String get contractShareWhatsapp => 'WhatsApp';

  @override
  String get contractShareEmail => 'Email';

  @override
  String get contractSharePrint => 'Print';

  @override
  String get contractShareNote =>
      'The agreement file is shared to the app you choose. Nothing is sent automatically.';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authLegalIntro => 'By continuing, you agree to our';

  @override
  String get authLegalAnd => 'and';

  @override
  String get legalTermsBody =>
      'RentalHub Terms of Service\n\n1. What RentalHub is\nRentalHub is a car rental marketplace in Pakistan that connects vehicle owners (shops) with customers. Owners list their vehicles and set their own rates; customers book through the app.\n\n2. Your account\nYou are responsible for keeping your sign-in details safe and for everything done with your account. Give true information about yourself, your shop and your vehicles.\n\n3. Bookings and payments\nBooking prices are set by the vehicle owner. Payments, advances and security deposits follow the terms shown at booking time. A booking can be cancelled under the cancellation terms shown for that booking.\n\n4. Your responsibilities\nOwners must keep their vehicles roadworthy, insured and legally registered, and must honour confirmed bookings. Customers must return vehicles on time, in the condition received, and pay any agreed extra charges for damage, late return or extra kilometres.\n\n5. Prohibited use\nDo not use RentalHub for anything unlawful, do not list a vehicle you do not have the right to rent out, and do not share another person\'s personal information without their permission.\n\n6. Liability\nRentalHub provides the marketplace and the booking tools. Owners and customers are responsible for their own vehicles, driving and agreements with each other. To the extent allowed by law, RentalHub is not liable for loss or damage arising from a rental between an owner and a customer.\n\n7. Changes and contact\nWe may update these terms and will show the current version in the app. Questions: contact RentalHub support from the Help section in the app.';

  @override
  String get legalPrivacyBody =>
      'RentalHub Privacy Policy\n\n1. What we collect\nWe collect the information you give us: your name, phone number, email address, CNIC details and documents, shop details, vehicle details and photos, booking and payment records, and messages you send through the app. We also collect basic technical information such as device type and app usage needed to run the service.\n\n2. How we use it\nWe use your information to run RentalHub: to create and verify accounts, list vehicles, process bookings and payments, prevent fraud and blacklisted rentals, and to contact you about your bookings and your shop.\n\n3. How we share it\nWe share your information only as needed to run the service: with the other party to your booking (owner or customer), with payment providers to process payments, and with the authorities when the law requires it. We do not sell your personal information.\n\n4. Photos and documents\nCNIC photos, selfies, licences and shop photos are used only for verification and for the rental record. They are not used for face matching and are not shared publicly.\n\n5. How long we keep it\nWe keep your information while your account is active and for as long as needed for bookings, payments, disputes and legal records. You can ask us to delete your account and its personal information from the Help section, subject to records we must keep by law.\n\n6. Your choices\nYou can update your profile and shop details in the app, and you can turn app notifications on or off in Settings.\n\n7. Contact\nQuestions about your data: contact RentalHub support from the Help section in the app.';

  @override
  String get onboardingSubmitForReview => 'Submit for Review';

  @override
  String onboardingDocRequired(String document) {
    return '$document is required before submitting.';
  }

  @override
  String get addVehicleCityRatesTitle => 'In-City / Out-City Day Rates';

  @override
  String get addVehicleCityRatesHint =>
      'Prefilled from your full-day rate. Change either rate if trips outside the city cost more.';

  @override
  String get addVehicleInCityDayRate => 'In-City Day Rate';

  @override
  String get addVehicleInCityDayRateHint => 'Same-city bookings, per day';

  @override
  String get addVehicleOutCityDayRate => 'Out-City Day Rate';

  @override
  String get addVehicleOutCityDayRateHint => 'Trips outside the city, per day';

  @override
  String get shareTitle => 'Share with Customers';

  @override
  String shareStepOfTwo(int step) {
    return 'Step $step of 2';
  }

  @override
  String get shareChoosePrice => 'Choose a price to share';

  @override
  String shareWithCustomersText(
      String vehicle, String rate, String period, String link) {
    return 'Rent $vehicle for $rate ($period) on RentalHub: $link';
  }

  @override
  String get shareLinkNote =>
      'The web listing page behind this link is not live yet.';

  @override
  String get rateMatrixInCityTitle => 'In-City Rent Rates';

  @override
  String get rateMatrixOutCityTitle => 'Out-City Rent Rates';

  @override
  String get settingsNotifyBookingRequests => 'Booking requests';

  @override
  String get settingsNotifyPaymentProofs => 'Payment proofs';

  @override
  String get settingsNotifyHandover => 'Handover';

  @override
  String get settingsNotifyReturns => 'Returns';

  @override
  String get settingsNotifyMaintenance => 'Maintenance reminders';

  @override
  String get reportDownloadPdf => 'Download PDF';

  @override
  String get reportDownloadPdfSaved => 'Report PDF saved to your device.';

  @override
  String get carEditorTitle => 'Package rates';

  @override
  String get carEditorSave => 'Save package';

  @override
  String get carEditorSaved => 'Rates saved';

  @override
  String get outCityRulesTitle => 'Out-of-city rules';

  @override
  String get outCityRulesSave => 'Save rules';

  @override
  String get outCityRulesSaved => 'Rules saved';

  @override
  String get outCityTripCharges => 'Trip charges';

  @override
  String get outCityRulesAppliesAll => 'Applies to all packages';

  @override
  String get outCityBoundaryTitle => 'Home city boundary';

  @override
  String get outCityBoundaryCity => 'City';

  @override
  String get outCityBoundaryRadius => 'Radius (km)';

  @override
  String get editVehicleTitle => 'Edit car details';

  @override
  String get editVehicleSave => 'Save details';

  @override
  String get editVehicleSaved => 'Car details saved';

  @override
  String get editVehicleStatus => 'Status';

  @override
  String get outCityModePerDay => 'Per day';

  @override
  String get outCityModePerKm => 'Per km';

  @override
  String get outCityModeFixedRoute => 'Fixed route';

  @override
  String get outCityPricingMode => 'Pricing mode';

  @override
  String get outCityPerKmRate => 'Per-km rate (Rs/km)';

  @override
  String get outCityFixedRouteLabel => 'Fixed route';

  @override
  String get outCityFixedRouteNone => 'No fixed route selected';

  @override
  String get outCityFixedRouteChoose => 'Choose a fixed route';

  @override
  String farePerKmUnit(String rate) {
    return '$rate / km';
  }

  @override
  String fareFixedRoute(String route) {
    return 'Fixed route: $route';
  }

  @override
  String farePerKmEstimate(int km) {
    return 'Estimated on $km km — final total on actual km at return';
  }

  @override
  String get outCityNightStay => 'Driver night stay (per night)';

  @override
  String get outCityNightStayCap =>
      'Charged for each night away from the home city';

  @override
  String get outCityTolls => 'Tolls & parking';

  @override
  String get outCityTollsCustomer => 'Paid by customer';

  @override
  String get outCityTollsIncluded => 'Included in rent';

  @override
  String bookingFareNightStay(int nights) {
    return 'Driver night stay ($nights nights)';
  }

  @override
  String get bookingFareTollsCustomer => 'Tolls & parking — paid by customer';

  @override
  String get bookingFareTollsIncluded => 'Tolls & parking — included in rent';

  @override
  String get outCityMapOffline => 'Map unavailable offline';

  @override
  String get outCityMapNoLocation =>
      'Shop location not set — boundary shown as text';

  @override
  String get shops_title => 'Shops';

  @override
  String get shops_showMap => 'Map view';

  @override
  String get shops_showList => 'List view';

  @override
  String get shops_allCities => 'All cities';

  @override
  String get shops_unverified => 'Unverified';

  @override
  String get shops_emptyTitle => 'No shops match these filters';

  @override
  String get shops_emptySubtitle => 'Try a different city or filter.';

  @override
  String get shops_mapOffline =>
      'Map unavailable offline — the list still works';

  @override
  String get shops_chooseCity => 'Choose a city to browse shops';

  @override
  String get shops_noPinNote =>
      'Shops without a saved location appear in the list only';

  @override
  String get home2_kpiActive => 'Active bookings';

  @override
  String get home2_kpiWallet => 'Wallet balance';

  @override
  String get home2_support => 'Support';

  @override
  String get home2_kycNotStarted => 'Not started';

  @override
  String home2_kycProgress(Object done, Object total) {
    return '$done of $total documents ready';
  }

  @override
  String get home2_kycView => 'View documents';

  @override
  String get home2_recentBookings => 'Recent bookings';

  @override
  String get home2_upcoming => 'Upcoming';

  @override
  String get home2_viewAll => 'View all';

  @override
  String get home2_noBookings => 'No bookings yet';

  @override
  String get home2_noUpcoming => 'Nothing coming up';

  @override
  String get home2_paymentOverdue => 'Payment overdue';

  @override
  String get home2_paymentDue => 'Payment due';

  @override
  String get admin2_displayUnverifiedShops => 'Display unverified shops';

  @override
  String get admin2_displayUnverifiedShopsHint =>
      'When off, unverified shops are hidden from the Shops tab.';

  @override
  String get admin2_allowBookingsFromUnverifiedShops =>
      'Allow bookings from unverified shops';

  @override
  String get admin2_allowBookingsFromUnverifiedShopsHint =>
      'When off, customers cannot book from unverified shops.';

  @override
  String get admin2_unverifiedBookingsDisabled =>
      'Bookings from unverified shops are currently disabled by the platform.';

  @override
  String get kyc2_qrCode => 'QR Code';

  @override
  String get kyc2_qrRead => 'QR code saved.';

  @override
  String get kyc2_licenseUnreadable =>
      'Could not read the license number from that photo — please type it.';

  @override
  String get appealTitle => 'Appeal blacklist listing';

  @override
  String get appealButton => 'Appeal blacklist decision';

  @override
  String get appealIntro =>
      'If you believe this listing is a mistake, you can ask the tribunal to review it.';

  @override
  String get appealReasonLabel => 'Reason for appeal';

  @override
  String get appealReasonHint => 'Explain why this listing should be reviewed…';

  @override
  String get appealReasonRequired => 'Please write a reason for your appeal.';

  @override
  String get appealSubmit => 'Submit appeal';

  @override
  String get appealSuccess => 'Appeal submitted. The tribunal will review it.';

  @override
  String get appealError => 'Could not submit the appeal. Please try again.';

  @override
  String get appealRecordNotFound =>
      'No blacklist record was found for this CNIC.';

  @override
  String get anncTitle => 'Announcement';

  @override
  String get anncLoading => 'Loading announcement…';

  @override
  String get anncNotFound => 'This announcement is no longer available.';

  @override
  String get anncLoadError =>
      'Could not load the announcement. Please try again.';

  @override
  String get couldNotOpenDialer => 'Could not open the dialer.';

  @override
  String get countdownPickupReached => 'Pickup time reached';

  @override
  String get countdownReturnReached => 'Return time reached';

  @override
  String get countdownTimeReached => 'Time reached';

  @override
  String kycRejectionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get onboardingNameHint => 'Your full name';

  @override
  String get pickerPastTime =>
      'That time has already passed. Please pick a later time.';

  @override
  String get rateSelectBoth => 'Please rate both the shop and the vehicle.';

  @override
  String get reviewDraftMissing =>
      'Booking details are missing. Please start again.';

  @override
  String get reviewSignInRequired => 'Please sign in to submit this booking.';

  @override
  String get reviewSubmitFailed =>
      'Could not submit the booking. Please try again.';

  @override
  String get shopLoadFailed => 'Could not load this showroom.';

  @override
  String get shopNoPhoneNumber => 'No phone number for this shop.';

  @override
  String shopWhatsappHello(String shopName) {
    return 'Hello $shopName, I found your listing on RentalHub.';
  }

  @override
  String get signInRequiredGeneric => 'Please sign in to continue.';

  @override
  String get statusProofRejected => 'Proof rejected';

  @override
  String get tripOutCityFixedRouteLine => 'Out-of-city: fixed route price';

  @override
  String tripOutCityPerDayLine(String rate) {
    return 'Out-of-city: $rate / day';
  }

  @override
  String tripOutCityPerKmLine(String rate) {
    return 'Out-of-city: $rate / km';
  }

  @override
  String get vehicleLoadFailed => 'Could not load this vehicle.';

  @override
  String get manualBookingWhatsappToggle => 'Send WhatsApp confirmation';
}
