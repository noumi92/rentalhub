import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'shops_filter_logic.dart';

export 'shops_filter_logic.dart' show ShopVerificationFilter;

/// The Shops verification filter row, shared by the listing and the
/// full-screen map — the same widget in both views, so the controls
/// (and the filter state behind them) cannot drift apart. The
/// map/list switch is NOT here: the listing opens the map with its
/// map button and the map returns with its back arrow. When the
/// platform setting hides unverified shops, the Unverified chip is
/// not offered at all.
class ShopsFilterBar extends StatelessWidget {
  const ShopsFilterBar({
    super.key,
    required this.verification,
    required this.onVerificationChanged,
    this.showUnverifiedFilter = true,
  });

  final ShopVerificationFilter verification;
  final ValueChanged<ShopVerificationFilter> onVerificationChanged;

  /// False when `platform_settings/global` hides unverified shops.
  final bool showUnverifiedFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <Widget>[
      _FilterChip(
        label: l10n.filterAll,
        selected: verification == ShopVerificationFilter.all,
        onSelected: () =>
            onVerificationChanged(ShopVerificationFilter.all),
      ),
      _FilterChip(
        label: l10n.verified,
        selected: verification == ShopVerificationFilter.verified,
        onSelected: () =>
            onVerificationChanged(ShopVerificationFilter.verified),
      ),
      if (showUnverifiedFilter)
        _FilterChip(
          label: l10n.shops_unverified,
          selected: verification == ShopVerificationFilter.unverified,
          onSelected: () =>
              onVerificationChanged(ShopVerificationFilter.unverified),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
