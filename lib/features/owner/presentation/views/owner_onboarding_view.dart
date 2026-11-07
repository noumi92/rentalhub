import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../constants/owner_onboarding_constants.dart';
import '../services/owner_onboarding_submission_service.dart';
import '../widgets/onboarding/onboarding_stepper_bar.dart';
import '../widgets/onboarding/shop_approval_status_step_widget.dart';
import '../widgets/onboarding/shop_details_step_widget.dart';
import '../widgets/onboarding/shop_kyc_docs_step_widget.dart';
import '../widgets/onboarding/shop_location_step_widget.dart';
import '../widgets/onboarding/shop_payout_step_widget.dart';

class OwnerOnboardingView extends StatefulWidget {
  const OwnerOnboardingView({super.key});

  @override
  State<OwnerOnboardingView> createState() => _OwnerOnboardingViewState();
}

class _OwnerOnboardingViewState extends State<OwnerOnboardingView> {
  int _currentStep = 1;

  // Step 1: Details
  XFile? _shopLogoFile;
  final _shopNameController = TextEditingController(text: 'Al-Falah Rent a Car');
  final _ownerNameController = TextEditingController(text: 'Ahmed Raza');
  final _cnicController = TextEditingController(text: '35201-9876543-1');
  final _whatsappController = TextEditingController(text: '03001234567');
  final _phoneController = TextEditingController(text: '04235761234');
  String _openingHours = '9:00 AM - 10:00 PM';

  // Step 2: Location
  final MapController _mapController = MapController();
  ll.LatLng _shopPin = const ll.LatLng(31.4720, 74.3850);
  final _addressController = TextEditingController(text: 'Shop 12, Main Boulevard, DHA Phase 5');
  String _selectedCity = 'Lahore';
  bool _isLocating = false;

  // Step 3: Payout (Initially disabled)
  bool _jazzCashEnabled = false, _easyPaisaEnabled = false, _bankEnabled = false;
  final _jazzCashAccount = TextEditingController(text: '03001234567');
  final _jazzCashTitle = TextEditingController(text: 'Ahmed Raza');
  final _easyPaisaAccount = TextEditingController(text: '03457654321');
  final _easyPaisaTitle = TextEditingController(text: 'Ahmed Raza');
  String _selectedBankName = 'Meezan Bank';
  final _bankAccountController = TextEditingController(text: 'PK36MEZN0001234567890123');
  final _bankAccountTitle = TextEditingController(text: 'Al-Falah Rent a Car');

  // Step 4: Documents & Photos
  XFile? _cnicFrontFile, _cnicBackFile, _shopHeaderFile;
  XFile? _fleetPhoto1File, _fleetPhoto2File, _fleetPhoto3File, _ntnFile, _selfieFile;

  @override
  void dispose() {
    for (final c in [_shopNameController, _ownerNameController, _cnicController, _whatsappController, _phoneController, _addressController, _jazzCashAccount, _jazzCashTitle, _easyPaisaAccount, _easyPaisaTitle, _bankAccountController, _bankAccountTitle]) {
      c.dispose();
    }
    super.dispose();
  }

  void _chooseMedia(Function(XFile?) onSet, {bool frontOnly = false, bool hasExisting = false}) {
    MediaPickerHelper.showMediaSourceSheet(context: context, onImageSelected: (f) => setState(() => onSet(f)), frontCameraOnly: frontOnly, hasExistingFile: hasExisting);
  }

  Future<void> _fetchCurrentGps() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        final newPin = ll.LatLng(pos.latitude, pos.longitude);
        setState(() {
          _shopPin = newPin;
          _addressController.text = 'Current GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        });
        _mapController.move(newPin, 15.0);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  bool _validateStep() {
    if (_currentStep == 1) {
      if (_shopNameController.text.trim().length < 3) {
        AppFeedback.showError(context, 'Shop name must be at least 3 characters.');
        return false;
      }
      final phoneErr = PakistaniValidators.validatePakistaniPhone(_whatsappController.text);
      if (phoneErr != null) {
        AppFeedback.showError(context, phoneErr);
        return false;
      }
    } else if (_currentStep == 2) {
      if (_addressController.text.trim().length < 5) {
        AppFeedback.showError(context, 'Please enter a valid showroom address.');
        return false;
      }
    } else if (_currentStep == 3) {
      if (!_jazzCashEnabled && !_easyPaisaEnabled && !_bankEnabled) {
        AppFeedback.showWarning(context, 'Please enable at least one payout method.');
        return false;
      }
      if (_bankEnabled) {
        final ibanErr = PakistaniValidators.validatePakistaniIban(_bankAccountController.text);
        if (ibanErr != null) {
          AppFeedback.showError(context, ibanErr);
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _handleSubmitShop() async {
    setState(() => _isLocating = true);
    try {
      final accounts = [
        if (_jazzCashEnabled) {'type': 'jazzcash', 'account': _jazzCashAccount.text.trim(), 'title': _jazzCashTitle.text.trim()},
        if (_easyPaisaEnabled) {'type': 'easypaisa', 'account': _easyPaisaAccount.text.trim(), 'title': _easyPaisaTitle.text.trim()},
        if (_bankEnabled) {'type': 'bank', 'bank_name': _selectedBankName, 'iban': _bankAccountController.text.trim(), 'title': _bankAccountTitle.text.trim()},
      ];
      await OwnerOnboardingSubmissionService.submitShowroomProfile(
        shopName: _shopNameController.text, ownerName: _ownerNameController.text, cnic: _cnicController.text,
        whatsapp: _whatsappController.text, phone: _phoneController.text, openingHours: _openingHours,
        shopPin: _shopPin, address: _addressController.text, city: _selectedCity, bankAccounts: accounts,
        shopLogoFile: _shopLogoFile, shopHeaderFile: _shopHeaderFile, fleetPhoto1File: _fleetPhoto1File,
        fleetPhoto2File: _fleetPhoto2File, fleetPhoto3File: _fleetPhoto3File, cnicFrontFile: _cnicFrontFile,
        cnicBackFile: _cnicBackFile, ntnFile: _ntnFile, selfieFile: _selfieFile,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Showroom profile submitted for verification!');
      setState(() => _currentStep = 5);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _handleNext() async {
    if (!_validateStep()) return;
    if (_currentStep == 4) {
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomCurvedHeader(
                      height: 105,
                      leadingWidget: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: _prevStep),
                      titleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getHeaderTitle(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(_getHeaderSubtitle(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                        ],
                      ),
                      actions: [
                        if (_currentStep < 5)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                            child: Text('Step $_currentStep of 4', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                      ],
                    ),
                    if (_currentStep < 5) OnboardingStepperBar(currentStep: _currentStep),
                    Padding(padding: const EdgeInsets.all(16), child: _buildCurrentStepContent()),
                  ],
                ),
              ),
            ),
            if (_currentStep < 5)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderSubtle)), boxShadow: [BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, -3))]),
                child: DebouncedButton(
                  text: _currentStep == 4 ? 'Submit Shop for Verification' : 'Next Step',
                  icon: _currentStep == 4 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                  onPressed: () async => _handleNext(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return ShopDetailsStepWidget(
          shopLogoFile: _shopLogoFile,
          onPickLogo: () => _chooseMedia((f) => _shopLogoFile = f, hasExisting: _shopLogoFile != null),
          shopNameController: _shopNameController,
          ownerNameController: _ownerNameController,
          cnicController: _cnicController,
          whatsappController: _whatsappController,
          phoneController: _phoneController,
          openingHours: _openingHours,
          onOpeningHoursChanged: (v) => setState(() => _openingHours = v),
        );
      case 2:
        return ShopLocationStepWidget(
          mapController: _mapController,
          shopPin: _shopPin,
          onPinChanged: (p) => setState(() => _shopPin = p),
          addressController: _addressController,
          selectedCity: _selectedCity,
          onCityChanged: (c) => setState(() => _selectedCity = c),
          majorCities: OwnerOnboardingConstants.majorCities,
          isLocating: _isLocating,
          onFetchGps: _fetchCurrentGps,
        );
      case 3:
        return ShopPayoutStepWidget(
          jazzCashEnabled: _jazzCashEnabled, onJazzCashToggle: (v) => setState(() => _jazzCashEnabled = v), jazzCashAccount: _jazzCashAccount, jazzCashTitle: _jazzCashTitle,
          easyPaisaEnabled: _easyPaisaEnabled, onEasyPaisaToggle: (v) => setState(() => _easyPaisaEnabled = v), easyPaisaAccount: _easyPaisaAccount, easyPaisaTitle: _easyPaisaTitle,
          bankEnabled: _bankEnabled, onBankToggle: (v) => setState(() => _bankEnabled = v), selectedBankName: _selectedBankName, onBankNameChanged: (b) => setState(() => _selectedBankName = b),
          pakistaniBanks: OwnerOnboardingConstants.pakistaniBanks, bankAccountController: _bankAccountController, bankAccountTitle: _bankAccountTitle,
        );
      case 4:
        return ShopKycDocsStepWidget(
          shopHeaderFile: _shopHeaderFile, onPickShopHeader: () => _chooseMedia((f) => _shopHeaderFile = f, hasExisting: _shopHeaderFile != null), onRemoveShopHeader: () => setState(() => _shopHeaderFile = null),
          fleetPhoto1File: _fleetPhoto1File, onPickFleet1: () => _chooseMedia((f) => _fleetPhoto1File = f, hasExisting: _fleetPhoto1File != null), onRemoveFleet1: () => setState(() => _fleetPhoto1File = null),
          fleetPhoto2File: _fleetPhoto2File, onPickFleet2: () => _chooseMedia((f) => _fleetPhoto2File = f, hasExisting: _fleetPhoto2File != null), onRemoveFleet2: () => setState(() => _fleetPhoto2File = null),
          fleetPhoto3File: _fleetPhoto3File, onPickFleet3: () => _chooseMedia((f) => _fleetPhoto3File = f, hasExisting: _fleetPhoto3File != null), onRemoveFleet3: () => setState(() => _fleetPhoto3File = null),
          cnicFrontFile: _cnicFrontFile, onPickCnicFront: () => _chooseMedia((f) => _cnicFrontFile = f, hasExisting: _cnicFrontFile != null), onRemoveCnicFront: () => setState(() => _cnicFrontFile = null),
          cnicBackFile: _cnicBackFile, onPickCnicBack: () => _chooseMedia((f) => _cnicBackFile = f, hasExisting: _cnicBackFile != null), onRemoveCnicBack: () => setState(() => _cnicBackFile = null),
          ntnFile: _ntnFile, onPickNtn: () => _chooseMedia((f) => _ntnFile = f, hasExisting: _ntnFile != null), onRemoveNtn: () => setState(() => _ntnFile = null),
          selfieFile: _selfieFile, onPickSelfie: () => _chooseMedia((f) => _selfieFile = f, frontOnly: true, hasExisting: _selfieFile != null), onRemoveSelfie: () => setState(() => _selfieFile = null),
        );
      case 5:
      default:
        return ShopApprovalStatusStepWidget(onGoToFleet: () => context.go(RouteNames.ownerFleet));
    }
  }

  String _getHeaderTitle() => const {
    1: 'Shop Registration',
    2: 'Location & Map Pin',
    3: 'Payout Accounts',
    4: 'KYC & Verification',
  }[_currentStep] ?? 'Application Submitted';

  String _getHeaderSubtitle() => const {
    1: 'Business identity and contact details',
    2: 'Physical address and geo-coordinates',
    3: 'JazzCash, EasyPaisa or Pakistani Bank',
    4: 'Shop banner, 3 fleet photos & CNIC',
  }[_currentStep] ?? 'Review status and fleet management';
}
