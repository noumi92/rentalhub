import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// Audit §5 (O33): the Shop Settings screen — the shop name and shop
/// fields are editable here (they were display-only in settings) and
/// save back to the `shops` document. Reads and writes are lazy
/// (try/catch): a failed load renders an error state with retry, and
/// a failed save reports the error instead of pretending it saved.
class OwnerShopSettingsView extends StatefulWidget {
  const OwnerShopSettingsView({super.key});

  @override
  State<OwnerShopSettingsView> createState() => _OwnerShopSettingsViewState();
}

class _OwnerShopSettingsViewState extends State<OwnerShopSettingsView> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _openingHoursController = TextEditingController();
  bool _loading = true;
  bool _hasError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_shopNameController, _ownerNameController, _phoneController, _addressController, _cityController, _openingHoursController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('shops').doc(currentShopId()).get();
      final data = doc.data() ?? {};
      if (!mounted) return;
      setState(() {
        _shopNameController.text = (data['name'] ?? data['shopName'] ?? '') as String;
        _ownerNameController.text = (data['ownerName'] ?? '') as String;
        _phoneController.text = (data['phoneNumber'] ?? data['phone'] ?? '') as String;
        _addressController.text = (data['address'] ?? '') as String;
        _cityController.text = (data['city'] ?? '') as String;
        _openingHoursController.text = (data['openingHours'] ?? '') as String;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_shopNameController.text.trim().length < 3) {
      AppFeedback.showError(context, l10n.shopSettingsNameShort);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('shops').doc(currentShopId()).set({
        'name': _shopNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'openingHours': _openingHoursController.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) AppFeedback.showSuccess(context, l10n.shopSettingsSaved);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.shopSettingsSaveFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.shopSettingsTitle,
              subtitle: l10n.shopSettingsSubtitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _loading
                  ? AppLoadingState(message: l10n.shopSettingsTitle)
                  : _hasError
                      ? AppErrorState(message: l10n.shopSettingsLoadError, onRetry: _load)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _field(l10n.shopSettingsShopName, _shopNameController),
                              const SizedBox(height: 12),
                              _field(l10n.shopSettingsOwnerName, _ownerNameController),
                              const SizedBox(height: 12),
                              _field(l10n.shopSettingsPhone, _phoneController, keyboardType: TextInputType.phone),
                              const SizedBox(height: 12),
                              _field(l10n.shopSettingsAddress, _addressController, maxLines: 2),
                              const SizedBox(height: 12),
                              _field(l10n.shopSettingsCity, _cityController),
                              const SizedBox(height: 12),
                              _field(l10n.shopSettingsOpeningHours, _openingHoursController),
                            ],
                          ),
                        ),
            ),
            if (!_loading && !_hasError)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
                child: DebouncedButton(
                  text: l10n.shopSettingsSave,
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
