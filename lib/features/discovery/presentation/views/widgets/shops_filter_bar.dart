import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'city_selector_bar.dart';
import 'shops_filter_logic.dart';

export 'shops_filter_logic.dart' show ShopVerificationFilter;

/// F-R1: the Shops filter row, shared by the listing and the
/// full-screen map — the same widget in both views, so the controls
/// (and the filter state behind them) cannot drift apart. ONE
/// horizontally scrollable row, 60 px tall: (1) a city chip-button
/// showing the current city, opening the city picker bottom sheet,
/// (2) the verification chips (All / Verified / Unverified), (3)
/// nothing else. The map/list switch is NOT here: the listing opens
/// the map with its map button and the map returns with its back
/// arrow. When the platform setting hides unverified shops, the
/// Unverified chip is not offered at all.
///
/// Selected state: the single theme token (DS-1 — no per-file
/// `selectedColor` anywhere here); the selected verification chip
/// is scrolled into view on build and on change, and the city
/// button always displays the selected city, so the selection is
/// visible without scrolling. Filter semantics are untouched
/// (`filterShopsForDisplay`); this is presentation only.
class ShopsFilterBar extends StatefulWidget {
  const ShopsFilterBar({
    super.key,
    required this.majorCities,
    required this.selectedCity,
    required this.onSelectCity,
    required this.verification,
    required this.onVerificationChanged,
    this.showUnverifiedFilter = true,
  });

  /// City-menu entries (`shopsCityMenuEntries`: "All cities" first,
  /// then the 11 major cities) for the picker sheet.
  final List<Map<String, dynamic>> majorCities;

  /// Display name of the selected city (or the "All cities" label).
  final String selectedCity;

  final ValueChanged<Map<String, dynamic>> onSelectCity;

  final ShopVerificationFilter verification;
  final ValueChanged<ShopVerificationFilter> onVerificationChanged;

  /// False when `platform_settings/global` hides unverified shops.
  final bool showUnverifiedFilter;

  @override
  State<ShopsFilterBar> createState() => _ShopsFilterBarState();
}

class _ShopsFilterBarState extends State<ShopsFilterBar> {
  final _scrollController = ScrollController();
  final _chipKeys = <ShopVerificationFilter, GlobalKey>{
    for (final f in ShopVerificationFilter.values) f: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(ShopsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verification != widget.verification) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelected() {
    final context = _chipKeys[widget.verification]?.currentContext;
    if (context != null) {
      // Minimal reveal: scrolls only when the selected chip is not
      // fully visible, and only as far as needed. Centering it
      // (explicit alignment 0.5) would push the city button — which
      // must stay visible — off-screen at narrow widths / large text.
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <Widget>[
      _FilterChip(
        key: _chipKeys[ShopVerificationFilter.all],
        label: l10n.filterAll,
        selected: widget.verification == ShopVerificationFilter.all,
        onSelected: () =>
            widget.onVerificationChanged(ShopVerificationFilter.all),
      ),
      _FilterChip(
        key: _chipKeys[ShopVerificationFilter.verified],
        label: l10n.verified,
        selected: widget.verification == ShopVerificationFilter.verified,
        onSelected: () => widget
            .onVerificationChanged(ShopVerificationFilter.verified),
      ),
      if (widget.showUnverifiedFilter)
        _FilterChip(
          key: _chipKeys[ShopVerificationFilter.unverified],
          label: l10n.shops_unverified,
          selected:
              widget.verification == ShopVerificationFilter.unverified,
          onSelected: () => widget
              .onVerificationChanged(ShopVerificationFilter.unverified),
        ),
    ];
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              avatar: const Icon(Icons.location_on_rounded, size: 18),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.selectedCity),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
              onPressed: () => showCityPickerBottomSheet(
                context: context,
                majorCities: widget.majorCities,
                selectedCity: widget.selectedCity,
                onSelectCity: widget.onSelectCity,
              ),
            ),
            for (var i = 0; i < chips.length; i++) ...[
              const SizedBox(width: 8),
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
    super.key,
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
