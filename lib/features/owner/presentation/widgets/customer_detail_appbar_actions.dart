import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// AppBar trailing actions for [OwnerCustomerDetailView]: Edit icon (walk-in)
/// + overflow menu (`⋮`) containing Archive/Restore and Block/Unblock so
/// destructive actions stay out of the main scroll flow.
List<Widget> buildCustomerDetailAppBarActions({
  required BuildContext context,
  required CustomerEntity? customer,
  required String statusShopId,
  required bool acting,
  required VoidCallback onEdit,
  required VoidCallback onArchive,
  required VoidCallback onToggleBlock,
}) {
  if (customer == null) return const [];
  final l10n = AppLocalizations.of(context)!;
  final isWalkIn = customer.source == 'walk_in';
  final shopStatus = customer.statusForShop(statusShopId);
  final blocked = shopStatus == CustomerEntity.statusBlocked;
  final archived = shopStatus == CustomerEntity.statusArchived;

  return [
    if (isWalkIn)
      IconButton(
        key: const ValueKey('customer_detail_appbar_edit'),
        tooltip: l10n.customerDetailEdit,
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        onPressed: acting ? null : onEdit,
      ),
    PopupMenuButton<String>(
      key: const ValueKey('customer_detail_appbar_menu'),
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      enabled: !acting,
      onSelected: (v) {
        if (v == 'archive') onArchive();
        if (v == 'block') onToggleBlock();
      },
      itemBuilder: (_) => [
        if (isWalkIn && !archived)
          PopupMenuItem<String>(
            value: 'archive',
            child: Text(l10n.customerDetailArchive),
          ),
        PopupMenuItem<String>(
          value: 'block',
          child: Text(
            archived
                ? l10n.customerDetailRestore
                : blocked
                    ? l10n.customerDetailUnblock
                    : l10n.customerDetailBlock,
            style: TextStyle(
              color: blocked || archived
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    ),
  ];
}
