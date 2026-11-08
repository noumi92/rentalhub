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
  // Audit §19: blacklisted, but no record returned — the banner shows
  // the "details unavailable" state; no record is ever invented.
  bool _blacklistNoRecord = false;
  // Audit §19: inline field error (was snackbar-only).
  String? _cnicError;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _verifyCnic() async {
  final l10n = AppLocalizations.of(context)!;
    final cnic = _cnicController.text.trim();
    if (cnic.replaceAll('-', '').trim().length != 13) {
      setState(() => _cnicError = l10n.customersScanInvalidCnic);
      AppFeedback.showError(context, l10n.customersScanInvalidCnic);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final ds = sl<BlacklistRemoteDataSource>();
      final isBlacklisted = await ds.isCnicBlacklisted(cnic);
      if (isBlacklisted) {
        final record = await ds.getBlacklistRecordByCnic(cnic);
        // Audit §19: a null record used to be replaced by a fabricated
        // BLK-AUTO / '0300-0000000' record — now the banner renders
        // "details unavailable" instead.
        setState(() { _foundBlacklist = record; _blacklistNoRecord = record == null; _hasSearched = true; });
      } else {
        setState(() { _foundBlacklist = null; _blacklistNoRecord = false; _hasSearched = true; });
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersScanLookupFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Phase B (C2): real on-device OCR. The camera photo is read by
  /// ML Kit, the owner reviews and corrects the result, and only then
  /// is the customer saved and the blacklist checked.
  Future<void> _scanCnicWithCamera() async {
  final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _isVerifying = true);
    try {
      final result = await CnicOcrService().scanFront(File(picked.path));
      if (!mounted) return;
      if (!result.hasAnything) {
        AppFeedback.showError(context, l10n.customersScanUnreadable);
        return;
      }
      await context.push(
        '/owner/customers/cnic-review',
        extra: <String, dynamic>{
          'result': result,
          'frontImagePath': picked.path,
          'onSaved': (String cnic) { _cnicController.text = cnic; _verifyCnic(); },
        },
      );
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersScanFailed(e.toString()));
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
    AppFeedback.showInfo(context, l10n.customersScanDeclined);
    setState(() { _hasSearched = false; _foundBlacklist = null; _blacklistNoRecord = false; _cnicController.clear(); });
  }

  /// Audit §19: Tribunal Policy opens a bottom sheet with the actual
  /// policy text instead of a toast.
  void _showTribunalPolicy() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.customersScanTribunalPolicy, style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.customersScanTribunalInfo, style: Theme.of(sheetContext).textTheme.bodyMedium),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(l10n.back))),
          ],
        ),
      ),
    );
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
              title: l10n.customersScanTitle,
              subtitle: l10n.customersScanSubtitle,
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: l10n.customersScanTribunalPolicy,
                  onPressed: _showTribunalPolicy,
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
                      errorText: _cnicError,
                      onCnicChanged: (_) { if (_cnicError != null) setState(() => _cnicError = null); },
                      onVerify: _verifyCnic,
                      onCameraScan: _scanCnicWithCamera,
                    ),
                    const SizedBox(height: 18),
                    BlacklistStatusBanner(
                      isChecked: _hasSearched,
                      blacklistedRecord: _foundBlacklist,
                      detailsUnavailable: _blacklistNoRecord,
                      onProceed: _proceedToAddCustomer,
                      onDecline: _declineCustomer,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        // Audit §19: pop/go replaces the push stack —
                        // back from the list no longer returns to scan.
                        onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(RouteNames.ownerCustomers); } },
                        icon: const Icon(Icons.people_rounded),
                        label: Text(l10n.customersScanViewAll),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        // Audit §19: go() replaces the stack — back
                        // from the blacklist no longer returns to scan.
                        onPressed: () => context.go(RouteNames.ownerBlacklist),
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
