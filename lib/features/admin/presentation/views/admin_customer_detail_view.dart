import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_qr_code_row.dart';
import '../widgets/admin_shell.dart';
import '../widgets/customer_detail_actions.dart';
import '../widgets/customer_trust_breakdown.dart';

/// Phase C (C1) — one customer: the C3 trust score with its breakdown,
/// CNIC and KYC state, blacklist state, trips and booking history,
/// guarantor links from the bookings, admin notes, and the
/// Watchlist/Blacklist actions.
///
/// The CNIC back-QR number is shown here ONLY for a super admin
/// (visibility rule, 2026-11-10): the number lives in the restricted
/// `customer_qr_codes/{customerId}` doc, the rules deny the read for
/// anyone else, and this view never even requests it for other roles.
class AdminCustomerDetailView extends StatefulWidget {
  const AdminCustomerDetailView({
    super.key,
    required this.customerId,
    this.loadDetail,
    this.resolveAdminRole,
    this.loadQrCode,
  });

  final String customerId;

  /// Test seams (data access). Defaults read the real data source
  /// and session; tests pass fakes so no Firebase/DI is needed.
  final Future<CustomerDetail?> Function(String customerId)? loadDetail;
  final Future<String?> Function()? resolveAdminRole;
  final Future<String?> Function(String customerId)? loadQrCode;

  @override
  State<AdminCustomerDetailView> createState() =>
      _AdminCustomerDetailViewState();
}

class _AdminCustomerDetailViewState extends State<AdminCustomerDetailView> {
  final _noteController = TextEditingController();
  CustomerDetail? _detail;
  bool _isLoading = true;
  bool _isWorking = false;
  bool _isSuperAdmin = false;
  String? _qrCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  static Future<String?> _defaultResolveRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await AdminSession.resolveAdminRole(user);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final detail = await (widget.loadDetail?.call(widget.customerId) ??
        sl<AdminPeopleDataSource>().getCustomerDetail(widget.customerId));
    if (!mounted) return;
    setState(() { _detail = detail; _isLoading = false; });
    if (detail == null) return;
    // The QR number is requested ONLY for a super admin — the rules would deny the read for anyone else, so it is not even attempted.
    final role = await (widget.resolveAdminRole?.call() ?? _defaultResolveRole());
    if (!mounted) return;
    final isSuperAdmin = role == AdminPermissions.superAdmin;
    final qrCode = isSuperAdmin
        ? await (widget.loadQrCode?.call(widget.customerId) ??
            sl<AdminPeopleDataSource>().getCustomerQrCode(widget.customerId))
        : null;
    if (!mounted) return;
    setState(() { _isSuperAdmin = isSuperAdmin; _qrCode = qrCode; });
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().addCustomerNote(customerId: widget.customerId, text: text);
    if (!mounted) return;
    if (synced) { _noteController.clear(); await _load(); } else { AppFeedback.showError(context, 'Could not reach the server.'); }
    setState(() => _isWorking = false);
  }

  Future<void> _blacklist() async {
    final d = _detail;
    if (d == null) return;
    final cnic = d.customer.cnic;
    if (cnic == null || cnic.isEmpty) {
      AppFeedback.showError(context, 'No CNIC on file — a blacklist entry needs one.');
      return;
    }
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().reportCustomerToBlacklist(customerId: d.customer.customerId, cnic: cnic, phone: d.customer.phone, reasonCategory: 'Admin report', description: 'Reported by an admin from the customer detail screen.', reportedByShopId: 'admin');
    if (!mounted) return;
    if (synced) { AppFeedback.showSuccess(context, 'Customer reported to the blacklist.'); await _load(); } else { AppFeedback.showError(context, 'Could not reach the server.'); }
    setState(() => _isWorking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminShell(
      activeRoute: RouteNames.adminCustomers,
      title: 'Customer detail',
      subtitle: 'Trust score, KYC, trips and admin actions',
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminCustomers),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Customer not found.', style: TextStyle(fontWeight: FontWeight.w700))))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_detail!.customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${_detail!.customer.phone} • CNIC ${_detail!.customer.cnic ?? 'not on file'} • Source: ${_detail!.customer.source}', style: const TextStyle(fontSize: 13)),
                      AdminQrCodeRow(isSuperAdmin: _isSuperAdmin, qrCode: _qrCode),
                      const SizedBox(height: 8),
                      if (_detail!.isBlacklisted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                          child: Text('Blacklisted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.error)),
                        ),
                      const SizedBox(height: 16),
                      CustomerTrustBreakdown(
                        breakdown: _detail!.trustBreakdown,
                        storedScore: _detail!.storedTrustScore,
                        completedTrips: _detail!.completedTrips,
                        meanOwnerRating: _detail!.meanOwnerRating,
                        kycStatus: _detail!.kycStatus,
                      ),
                      const SizedBox(height: 20),
                      _section('Booking history',
                          _detail!.bookings.isEmpty
                              ? ['No bookings yet.']
                              : _detail!.bookings
                                  .take(10)
                                  .map((b) =>
                                      '${b.vehicleName ?? b.vehicleId} • ${b.status} • ${l10n.amountRs(formatRs(b.totalAmount))}')
                                  .toList()),
                      _section(
                          'Guarantors',
                          _detail!.bookings
                              .where((b) =>
                                  (b.guarantorName ?? '').isNotEmpty)
                              .map((b) =>
                                  '${b.guarantorName} • CNIC ${b.guarantorCnic ?? '—'} • ${b.guarantorPhone ?? ''}')
                              .toSet()
                              .toList()),
                      _section('Admin notes',
                          _detail!.notes.isEmpty
                              ? ['No notes yet.']
                              : _detail!.notes
                                  .map((n) => n.text)
                                  .toList()),
                      CustomerDetailActions(
                        noteController: _noteController,
                        isWorking: _isWorking,
                        onAddNote: _addNote,
                        onWatchlist: () async {
                          final synced =
                              await sl<AdminPeopleDataSource>()
                                  .setCustomerWatchlisted(
                            customerId: widget.customerId,
                            watchlisted: true,
                          );
                          if (!context.mounted) return;
                          if (synced) {
                            AppFeedback.showSuccess(context,
                                'Customer added to the watchlist.');
                          } else {
                            AppFeedback.showError(
                                context, 'Could not reach the server.');
                          }
                        },
                        onBlacklist: _blacklist,
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
