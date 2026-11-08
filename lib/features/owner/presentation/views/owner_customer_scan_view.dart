import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../blacklist/domain/entities/blacklist_entity.dart';
import '../../../trust/data/services/cnic_ocr_service.dart';
import '../widgets/operations/cnic_scanner_input_widget.dart';
import '../widgets/operations/blacklist_status_banner.dart';
import 'owner_cnic_review_view.dart';

class OwnerCustomerScanView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerCustomerScanView({super.key, this.onBack});

  @override
  State<OwnerCustomerScanView> createState() => _OwnerCustomerScanViewState();
}

class _OwnerCustomerScanViewState extends State<OwnerCustomerScanView> {
  final _cnicController = TextEditingController();
  bool _isVerifying = false;
  bool _hasSearched = false;
  BlacklistEntity? _foundBlacklist;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _verifyCnic() async {
  final l10n = AppLocalizations.of(context)!;
    final cnic = _cnicController.text.trim();
    if (cnic.length < 13) {
      AppFeedback.showError(
          context, l10n.customersScanInvalidCnic);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final ds = sl<BlacklistRemoteDataSource>();
      final isBlacklisted = await ds.isCnicBlacklisted(cnic);
      if (isBlacklisted) {
        final record = await ds.getBlacklistRecordByCnic(cnic);
        setState(() {
          _foundBlacklist = record ??
              BlacklistEntity(
                blacklistId: 'BLK-AUTO',
                reportedByShopId: 'All-Pakistan Tribunal',
                cnicNumber: cnic,
                phoneNumber: '0300-0000000',
                reasonCategory: l10n.customersScanFallbackReason,
                description: l10n.customersScanFallbackDescription,
              );
          _hasSearched = true;
        });
      } else {
        setState(() {
          _foundBlacklist = null;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.customersScanLookupFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Phase B (C2): real on-device OCR. The camera photo is read by
  /// ML Kit, the owner reviews and corrects the result, and only then
  /// is the customer saved and the blacklist checked.
  Future<void> _scanCnicWithCamera() async {
  final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _isVerifying = true);
    try {
      final result = await CnicOcrService().scanFront(File(picked.path));
      if (!mounted) return;
      if (!result.hasAnything) {
        AppFeedback.showError(
            context, l10n.customersScanUnreadable);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OwnerCnicReviewView(
            initial: result,
            onSaved: (cnic) {
              _cnicController.text = cnic;
              _verifyCnic();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.customersScanFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Phone-test #18: a clean scan now opens the Add Customer form
  /// (CNIC prefilled) instead of jumping straight into the walk-in
  /// booking wizard. Adding a customer is completable without booking
  /// a car; booking stays reachable from the customer row and from
  /// Requests → New Booking.
  void _proceedToAddCustomer() {
    final cnic = Uri.encodeComponent(_cnicController.text.trim());
    context.push('${RouteNames.ownerAddCustomer}?cnic=$cnic');
  }

  void _declineCustomer() {
  final l10n = AppLocalizations.of(context)!;
    AppFeedback.showInfo(
        context, l10n.customersScanDeclined);
    setState(() {
      _hasSearched = false;
      _foundBlacklist = null;
      _cnicController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.customersScanTitle,
              subtitle: l10n.customersScanSubtitle,
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: l10n.customersScanTribunalPolicy,
                  onPressed: () => AppFeedback.showInfo(context,
                      l10n.customersScanTribunalInfo),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CnicScannerInputWidget(
                      controller: _cnicController,
                      isVerifying: _isVerifying,
                      onVerify: _verifyCnic,
                      onCameraScan: _scanCnicWithCamera,
                    ),
                    const SizedBox(height: 18),
                    BlacklistStatusBanner(
                      isChecked: _hasSearched,
                      blacklistedRecord: _foundBlacklist,
                      onProceed: _proceedToAddCustomer,
                      onDecline: _declineCustomer,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/owner/customers'),
                        icon: const Icon(Icons.people_rounded),
                        label: Text(l10n.customersScanViewAll),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/owner/blacklist'),
                        icon: const Icon(Icons.flag_rounded),
                        label: Text(l10n.blacklist),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
