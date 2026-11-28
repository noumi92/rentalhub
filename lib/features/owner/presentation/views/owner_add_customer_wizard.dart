import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../features/customer/domain/entities/customer_entity.dart';
import '../../../../features/customer/utils/save_walk_in_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/kyc_customer_saver.dart';
import 'add_customer/kyc_draft.dart';
import 'add_customer/kyc_step.dart';
import 'add_customer/kyc_stepper_header.dart';
import 'add_customer/step1_cnic.dart';
import 'add_customer/step3_docs.dart';
import 'add_customer/step4_guarantor.dart';

/// The Add Customer wizard shell (O11–O15): four steps, one draft,
/// one save at the end. Only one step widget is in the tree at a
/// time; steps own their controllers (initialised once from the
/// draft) and write back on every change, so Back/Next never loses
/// input. No face matching anywhere — the face photo is saved and an
/// admin reviews it manually.
///
/// Walk-in CRM (edit mode): pass [editingCustomer] to edit a saved
/// walk-in record instead of creating one. The draft is prefilled
/// from the record ([KycDraft.fromEntity]), media already on file
/// counts as present, and the save preserves the record's identity
/// (see [KycCustomerSaver.save]). Edit mode is walk-in only — the
/// route refuses online records before the wizard is built.
class OwnerAddCustomerWizard extends StatefulWidget {
  final String? prefilledCnic;

  /// The walk-in record being edited, or null to create a new one.
  final CustomerEntity? editingCustomer;

  /// Injectable Firestore for tests; production uses the default
  /// instance (see [_OwnerAddCustomerWizardState._firestore]).
  final FirebaseFirestore? firestore;

  final int initialStep;

  const OwnerAddCustomerWizard({
    super.key,
    this.prefilledCnic,
    this.editingCustomer,
    this.firestore,
    this.initialStep = 0,
  });

  @override
  State<OwnerAddCustomerWizard> createState() => _OwnerAddCustomerWizardState();
}

class _OwnerAddCustomerWizardState extends State<OwnerAddCustomerWizard> {
  late final KycDraft _draft;
  final _stepKeys = List<GlobalKey>.generate(3, (_) => GlobalKey());
  int _step = 0;
  bool _isSaving = false;
  bool _isValidating = false;

  /// The Firestore to resolve the shop id against, or null when
  /// Firebase is not initialised (tests) — the save then keeps the
  /// bare UID, as before.
  FirebaseFirestore? get _firestore {
    if (widget.firestore != null) return widget.firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, 2);
    final editing = widget.editingCustomer;
    _draft = editing != null
        ? KycDraft.fromEntity(editing)
        : KycDraft(prefilledCnic: widget.prefilledCnic);
  }

  bool get _isEdit => widget.editingCustomer != null;

  List<String> _stepLabels(AppLocalizations l10n) => [
        l10n.kycWizardStepCnic,
        l10n.kycWizardLicense,
        l10n.kycWizardStepGuarantor,
      ];

  Future<void> _next() async {
    setState(() => _isValidating = true);
    bool ok = false;
    try {
      ok = await (_stepKeys[_step].currentState as KycStepState?)?.validate() ?? false;
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
    if (ok && mounted) setState(() => _step++);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      // Shop-id linking (2026-11-15): customers must be written
      // with the shop DOCUMENT id (`shop_<uid>`), not the bare UID
      // from [currentShopId] — the customers list reads by that doc
      // id. Falls back to the bare UID for the legacy shop whose doc
      // id IS the UID.
      final shopId = await canonicalShopId(_firestore, currentShopId());
      final result = await KycCustomerSaver().save(
        shopId: shopId,
        draft: _draft,
        existing: widget.editingCustomer,
      );
      if (!mounted) return;
      if (result.queuedPhotos > 0) {
        AppFeedback.showInfo(context, l10n.kycWizardPhotosPending);
      } else {
        AppFeedback.showSuccess(
            context,
            _isEdit ? l10n.customerDetailEditSaved : l10n.addCustomerSaved);
      }
      if (result.skippedExtraDocs > 0) {
        AppFeedback.showInfo(context, l10n.kycWizardExtraSkipped);
      }
      if (_isEdit) {
        // Edit mode lands back on the profile (not the O13 success
        // screen — the customer already exists).
        context.go(
          RouteNames.ownerCustomerDetail
              .replaceFirst(':id', result.customer.customerId),
        );
        return;
      }
      // O13: land on the success screen (not the list) — it offers
      // Start Booking (prefilled) and View Profile for this customer.
      // The saved record travels via `extra`; a deep link without it
      // loads the record by id instead.
      context.go(
        RouteNames.ownerCustomerAdded
            .replaceFirst(':id', result.customer.customerId),
        extra: result.customer,
      );
    } on BlacklistedCustomerException {
      if (mounted) AppFeedback.showError(context, l10n.customersScanDeclined);
    } catch (e) {
      debugPrint('KYC wizard save failed: $e');
      if (mounted) AppFeedback.showError(context, l10n.kycWizardUploadFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _currentStep() {
    void refresh() => setState(() {});
    switch (_step) {
      case 0:
        return Step1Cnic(key: _stepKeys[0], draft: _draft, onChanged: refresh, isEdit: _isEdit);
      case 1:
        return Step3Docs(key: _stepKeys[1], draft: _draft, onChanged: refresh);
      default:
        return Step4Guarantor(key: _stepKeys[2], draft: _draft, onChanged: refresh, shopId: currentShopId());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = _stepLabels(l10n);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
                title: _isEdit
                    ? l10n.customerDetailEditTitle
                    : l10n.addCustomerTitle,
                subtitle: labels[_step]),
            KycStepperHeader(step: _step, labels: labels),
            Expanded(
              child: SingleChildScrollView(
                // Shared outer padding for every step (was step 1
                // only — steps 2–4 sat flush to the screen edge).
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _currentStep(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: Text(l10n.back)),
                  Expanded(
                    child: _step < 2
                        ? DebouncedButton(text: l10n.kycWizardNext, isLoading: _isValidating, onPressed: _next)
                        : DebouncedButton(text: _isEdit ? l10n.customerDetailSaveChanges : l10n.addCustomerSave, icon: Icons.check_rounded, isLoading: _isSaving, onPressed: _save),
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
