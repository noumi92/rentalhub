import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../trust/data/datasources/kyc_remote_data_source.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/save_customer_usecase.dart';
import '../profile_hub_loader.dart';
import '../widgets/edit_profile_form.dart';
import '../../../../l10n/app_localizations.dart';

/// Profile hub (2026-11-25): the full-screen edit-profile flow.
/// Name, phone, CNIC, date of birth, father's name, address and
/// profile photo — replacing the old edit-profile sheet (name/phone/CNIC
/// only).
///
/// Saves go through [SaveCustomerUseCase] (the same path the owner
/// flows use), never a direct data-source upsert. A CNIC change on
/// a verified record writes the new number to BOTH
/// `customers/{uid}.cnic` and `kyc_documents/{uid}.cnicNumber` and
/// flags the KYC record for re-review ('resubmitted') instead of
/// silently diverging the two records. The owner-approval status
/// (`approvalStatus`) is deliberately untouched by a CNIC edit.
class CustomerEditProfileView extends StatefulWidget {
  const CustomerEditProfileView({
    super.key,
    this.initialData,
    this.saveUseCase,
    this.kycDataSource,
    this.storageClient,
  });

  /// Test seam: loaded hub data. When null the view loads it itself.
  final ProfileHubData? initialData;

  /// Test seams: default to the service locator.
  final SaveCustomerUseCase? saveUseCase;
  final KycRemoteDataSource? kycDataSource;
  final CPanelStorageClient? storageClient;

  @override
  State<CustomerEditProfileView> createState() =>
      _CustomerEditProfileViewState();
}

class _CustomerEditProfileViewState extends State<CustomerEditProfileView> {
  ProfileHubData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData;
      _loading = false;
    } else {
      _load();
    }
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

  String _uid() =>
      _data?.customer?.customerId ?? ProfileHubLoader.uid();

  Future<void> _save(EditProfileData data) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _uid();
    if (uid.isEmpty) {
      throw Exception(l10n.profileNotSignedIn);
    }
    final oldCnic = _data?.cnic ?? '';
    final wasVerified = _data?.kycVerified ?? false;

    String? photoUrl = _data?.photoUrl;
    if (data.photoFile != null) {
      photoUrl = await _uploadPhoto(uid, data.photoFile!);
      if (photoUrl == null) {
        throw Exception(l10n.editPhotoUploadError);
      }
    }

    final existing = _data?.customer;
    // Empty optional fields keep their stored value (copyWith cannot
    // clear a field to null); the CNIC keeps the old sheet's
    // behaviour — an emptied CNIC overwrites with ''.
    final entity = existing?.copyWith(
          name: data.name,
          phone: data.phone,
          cnic: data.cnic,
          dateOfBirth:
              data.dateOfBirth.isEmpty ? null : data.dateOfBirth,
          fatherName:
              data.fatherName.isEmpty ? null : data.fatherName,
          address: data.address.isEmpty ? null : data.address,
          profilePhotoUrl: photoUrl,
        ) ??
        CustomerEntity(
          customerId: uid,
          shopId: '',
          name: data.name,
          phone: data.phone,
          cnic: data.cnic.isEmpty ? null : data.cnic,
          source: 'online',
          createdAt: DateTime.now(),
          dateOfBirth:
              data.dateOfBirth.isEmpty ? null : data.dateOfBirth,
          fatherName:
              data.fatherName.isEmpty ? null : data.fatherName,
          address: data.address.isEmpty ? null : data.address,
          profilePhotoUrl: photoUrl,
        );

    final saver = widget.saveUseCase ??
        (sl.isRegistered<SaveCustomerUseCase>()
            ? sl<SaveCustomerUseCase>()
            : null);
    if (saver == null) {
      throw Exception(l10n.editSaveError('SaveCustomerUseCase'));
    }
    await saver(entity);

    // CNIC changed on a verified record: keep the two CNIC sources
    // in step and flag the KYC record for re-review. Best-effort —
    // the profile save itself already succeeded.
    if (wasVerified &&
        data.cnic.isNotEmpty &&
        data.cnic.trim() != oldCnic.trim()) {
      final kyc = widget.kycDataSource ??
          (sl.isRegistered<KycRemoteDataSource>()
              ? sl<KycRemoteDataSource>()
              : null);
      if (kyc != null) {
        try {
          await kyc.syncCnicNumber(uid, data.cnic.trim());
        } catch (_) {}
        try {
          await kyc.flagForReReview(uid);
        } catch (_) {}
      }
    }

    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(data.name);
    } catch (_) {}
    if (mounted) {
      AppFeedback.showSuccess(context, l10n.profileSaved);
      Navigator.of(context).pop(true);
    }
  }

  /// Uploads the picked photo the way the auth flow does
  /// (folder 'profile') and returns its signed URL, or null when
  /// the upload fails — never a made-up URL.
  Future<String?> _uploadPhoto(String uid, File file) async {
    final client = widget.storageClient ??
        (sl.isRegistered<CPanelStorageClient>()
            ? sl<CPanelStorageClient>()
            : null);
    if (client == null) return null;
    try {
      if (!await file.exists()) return null;
      final key = await client.uploadFile(
        file: file,
        userUid: uid,
        folder: 'profile',
      );
      return client.getSignedMediaUrl(key, uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.editProfile,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: _loading
                    ? const AppLoadingState()
                    : data == null || _uid().isEmpty
                        ? AppErrorState(
                            message: l10n.signInRequiredGeneric,
                            onRetry: _load,
                          )
                        : EditProfileForm(
                            initialName: data.name,
                            initialPhone: data.phone,
                            initialCnic: data.cnic,
                            initialDateOfBirth: data.dateOfBirth ?? '',
                            initialFatherName: data.fatherName ?? '',
                            initialAddress: data.address ?? '',
                            initialPhotoUrl: data.photoUrl,
                            kycVerified: data.kycVerified,
                            onSave: _save,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
