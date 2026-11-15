import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../widgets/qr_camera_error_state.dart';
import '../widgets/qr_scan_frame_overlay.dart';

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
  // §17: feedback while a scanned / typed code resolves — the screen
  // used to look dead on a slow connection after a scan or tap.
  bool _resolving = false;
  bool _torchOn = false;

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
  final l10n = AppLocalizations.of(context)!;
    if (_handled) return;
    setState(() {
      _handled = true;
      _resolving = true;
    });
    try {
      final booking =
          await sl<BookingRemoteDataSource>().getBookingById(bookingId);
      if (booking == null) {
        if (mounted) {
          AppFeedback.showError(context, l10n.qrNoBooking(bookingId));
          setState(() {
            _handled = false;
            _resolving = false;
          });
        }
        return;
      }
      if (!mounted) return;
      context.push(RouteNames.ownerHandover.replaceFirst(':id', bookingId));
      setState(() {
        _handled = false;
        _resolving = false;
      });
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.qrOpenFailed(e.toString()));
        setState(() {
          _handled = false;
          _resolving = false;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
  final l10n = AppLocalizations.of(context)!;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    final bookingId = _bookingIdFromCode(code);
    if (bookingId == null) {
      AppFeedback.showError(context, l10n.qrNotBookingCode);
      return;
    }
    _openBooking(bookingId);
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Torch unavailable on this device — the toggle simply stays off.
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.qrScanTitle,
              subtitle: l10n.qrScanSubtitle,
              onBack: () => context.pop(),
              actions: [
                // §17: torch toggle (existing MobileScanner API, no
                // new dependency).
                IconButton(
                  icon: Icon(
                      _torchOn
                          ? Icons.flashlight_on_rounded
                          : Icons.flashlight_off_rounded,
                      color: Colors.white),
                  tooltip: _torchOn ? l10n.qrTorchOn : l10n.qrTorchOff,
                  onPressed: _toggleTorch,
                ),
              ],
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onDetect,
                              // §17: a denied / unavailable camera used
                              // to render a black box with no explanation.
                              errorBuilder: (context, error) =>
                                  QrCameraErrorState(error: error),
                            ),
                            // §17: corner-frame overlay for aiming.
                            const IgnorePointer(
                              child: QrScanFrameOverlay(),
                            ),
                            if (_resolving)
                              Container(
                                color: Colors.black38,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _idController,
                            decoration: InputDecoration(
                              hintText: l10n.qrTypeHint,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // §17: 48dp minimum height + the dedicated
                        // qrOpen key (was ~36dp reusing a disputes key).
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _resolving
                                ? null
                                : () {
                                    final id = _idController.text.trim();
                                    if (id.isEmpty) return;
                                    _openBooking(id);
                                  },
                            child: Text(l10n.qrOpen),
                          ),
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

