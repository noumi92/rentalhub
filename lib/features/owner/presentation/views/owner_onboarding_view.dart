import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../constants/owner_onboarding_constants.dart';
import '../services/owner_onboarding_submission_service.dart';
import '../widgets/onboarding/onboarding_stepper_bar.dart';
import '../widgets/onboarding/shop_approval_status_step_widget.dart';
import '../widgets/onboarding/shop_review_step_widget.dart';
import '../widgets/onboarding/shop_details_step_widget.dart';
import '../widgets/onboarding/shop_kyc_docs_step_widget.dart';
import '../widgets/onboarding/shop_location_step_widget.dart';
import '../widgets/onboarding/shop_payout_step_widget.dart';

class OwnerOnboardingView extends StatefulWidget {
  /// Audit §5 (P2-5): the fleet-add gate links to the status step, so
  /// the router may open the wizard straight at it (`initialStep: 6`).
  final int initialStep;
  const OwnerOnboardingView({super.key, this.initialStep = 1});

  @override
  State<OwnerOnboardingView> createState() => _OwnerOnboardingViewState();
}

class _OwnerOnboardingViewState extends State<OwnerOnboardingView> {
  late int _currentStep = widget.initialStep;

  // Step 1: Details — controllers start EMPTY (audit §1/C6): the old prefilled shop name / owner / CNIC / phones were publishable as-is. Hints live on the fields (see the step widgets).
  XFile? _shopLogoFile;
  final _shopNameController = TextEditingController(); final _ownerNameController = TextEditingController();
  final _cnicController = TextEditingController(); final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  String _openingHours = '9:00 AM - 10:00 PM';

  // Step 2: Location
  final MapController _mapController = MapController();
  ll.LatLng _shopPin = const ll.LatLng(31.4720, 74.3850);
  final _addressController = TextEditingController();
  String _selectedCity = 'Lahore';
  bool _isLocating = false;
  // Audit §1: submit progress is its own flag — _isLocating used to double as the submit flag, so the button showed no loading state.
  bool _isSubmitting = false;

  // Step 3: Payout (Initially disabled)
  bool _jazzCashEnabled = false, _easyPaisaEnabled = false, _bankEnabled = false;
  final _jazzCashAccount = TextEditingController(); final _jazzCashTitle = TextEditingController();
  final _easyPaisaAccount = TextEditingController(); final _easyPaisaTitle = TextEditingController();
  String _selectedBankName = 'Meezan Bank';
  final _bankAccountController = TextEditingController(); final _bankAccountTitle = TextEditingController();

  // Step 4: Documents & Photos
  XFile? _cnicFrontFile, _cnicBackFile, _shopHeaderFile;
  XFile? _fleetPhoto1File, _fleetPhoto2File, _fleetPhoto3File, _ntnFile, _selfieFile;

  @override
  void dispose() {
    for (final c in [_shopNameController, _ownerNameController, _cnicController, _whatsappController, _phoneController, _addressController, _jazzCashAccount, _jazzCashTitle, _easyPaisaAccount, _easyPaisaTitle, _bankAccountController, _bankAccountTitle]) { c.dispose();
    }
    super.dispose();
  }

  void _chooseMedia(Function(XFile?) onSet, {bool frontOnly = false, bool hasExisting = false}) {
    MediaPickerHelper.showMediaSourceSheet(context: context, onImageSelected: (f) => setState(() => onSet(f)), frontCameraOnly: frontOnly, hasExistingFile: hasExisting);
  }

  Future<void> _fetchCurrentGps() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        final newPin = ll.LatLng(pos.latitude, pos.longitude);
        setState(() { _shopPin = newPin; _addressController.text = l10n.onboardingCurrentGps(pos.latitude.toStringAsFixed(4), pos.longitude.toStringAsFixed(4)); }); _mapController.move(newPin, 15.0);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  bool _validateStep() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentStep == 1) {
      if (_shopNameController.text.trim().length < 3) { AppFeedback.showError(context, l10n.onboardingShopNameShort); return false; }
      final phoneErr = PakistaniValidators.validatePakistaniPhone(_whatsappController.text);
      if (phoneErr != null) {
        AppFeedback.showError(context, phoneErr);
        return false; }
    } else if (_currentStep == 2) {
      if (_addressController.text.trim().length < 5) { AppFeedback.showError(context, l10n.onboardingAddressInvalid); return false;
      }
    } else if (_currentStep == 3) {
      if (!_jazzCashEnabled && !_easyPaisaEnabled && !_bankEnabled) { AppFeedback.showWarning(context, l10n.onboardingPayoutRequired); return false;
      }
      if (_bankEnabled) {
        final ibanErr = PakistaniValidators.validatePakistaniIban(_bankAccountController.text);
        if (ibanErr != null) { AppFeedback.showError(context, ibanErr); return false; }
      }
    } else if (_currentStep == 4) {
      // Audit §5 finish (P2-4): CNIC front + back + selfie are REQUIRED — missing ones block submit with field errors, never a success.
      final missing = <String>[if (_cnicFrontFile == null) l10n.onboardingCnicFront, if (_cnicBackFile == null) l10n.onboardingCnicBack, if (_selfieFile == null) l10n.onboardingSelfie];
      if (missing.isNotEmpty) { AppFeedback.showError(context, l10n.onboardingDocRequired(missing.join(', '))); return false; }
    }
    return true;
  }

  Future<void> _handleSubmitShop() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final accounts = [
        if (_jazzCashEnabled) {'type': 'jazzcash', 'account': _jazzCashAccount.text.trim(), 'title': _jazzCashTitle.text.trim()},
        if (_easyPaisaEnabled) {'type': 'easypaisa', 'account': _easyPaisaAccount.text.trim(), 'title': _easyPaisaTitle.text.trim()},
        if (_bankEnabled) {'type': 'bank', 'bank_name': _selectedBankName, 'iban': _bankAccountController.text.trim(), 'title': _bankAccountTitle.text.trim()},
      ];
      await OwnerOnboardingSubmissionService.submitShowroomProfile(
        shopName: _shopNameController.text, ownerName: _ownerNameController.text, cnic: _cnicController.text, whatsapp: _whatsappController.text, phone: _phoneController.text, openingHours: _openingHours,
        shopPin: _shopPin, address: _addressController.text, city: _selectedCity, bankAccounts: accounts, shopLogoFile: _shopLogoFile, shopHeaderFile: _shopHeaderFile,
        fleetPhoto1File: _fleetPhoto1File, fleetPhoto2File: _fleetPhoto2File, fleetPhoto3File: _fleetPhoto3File, cnicFrontFile: _cnicFrontFile, cnicBackFile: _cnicBackFile, ntnFile: _ntnFile, selfieFile: _selfieFile,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.onboardingSubmitted);
      setState(() => _currentStep = 6);
    } catch (_) {
      if (!mounted) return;
      AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleNext() async {
    if (!_validateStep()) return;
    if (_currentStep == 5) {
      await _handleSubmitShop();
      return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.onboardingRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset — no double status bar.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: _getHeaderTitle(l10n),
              subtitle: _getHeaderSubtitle(l10n),
              onBack: _prevStep,
              actions: [
                if (_currentStep < 6)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                    child: Text(l10n.onboardingStepOfFive(_currentStep), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep < 6) OnboardingStepperBar(currentStep: _currentStep),
                    Padding(padding: const EdgeInsets.all(16), child: _buildCurrentStepContent()),
                  ],
                ),
              ),
            ),
            if (_currentStep < 6)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor)), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: Offset(0, -3))]),
                child: DebouncedButton(
                  text: _currentStep == 5 ? l10n.onboardingSubmitForReview : l10n.onboardingNextStep, // Audit §5 finish (P2-4): review-step button reads "Submit for Review".
                  icon: _currentStep == 5 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                  isLoading: _isSubmitting,
                  onPressed: () async => _handleNext(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 1:
        return ShopDetailsStepWidget(shopLogoFile: _shopLogoFile, onPickLogo: () => _chooseMedia((f) => _shopLogoFile = f, hasExisting: _shopLogoFile != null),
          shopNameController: _shopNameController, ownerNameController: _ownerNameController, cnicController: _cnicController, whatsappController: _whatsappController, phoneController: _phoneController,
          openingHours: _openingHours, onOpeningHoursChanged: (v) => setState(() => _openingHours = v));
      case 2:
        return ShopLocationStepWidget(mapController: _mapController, shopPin: _shopPin, onPinChanged: (p) { setState(() => _shopPin = p); _mapController.move(p, 14.0); },
          addressController: _addressController, selectedCity: _selectedCity, onCityChanged: (c) => setState(() => _selectedCity = c), majorCities: OwnerOnboardingConstants.majorCities, isLocating: _isLocating, onFetchGps: _fetchCurrentGps);
      case 3:
        return ShopPayoutStepWidget(jazzCashEnabled: _jazzCashEnabled, onJazzCashToggle: (v) => setState(() => _jazzCashEnabled = v), jazzCashAccount: _jazzCashAccount, jazzCashTitle: _jazzCashTitle,
          easyPaisaEnabled: _easyPaisaEnabled, onEasyPaisaToggle: (v) => setState(() => _easyPaisaEnabled = v), easyPaisaAccount: _easyPaisaAccount, easyPaisaTitle: _easyPaisaTitle,
          bankEnabled: _bankEnabled, onBankToggle: (v) => setState(() => _bankEnabled = v), selectedBankName: _selectedBankName, onBankNameChanged: (b) => setState(() => _selectedBankName = b), pakistaniBanks: OwnerOnboardingConstants.pakistaniBanks, bankAccountController: _bankAccountController, bankAccountTitle: _bankAccountTitle);
      case 4:
        return ShopKycDocsStepWidget(shopHeaderFile: _shopHeaderFile, onPickShopHeader: () => _chooseMedia((f) => _shopHeaderFile = f, hasExisting: _shopHeaderFile != null), onRemoveShopHeader: () => setState(() => _shopHeaderFile = null),
          fleetPhoto1File: _fleetPhoto1File, onPickFleet1: () => _chooseMedia((f) => _fleetPhoto1File = f, hasExisting: _fleetPhoto1File != null), onRemoveFleet1: () => setState(() => _fleetPhoto1File = null), fleetPhoto2File: _fleetPhoto2File, onPickFleet2: () => _chooseMedia((f) => _fleetPhoto2File = f, hasExisting: _fleetPhoto2File != null), onRemoveFleet2: () => setState(() => _fleetPhoto2File = null),
          fleetPhoto3File: _fleetPhoto3File, onPickFleet3: () => _chooseMedia((f) => _fleetPhoto3File = f, hasExisting: _fleetPhoto3File != null), onRemoveFleet3: () => setState(() => _fleetPhoto3File = null), cnicFrontFile: _cnicFrontFile, onPickCnicFront: () => _chooseMedia((f) => _cnicFrontFile = f, hasExisting: _cnicFrontFile != null), onRemoveCnicFront: () => setState(() => _cnicFrontFile = null),
          cnicBackFile: _cnicBackFile, onPickCnicBack: () => _chooseMedia((f) => _cnicBackFile = f, hasExisting: _cnicBackFile != null), onRemoveCnicBack: () => setState(() => _cnicBackFile = null), ntnFile: _ntnFile, onPickNtn: () => _chooseMedia((f) => _ntnFile = f, hasExisting: _ntnFile != null), onRemoveNtn: () => setState(() => _ntnFile = null), selfieFile: _selfieFile, onPickSelfie: () => _chooseMedia((f) => _selfieFile = f, frontOnly: true, hasExisting: _selfieFile != null), onRemoveSelfie: () => setState(() => _selfieFile = null));
      case 5:
        return ShopReviewStepWidget(
          shopName: _shopNameController.text.trim(), ownerName: _ownerNameController.text.trim(), cnic: _cnicController.text.trim(), whatsapp: _whatsappController.text.trim(),
          phone: _phoneController.text.trim(), openingHours: _openingHours, shopLogoName: _shopLogoFile?.name, address: _addressController.text.trim(), city: _selectedCity,
          payoutMethods: [if (_jazzCashEnabled) 'JazzCash', if (_easyPaisaEnabled) 'EasyPaisa', if (_bankEnabled) _selectedBankName],
          attachedDocuments: [if (_cnicFrontFile != null) l10n.onboardingReviewCnicFront, if (_cnicBackFile != null) l10n.onboardingReviewCnicBack, if (_selfieFile != null) l10n.onboardingReviewSelfie, if (_ntnFile != null) l10n.onboardingReviewNtn, if (_shopHeaderFile != null) l10n.onboardingReviewShopPhoto, if (_fleetPhoto1File != null) l10n.onboardingReviewFleetPhoto1, if (_fleetPhoto2File != null) l10n.onboardingReviewFleetPhoto2, if (_fleetPhoto3File != null) l10n.onboardingReviewFleetPhoto3],
        );
      case 6:
      default:
        return ShopApprovalStatusStepWidget(onGoToFleet: () => context.go(RouteNames.ownerFleet));
    }
  }

  String _getHeaderTitle(AppLocalizations l10n) => { 1: l10n.onboardingHeaderShop, 2: l10n.onboardingHeaderLocation, 3: l10n.onboardingHeaderPayout, 4: l10n.onboardingHeaderKyc, 5: l10n.onboardingHeaderReview, }[_currentStep] ?? l10n.onboardingHeaderSubmitted;

  String _getHeaderSubtitle(AppLocalizations l10n) => { 1: l10n.onboardingSubtitleShop, 2: l10n.onboardingSubtitleLocation, 3: l10n.onboardingSubtitlePayout, 4: l10n.onboardingSubtitleKyc, 5: l10n.onboardingSubtitleReview, }[_currentStep] ?? l10n.onboardingSubtitleSubmitted;
}
