import 'package:cloud_firestore/cloud_firestore.dart';

/// Phase C (C3): the customer-side read of support tickets, for the
/// Support tab badge. The customer app has no ticket-thread view —
/// replies do not appear in the app yet — but the ticket STATUS is
/// readable: an admin reply moves a ticket from 'open' to
/// 'in_progress' (see `AdminSupportDataSource.replyToTicket`), so
/// 'in_progress' tickets are exactly the ones with an admin reply
/// waiting. No Firestore (tests, or no Firebase app) → a stream of 0,
/// so the badge hides instead of throwing.
class CustomerSupportDataSource {
  final FirebaseFirestore? _firestore;

  CustomerSupportDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Number of [customerId]'s tickets an admin has replied to.
  Stream<int> streamRepliedTicketCount(String customerId) {
    if (customerId.isEmpty) return Stream.value(0);
    final fs = _resolvedFirestore;
    if (fs == null) return Stream.value(0);
    return fs
        .collection('support_tickets')
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'in_progress')
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
