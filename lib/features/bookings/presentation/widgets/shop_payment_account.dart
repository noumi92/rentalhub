import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../l10n/app_localizations.dart';

/// One shop payment account, as stored under `bank_accounts` on the
/// shop doc (ShopModel.toMap): wallets
/// `{'type': 'jazzcash'|'easypaisa', 'account', 'title'}` and banks
/// `{'type': 'bank', 'bank_name', 'iban', 'title'}`.
///
/// The account's identity is its [number] — the wallet mobile number
/// or the bank IBAN. That is the value O18 stores on the booking as
/// [selectedPaymentAccount]: it is what the customer pays into, what
/// the owner picks in the approve sheet, and what the customer view
/// filters on. A bank has no separate account number, and a wallet
/// has no IBAN, so the number is unambiguous per account.
class ShopPaymentAccount {
  const ShopPaymentAccount({
    required this.type,
    this.bankName,
    required this.title,
    required this.number,
  });

  /// Lowercased raw type: 'jazzcash' | 'easypaisa' | 'bank'.
  final String type;

  /// Bank name for type 'bank'; null for wallets.
  final String? bankName;

  /// The account-holder title the shop entered.
  final String title;

  /// Wallet mobile number, or bank IBAN.
  final String number;

  bool get isWallet => type == 'jazzcash' || type == 'easypaisa';

  String methodTitle(AppLocalizations l10n) {
    if (type == 'jazzcash') return l10n.paymentJazzcash;
    if (type == 'easypaisa') return l10n.paymentEasypaisa;
    return bankName ?? l10n.paymentBankTransfer;
  }

  static ShopPaymentAccount? fromMap(Map<String, dynamic> map) {
    final type = (map['type'] as String? ?? 'bank').toLowerCase();
    final isWallet = type == 'jazzcash' || type == 'easypaisa';
    final number = isWallet
        ? (map['account'] as String? ?? '')
        : (map['iban'] as String? ?? '');
    if (number.isEmpty) return null;
    return ShopPaymentAccount(
      type: type,
      bankName: map['bank_name'] as String?,
      title: map['title'] as String? ?? '',
      number: number,
    );
  }

  /// All configured accounts for a shop, in stored order. Empty
  /// when the shop doc cannot be read or configures none — never
  /// another shop's accounts.
  static Future<List<ShopPaymentAccount>> fetch(
    String shopId, {
    FirebaseFirestore? firestore,
  }) async {
    try {
      final fs = firestore ?? FirebaseFirestore.instance;
      final snap = await fs.collection('shops').doc(shopId).get();
      return fromShopData(snap.data());
    } catch (_) {
      return const [];
    }
  }

  static List<ShopPaymentAccount> fromShopData(Map<String, dynamic>? data) {
    final raw = data?['bank_accounts'] as List<dynamic>?;
    if (raw == null) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromMap)
        .whereType<ShopPaymentAccount>()
        .toList();
  }

  /// O18 customer view: when the owner assigned an account to the
  /// booking, the customer pays into that one only. Older bookings
  /// carry no assignment, so they still see every account. And when
  /// the assigned account is gone from the shop (removed or
  /// re-entered since approval), fall back to all accounts rather
  /// than stranding the customer with nowhere to pay.
  static List<ShopPaymentAccount> visible(
    List<ShopPaymentAccount> all,
    String? selectedPaymentAccount,
  ) {
    if (selectedPaymentAccount == null || selectedPaymentAccount.isEmpty) {
      return all;
    }
    final chosen =
        all.where((a) => a.number == selectedPaymentAccount).toList();
    return chosen.isEmpty ? all : chosen;
  }
}
