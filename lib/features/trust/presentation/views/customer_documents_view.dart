import 'package:flutter/material.dart';

import '../../../../core/auth/signed_in_user.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../data/datasources/kyc_remote_data_source.dart';
import '../../domain/entities/kyc_document_entity.dart';
import 'widgets/kyc_documents_panel.dart';
import '../../../../l10n/app_localizations.dart';

// G3: the customer's real documents. The CNIC comes from their own
// `customers` record (empty when they have none — no demo number), the
// submission form holds the photos they actually pick, and the status
// banner shows the real KYC status from `kyc_documents/{uid}`.
//
// Profile hub (2026-11-25): the body lives in [KycDocumentsPanel],
// shared with the hub's Documents & KYC tab — this view is now the
// thin standalone wrapper (route /customer/kyc deep-link target and
// the screen the tests pump directly).
class CustomerDocumentsView extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const CustomerDocumentsView({super.key, this.onSubmitted});

  @override
  State<CustomerDocumentsView> createState() => _CustomerDocumentsViewState();
}

class _CustomerDocumentsViewState extends State<CustomerDocumentsView> {
  KycDocumentEntity? _existing;
  String _initialCnic = '';
  // CU-M10: the admin's rejection reason, read off the `customers`
  // record (`rejectionReason`) — the KYC record carries no reason.
  String? _rejectionReason;
  // CU-m3: nobody signed in — the documents must not load under the
  // shared 'cust-101' id.
  bool _signedOut = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// The signed-in uid, or '' when nobody is signed in (CU-m3: the
  /// old 'cust-101' fallback is gone).
  String _uid() => SignedInUser.uid();

  Future<void> _loadExisting() async {
    final uid = _uid();
    if (uid.isEmpty) {
      if (mounted) {
        setState(() {
          _signedOut = true;
          _loading = false;
        });
      }
      return;
    }
    KycDocumentEntity? existing;
    String cnic = '';
    String? rejectionReason;
    try {
      existing = await sl<KycRemoteDataSource>().getKyc(uid);
      if (sl.isRegistered<CustomerRemoteDataSource>()) {
        final record =
            await sl<CustomerRemoteDataSource>().getCustomerById(uid);
        cnic = record?.cnic ?? existing?.cnicNumber ?? '';
        rejectionReason = record?.rejectionReason;
      } else {
        cnic = existing?.cnicNumber ?? '';
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _existing = existing;
        _initialCnic = cnic;
        _rejectionReason = rejectionReason;
        _loading = false;
      });
    }
  }

  Future<void> _onSubmitted(String cnic) async {
    final l10n = AppLocalizations.of(context)!;
    // CU-m3: signed out — nothing to save under (the form is not
    // rendered in that state, this is a belt-and-braces guard).
    final uid = _uid();
    if (uid.isEmpty) return;
    // The owner's triage reads the CNIC off the `customers` record, so
    // the submitted number lands there too.
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
            name: SignedInUser.current()?.displayName ?? l10n.kycCustomer,
            phone: SignedInUser.current()?.phoneNumber ?? '',
            cnic: cnic,
            source: 'online',
            createdAt: DateTime.now(),
          ));
        }
      }
    } catch (_) {}
    await _loadExisting();
    if (mounted) {
      AppFeedback.showSuccess(
        context,
        l10n.kycSubmittedNote,
      );
      widget.onSubmitted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // #5/#16: plain MinimalAppBar — the greeting header
              // (dead bell + dead avatar) is gone.
              MinimalAppBar(
                title: l10n.kycTitle,
                subtitle: l10n.kycVaultNote,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: KycDocumentsPanel(
                      existing: _existing,
                      initialCnic: _initialCnic,
                      rejectionReason: _rejectionReason,
                      loading: _loading,
                      signedOut: _signedOut,
                      userUid: _uid(),
                      onSubmitted: _onSubmitted,
                      onRetry: _loadExisting,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
