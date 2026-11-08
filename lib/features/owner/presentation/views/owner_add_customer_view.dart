import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
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

  const OwnerAddCustomerView({super.key, this.prefilledCnic});

  @override
  State<OwnerAddCustomerView> createState() => _OwnerAddCustomerViewState();
}

class _OwnerAddCustomerViewState extends State<OwnerAddCustomerView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cnicController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

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
      await saveWalkInCustomer(
        shopId: currentShopId(),
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
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.addCustomerTitle,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\-]')),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.cnicVerifyTitle,
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
                            ? 'Full name is required'
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
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.person_add_rounded, size: 18),
                          label: Text(
                            l10n.addCustomerSave,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
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
