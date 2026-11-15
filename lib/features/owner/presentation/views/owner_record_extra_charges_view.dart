import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../services/handover_photo_upload_service.dart';

/// Audit item 6 (O28): Record Extra Charges — Charge Type picker
/// (Late Return / Extra KM / Damage / Cleaning), Amount, Remarks,
/// Add Charge. Each charge is saved to `return_extra_charges`,
/// scoped by booking id, and the return settlement folds the total
/// into its deductions. Saved charges for this booking list below
/// the form so the owner sees what is already recorded.
class OwnerRecordExtraChargesView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerRecordExtraChargesView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerRecordExtraChargesView> createState() =>
      _OwnerRecordExtraChargesViewState();
}

class _OwnerRecordExtraChargesViewState
    extends State<OwnerRecordExtraChargesView> {
  static const List<String> chargeTypes = [
    'late_return',
    'extra_km',
    'damage',
    'cleaning',
  ];

  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String _chargeType = 'late_return';
  bool _isAdding = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _saved = const [];
  // OW-M10: the load had no try/catch — a failure left _isLoading
  // true forever.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    if (mounted) setState(() => _loadFailed = false);
    try {
      final saved = await ReturnRecordsService()
          .loadExtraCharges(widget.booking.bookingId);
      if (mounted) {
        setState(() {
          _saved = saved;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _addCharge() async {
    final l10n = AppLocalizations.of(context)!;
    final amount =
        (int.tryParse(_amountController.text.trim()) ?? 0).clamp(0, 1 << 30);
    if (amount <= 0) {
      AppFeedback.showError(context, l10n.extraChargeAmountRequired);
      return;
    }
    setState(() => _isAdding = true);
    try {
      final id = await ReturnRecordsService().saveExtraCharge(
        bookingId: widget.booking.bookingId,
        shopId: widget.booking.shopId,
        chargeType: _chargeType,
        amount: amount,
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      if (id == null) {
        AppFeedback.showError(context, l10n.extraChargeSaveFailed);
        return;
      }
      AppFeedback.showSuccess(context, l10n.extraChargeAdded);
      _amountController.clear();
      _remarksController.clear();
      await _loadSaved();
    } catch (_) {
      // OW-M10: the old try/finally had no catch — an unexpected
      // throw from saveExtraCharge propagated as an unhandled async
      // error. (The id == null branch above covers only the expected
      // failure.)
      if (mounted) AppFeedback.showError(context, l10n.extraChargeSaveFailed);
    } finally {
      if (mounted) setState(() => _isAdding = false);
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
              title: l10n.extraChargeTitle,
              subtitle: '#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? l10n.summaryVehicle}',
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.extraChargeTypeLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chargeTypes.map((t) {
                        return ChoiceChip(
                          label: Text(_typeLabel(l10n, t)),
                          selected: _chargeType == t,
                          onSelected: (v) {
                            if (v) setState(() => _chargeType = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.extraChargeAmountLabel,
                        hintText: l10n.extraChargeAmountHint,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _remarksController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.extraChargeRemarksLabel,
                        hintText: l10n.extraChargeRemarksHint,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DebouncedButton(
                      text: l10n.extraChargeAdd,
                      icon: Icons.add_circle_rounded,
                      isLoading: _isAdding,
                      onPressed: _addCharge,
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 24),
                      // DS-11: labelled inline spinner (text + spinner),
                      // not a bare spinner — the error branch below
                      // already retries via AppErrorState.
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Text(l10n.extraChargeLoading)]),
                    ] else if (_loadFailed) ...[
                      const SizedBox(height: 24),
                      AppErrorState(
                          message: l10n.extraChargeLoadError,
                          onRetry: _loadSaved),
                    ] else if (_saved.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(l10n.extraChargeSavedTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ..._saved.map((charge) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _typeLabel(l10n, '${charge['chargeType'] ?? ''}'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.amountRs(formatRs((charge['amount'] as num?)?.toInt() ?? 0)),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )),
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

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'extra_km':
        return l10n.extraChargeTypeExtraKm;
      case 'damage':
        return l10n.extraChargeTypeDamage;
      case 'cleaning':
        return l10n.extraChargeTypeCleaning;
      default:
        return l10n.extraChargeTypeLateReturn;
    }
  }
}
