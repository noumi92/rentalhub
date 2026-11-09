import '../../bookings/domain/entities/booking_entity.dart';
import '../domain/entities/finance_account_entity.dart';
import '../domain/entities/finance_transfer_entity.dart';

/// Phase B (H1/H2/H5): the pure finance arithmetic — balances,
/// period totals and per-car P&L, all computed from the ledger and
/// the bookings so the numbers can never disagree with the data.
class FinanceSummary {
  /// The live balance of one account: its opening balance plus
  /// every transfer posted to it.
  static int accountBalance(
    FinanceAccountEntity account,
    List<FinanceTransferEntity> transfers,
  ) {
    var balance = account.openingBalancePkr;
    for (final t in transfers) {
      if (t.accountId != account.accountId) continue;
      balance += t.kind == 'income' ? t.amountPkr : -t.amountPkr;
    }
    return balance;
  }

  static ({int income, int expenses, int net}) periodTotals(
    List<FinanceTransferEntity> transfers, {
    DateTime? from,
    DateTime? to,
  }) {
    var income = 0;
    var expenses = 0;
    for (final t in transfers) {
      if (from != null && t.createdAt.isBefore(from)) continue;
      if (to != null && !t.createdAt.isBefore(to)) continue;
      if (t.kind == 'income') {
        income += t.amountPkr;
      } else {
        expenses += t.amountPkr;
      }
    }
    return (income: income, expenses: expenses, net: income - expenses);
  }

  /// Audit impl (O45/O37): ledger totals per category code for one
  /// kind ('income' | 'expense') inside a period. Codes the caller
  /// does not recognise stay under their own code, so a custom
  /// category still shows up instead of vanishing.
  static Map<String, int> categoryTotals(
    List<FinanceTransferEntity> transfers, {
    required String kind,
    DateTime? from,
    DateTime? to,
  }) {
    final totals = <String, int>{};
    for (final t in transfers) {
      if (t.kind != kind) continue;
      if (from != null && t.createdAt.isBefore(from)) continue;
      if (to != null && !t.createdAt.isBefore(to)) continue;
      totals[t.category] = (totals[t.category] ?? 0) + t.amountPkr;
    }
    return totals;
  }

  /// A car's profit and loss: booking revenue (completed, paid and
  /// active trips) plus ledger income tagged to the car, minus the
  /// ledger expenses tagged to it.
  static ({int revenue, int income, int expenses, int net}) vehiclePnL({
    required String vehicleId,
    required List<BookingEntity> bookings,
    required List<FinanceTransferEntity> transfers,
  }) {
    final revenue = bookings
        .where((b) =>
            b.vehicleId == vehicleId &&
            (b.status == 'completed' ||
                b.status == 'paid' ||
                b.status == 'active'))
        .fold<int>(0, (total, b) => total + b.totalAmount);
    final tagged = transfers.where((t) => t.vehicleId == vehicleId);
    final income =
        tagged.where((t) => t.kind == 'income').fold<int>(0, (total, t) => total + t.amountPkr);
    final expenses = tagged
        .where((t) => t.kind == 'expense')
        .fold<int>(0, (total, t) => total + t.amountPkr);
    return (
      revenue: revenue,
      income: income,
      expenses: expenses,
      net: revenue + income - expenses,
    );
  }

  /// What the cash till should hold right now: the cash account's
  /// opening balance plus today's cash transfers.
  static int expectedCashToday({
    required FinanceAccountEntity cashAccount,
    required List<FinanceTransferEntity> transfers,
    DateTime? day,
  }) {
    final today = day ?? DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    var cash = cashAccount.openingBalancePkr;
    for (final t in transfers) {
      if (t.accountId != cashAccount.accountId) continue;
      if (t.createdAt.isBefore(start) || !t.createdAt.isBefore(end)) {
        continue;
      }
      cash += t.kind == 'income' ? t.amountPkr : -t.amountPkr;
    }
    return cash;
  }
}
