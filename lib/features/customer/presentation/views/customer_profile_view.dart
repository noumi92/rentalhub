import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/customer_remote_data_source.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../profile_hub_loader.dart';
import '../widgets/blacklist_appeal_sheet.dart';
import '../widgets/profile_body.dart';
import '../widgets/profile_hub_header.dart';
import '../widgets/profile_kyc_tab.dart';
import '../../../../l10n/app_localizations.dart';

// Profile hub (2026-11-25): one screen for the customer's identity
// and documents — a "Profile" tab and a "Documents & KYC" tab under
// a single shared header, loaded once by [ProfileHubLoader].
// /customer/profile is the hub; /customer/kyc deep-links into the
// hub on the KYC tab. The standalone CustomerDocumentsView still
// exists for the tests that pump it directly.
//
// Sign-out lives on the Settings screen only now (it was rendered
// twice); the trust section folds the Reputation view in (the
// reputation route stays live as a deep link).
class CustomerProfileView extends StatefulWidget {
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenReputation;
  final VoidCallback? onOpenSupport;

  /// 0 = Profile tab, 1 = Documents & KYC tab (the /customer/kyc
  /// deep link opens here).
  final int initialTab;

  const CustomerProfileView({
    super.key,
    this.onOpenDocuments,
    this.onOpenSavedShops,
    this.onOpenSettings,
    this.onOpenReputation,
    this.onOpenSupport,
    this.initialTab = 0,
  });

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  ProfileHubData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 1 ? 1 : 0,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await ProfileHubLoader.load();
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  String get _cnic => _data?.cnic ?? '';

  void _openDocuments() {
    if (widget.onOpenDocuments != null) {
      widget.onOpenDocuments!();
    } else {
      _tabController.animateTo(1);
    }
  }

  Future<void> _openEdit() async {
    await context.push<bool>(RouteNames.customerEditProfile);
    await _load();
  }

  /// The owner's triage reads the CNIC off the `customers` record,
  /// so a KYC submission lands there too (same write the standalone
  /// documents view makes).
  Future<void> _onKycSubmitted(String cnic) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = ProfileHubLoader.uid();
    if (uid.isEmpty) return;
    try {
      if (sl.isRegistered<CustomerRemoteDataSource>()) {
        final ds = sl<CustomerRemoteDataSource>();
        final existing = await ds.getCustomerById(uid);
        if (existing != null) {
          await ds.upsertCustomer(existing.copyWith(cnic: cnic));
        } else {
          await ds.upsertCustomer(CustomerEntity(
            customerId: uid,
            shopId: '',
            name: _data?.name ?? l10n.kycCustomer,
            phone: _data?.phone ?? '',
            cnic: cnic,
            source: 'online',
            createdAt: DateTime.now(),
          ));
        }
      }
    } catch (_) {}
    await _load();
    if (mounted) {
      AppFeedback.showSuccess(context, l10n.kycSubmittedNote);
    }
  }

  /// Admin final pass (2026-11-10): appeal entry point — the record is
  /// resolved from the customer's own CNIC first; no record is reported honestly.
  Future<void> _openAppeal() async {
    final l10n = AppLocalizations.of(context)!;
    if (!sl.isRegistered<BlacklistRemoteDataSource>() ||
        _cnic.isEmpty) {
      AppFeedback.showError(context, l10n.appealRecordNotFound);
      return;
    }
    final record = await sl<BlacklistRemoteDataSource>()
        .getBlacklistRecordByCnic(_cnic);
    if (!mounted) return;
    if (record == null) {
      AppFeedback.showError(context, l10n.appealRecordNotFound);
      return;
    }
    await showBlacklistAppealSheet(
      context,
      blacklistId: record.blacklistId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data;
    // Signed-out visitors have an empty name; show the localized
    // guest label (never a hardcoded 'Guest').
    final displayName = data == null || data.name.isEmpty
        ? l10n.profileGuest
        : data.name;
    return Scaffold(
      // MinimalAppBar owns the top inset — SafeArea(top: false) avoids the double status-bar band (SH-M3 class).
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ProfileHubHeader(
              name: displayName,
              email: data?.email ?? '',
              phone: data?.phone ?? '',
              photoUrl: data?.photoUrl,
              trustScore: data?.trustScore,
              kycStatus: data?.kycStatus ?? '',
              onEdit: _openEdit,
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.profileTitle),
                Tab(text: l10n.profileTabKyc),
              ],
            ),
            Expanded(
              child: _loading && data == null
                  ? const AppLoadingState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          onRefresh: _load,
                          child: SingleChildScrollView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: ProfileBody(
                              loading: _loading,
                              loadFailed: data?.loadFailed ?? false,
                              name: displayName,
                              email: data?.email ?? '',
                              phone: data?.phone ?? '',
                              dateOfBirth: data?.dateOfBirth,
                              fatherName: data?.fatherName,
                              address: data?.address,
                              trustScore: data?.trustScore,
                              kycVerified: data?.kycVerified ?? false,
                              isBlacklisted: data?.isBlacklisted ?? false,
                              onOpenReputation: widget.onOpenReputation,
                              onAppeal: (data?.isBlacklisted ?? false) &&
                                      _cnic.isNotEmpty
                                  ? _openAppeal
                                  : null,
                              ownerReviews: data?.ownerReviews ?? const [],
                              cnic: _cnic,
                              onOpenDocuments: _openDocuments,
                              onOpenSavedShops: widget.onOpenSavedShops,
                              onOpenSettings: widget.onOpenSettings,
                              onOpenSupport: widget.onOpenSupport,
                              onRetry: _load,
                            ),
                          ),
                        ),
                        ProfileKycTab(
                          existing: data?.kyc,
                          initialCnic: _cnic.isNotEmpty
                              ? _cnic
                              : (data?.kyc?.cnicNumber ?? ''),
                          rejectionReason: data?.rejectionReason,
                          loading: _loading,
                          signedOut: ProfileHubLoader.uid().isEmpty,
                          userUid: ProfileHubLoader.uid(),
                          onSubmitted: _onKycSubmitted,
                          onRetry: _load,
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
