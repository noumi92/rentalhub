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
  static String labelFor(AppLocalizations? l10n, ShellNavItem item) {
    if (l10n == null || item.l10nKey == null) return item.label;
    switch (item.l10nKey!) {
      case 'navHome':
        return l10n.navHome;
      case 'navBookings':
        return l10n.navBookings;
      case 'navWallet':
        return l10n.walletLabel;
      case 'navSupport':
        return l10n.navSupport;
      case 'navProfile':
        return l10n.navProfile;
      case 'navDashboard':
        return l10n.navDashboard;
      case 'navFleet':
        return l10n.dashboardFleet;
      case 'navRequests':
        return l10n.navRequests;
      case 'navCustomers':
        return l10n.customersTitle;
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
    final l10n = AppLocalizations.of(context);
    // Audit fix: the 56 px content height is kept, but the system
    // gesture inset is added below it (Scaffold passes the full
    // MediaQuery padding to bottomNavigationBar). At large text
    // scales the 12 sp labels need more room, so the content grows
    // past 56 px instead of clipping.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final textScaler = MediaQuery.textScalerOf(context);
    final contentHeight =
        math.max(navHeight, 40 + textScaler.scale(12));
    return Container(
      height: contentHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      color: background,
      child: NavigationBar(
        height: contentHeight,
        backgroundColor: background,
        elevation: 0,
        selectedIndex: currentIndex,
        // E2: a light selection click on every tab tap.
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        destinations: [
          for (final item in items)
            NavigationDestination(
                icon: item.icon, label: labelFor(l10n, item)),
        ],
      ),
    );
  }
}
