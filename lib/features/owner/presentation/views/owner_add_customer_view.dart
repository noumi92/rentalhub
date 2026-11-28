import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/utils/cnic_input_formatter.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/save_walk_in_customer.dart';

/// Phone-test #18: adding a customer is its own step — scan CNIC,
/// enter details, save — instead of the only way forward being the
/// walk-in booking wizard. The CNIC arrives prefilled from the scan
/// view; the owner enters the name and phone, and the record is saved
/// to the `customers` collection through the existing customer write
/// path ([saveWalkInCustomer] → SaveCustomerUseCase → upsert), then
/// the view returns to the Customers list with a confirmation.
/// Guarantor capture stays a later step; the form is name/phone/CNIC
/// only. Booking stays separate: from a customer row or Requests.
class OwnerAddCustomerView extends StatefulWidget {
  final String? prefilledCnic;

  /// Injectable Firestore for tests; production uses the default
  /// instance (see [_OwnerAddCustomerViewState._firestore]).
  final FirebaseFirestore? firestore;

  const OwnerAddCustomerView({super.key, this.prefilledCnic, this.firestore});

  @override
  State<OwnerAddCustomerView> createState() => _OwnerAddCustomerViewState();
}

class _OwnerAddCustomerViewState extends State<OwnerAddCustomerView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cnicController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

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
    _cnicController =
        TextEditingController(text: widget.prefilledCnic ?? '');
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      // Shop-id linking (2026-11-15): write the customer with the
      // shop DOCUMENT id (`shop_<uid>`), not the bare UID — the
      // customers list reads by that doc id. Falls back to the bare
      // UID for the legacy shop whose doc id IS the UID.
      final shopId = await canonicalShopId(_firestore, currentShopId());
      await saveWalkInCustomer(
        shopId: shopId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        cnic: _cnicController.text.trim(),
        fallbackCustomerId:
            'cust-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.addCustomerSaved);
      // Back to the Customers list (fresh load shows the new
      // customer); the scan view is left behind, not returned to.
      context.go(RouteNames.ownerCustomers);
    } on BlacklistedCustomerException {
      // Audit §21: the blacklist check lives in saveWalkInCustomer
      // and refuses before anything is written.
      if (mounted) {
        AppFeedback.showError(context, l10n.customersScanDeclined);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset — no double status bar.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.addCustomerTitle,
              // Audit §21: the screen had no subtitle and no guidance.
              subtitle: l10n.addCustomerHelper,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _cnicController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [CnicInputFormatter()],
                        decoration: InputDecoration(
                          // Audit §21: the label reused the "CNIC
                          // Check" section title — now "CNIC Number".
                          labelText: l10n.addCustomerCnic,
                          hintText: '35201-1234567-1',
                          prefixIcon: const Icon(Icons.badge_rounded),
                          border: const OutlineInputBorder(),
                        ),
                        validator: PakistaniValidators.validateCnic,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.addCustomerName,
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.addCustomerFullNameRequired
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.addCustomerPhone,
                          hintText: '0300-1234567',
                          prefixIcon: const Icon(Icons.phone_rounded),
                          border: const OutlineInputBorder(),
                        ),
                        validator:
                            PakistaniValidators.validatePakistaniPhone,
                      ),
                      const SizedBox(height: 20),
                      // Audit §21: helper line under the fields (the
                      // same line is the app-bar subtitle above).
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(child: Text(l10n.addCustomerHelper, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Audit §21/C7: 54dp DebouncedButton (was 48dp).
                      DebouncedButton(
                        text: l10n.addCustomerSave,
                        icon: Icons.person_add_rounded,
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
