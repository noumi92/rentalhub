import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../finance/utils/report_pdf_generator.dart';

/// Audit impl (O37): the reports "Download PDF" action — the same
/// A4 report the screen shows (monthly earnings + car-wise table)
/// as a real PDF, downloaded to the device following the statement
/// PDF's pattern (`path_provider` + `dart:io`). CSV export is
/// untouched. The period label comes from the existing
/// `financeThisMonth` / `financeLastMonth` / `financeFilterAll`
/// keys; the monthly rows are the last 6 months, the car rows are
/// the period-filtered rows the screen already computes.
class ReportPdfDownloadButton extends StatefulWidget {
  final String shopId;
  final String period; // 'this_month' | 'last_month' | 'all'
  final List<BookingEntity> bookings;
  final List<(String, int, int)> carRows;

  const ReportPdfDownloadButton({
    super.key,
    required this.shopId,
    required this.period,
    required this.bookings,
    required this.carRows,
  });

  @override
  State<ReportPdfDownloadButton> createState() =>
      _ReportPdfDownloadButtonState();
}

class _ReportPdfDownloadButtonState extends State<ReportPdfDownloadButton> {
  bool _isBusy = false;

  String _periodLabel(AppLocalizations l10n) {
    return switch (widget.period) {
      'last_month' => l10n.financeLastMonth,
      'all' => l10n.financeFilterAll,
      _ => l10n.financeThisMonth,
    };
  }

  Future<void> _downloadPdf() async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBusy = true);
    try {
      final bytes = await ReportPdfGenerator.generateReportPdf(
        shopName:
            widget.bookings.firstOrNull?.shopName ?? widget.shopId,
        periodLabel: _periodLabel(l10n),
        monthlyRows: ReportPdfGenerator.monthlyRows(widget.bookings),
        carRows: widget.carRows,
      );
      final dir = await getApplicationDocumentsDirectory();
      final file =
          File('${dir.path}/rentalhub-report-${widget.period}.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.reportDownloadPdfSaved);
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.reportDownloadPdf,
      icon: const Icon(Icons.download_rounded, color: Colors.white),
      onPressed: _isBusy ? null : _downloadPdf,
    );
  }
}
