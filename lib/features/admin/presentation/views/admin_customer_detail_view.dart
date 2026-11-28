import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_shell.dart';
import '../widgets/customer_detail_header.dart';
import '../widgets/customer_detail_actions.dart';
import '../widgets/customer_detail_kyc_tab.dart';
import '../widgets/customer_detail_notes_tab.dart';
import '../widgets/customer_detail_profile_tab.dart';

/// One-stop Customer Management Hub: KPIs + horizontal tabs (Profile,
/// KYC & Docs for decideKyc roles, Bookings, Notes & Flags) + sticky actions.
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
  bool _canReviewKyc = false;
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
    // Step 3 — the profile tab's KYC entry point is gated on the
    // existing decideKyc permission (super admin + operations),
    // resolved here once alongside the QR-code role check.
    final canReviewKyc =
        AdminPermissions.can(role, AdminPermission.decideKyc);
    final qrCode = isSuperAdmin
        ? await (widget.loadQrCode?.call(widget.customerId) ??
            sl<AdminPeopleDataSource>().getCustomerQrCode(widget.customerId))
        : null;
    if (!mounted) return;
    setState(() { _isSuperAdmin = isSuperAdmin; _canReviewKyc = canReviewKyc; _qrCode = qrCode; });
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

  Future<void> _toggleWatchlist() async {
    final d = _detail;
    if (d == null) return;
    // AD-M6: the watchlist action is a toggle.
    final target = !d.isWatchlisted;
    final check = await AdminPermissionCheck.check(context, AdminPermission.manageBlacklist);
    if (!check.proceed) return;
    final synced = await sl<AdminPeopleDataSource>().setCustomerWatchlisted(
      customerId: widget.customerId,
      watchlisted: target,
      adminRole: check.role,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (synced) {
      AppFeedback.showSuccess(context, target ? l10n.admin2_customerDetailWatchlistAdded : l10n.admin2_customerDetailWatchlistRemoved);
      await _load();
    } else {
      AppFeedback.showError(context, l10n.admin2_serverUnreachable);
    }
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
    // the case on it. Phase 3 (3.6b): the category is a real enum
    // value and the description is free text, not the same string
    // passed twice.
    final report = await showBlacklistReportDialog(context);
    if (report == null || !mounted) return;
    final check = await AdminPermissionCheck.check(context, AdminPermission.manageBlacklist);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().reportCustomerToBlacklist(customerId: d.customer.customerId, cnic: cnic, phone: d.customer.phone, reasonCategory: report.category.value, description: report.description, reportedByShopId: 'admin', adminRole: check.role);
    if (!mounted) return;
    if (synced) { AppFeedback.showSuccess(context, AppLocalizations.of(context)!.admin2_customerDetailReported); await _load(); } else { AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_serverUnreachable); }
    setState(() => _isWorking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;
    // Mobile-first: 16dp on a phone, 24dp on desktop.
    final padding = EdgeInsets.all(
        windowSizeClassOf(context) == WindowSizeClass.compact ? 16 : 24);
    return AdminShell(
      activeRoute: RouteNames.adminCustomers,
      title: l10n.admin2_customerDetailTitle,
      subtitle: l10n.admin2_customerDetailSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminCustomers),
      // Phase 4 (4.4a) — Watchlist / Blacklist are the sticky bar
      // now, reachable from every tab.
      bottomBar: detail == null
          ? null
          : CustomerDetailStickyActions(
              detail: detail,
              isWorking: _isWorking,
              onWatchlist: _toggleWatchlist,
              onBlacklist: _blacklist,
            ),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_customerDetailLoadFailed,
                  onRetry: _load,
                )
              : detail == null
                  ? AppEmptyState(title: l10n.admin2_customerDetailNotFound)
                  : DefaultTabController(
                      key: ValueKey('customer-tabs-$_canReviewKyc'),
                      length: _canReviewKyc ? 3 : 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: padding.copyWith(bottom: 0),
                            child: CustomerDetailHeader(
                              detail: detail,
                              isSuperAdmin: _isSuperAdmin,
                              qrCode: _qrCode,
                            ),
                          ),
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              Tab(text: l10n.admin2_customerDetailTabProfile),
                              if (_canReviewKyc) Tab(text: l10n.adminKycReviewTitle),
                              Tab(text: l10n.admin2_customerDetailTabNotes),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                CustomerDetailProfileTab(detail: detail, padding: padding, canReviewKyc: _canReviewKyc),
                                if (_canReviewKyc)
                                  CustomerDetailKycTab(
                                    customerId: widget.customerId,
                                    isSuperAdmin: _isSuperAdmin,
                                    qrCode: _qrCode,
                                    onDecided: _load,
                                  ),
                                CustomerDetailNotesTab(
                                  detail: detail,
                                  padding: padding,
                                  noteController: _noteController,
                                  isWorking: _isWorking,
                                  onAddNote: _addNote,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
