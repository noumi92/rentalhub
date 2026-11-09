import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_shell.dart';

/// Phase D (D1) — one booking: the lifecycle, amounts, in/out-city,
/// payment and deposit, the agreement PDF, the handover checklist
/// with odometer, the dispute (if any), and the messages log.
/// "Download all" shares a plain-text summary of the booking
/// (the agreement PDF opens from its link; the handover photos are
/// not stored as files, so there is no bundle to download).
class AdminBookingDetailView extends StatefulWidget {
  const AdminBookingDetailView({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<AdminBookingDetailView> createState() =>
      _AdminBookingDetailViewState();
}

class _AdminBookingDetailViewState extends State<AdminBookingDetailView> {
  BookingDetail? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await sl<AdminPlatformDataSource>()
        .getBookingDetail(widget.bookingId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAll() async {
    final d = _detail;
    if (d == null) return;
    final b = d.booking;
    final l10n = AppLocalizations.of(context)!;
    final summary = '''
Booking ${b.bookingId}
Status: ${b.status} • Trip: ${b.tripType} (${b.kmLimit ?? '—'} km limit)
Vehicle: ${b.vehicleName ?? b.vehicleId} (${b.vehiclePlate ?? '—'})
Shop: ${b.shopName ?? b.shopId} • Customer: ${b.customerName ?? b.customerId}
Pickup: ${b.pickupTime} • Return: ${b.returnTime}
Total: ${l10n.amountRs(formatRs(b.totalAmount))} • Advance required: ${l10n.amountRs(formatRs(b.advanceRequired))} • Paid: ${l10n.amountRs(formatRs(b.advancePaid))} • Remaining: ${l10n.amountRs(formatRs(b.remainingBalance))}
Deposit: ${d.deposit == null ? 'none' : '${l10n.amountRs(formatRs(d.deposit!.amount))} (${d.deposit!.status})'}
Agreement PDF: ${d.agreementPdfUrl ?? 'none'}
Handover: ${d.handover == null ? 'none' : 'odometer ${d.handover!.initialOdometer} km, fuel ${d.handover!.fuelLevel}, damage: ${d.handover!.damageNotes.join('; ')}'}
''';
    await SharePlus.instance.share(ShareParams(
      text: summary,
      subject: 'Booking ${b.bookingId}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminShell(
      activeRoute: RouteNames.adminBookings,
      title: 'Booking detail',
      subtitle: 'Lifecycle, money, handover and messages',
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminBookings),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Booking not found.',
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_detail!.booking.vehicleName ?? _detail!.booking.vehicleId} • ${_detail!.booking.bookingId}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _downloadAll,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Download all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${_detail!.booking.status} • Trip: ${_detail!.booking.tripType} • Package: ${_detail!.booking.packageType} • ${(_detail!.booking.isWithDriver) ? 'with driver' : 'self drive'}',
                        style: const TextStyle(
                            fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      _section('Amounts', [
                        l10n.bookingTotalAmount(
                            formatRs(_detail!.booking.totalAmount)),
                        'Advance required: ${l10n.amountRs(formatRs(_detail!.booking.advanceRequired))}',
                        'Advance paid: ${l10n.amountRs(formatRs(_detail!.booking.advancePaid))}',
                        'Remaining balance: ${l10n.amountRs(formatRs(_detail!.booking.remainingBalance))}',
                        if ((_detail!.booking.transactionId ?? '').isNotEmpty)
                          'Transaction: ${_detail!.booking.transactionId}',
                      ]),
                      _section('Payment & deposit', [
                        if (_detail!.booking.paymentProofUrl != null)
                          'Payment proof: ${_detail!.booking.paymentProofUrl}',
                        _detail!.deposit == null
                            ? 'No deposit record.'
                            : 'Deposit ${l10n.amountRs(formatRs(_detail!.deposit!.amount))} — ${_detail!.deposit!.status}'
                                '${_detail!.deposit!.deductedAmount != null ? ' (deducted ${l10n.amountRs(formatRs(_detail!.deposit!.deductedAmount!))})' : ''}',
                      ]),
                      _section('Agreement', [
                        if (_detail!.agreementPdfUrl != null)
                          'Agreement PDF on file — tap to open.',
                        if (_detail!.agreementPdfUrl == null)
                          'No agreement PDF on file.',
                      ]),
                      if (_detail!.agreementPdfUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_rounded,
                                size: 18),
                            label: const Text('Open agreement PDF'),
                            onPressed: () async {
                              final uri =
                                  Uri.parse(_detail!.agreementPdfUrl!);
                              if (!await launchUrl(uri,
                                  mode: LaunchMode.externalApplication)) {
                                if (context.mounted) {
                                  AppFeedback.showError(context,
                                      'Could not open the PDF link.');
                                }
                              }
                            },
                          ),
                        ),
                      _section('Handover', [
                        if (_detail!.handover == null) 'No handover record.',
                        if (_detail!.handover != null) ...[
                          'Odometer at pickup: ${_detail!.handover!.initialOdometer} km',
                          'Fuel: ${_detail!.handover!.fuelLevel}',
                          'Damage notes: ${_detail!.handover!.damageNotes.isEmpty ? 'none' : _detail!.handover!.damageNotes.join('; ')}',
                        ],
                      ]),
                      if (_detail!.dispute != null)
                        _section('Dispute', [
                          '${_detail!.dispute!.category}: ${_detail!.dispute!.description}',
                          'Status: ${_detail!.dispute!.status}',
                        ]),
                      _section(
                          'Messages log',
                          _detail!.messages.isEmpty
                              ? ['No notifications recorded for this booking.']
                              : _detail!.messages
                                  .map((m) => '${m.title} — ${m.body}')
                                  .toList()),
                    ],
                  ),
                ),
    );
  }

  Widget _section(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: const TextStyle(
                        fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
