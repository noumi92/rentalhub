import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../trust/data/datasources/kyc_remote_data_source.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/save_customer_usecase.dart';
import '../profile_hub_loader.dart';
import '../widgets/edit_profile_form.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen customer edit-profile flow (name, phone, CNIC, DOB,
/// father's name, address, photo). Persists to `customers/{uid}` via
/// [SaveCustomerUseCase], mirrors identity fields to `users/{uid}`,
/// and keeps `kyc_documents/{uid}` in sync on CNIC edits.
class CustomerEditProfileView extends StatefulWidget {
  const CustomerEditProfileView({
    super.key,
    this.initialData,
    this.saveUseCase,
    this.kycDataSource,
    this.storageClient,
    this.firestoreService,
  });

  final ProfileHubData? initialData;
  final SaveCustomerUseCase? saveUseCase;
  final KycRemoteDataSource? kycDataSource;
  final CPanelStorageClient? storageClient;
  final FirestoreService? firestoreService;

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

  String? _editableValue(String input, String? stored) =>
      input.isEmpty ? (stored == null ? null : '') : input;

  Future<void> _save(EditProfileData data) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _uid();
    if (uid.isEmpty) throw Exception(l10n.profileNotSignedIn);
    final oldCnic = _data?.cnic ?? '';
    final wasVerified = _data?.kycVerified ?? false;
    final normalizedCnic =
        data.cnic.isEmpty ? '' : PakistaniValidators.formatCnic(data.cnic);

    String? photoUrl = _data?.photoUrl;
    if (data.photoFile != null) {
      photoUrl = await _uploadPhoto(uid, data.photoFile!);
      if (photoUrl == null) throw Exception(l10n.editPhotoUploadError);
    }

    final existing = _data?.customer;
    // Previously stored optional fields cleared to '' overwrite the
    // stored value under Firestore merge; untouched nulls stay null.
    final entity = existing?.copyWith(
          name: data.name,
          phone: data.phone,
          cnic: _editableValue(normalizedCnic, existing.cnic),
          dateOfBirth: _editableValue(data.dateOfBirth, existing.dateOfBirth),
          fatherName: _editableValue(data.fatherName, existing.fatherName),
          address: _editableValue(data.address, existing.address),
          profilePhotoUrl: photoUrl,
        ) ??
        CustomerEntity(
          customerId: uid,
          shopId: '',
          name: data.name,
          phone: data.phone,
          cnic: normalizedCnic.isEmpty ? null : normalizedCnic,
          source: 'online',
          createdAt: DateTime.now(),
          dateOfBirth: data.dateOfBirth.isEmpty ? null : data.dateOfBirth,
          fatherName: data.fatherName.isEmpty ? null : data.fatherName,
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

    // Mirror editable account fields to `users/{uid}` so auth/admin
    // views stay in sync with `customers/{uid}` without touching role.
    final fs = widget.firestoreService ??
        (sl.isRegistered<FirestoreService>() ? sl<FirestoreService>() : null);
    if (fs != null) {
      try {
        await fs.setDocument('users', uid, {
          'full_name': data.name,
          'phone_number': data.phone,
          if (photoUrl != null && photoUrl.isNotEmpty)
            'profile_photo_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    // Keep `kyc_documents/{uid}.cnicNumber` in step on any CNIC change
    // and flag verified KYC for re-review.
    if (normalizedCnic != oldCnic.trim()) {
      final kyc = widget.kycDataSource ??
          (sl.isRegistered<KycRemoteDataSource>()
              ? sl<KycRemoteDataSource>()
              : null);
      if (kyc != null) {
        if (normalizedCnic.isNotEmpty) {
          try {
            await kyc.syncCnicNumber(uid, normalizedCnic);
          } catch (_) {}
        }
        if (wasVerified) {
          try {
            await kyc.flagForReReview(uid);
          } catch (_) {}
        }
      }
    }

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      await authUser?.updateDisplayName(data.name);
      if (data.photoFile != null && photoUrl != null) {
        await authUser?.updatePhotoURL(photoUrl);
      }
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
