import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../blacklist/domain/entities/blacklist_entity.dart';
import '../widgets/operations/cnic_scanner_input_widget.dart';
import '../widgets/operations/blacklist_status_banner.dart';
import 'owner_manual_booking_view.dart';

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
    final cnic = _cnicController.text.trim();
    if (cnic.length < 13) {
      AppFeedback.showError(context, 'Please enter a valid 13-digit Pakistani CNIC');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final ds = sl<BlacklistRemoteDataSource>();
      final isBlacklisted = await ds.isCnicBlacklisted(cnic);
      if (isBlacklisted) {
        final record = await ds.getBlacklistRecordByCnic(cnic);
        setState(() {
          _foundBlacklist = record ?? BlacklistEntity(
            blacklistId: 'BLK-AUTO',
            reportedByShopId: 'All-Pakistan Tribunal',
            cnicNumber: cnic,
            phoneNumber: '0300-0000000',
            reasonCategory: 'Reported in National Blacklist',
            description: 'Severe fraud / non-payment incident flagged.',
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
      if (mounted) AppFeedback.showError(context, 'Verification lookup failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _proceedToManualBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerManualBookingView(
          prefilledCnic: _cnicController.text.trim(),
        ),
      ),
    );
  }

  void _declineCustomer() {
    AppFeedback.showInfo(context, 'Customer flagged and declined entry into showroom.');
    setState(() {
      _hasSearched = false;
      _foundBlacklist = null;
      _cnicController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KYC & Blacklist Radar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('National Anti-Fraud Network • Real-time', style: TextStyle(color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'Tribunal Policy',
                  onPressed: () => AppFeedback.showInfo(context, 'Every Pakistani rental shop shares instant fraud telemetry via RentalHub.'),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CnicScannerInputWidget(
                      controller: _cnicController,
                      isVerifying: _isVerifying,
                      onVerify: _verifyCnic,
                      onCameraScan: () {
                        _cnicController.text = '35201-9999999-1';
                        _verifyCnic();
                      },
                    ),
                    const SizedBox(height: 18),
                    BlacklistStatusBanner(
                      isChecked: _hasSearched,
                      blacklistedRecord: _foundBlacklist,
                      onProceed: _proceedToManualBooking,
                      onDecline: _declineCustomer,
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
