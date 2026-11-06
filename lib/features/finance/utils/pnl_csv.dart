import '../domain/entities/finance_transfer_entity.dart';

/// Phase B (H5): the P&L statement as a CSV, which opens in Excel
/// and Google Sheets. The `excel` package cannot be used here —
/// it pins `xml <7.0.0` while the agreement PDF package needs
/// `xml ^7.0.1`, so the two cannot coexist; CSV is the honest
/// substitute, not a silent downgrade.
class PnLCsv {
  static String build({
    required String shopName,
    required String periodLabel,
    required int bookingRevenue,
    required int ledgerIncome,
    required int expenses,
    required List<FinanceTransferEntity> transfers,
  }) {
    final rows = <List<String>>[
      ['RentalHub P&L Statement', shopName, periodLabel],
      [],
      ['Booking revenue', '$bookingRevenue'],
      ['Other income', '$ledgerIncome'],
      ['Expenses', '$expenses'],
      ['Net profit', '${bookingRevenue + ledgerIncome - expenses}'],
      [],
      ['Date', 'Kind', 'Category', 'Amount (Rs)', 'Note'],
      for (final t in transfers)
        [
          t.createdAt.toIso8601String().substring(0, 10),
          t.kind,
          t.category,
          '${t.amountPkr}',
          (t.note ?? '').replaceAll(',', ';'),
        ],
    ];
    return rows.map((r) => r.join(',')).join('\n');
  }
}
