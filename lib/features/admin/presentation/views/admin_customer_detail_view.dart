import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_qr_code_row.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
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
  const AdminCustomerDetailView({super.key, required this.customerId, this.loadDetail, this.resolveAdminRole, this.loadQrCode});

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
  bool _hasError = false;
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
    if (!_isLoading) setState(() => _hasError = false);
    CustomerDetail? detail;
    try {
      detail = await (widget.loadDetail?.call(widget.customerId) ??
          sl<AdminPeopleDataSource>().getCustomerDetail(widget.customerId));
    } catch (_) {
      if (!mounted) return;
      setState(() { _hasError = true; _isLoading = false; });
      return;
    }
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
    final check = await AdminPermissionCheck.check(context, AdminPermission.manageBlacklist);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().addCustomerNote(customerId: widget.customerId, text: text, adminRole: check.role);
    if (!mounted) return;
    if (synced) { _noteController.clear(); await _load(); } else { AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_serverUnreachable); }
    setState(() => _isWorking = false);
  }

  Future<void> _blacklist() async {
    final d = _detail;
    if (d == null) return;
    final cnic = d.customer.cnic;
    if (cnic == null || cnic.isEmpty) {
      AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_customerDetailNoCnic);
      return;
    }
    // AD-M6: one tap used to file the report with hardcoded strings.
    // The admin confirms and gives the reason — the tribunal judges
    // the case on it — and it is passed through as the reason.
    final reason = await showBlacklistReportDialog(context);
    if (reason == null || reason.isEmpty || !mounted) return;
    final check = await AdminPermissionCheck.check(context, AdminPermission.manageBlacklist);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().reportCustomerToBlacklist(customerId: d.customer.customerId, cnic: cnic, phone: d.customer.phone, reasonCategory: reason, description: reason, reportedByShopId: 'admin', adminRole: check.role);
    if (!mounted) return;
    if (synced) { AppFeedback.showSuccess(context, AppLocalizations.of(context)!.admin2_customerDetailReported); await _load(); } else { AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_serverUnreachable); }
    setState(() => _isWorking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminShell(
      activeRoute: RouteNames.adminCustomers,
      title: l10n.admin2_customerDetailTitle,
      subtitle: l10n.admin2_customerDetailSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminCustomers),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_customerDetailLoadFailed,
                  onRetry: _load,
                )
              : _detail == null
                  ? AppEmptyState(title: l10n.admin2_customerDetailNotFound)
                  : SingleChildScrollView(
                  // Mobile-first: 16dp on a phone, 24dp on desktop.
                  padding: EdgeInsets.all(
                      windowSizeClassOf(context) ==
                              WindowSizeClass.compact
                          ? 16
                          : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_detail!.customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(l10n.admin2_customerDetailContact(_detail!.customer.phone, _detail!.customer.cnic ?? l10n.admin2_notOnFile, humanizeStatus(_detail!.customer.source, l10n)), style: const TextStyle(fontSize: 13)),
                      AdminQrCodeRow(isSuperAdmin: _isSuperAdmin, qrCode: _qrCode),
                      const SizedBox(height: 8),
                      if (_detail!.isBlacklisted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                          // Item 4: colorScheme.error (#EF4444) is
                          // 3.44:1 on the error container — the readable
                          // danger text token is ~6.1:1 on it.
                          child: Text(l10n.admin2_customerDetailBlacklisted, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.dangerTextFor(Theme.of(context).brightness))),
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
                      AdminDetailSection(
                          title: l10n.admin2_customerDetailBookingHistory,
                          lines: _detail!.bookings.isEmpty
                              ? [l10n.admin2_customerDetailNoBookings]
                              : _detail!.bookings
                                  .take(10)
                                  .map((b) =>
                                      '${b.vehicleName ?? b.vehicleId} • ${humanizeStatus(b.status, l10n)} • ${l10n.amountRs(formatRs(b.totalAmount))}')
                                  .toList()),
                      AdminDetailSection(
                          title: l10n.admin2_customerDetailGuarantors,
                          lines: _detail!.bookings
                              .where((b) =>
                                  (b.guarantorName ?? '').isNotEmpty)
                              .map((b) =>
                                  '${b.guarantorName} • CNIC ${b.guarantorCnic ?? '—'} • ${b.guarantorPhone ?? ''}')
                              .toSet()
                              .toList()),
                      AdminDetailSection(
                          title: l10n.admin2_customerDetailAdminNotes,
                          lines: _detail!.notes.isEmpty
                              ? [l10n.admin2_customerDetailNoNotes]
                              : _detail!.notes
                                  .map((n) => n.text)
                                  .toList()),
                      CustomerDetailActions(
                        noteController: _noteController,
                        isWorking: _isWorking,
                        isWatchlisted: _detail!.isWatchlisted,
                        onAddNote: _addNote,
                        onWatchlist: () async {
                          // AD-M6: the watchlist action is a toggle.
                          final target = !_detail!.isWatchlisted;
                          final check = await AdminPermissionCheck.check(context, AdminPermission.manageBlacklist);
                          if (!check.proceed) return;
                          final synced = await sl<AdminPeopleDataSource>()
                              .setCustomerWatchlisted(
                            customerId: widget.customerId,
                            watchlisted: target,
                            adminRole: check.role,
                          );
                          if (!context.mounted) return;
                          if (synced) {
                            AppFeedback.showSuccess(context, target ? l10n.admin2_customerDetailWatchlistAdded : l10n.admin2_customerDetailWatchlistRemoved);
                            await _load();
                          } else {
                            AppFeedback.showError(context, l10n.admin2_serverUnreachable);
                          }
                        },
                        onBlacklist: _blacklist,
                      ),
                    ],
                  ),
                ),
    );
  }
}
