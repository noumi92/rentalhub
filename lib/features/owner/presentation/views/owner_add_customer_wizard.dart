import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../features/customer/utils/save_walk_in_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/kyc_customer_saver.dart';
import 'add_customer/kyc_draft.dart';
import 'add_customer/kyc_step.dart';
import 'add_customer/step1_cnic.dart';
import 'add_customer/step2_photo.dart';
import 'add_customer/step3_docs.dart';
import 'add_customer/step4_guarantor.dart';

/// The Add Customer wizard shell (O11–O15): four steps, one draft,
/// one save at the end. Only one step widget is in the tree at a
/// time; steps own their controllers (initialised once from the
/// draft) and write back on every change, so Back/Next never loses
/// input. No face matching anywhere — the face photo is saved and an
/// admin reviews it manually.
class OwnerAddCustomerWizard extends StatefulWidget {
  final String? prefilledCnic;

  const OwnerAddCustomerWizard({super.key, this.prefilledCnic});

  @override
  State<OwnerAddCustomerWizard> createState() => _OwnerAddCustomerWizardState();
}

class _OwnerAddCustomerWizardState extends State<OwnerAddCustomerWizard> {
  late final KycDraft _draft;
  final _stepKeys = List<GlobalKey>.generate(4, (_) => GlobalKey());
  int _step = 0;
  bool _isSaving = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _draft = KycDraft(prefilledCnic: widget.prefilledCnic);
  }

  List<String> _stepLabels(AppLocalizations l10n) => [
        l10n.kycWizardStepCnic,
        l10n.kycWizardStepPhoto,
        l10n.kycWizardStepDocs,
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
      final result = await KycCustomerSaver().save(shopId: currentShopId(), draft: _draft);
      if (!mounted) return;
      if (result.queuedPhotos > 0) {
        AppFeedback.showInfo(context, l10n.kycWizardPhotosPending);
      } else {
        AppFeedback.showSuccess(context, l10n.addCustomerSaved);
      }
      if (result.skippedExtraDocs > 0) {
        AppFeedback.showInfo(context, l10n.kycWizardExtraSkipped);
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
        return Step1Cnic(key: _stepKeys[0], draft: _draft, onChanged: refresh);
      case 1:
        return Step2Photo(key: _stepKeys[1], draft: _draft, onChanged: refresh);
      case 2:
        return Step3Docs(key: _stepKeys[2], draft: _draft, onChanged: refresh);
      default:
        return Step4Guarantor(key: _stepKeys[3], draft: _draft, onChanged: refresh, shopId: currentShopId());
    }
  }

  Widget _stepItem(int index, String label) {
    final done = index < _step;
    final current = index == _step;
    final color = done
        ? AppColors.accentSuccessStrong
        : current
            ? AppColors.orangeFill
            : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || current ? color : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('${index + 1}', style: TextStyle(color: current ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          // Urdu labels (e.g. "دستاویزات اور دستخط") need two lines
          // at 360px — one line truncated them with an ellipsis.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: current ? FontWeight.w800 : FontWeight.w600, color: color),
        ),
      ],
    );
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
            MinimalAppBar(title: l10n.addCustomerTitle, subtitle: labels[_step]),
            Container(
              key: const Key('kyc-stepper-header'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    Expanded(child: _stepItem(i, labels[i])),
                    if (i < 3) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
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
                    child: _step < 3
                        ? DebouncedButton(text: l10n.kycWizardNext, isLoading: _isValidating, onPressed: _next)
                        : DebouncedButton(text: l10n.addCustomerSave, icon: Icons.check_rounded, isLoading: _isSaving, onPressed: _save),
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
