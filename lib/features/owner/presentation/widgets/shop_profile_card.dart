import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/current_shop.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// Audit §5 (O33): the settings profile card — the owner's name and
/// avatar (shop logo) above the shop name. Previously the card was
/// shop-name-only. The read is lazy (try/catch): a failed load keeps
/// the fallback text and the card never flashes "not set yet".
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
      final doc = await FirebaseFirestore.instance.collection('shops').doc(currentShopId()).get();
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: _loaded
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
    );
  }
}
