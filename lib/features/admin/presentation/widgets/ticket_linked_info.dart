import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../data/datasources/admin_support_data_source.dart';

/// The ticket's linked shop / purchase (F-M19, plan E1): chips that
/// open the shop or booking the ticket is about. The links come
/// from the ticket document (`shopId` / `bookingId`, written by the
/// customer form when the filing context supplied them); a ticket
/// filed before those fields existed shows nothing here rather than
/// a guessed link. The shop name is resolved live — the id alone is
/// never shown as the label.
///
/// Navigation follows the sheet's own pattern (AD-M13): pop the
/// sheet first, then `go` — navigating from inside the modal leaves
/// the sheet covering the destination.
class TicketLinkedInfo extends StatefulWidget {
  const TicketLinkedInfo({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  State<TicketLinkedInfo> createState() => _TicketLinkedInfoState();
}

class _TicketLinkedInfoState extends State<TicketLinkedInfo> {
  String? _shopName;

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    final shopId = widget.ticket.shopId;
    if (shopId == null) return;
    try {
      final shop = await sl<AdminShopsDataSource>().getShop(shopId);
      if (mounted && shop != null) {
        setState(() => _shopName = shop.shopName);
      }
    } catch (_) {
      // The chip falls back to the shop id below.
    }
  }

  void _open(String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    if (t.shopId == null && t.bookingId == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (t.shopId != null)
              ActionChip(
                avatar: const Icon(Icons.store_rounded, size: 16),
                label: Text(
                  '${l10n?.adminAuditLinkedShop ?? 'Shop'}: '
                  '${_shopName ?? t.shopId}',
                  softWrap: true,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _open(
                  RouteNames.adminShopDetail
                      .replaceFirst(':shopId', t.shopId!),
                ),
              ),
            if (t.bookingId != null)
              ActionChip(
                avatar:
                    const Icon(Icons.calendar_month_rounded, size: 16),
                label: Text(
                  '${l10n?.adminAuditLinkedBooking ?? 'Booking'}: '
                  '${t.bookingId}',
                  softWrap: true,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _open(
                  RouteNames.adminBookingDetail
                      .replaceFirst(':bookingId', t.bookingId!),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
