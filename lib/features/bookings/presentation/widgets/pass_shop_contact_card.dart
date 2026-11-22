import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_map_tile_layer.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// D3: the showroom contact card on the pickup pass — the shop's real
/// address, a real call button, real directions, and the signed rental
/// agreement (the A4 PDF from owner E) once handover has created it.
/// Nothing is invented: a shop with no address/phone/coords says so,
/// and the agreement button only appears once `agreements/{bookingId}`
/// exists.
class PassShopContactCard extends StatefulWidget {
  const PassShopContactCard({
    super.key,
    required this.shopId,
    required this.shopName,
    this.shopPhone,
    required this.bookingId,
  });

  final String shopId;
  final String shopName;
  final String? shopPhone;
  final String bookingId;

  @override
  State<PassShopContactCard> createState() => _PassShopContactCardState();
}

class _PassShopContactCardState extends State<PassShopContactCard> {
  ShopModel? _shop;
  double? _lat;
  double? _lng;
  String? _agreementUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    ShopModel? shop;
    double? lat;
    double? lng;
    String? agreementUrl;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .get();
      if (snap.exists && snap.data() != null) {
        shop = ShopModel.fromMap(snap.data()!, id: snap.id);
        // Coordinates come from the raw doc: fromMap fills in a Lahore
        // default when they are absent, and directions to a default
        // point would be wrong.
        final rawLat = snap.data()!['latitude'];
        final rawLng = snap.data()!['longitude'];
        if (rawLat is num && rawLng is num) {
          lat = rawLat.toDouble();
          lng = rawLng.toDouble();
        }
      }
    } catch (_) {}
    try {
      final snap = await FirebaseFirestore.instance
          .collection('agreements')
          .doc(widget.bookingId)
          .get();
      agreementUrl = snap.data()?['agreementPdfUrl'] as String?;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _shop = shop;
        _lat = lat;
        _lng = lng;
        _agreementUrl = agreementUrl;
        _loaded = true;
      });
    }
  }

  String _addressLine(AppLocalizations l10n) {
    if (!_loaded) return widget.shopName;
    final shop = _shop;
    if (shop == null) return widget.shopName;
    if (shop.address.trim().isEmpty) {
      return l10n.passShopNoAddress(shop.shopName);
    }
    final city = shop.city.trim();
    return city.isEmpty ? shop.address : '${shop.address}, $city';
  }

  String get _phone {
    final fromShop = _shop?.phoneNumber.trim() ?? '';
    if (fromShop.isNotEmpty) return fromShop;
    return (widget.shopPhone ?? '').trim();
  }

  Future<void> _callShop() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phone;
    if (phone.isEmpty) {
      AppFeedback.showInfo(
        context,
        l10n.passNoPhone,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        AppFeedback.showError(context, l10n.couldNotCall);
      }
    }
  }

  Future<void> _openDirections() async {
    await openMapDirections(
      context,
      lat: _lat,
      lng: _lng,
      address: _shop?.address,
    );
  }

  Future<void> _openAgreement() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _agreementUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, l10n.passOpenAgreementError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                l10n.passHandoverPoint,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _addressLine(l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callShop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label:  Text(l10n.passCallShop),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openDirections,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.successOnContainerFor(Theme.of(context).brightness),
                    side: BorderSide(color: AppColors.successBorderFor(Theme.of(context).brightness)),
                    backgroundColor: AppColors.successContainerFor(Theme.of(context).brightness),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label:  Text(l10n.passDirections),
                ),
              ),
            ],
          ),
          if (_agreementUrl != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAgreement,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.description_rounded, size: 16),
                label:  Text(l10n.passViewAgreement),
              ),
            ),
          ] else if (_loaded) ...[
            const SizedBox(height: 10),
            Text(
              l10n.passAgreementHint,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
