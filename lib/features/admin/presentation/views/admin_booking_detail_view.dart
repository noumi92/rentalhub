import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_booking_handover_section.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/dispute_decision_sheet.dart';

/// Phase D (D1) — one booking: the lifecycle, amounts, in/out-city,
/// payment and deposit, the agreement PDF, the handover checklist
/// with odometer and photos, the return checklist, the dispute
/// (if any), and the messages log. "Download all" shares a plain-text
/// summary of the booking (the agreement PDF opens from its link).
class AdminBookingDetailView extends StatefulWidget {
  const AdminBookingDetailView({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<AdminBookingDetailView> createState() => _AdminBookingDetailViewState();
}

class _AdminBookingDetailViewState extends State<AdminBookingDetailView> {
  BookingDetail? _detail;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final detail = await sl<AdminPlatformDataSource>()
          .getBookingDetail(widget.bookingId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAll() async {
    final d = _detail;
    if (d == null) return;
    final b = d.booking;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final summary = '''
${l10n.admin2_bookingSummaryTitle(b.bookingId)}
${l10n.admin2_bookingSummaryStatusLine(humanizeStatus(b.status, l10n), humanizeStatus(b.tripType, l10n), b.kmLimit?.toString() ?? '—')}
${l10n.admin2_bookingSummaryVehicle(b.vehicleName ?? b.vehicleId, b.vehiclePlate ?? '—')}
${l10n.admin2_bookingSummaryShop(b.shopName ?? b.shopId, b.customerName ?? b.customerId)}
${l10n.admin2_bookingSummaryPickup(dateFormat.format(b.pickupTime), dateFormat.format(b.returnTime))}
${l10n.admin2_bookingSummaryTotal(l10n.amountRs(formatRs(b.totalAmount)), l10n.amountRs(formatRs(b.advanceRequired)), l10n.amountRs(formatRs(b.advancePaid)), l10n.amountRs(formatRs(b.remainingBalance)))}
${d.deposit == null ? l10n.admin2_bookingSummaryDepositNone : l10n.admin2_bookingSummaryDeposit(l10n.amountRs(formatRs(d.deposit!.amount)), humanizeStatus(d.deposit!.status, l10n))}
${l10n.admin2_bookingSummaryAgreement(d.agreementPdfUrl ?? l10n.admin2_none)}
${d.handover == null ? l10n.admin2_bookingSummaryHandoverNone : l10n.admin2_bookingSummaryHandover(d.handover!.initialOdometer, d.handover!.fuelLevel, d.handover!.damageNotes.isEmpty ? l10n.admin2_none : d.handover!.damageNotes.join('; '))}
''';
    try {
      await SharePlus.instance.share(ShareParams(
        text: summary,
        subject: l10n.admin2_bookingSummaryTitle(b.bookingId),
      ));
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, l10n.admin2_bookingDetailShareFailed);
      }
    }
  }

  Future<void> _openAgreement(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, AppLocalizations.of(context)?.admin2_bookingDetailPdfFailed ?? 'Could not open the PDF link.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact = windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminBookings,
      title: l10n.admin2_bookingDetailTitle,
      subtitle: l10n.admin2_bookingDetailSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminBookings),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_bookingDetailLoadFailed,
                  onRetry: _load,
                )
              : _detail == null
                  ? AppEmptyState(title: l10n.admin2_bookingDetailNotFound)
                  : SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact: the Download button stacks under the
                      // title — beside a long vehicle • booking title
                      // it clips at 360px.
                      if (compact) ...[
                        Text(
                          '${_detail!.booking.vehicleName ?? _detail!.booking.vehicleId} • ${_detail!.booking.bookingId}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _downloadAll,
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(l10n.admin2_bookingDetailDownloadAll),
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_detail!.booking.vehicleName ?? _detail!.booking.vehicleId} • ${_detail!.booking.bookingId}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _downloadAll,
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 48)),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(l10n.admin2_bookingDetailDownloadAll),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.admin2_bookingDetailMeta(humanizeStatus(_detail!.booking.status, l10n), humanizeStatus(_detail!.booking.tripType, l10n), humanizeStatus(_detail!.booking.packageType, l10n), _detail!.booking.isWithDriver ? l10n.admin2_withDriver : l10n.admin2_selfDrive),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      AdminDetailSection(title: l10n.admin2_bookingDetailAmounts, lines: [
                        l10n.bookingTotalAmount(formatRs(_detail!.booking.totalAmount)),
                        l10n.admin2_bookingDetailAdvanceRequired(l10n.amountRs(formatRs(_detail!.booking.advanceRequired))),
                        l10n.admin2_bookingDetailAdvancePaid(l10n.amountRs(formatRs(_detail!.booking.advancePaid))),
                        l10n.admin2_bookingDetailRemaining(l10n.amountRs(formatRs(_detail!.booking.remainingBalance))),
                        if ((_detail!.booking.transactionId ?? '').isNotEmpty)
                          l10n.admin2_bookingDetailTransaction(_detail!.booking.transactionId!),
                      ]),
                      AdminDetailSection(title: l10n.admin2_bookingDetailPaymentDeposit, lines: [
                        if (_detail!.booking.paymentProofUrl != null)
                          l10n.admin2_bookingDetailPaymentProof(_detail!.booking.paymentProofUrl!),
                        _detail!.deposit == null
                            ? l10n.admin2_bookingDetailNoDeposit
                            : _detail!.deposit!.deductedAmount == null
                                ? l10n.admin2_bookingDetailDeposit(l10n.amountRs(formatRs(_detail!.deposit!.amount)), humanizeStatus(_detail!.deposit!.status, l10n))
                                : l10n.admin2_bookingDetailDepositDeducted(l10n.amountRs(formatRs(_detail!.deposit!.amount)), humanizeStatus(_detail!.deposit!.status, l10n), l10n.amountRs(formatRs(_detail!.deposit!.deductedAmount!))),
                      ]),
                      if (_detail!.agreementPdfUrl == null)
                        AdminDetailSection(title: l10n.admin2_bookingDetailAgreement, lines: [l10n.admin2_bookingDetailNoAgreement]),
                      if (_detail!.agreementPdfUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                            label: Text(l10n.admin2_bookingDetailOpenAgreement),
                            onPressed: () => _openAgreement(_detail!.agreementPdfUrl!),
                          ),
                        ),
                      AdminBookingHandoverSection(
                        handover: _detail!.handover,
                        returnSettlement: _detail!.returnSettlement,
                        deposit: _detail!.deposit,
                      ),
                      if (_detail!.dispute != null)
                        AdminDetailSection(title: l10n.admin2_bookingDetailDispute, lines: [
                          '${_detail!.dispute!.category}: ${_detail!.dispute!.description}',
                          l10n.admin2_bookingDetailDisputeStatus(humanizeStatus(_detail!.dispute!.status, l10n)),
                          if (_detail!.dispute!.decision != null)
                            _detail!.dispute!.decisionAmount == null
                                ? l10n.admin2_bookingDetailDisputeDecision(disputeDecisionLabel(_detail!.dispute!.decision!, l10n))
                                : l10n.admin2_bookingDetailDisputeDecisionAmount(disputeDecisionLabel(_detail!.dispute!.decision!, l10n), l10n.amountRs(formatRs(_detail!.dispute!.decisionAmount!))),
                          if (_detail!.dispute!.adminNote != null)
                            '${l10n.disputeDecisionNote}: ${_detail!.dispute!.adminNote}',
                        ]),
                      AdminDetailSection(
                          title: l10n.admin2_bookingDetailMessages,
                          lines: _detail!.messages.isEmpty
                              ? [l10n.admin2_bookingDetailNoMessages]
                              : _detail!.messages.map((m) => '${m.title} — ${m.body}').toList()),
                    ],
                  ),
                ),
    );
  }
}
