import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/current_shop.dart';
import '../../../../../core/utils/shop_id_resolution.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// Audit §5 (O33): the settings profile card — the owner's name and
/// avatar (shop logo) above the shop name. Previously the card was
/// shop-name-only. The read is lazy (try/catch): a failed load keeps
/// the fallback text and the card never flashes "not set yet".
/// Showroom redesign Phase 4 (2026-11-16): the card carries a
/// "Showroom Owner" heading and an orange shortcut pill to the
/// existing shop editor (/owner/settings/shop) — no new screen.
class ShopProfileCard extends StatefulWidget {
  const ShopProfileCard({super.key});

  @override
  State<ShopProfileCard> createState() => _ShopProfileCardState();
}

class _ShopProfileCardState extends State<ShopProfileCard> {
  String _shopName = '';
  String _ownerName = '';
  String? _logoUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Shop-id linking (2026-11-15): the shops document is
      // `shop_<uid>`; the bare UID read always missed, so the card
      // showed the fallback text instead of the real shop name.
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(await canonicalShopId(
              FirebaseFirestore.instance, currentShopId()))
          .get();
      final data = doc.data() ?? {};
      if (!mounted) return;
      setState(() {
        _shopName = (data['name'] ?? data['shopName'] ?? '') as String;
        _ownerName = (data['ownerName'] ?? '') as String;
        _logoUrl = data['logoUrl'] as String?;
      });
    } catch (_) {
      // Keeps the fallback text below; the card still resolves.
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecoration.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.settingsShowroomOwner, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              _setUpShopPill(context),
            ],
          ),
          const SizedBox(height: 12),
          _loaded
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: _logoUrl != null && _logoUrl!.startsWith('http') ? NetworkImage(_logoUrl!) : null,
                      child: _logoUrl != null && _logoUrl!.startsWith('http') ? null : const Icon(Icons.storefront_rounded, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ownerName.isNotEmpty ? _ownerName : l10n.shopProfileOwnerUnknown,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _shopName.isNotEmpty ? _shopName : l10n.shopNotSet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox(height: 52),
        ],
      ),
    );
  }

  /// Orange shortcut to the existing shop editor — no new screen.
  /// The pill reads `settingsSetUpShop` ("Set Up Shop", Phase 5,
  /// 2026-11-16); the target is /owner/settings/shop. The
  /// "Shop settings" string was NOT reused: two frozen tests count
  /// it at exactly two occurrences (app-bar title + Operations
  /// row) in both locales. `orangeFill` (not `accentOrange`)
  /// carries the small white label: white on #EA580C is 3.56:1
  /// and fails AA, white on #C2410C is 5.18:1.
  Widget _setUpShopPill(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Capped so the heading row never overflows: at 200% text
    // scale the pill label alone is wider than the row (E3), and
    // the FittedBox scales it down inside the cap instead.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: FilledButton(
        onPressed: () => context.push(RouteNames.ownerShopSettings),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orangeFill,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: const StadiumBorder(),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.settingsSetUpShop, maxLines: 1)),
      ),
    );
  }
}
