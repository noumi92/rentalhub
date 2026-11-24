import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';

/// Customer rework (Worker C): the customer Home action row — three
/// compact chips (Wallet, Support, SOS) plus the prominent
/// "Book a Car" button, in one horizontal row directly under the
/// KYC banner.
///
/// Home redesign (2026-11-24): "Book a Car" left the extended
/// floating button — the FAB overlapped booking cards while
/// scrolling — and now lives here as the row's primary action. The
/// theme FilledButton is already the orange fill in both modes, so
/// no colour is set here. The chips keep the
/// `quick-action-<label>` keys the navigation tests tap. SOS uses
/// the error container tokens (dark leg #3B1215 / #FCA5A5, light leg
/// #FEF2F2 / #B91C1C) — the red tint of the design, never a
/// hardcoded hex.
///
/// Destinations (all real, no dead tiles):
/// - Wallet → the wallet tab ([RouteNames.customerWallet]).
/// - Support → the support inbox ([RouteNames.customerSupport]) as
///   a sub-screen (pushed, so back returns to Home — Support is no
///   longer a tab).
/// - SOS → the SOS screen ([RouteNames.customerSos]).
/// - Book a Car → the Shops tab ([RouteNames.customerShops]).
class CustomerHomeQuickActions extends StatelessWidget {
  const CustomerHomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: _ActionChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: l10n.walletLabel,
                  color: AppColors.primaryTextFor(brightness),
                  onTap: () => context.go(RouteNames.customerWallet),
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: _ActionChip(
                  icon: Icons.support_agent_rounded,
                  label: l10n.home2_support,
                  color: AppColors.successTextFor(brightness),
                  onTap: () => context.push(RouteNames.customerSupport),
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: _ActionChip(
                  icon: Icons.sos_rounded,
                  label: l10n.sos,
                  color: AppColors.errorOnContainerFor(brightness),
                  background: AppColors.errorContainerFor(brightness),
                  onTap: () => context.push(RouteNames.customerSos),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // The button's label is 324px wide at 200% text scale in the
        // test font (and wide in Urdu) — wider than the whole row
        // leaves for it — so the button is capped at 200px and its
        // label ellipsizes instead of overflowing the row. Below
        // the cap the button is its natural width.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: FilledButton.icon(
            key: const ValueKey('home-book-car'),
            onPressed: () => context.go(RouteNames.customerShops),
            icon: const Icon(Icons.directions_car_rounded, size: 20),
            label: Text(
              l10n.quickBookCar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              // CU-M3: 48dp minimum tap target.
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    );
  }
}

/// One compact icon-and-label chip. The label ellipsizes instead of
/// overflowing at large text scales; the chip is 48dp tall (CU-M3).
/// Gaps and padding are tight on purpose: three chips plus the Book
/// a Car button must fit 360px even at 200% text scale — the labels
/// shrink to their icons rather than overflowing the row.
/// [background] is a full container tint when given (SOS); otherwise
/// the chip is the label colour at 12% alpha.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('quick-action-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: background ?? color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
