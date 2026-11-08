import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import 'shop_fleet_photos.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';

/// The B1 review sheet for one shop application: the 6-item checklist
/// (computed from the shop document), the KYC documents and bank
/// accounts on file, fleet photos (tap to zoom), and the decision —
/// Approve, Ask for more info, or Reject with a reason the owner sees.
class ShopApplicationDetailSheet extends StatefulWidget {
  const ShopApplicationDetailSheet({
    super.key,
    required this.shop,
    required this.onDecided,
  });

  final ShopModel shop;
  final VoidCallback onDecided;

  @override
  State<ShopApplicationDetailSheet> createState() =>
      _ShopApplicationDetailSheetState();
}

class _ShopApplicationDetailSheetState
    extends State<ShopApplicationDetailSheet> {
  final _reasonController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _decide(String decision) async {
    final reason = _reasonController.text.trim();
    if (decision != 'approved' && reason.isEmpty) {
      AppFeedback.showError(
          context, 'A reason is required — the owner sees it.');
      return;
    }
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().decideShopApplication(
      shopId: widget.shop.shopId,
      decision: decision,
      reason: reason,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, 'Decision saved.');
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(
          context, 'Could not reach the server — try again.');
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final checklist = ShopApplicationChecklist.fromShop(shop);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.shopName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    )),
            const SizedBox(height: 4),
            Text('${shop.city} • ${shop.address}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(
                'Owner: ${shop.ownerName ?? '—'} • ${shop.phoneNumber} • CNIC ${shop.cnicNumber ?? '—'}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text('Checklist — ${checklist.doneCount} of 6 complete',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 8),
            ...checklist.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        color: item.done
                            ? Colors.green.shade700
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.label)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            _section('KYC documents on file',
                shop.kycDocuments.isEmpty
                    ? ['None uploaded yet.']
                    : shop.kycDocuments.keys.toList()),
            _section('Bank / wallet accounts',
                shop.bankAccounts.isEmpty
                    ? ['None on file.']
                    : shop.bankAccounts
                        .map((a) =>
                            '${a['type'] ?? 'account'} — ${a['title'] ?? a['account'] ?? ''}')
                        .toList()),
            if (shop.fleetPhotos.isNotEmpty) ...[
              const Text('Fleet photos',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: 8),
              ShopFleetPhotos(photoUrls: shop.fleetPhotos),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'Reason (required to ask for more info or reject — the owner sees it)',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isWorking ? null : () => _decide('approved'),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isWorking
                        ? null
                        : () => _decide('info_requested'),
                    child: const Text('Ask for more info'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isWorking ? null : () => _decide('rejected'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call owner'),
                onPressed: shop.phoneNumber.isEmpty
                    ? null
                    : () =>
                        launchUrl(Uri.parse('tel:${shop.phoneNumber}')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )),
        ],
      ),
    );
  }
}
