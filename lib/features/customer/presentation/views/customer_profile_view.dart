import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../data/datasources/customer_remote_data_source.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../trust/data/datasources/kyc_remote_data_source.dart';
import '../../../trust/data/services/trust_score_service.dart';
import '../widgets/blacklist_appeal_sheet.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/profile_cnic_row.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/profile_sign_out_tile.dart';
import '../widgets/profile_trust_card.dart';
import '../../../../l10n/app_localizations.dart';

// H1: the profile is the customer's real record — name/phone/CNIC
// from `customers`, trust + blacklist from `users`, KYC from their
// submission. No invented identity: a signed-out visitor sees 'Guest'.
class CustomerProfileView extends StatefulWidget {
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenReputation;
  final VoidCallback? onOpenSupport;
  final VoidCallback? onSignOut;

  const CustomerProfileView({
    super.key,
    this.onOpenDocuments,
    this.onOpenSavedShops,
    this.onOpenSettings,
    this.onOpenReputation,
    this.onOpenSupport,
    this.onSignOut,
  });

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> {
  String _name = 'Guest';
  String _email = '';
  String _phone = '';
  String _cnic = '';
  double? _trustScore;
  bool _kycVerified = false;
  bool _isBlacklisted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadProfile() async {
    var name = 'Guest';
    var email = '';
    var phone = '';
    var cnic = '';
    double? trustScore;
    var kycVerified = false;
    var isBlacklisted = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        name = user.displayName ?? 'Guest';
        email = user.email ?? '';
        phone = user.phoneNumber ?? '';
        double? storedTrustScore;
        if (sl.isRegistered<FirestoreService>()) {
          final record = await sl<FirestoreService>().getUser(user.uid);
          storedTrustScore = record?.trustScore;
          isBlacklisted = record?.isBlacklisted ?? false;
        }
        // Live score first (shared TrustScoreService, same as the admin panel); stored trust_score is the fallback.
        trustScore = (await const TrustScoreService().compute(user.uid))?.breakdown.total ?? storedTrustScore;
        if (sl.isRegistered<CustomerRemoteDataSource>()) {
          final customer = await sl<CustomerRemoteDataSource>().getCustomerById(user.uid);
          if (customer != null) {
            name = customer.name;
            phone = customer.phone;
            cnic = customer.cnic ?? '';
          }
        }
        if (sl.isRegistered<KycRemoteDataSource>()) {
          final kyc = await sl<KycRemoteDataSource>().getKyc(user.uid);
          kycVerified = kyc?.status == 'verified';
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
        _phone = phone;
        _cnic = cnic;
        _trustScore = trustScore;
        _kycVerified = kycVerified;
        _isBlacklisted = isBlacklisted;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile({
    required String name,
    required String phone,
    required String cnic,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _uid();
    if (uid.isEmpty) {
      throw Exception(l10n.profileNotSignedIn);
    }
    if (sl.isRegistered<CustomerRemoteDataSource>()) {
      final ds = sl<CustomerRemoteDataSource>();
      final existing = await ds.getCustomerById(uid);
      if (existing != null) {
        await ds.upsertCustomer(
          existing.copyWith(name: name, phone: phone, cnic: cnic),
        );
      } else {
        await ds.upsertCustomer(CustomerEntity(
          customerId: uid,
          shopId: '',
          name: name,
          phone: phone,
          cnic: cnic.isEmpty ? null : cnic,
          source: 'online',
          createdAt: DateTime.now(),
        ));
      }
    }
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    } catch (_) {}
    await _loadProfile();
    if (mounted) {
      AppFeedback.showSuccess(context, l10n.profileSaved);
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

  void _openEdit() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProfileSheet(
        initialName: _name == 'Guest' ? '' : _name,
        initialPhone: _phone,
        initialCnic: _cnic,
        onSave: _saveProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // MinimalAppBar owns the top inset — SafeArea(top: false)
      // avoids the double status-bar band (SH-M3 class).
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: _name == 'Guest' ? l10n.profileGuest : _name,
              subtitle: _email.isNotEmpty ? _email : (_phone.isNotEmpty ? _phone : l10n.profileNotSignedInShort),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  tooltip: l10n.profileEditProfile,
                  onPressed: _openEdit,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    if (_loading)
                      // E2: shared loading state.
                      AppLoadingState(message: l10n.profileLoading)
                    else ...[
                      ProfileTrustCard(trustScore: _trustScore, kycVerified: _kycVerified, isBlacklisted: _isBlacklisted, onTap: widget.onOpenReputation, onAppeal: (_isBlacklisted && _cnic.isNotEmpty) ? _openAppeal : null),
                      const SizedBox(height: 16),
                      // E1: the customer's own CNIC, masked by default.
                      if (_cnic.isNotEmpty) ...[
                        ProfileCnicRow(cnic: _cnic),
                        const SizedBox(height: 16),
                      ],
                      ProfileMenuSection(
                        onOpenDocuments: widget.onOpenDocuments,
                        onOpenSavedShops: widget.onOpenSavedShops,
                        onOpenSettings: widget.onOpenSettings,
                        onOpenSupport: widget.onOpenSupport,
                      ),
                      const SizedBox(height: 16),
                      ProfileSignOutTile(onTap: widget.onSignOut),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
