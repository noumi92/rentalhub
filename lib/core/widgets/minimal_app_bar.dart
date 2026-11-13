import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Minimal app bar (design direction #16): flat solid navy, 56 dp title
/// bar (+ status-bar padding), bold white title 18 sp / w900 +
/// 70%-white subtitle 12 sp, back arrow automatically when the route
/// can pop (tab roots: none). Every screen except the login hero uses
/// this; login keeps the curved hero ([CustomCurvedHeader] hero
/// variant).
///
/// 56 dp is a minimum, not a fixed height: at 200% text scale the
/// two-line title + subtitle need more room, and a fixed 56 dp box
/// overflowed by 16 px (multi_screen_overflow_test) — so the bar
/// grows past 56 dp instead of clipping.
///
/// The bar owns the top inset exactly once (C1): it adds
/// `MediaQuery.padding.top` itself, so callers wrap the scaffold body
/// in `SafeArea(top: false)` and the shell strips the inset from the
/// branch subtree — no double status-bar band.
class MinimalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MinimalAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
    final showBack = onBack != null || canPop;
    // Audit SH-N8: the title/subtitle pair lived as hardcoded 18 sp
    // w900 / 12 sp styles here. It now comes from the theme's
    // HeaderTextTheme (the header spec: 18/12, white on navy, Urdu
    // title capped at w700).
    final headerText = HeaderTextTheme.of(context);
    return Container(
      color: AppColors.primaryDark,
      padding: EdgeInsets.only(top: topPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                tooltip: AppLocalizations.of(context)?.back ?? 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerText.headerTitle,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: headerText.headerSubtitle,
                    ),
                ],
              ),
            ),
            if (actions != null) ...actions!,
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
