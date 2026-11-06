import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';

/// Phase B (E1): the owner scans the QR on the customer's confirmed
/// booking (or on the agreement) and lands straight on handover.
/// The QR encodes the agreement verification URL, so the booking id
/// is read from its `id=` parameter; a bare booking id is accepted
/// too. A manual entry field covers the camera-can't-read-it case.
class OwnerQrScanView extends StatefulWidget {
  const OwnerQrScanView({super.key});

  @override
  State<OwnerQrScanView> createState() => _OwnerQrScanViewState();
}

class _OwnerQrScanViewState extends State<OwnerQrScanView> {
  final _idController = TextEditingController();
  final _scannerController = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _idController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String? _bookingIdFromCode(String code) {
    final uri = Uri.tryParse(code);
    final id = uri?.queryParameters['id'];
    if (id != null && id.isNotEmpty) return id;
    if (code.startsWith('RH-')) return code;
    return null;
  }

  Future<void> _openBooking(String bookingId) async {
    if (_handled) return;
    setState(() => _handled = true);
    try {
      final booking = await sl<BookingRemoteDataSource>()
          .getBookingById(bookingId);
      if (booking == null) {
        if (mounted) {
          AppFeedback.showError(
              context, 'No booking found for #$bookingId.');
          setState(() => _handled = false);
        }
        return;
      }
      if (!mounted) return;
      context.push(RouteNames.ownerHandover.replaceFirst(':id', bookingId));
      setState(() => _handled = false);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not open the booking: $e');
        setState(() => _handled = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    final bookingId = _bookingIdFromCode(code);
    if (bookingId == null) {
      AppFeedback.showError(
          context, 'This is not a RentalHub booking code.');
      return;
    }
    _openBooking(bookingId);
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
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scan Booking QR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text('Point the camera at the customer’s booking code',
                      style: TextStyle(
                          color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _idController,
                            decoration: const InputDecoration(
                              hintText: 'Or type the booking id, e.g. RH-…',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final id = _idController.text.trim();
                            if (id.isEmpty) return;
                            _openBooking(id);
                          },
                          child: const Text('Open'),
                        ),
                      ],
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
