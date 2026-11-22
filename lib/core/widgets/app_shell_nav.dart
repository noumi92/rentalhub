import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Phase C (C2): the ONE bottom navigation for the whole app — the
/// customer and owner shells both render this widget, parameterized by
/// their five tabs. It replaces the two duplicated M2
/// `BottomNavigationBar` widgets (`customer_bottom_nav.dart`,
/// `owner_bottom_nav.dart`, deleted with this phase).
///
/// Rulebook §4.4 flush spec (phone-test #16): a bar attached to the
/// bottom edge, height 56 px, no margin, no radius, no extra padding,
/// no SafeArea — it replaces the 68 px floating pill (16 px margin,
/// radius 32). Navy background, orange active indicator, labels 12 sp
/// — all from the theme's `navigationBarTheme` (light:
/// `primary`/`secondary`; dark: `primaryDarkOnDark`/`secondaryDark`),
/// so both themes get the spec without a literal here.
///
/// An item's [ShellNavItem.icon] is a full widget (not an [IconData])
/// so a tab can carry a live badge — the Requests and Support tabs
/// pass a badge widget that wraps the icon in a [Badge] when its
/// count is nonzero, and renders the plain icon otherwise.
///
/// [label] is the English fallback; [l10nKey] names the localized
/// label (resolved at render time, so the tabs follow the locale).
/// Tests construct items without a key and keep the plain label.
///
/// Phone bug (run #50 APK): this used to be a Material
/// [NavigationBar] forced to 56 px. NavigationBar is designed for an
/// 80 px bar: its destination layout centres the icon and puts the
/// label below it, so icon + label need ~64 px — at 56 px the icons
/// poked out of the top of the bar and the labels were clipped at
/// the bottom edge (reproduced in a widget test: unselected icons
/// 3 px above the bar, labels 7 px below it). The bar is now a plain
/// [Row] of icon-over-label destinations sized to fit 56 px exactly:
/// selected 32 (pill) + 2 + ~17 (label) = 51 px, unselected
/// 24 + 2 + ~17 = 43 px, both centred — no overflow at any text
/// scale the bar grows for (see [contentHeight]).
class ShellNavItem {
  final Widget icon;
  final String label;
  final String? l10nKey;

  const ShellNavItem({required this.icon, required this.label, this.l10nKey});
}

class AppShellNav extends StatelessWidget {
  /// Rulebook §4.4 flush geometry: 56 px of content, attached to the
  /// bottom edge — no margin, no radius, no extra padding, no SafeArea.
  /// Audit fix (gesture bar): on gesture-navigation devices the 56 px
  /// content keeps its height, but `MediaQuery.padding.bottom` is added
  /// BELOW it, so the tab labels clear the system gesture pill. The bar
  /// stays flush (no floating margin); the extra height is system
  /// inset, not padding around the bar. At large text scales the
  /// content grows past 56 px instead of clipping the labels.
  static const double navHeight = 56;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ShellNavItem> items;

  const AppShellNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Phase F: the tab label in the current locale when the item
  /// carries an [ShellNavItem.l10nKey], else its plain [ShellNavItem.label].
  /// Audit SH-N15: every key is now a `nav*` key with a 1:1 getter —
  /// the old `tab2_navShops` numbering artefact is gone, and
  /// `navFleet` / `navWallet` / `navCustomers` no longer borrow the
  /// `dashboardFleet` / `walletLabel` / `customersTitle` getters.
  /// A key with no case here falls back to the English `label` — the
  /// nav-labels test fails if any shipped key is unmapped.
  static String labelFor(AppLocalizations? l10n, ShellNavItem item) {
    if (l10n == null || item.l10nKey == null) return item.label;
    switch (item.l10nKey!) {
      case 'navHome':
        return l10n.navHome;
      case 'navShops':
        return l10n.navShops;
      case 'navBookings':
        return l10n.navBookings;
      case 'navWallet':
        return l10n.navWallet;
      case 'navSupport':
        return l10n.navSupport;
      case 'navProfile':
        return l10n.navProfile;
      case 'navDashboard':
        return l10n.navDashboard;
      case 'navFleet':
        return l10n.navFleet;
      case 'navRequests':
        return l10n.navRequests;
      case 'navCustomers':
        return l10n.navCustomers;
      case 'navSettings':
        return l10n.navSettings;
      default:
        return item.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.primary;
    final indicatorColor = theme.navigationBarTheme.indicatorColor ??
        theme.colorScheme.secondary;
    final l10n = AppLocalizations.of(context);
    // Audit fix: the 56 px content height is kept, but the system
    // gesture inset is added below it (Scaffold passes the full
    // MediaQuery padding to bottomNavigationBar). At large text
    // scales the 12 sp labels need more room, so the content grows
    // past 56 px instead of clipping: the tallest column is the
    // selected one (32 px pill + 2 px gap + the scaled label), so
    // the growth budget is 36 px + 1.4x the scaled label size.
    // Audit 2026-11-15 AC-15: at large text scale the label may
    // wrap to 2 lines, so the budget counts 2 lines then.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final textScaler = MediaQuery.textScalerOf(context);
    final allowTwoLineLabels = textScaler.scale(1) > 1.3;
    final labelLines = allowTwoLineLabels ? 2 : 1;
    final contentHeight = math.max(
        navHeight, 34 + labelLines * textScaler.scale(12) * 1.4);
    // Phone bug: a Material NavigationBar forced to 56 px clips the
    // labels (its destinations need ~64 px). Each destination here
    // is an explicit icon-over-label column that fits 56 px, with a
    // full-height tap target.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        height: contentHeight + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        color: background,
        child: SizedBox(
          height: contentHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _TabDestination(
                    item: items[i],
                    label: labelFor(l10n, items[i]),
                    selected: i == currentIndex,
                    indicatorColor: indicatorColor,
                    iconTheme: theme.navigationBarTheme.iconTheme,
                    labelStyle: theme.navigationBarTheme.labelTextStyle,
                    allowTwoLineLabel: allowTwoLineLabels,
                    onTap: () {
                      // E2: a light selection click on every tab tap.
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab: icon over label, centred in the 56 px content height.
/// The selected tab gets the orange pill behind its icon (64x32,
/// the M3 indicator shape); unselected tabs show the bare icon.
/// Both columns are centred, so the icon centres line up across
/// tabs and the labels always sit fully inside the bar.
class _TabDestination extends StatelessWidget {
  final ShellNavItem item;
  final String label;
  final bool selected;
  final Color indicatorColor;
  final WidgetStateProperty<IconThemeData?>? iconTheme;
  final WidgetStateProperty<TextStyle?>? labelStyle;
  final bool allowTwoLineLabel;
  final VoidCallback onTap;

  const _TabDestination({
    required this.item,
    required this.label,
    required this.selected,
    required this.indicatorColor,
    required this.iconTheme,
    required this.labelStyle,
    this.allowTwoLineLabel = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final states = selected ? {WidgetState.selected} : <WidgetState>{};
    final resolvedIcon =
        iconTheme?.resolve(states) ?? const IconThemeData(size: 24);
    // Audit 2026-11-15 DS-8: the 12 sp fallback is off-scale (§4.5:
    // 28/20/16/15/13/11) — read the labelSmall theme slot instead,
    // with the nav's white-on-navy colours per state. The last
    // fallback carries no size: ThemeData always defines labelSmall,
    // so it only renders if a foreign theme drops the slot.
    final resolvedLabel = labelStyle?.resolve(states) ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
              color: Colors.white.withValues(
                  alpha: selected ? 1 : 0.6),
            ) ??
        TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: Colors.white.withValues(alpha: selected ? 1 : 0.6),
        );
    final icon = selected
        ? Container(
            width: 64,
            height: 32,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: item.icon,
          )
        : item.icon;
    // Audit SH-N5: the bar is a hand-rolled Row, not Material 3
    // NavigationBar (phone bug, run #50: NavigationBar forced to
    // 56 px clipped icons/labels), so M3's selected-state semantics
    // do not come for free. Each destination carries an explicit
    // Semantics node — button, localised label, selected state — so
    // screen readers announce the tabs the way NavigationBar would.
    // (Rulebook §4.4 deviation, recorded in the SH-N5 rulebook note.)
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      excludeSemantics: true,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(data: resolvedIcon, child: icon),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                style: resolvedLabel,
                maxLines: allowTwoLineLabel ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
