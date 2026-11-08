import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_suspend_dialog.dart';

/// Phase B (B2) — one shop: plan, cars, lifetime bookings, rating,
/// KYC and bank summary, and the admin actions — suspend/unsuspend
/// with a reason, and message the owner on WhatsApp.
class AdminShopDetailView extends StatefulWidget {
  const AdminShopDetailView({super.key, required this.shopId});

  final String shopId;

  @override
  State<AdminShopDetailView> createState() => _AdminShopDetailViewState();
}

class _AdminShopDetailViewState extends State<AdminShopDetailView> {
  ShopModel? _shop;
  int _vehicleCount = 0;
  int _bookingCount = 0;
  bool _isLoading = true;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ds = sl<AdminShopsDataSource>();
    final shop = await ds.getShop(widget.shopId);
    final vehicles = await ds.getShopVehicleCount(widget.shopId);
    final bookings = await ds.getShopBookingCount(widget.shopId);
    if (mounted) {
      setState(() {
        _shop = shop;
        _vehicleCount = vehicles;
        _bookingCount = bookings;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSuspend(bool suspend) async {
    final reason = await showSuspendDialog(context, suspend: suspend);
    if (reason == null) return;
    if (!mounted) return;
    if (reason.isEmpty) {
      AppFeedback.showError(context, 'A reason is required.');
      return;
    }
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().setShopSuspended(
      shopId: widget.shopId,
      suspended: suspend,
      reason: reason,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
          context, suspend ? 'Shop suspended.' : 'Suspension lifted.');
      await _load();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
    }
    setState(() => _isWorking = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: RouteNames.adminShops,
      title: 'Shop detail',
      subtitle: 'Plan, fleet, bookings and admin actions',
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminShops),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shop == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Shop not found.',
                      style: TextStyle(
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_shop!.shopName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        '${_shop!.city} • ${_shop!.address}\nOwner: ${_shop!.ownerName ?? '—'} • ${_shop!.phoneNumber}',
                        style: const TextStyle(
                            fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _fact('Plan', _shop!.plan),
                          _fact('Status',
                              _shop!.suspended ? 'Suspended' : _shop!.verificationStatus),
                          _fact('Cars', '$_vehicleCount'),
                          _fact('Lifetime bookings', '$_bookingCount'),
                          _fact('Rating',
                              _shop!.rating.toStringAsFixed(1)),
                        ],
                      ),
                      if (_shop!.suspended &&
                          (_shop!.suspensionReason ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Suspension reason: ${_shop!.suspensionReason}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 20),
                      _section('KYC documents',
                          _shop!.kycDocuments.isEmpty
                              ? ['None uploaded yet.']
                              : _shop!.kycDocuments.keys.toList()),
                      _section('Bank / wallet accounts',
                          _shop!.bankAccounts.isEmpty
                              ? ['None on file.']
                              : _shop!.bankAccounts
                                  .map((a) =>
                                      '${a['type'] ?? 'account'} — ${a['title'] ?? a['account'] ?? ''}')
                                  .toList()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.message_rounded,
                                  size: 18),
                              label: const Text('Message owner'),
                              onPressed: () async {
                                final uri = whatsappUri(
                                  phone: _shop!.phoneNumber,
                                  message:
                                      'Hello from RentalHub admin regarding ${_shop!.shopName}.',
                                );
                                if (uri == null) {
                                  AppFeedback.showError(context,
                                      'No phone number on file for this shop.');
                                  return;
                                }
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isWorking
                                  ? null
                                  : () => _toggleSuspend(!_shop!.suspended),
                              style: _shop!.suspended
                                  ? null
                                  : FilledButton.styleFrom(
                                      backgroundColor: Colors.red.shade700),
                              child: Text(_isWorking
                                  ? 'Saving…'
                                  : _shop!.suspended
                                      ? 'Lift suspension'
                                      : 'Suspend shop'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _fact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ],
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
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: const TextStyle(
                        fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
