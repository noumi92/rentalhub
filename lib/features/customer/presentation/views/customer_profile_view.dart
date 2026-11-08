import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../data/datasources/customer_remote_data_source.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../trust/data/datasources/kyc_remote_data_source.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_card.dart';
import '../widgets/profile_sign_out_tile.dart';
import '../widgets/profile_trust_card.dart';

// H1: the profile is the customer's real record — name/phone/CNIC from
// their `customers` record (the same record the owner sees in triage),
// the trust score and blacklist state from their `users` record, and
// the KYC state from their KYC submission. No invented identity: a
// signed-out visitor sees 'Guest', never 'Ahmed Khan'.
class CustomerProfileView extends StatefulWidget {
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenReputation;
  final VoidCallback? onSignOut;
  final VoidCallback? onBack;

  const CustomerProfileView({
    super.key,
    this.onOpenDocuments,
    this.onOpenSavedShops,
    this.onOpenSettings,
    this.onOpenReputation,
    this.onSignOut,
    this.onBack,
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
        if (sl.isRegistered<FirestoreService>()) {
          final record =
              await sl<FirestoreService>().getUser(user.uid);
          trustScore = record?.trustScore;
          isBlacklisted = record?.isBlacklisted ?? false;
        }
        if (sl.isRegistered<CustomerRemoteDataSource>()) {
          final customer = await sl<CustomerRemoteDataSource>()
              .getCustomerById(user.uid);
          if (customer != null) {
            name = customer.name;
            phone = customer.phone;
            cnic = customer.cnic ?? '';
          }
        }
        if (sl.isRegistered<KycRemoteDataSource>()) {
          final kyc =
              await sl<KycRemoteDataSource>().getKyc(user.uid);
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
    final uid = _uid();
    if (uid.isEmpty) {
      throw Exception('Not signed in.');
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
      AppFeedback.showSuccess(context, 'Profile saved.');
    }
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 120,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: ProfileHeader(
                name: _name,
                email: _email,
                phone: _phone,
                onEdit: _openEdit,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    if (_loading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else ...[
                      ProfileTrustCard(
                        trustScore: _trustScore,
                        kycVerified: _kycVerified,
                        isBlacklisted: _isBlacklisted,
                        onTap: widget.onOpenReputation,
                      ),
                      const SizedBox(height: 16),
                      ProfileMenuCard(items: [
                        ProfileMenuItem(
                          icon: Icons.badge_outlined,
                          title: 'My Documents (KYC)',
                          subtitle: 'CNIC Front/Back & Driving License',
                          onTap: widget.onOpenDocuments,
                        ),
                        ProfileMenuItem(
                          icon: Icons.favorite_border_rounded,
                          title: 'Saved Showrooms',
                          subtitle: 'Bookmarked rental agencies',
                          onTap: widget.onOpenSavedShops,
                        ),
                        ProfileMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings & Language',
                          subtitle: 'English / Urdu, Notifications',
                          onTap: widget.onOpenSettings,
                        ),
                      ]),
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
