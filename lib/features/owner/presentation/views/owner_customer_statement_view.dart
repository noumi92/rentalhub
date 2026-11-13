import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/utils/statement_pdf_generator.dart';
import '../widgets/finance/statement_table.dart';

/// Audit impl (O46/O47): one customer's statement — a table of
/// Booking / Date / Rent / Paid / Due, the total due, a WhatsApp
/// send (a wa.me deep link with the statement text, by hand — no
/// Business API needed) and a real A4 statement PDF (download to
/// the device, or share). Builds on the dues grouping: the same
/// bookings, the same remaining balances, shown as a statement.
class OwnerCustomerStatementView extends StatefulWidget {
  final String shopId;
  final String customerId;

  const OwnerCustomerStatementView({
    super.key,
    required this.shopId,
    required this.customerId,
  });

  @override
  State<OwnerCustomerStatementView> createState() =>
      _OwnerCustomerStatementViewState();
}

class _OwnerCustomerStatementViewState
    extends State<OwnerCustomerStatementView> {
  List<BookingEntity> _bookings = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final all =
          await sl<BookingRemoteDataSource>().getShopBookings(widget.shopId);
      if (mounted) {
        setState(() {
          _bookings = all
              .where((b) => b.customerId == widget.customerId)
              .toList()
            ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // OW-m7: the name never falls back to the raw customerId — an
  // unknown customer shows "—".
  String get _customerName =>
      _bookings.firstOrNull?.customerName ?? '—';
  String get _customerPhone => _bookings.firstOrNull?.customerPhone ?? '';
  // OW-m7: dues count only due statuses (same set as customer
  // detail) — cancelled bookings no longer inflate the total.
  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};
  int get _totalDue => _bookings
      .where((b) => _dueStatuses.contains(b.status) && b.remainingBalance > 0)
      .fold(0, (total, b) => total + b.remainingBalance);

  String _statementText(BuildContext context, AppLocalizations l10n) {
    // OW-m7: locale-aware dates, not raw d/m/y.
    final locale = Localizations.localeOf(context).languageCode;
    final lines = <String>[
      l10n.financeStatementMessageTitle(_customerName),
      for (final b in _bookings)
        l10n.financeStatementMessageRow(
          b.bookingId,
          DateFormat.yMd(locale).format(b.pickupTime),
          formatRs(b.totalAmount),
          formatRs(b.advancePaid),
          formatRs(b.remainingBalance),
        ),
      l10n.financeStatementMessageTotal(formatRs(_totalDue)),
    ];
    return lines.join('\n');
  }

  Future<void> _sendWhatsApp() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = whatsappUri(phone: _customerPhone, message: _statementText(context, l10n));
    if (uri == null) {
      AppFeedback.showError(context, l10n.financeDuesNoPhoneError);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppFeedback.showError(context, l10n.financeDuesWhatsappFailed);
    }
  }

  Future<void> _downloadPdf() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBusy = true);
    try {
      final bytes = await StatementPdfGenerator.generateCustomerStatement(
        shopName: _bookings.firstOrNull?.shopName ?? '—',
        customerName: _customerName,
        customerPhone: _customerPhone,
        bookings: _bookings,
      );
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/statement-${widget.customerId}.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.financeStatementDownloaded);
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sharePdf() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBusy = true);
    try {
      final bytes = await StatementPdfGenerator.generateCustomerStatement(
        shopName: _bookings.firstOrNull?.shopName ?? '—',
        customerName: _customerName,
        customerPhone: _customerPhone,
        bookings: _bookings,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes,
                name: 'statement-${widget.customerId}.pdf',
                mimeType: 'application/pdf'),
          ],
        ),
      );
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.financeStatementTitle,
              subtitle: _customerName,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError, onRetry: _load)
                      : _bookings.isEmpty
                          ? AppEmptyState(
                              title: l10n.financeStatementEmpty,
                              icon: Icons.receipt_long_rounded)
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatementTotalCard(totalDue: _totalDue),
                                  const SizedBox(height: 16),
                                  StatementTable(bookings: _bookings),
                                  const SizedBox(height: 16),
                                  DebouncedButton(
                                    text: l10n.financeStatementSend,
                                    icon: Icons.message_rounded,
                                    isLoading: _isBusy,
                                    onPressed: _sendWhatsApp,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(
                                              Icons.download_rounded,
                                              size: 18),
                                          label: Text(
                                              l10n.financeStatementDownload),
                                          onPressed:
                                              _isBusy ? null : _downloadPdf,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.share_rounded,
                                              size: 18),
                                          label: Text(
                                              l10n.financeStatementShare),
                                          onPressed:
                                              _isBusy ? null : _sharePdf,
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
