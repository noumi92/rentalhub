import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../cubit/kyc_cubit.dart';
import '../../data/datasources/kyc_remote_data_source.dart';
import '../../domain/entities/kyc_document_entity.dart';
import 'widgets/kyc_status_banner.dart';
import 'widgets/kyc_submission_form.dart';
import '../../../../l10n/app_localizations.dart';

// G3: the customer's real documents. The CNIC comes from their own
// `customers` record (empty when they have none — no demo number), the
// submission form holds the photos they actually pick, and the status
// banner shows the real KYC status from `kyc_documents/{uid}`.
class CustomerDocumentsView extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const CustomerDocumentsView({super.key, this.onSubmitted});

  @override
  State<CustomerDocumentsView> createState() => _CustomerDocumentsViewState();
}

class _CustomerDocumentsViewState extends State<CustomerDocumentsView> {
  KycDocumentEntity? _existing;
  String _initialCnic = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  String _uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'cust-101';
    } catch (_) {
      return 'cust-101';
    }
  }

  Future<void> _loadExisting() async {
    KycDocumentEntity? existing;
    String cnic = '';
    try {
      existing = await sl<KycRemoteDataSource>().getKyc(_uid());
      if (sl.isRegistered<CustomerRemoteDataSource>()) {
        final record =
            await sl<CustomerRemoteDataSource>().getCustomerById(_uid());
        cnic = record?.cnic ?? existing?.cnicNumber ?? '';
      } else {
        cnic = existing?.cnicNumber ?? '';
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _existing = existing;
        _initialCnic = cnic;
        _loading = false;
      });
    }
  }

  Future<void> _onSubmitted(String cnic) async {
    final l10n = AppLocalizations.of(context)!;
    // The owner's triage reads the CNIC off the `customers` record, so
    // the submitted number lands there too.
    try {
      if (sl.isRegistered<CustomerRemoteDataSource>()) {
        final ds = sl<CustomerRemoteDataSource>();
        final existing = await ds.getCustomerById(_uid());
        if (existing != null) {
          await ds.upsertCustomer(existing.copyWith(cnic: cnic));
        } else {
          await ds.upsertCustomer(CustomerEntity(
            customerId: _uid(),
            shopId: '',
            name: FirebaseAuth.instance.currentUser?.displayName ?? l10n.kycCustomer,
            phone: FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
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
    return BlocProvider.value(
      value: sl<KycCubit>(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomCurvedHeader(
                  variant: CustomCurvedHeaderVariant.hero,
                  showProfileGreeting: true,
                  titleWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.kycTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l10n.kycVaultNote,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.primaryContainer),
                      ),
                    ],
                  ),
                ),
                HeaderOverlapContainer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _loading
                            ? const Center(
                                child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_existing != null) ...[
                                    KycStatusBanner(status: _existing!.status),
                                    const SizedBox(height: 14),
                                  ],
                                  KycSubmissionForm(
                                    initialCnic: _initialCnic,
                                    existing: _existing,
                                    userUid: _uid(),
                                    onSubmitted: _onSubmitted,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
