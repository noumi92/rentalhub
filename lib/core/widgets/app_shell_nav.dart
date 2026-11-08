import 'package:flutter/material.dart';

/// Phase C (C2): the ONE bottom navigation for the whole app — the
/// customer and owner shells both render this widget, parameterized by
/// their five tabs. It replaces the two duplicated M2
/// `BottomNavigationBar` widgets (`customer_bottom_nav.dart`,
/// `owner_bottom_nav.dart`, deleted with this phase).
///
/// Rulebook §4.4 floating spec: a floating container, height 68 px,
/// margin 16 px, radius 32 px, navy background, orange active
/// indicator, shadow `0 -4 20 rgba(0,0,0,0.08)`. The navy/orange
/// colours come from the theme's `navigationBarTheme` (light:
/// `primary`/`secondary`; dark: `primaryDarkOnDark`/`secondaryDark`),
/// so both themes get the spec without a literal here. Labels are
/// 12 sp via the same theme.
///
/// An item's [ShellNavItem.icon] is a full widget (not an [IconData])
/// so a tab can carry a live badge — the Requests and Support tabs
/// pass a badge widget that wraps the icon in a [Badge] when its
/// count is nonzero, and renders the plain icon otherwise.
class ShellNavItem {
  final Widget icon;
  final String label;

  const ShellNavItem({required this.icon, required this.label});
}

class AppShellNav extends StatelessWidget {
  /// Rulebook §4.4 floating geometry.
  static const double navHeight = 68;
  static const double navMargin = 16;
  static const double navRadius = 32;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ShellNavItem> items;

  const AppShellNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.navigationBarTheme.backgroundColor ??
        theme.colorScheme.primary;
    return Container(
      height: navHeight,
      margin: const EdgeInsets.all(navMargin),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(navRadius),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            offset: Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(navRadius),
        child: NavigationBar(
          height: navHeight,
          elevation: 0,
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          destinations: [
            for (final item in items)
              NavigationDestination(icon: item.icon, label: item.label),
          ],
        ),
      ),
    );
  }
}
