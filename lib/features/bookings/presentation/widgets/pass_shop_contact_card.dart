import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../discovery/data/models/shop_model.dart';

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

  String get _addressLine {
    if (!_loaded) return widget.shopName;
    final shop = _shop;
    if (shop == null) return widget.shopName;
    if (shop.address.trim().isEmpty) {
      return '${shop.shopName} — address not listed yet.';
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
    final phone = _phone;
    if (phone.isEmpty) {
      AppFeedback.showInfo(
        context,
        'This showroom has no phone number listed.',
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not place the call.');
      }
    }
  }

  Future<void> _openDirections() async {
    final shop = _shop;
    String? query;
    if (_lat != null && _lng != null) {
      query = '$_lat,$_lng';
    } else if (shop != null && shop.address.trim().isNotEmpty) {
      query = shop.address;
    }
    if (query == null) {
      AppFeedback.showInfo(
        context,
        'This showroom has no location listed yet.',
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not open Maps.');
      }
    }
  }

  Future<void> _openAgreement() async {
    final url = _agreementUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not open the agreement.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
                'Showroom Handover Point',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _addressLine,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callShop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call Shop'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openDirections,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentSuccess,
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Directions'),
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
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.description_rounded, size: 16),
                label: const Text('View Rental Agreement (PDF)'),
              ),
            ),
          ] else if (_loaded) ...[
            const SizedBox(height: 10),
            Text(
              'Your signed rental agreement will appear here after handover.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
