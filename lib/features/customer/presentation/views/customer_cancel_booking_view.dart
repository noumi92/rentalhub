import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/services/booking_cancel_service.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';

class CustomerCancelBookingView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onCancelled;
  final VoidCallback? onBack;

  const CustomerCancelBookingView({
    super.key,
    required this.booking,
    this.onCancelled,
    this.onBack,
  });

  @override
  State<CustomerCancelBookingView> createState() =>
      _CustomerCancelBookingViewState();
}

class _CustomerCancelBookingViewState extends State<CustomerCancelBookingView> {
  String _selectedReason = 'Change of travel plans';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Change of travel plans',
    'Found another vehicle',
    'Showroom delay in approval',
    'Unexpected emergency',
    'Other reason',
  ];

  /// The stored reason stays English (it is written to the booking's
  /// `rejectionReason`, which the detail screen and owner triage read);
  /// only the displayed radio label is localized.
  String _reasonLabel(AppLocalizations l10n, String reason) {
    switch (reason) {
      case 'Change of travel plans':
        return l10n.cancelReasonPlans;
      case 'Found another vehicle':
        return l10n.cancelReasonOtherVehicle;
      case 'Showroom delay in approval':
        return l10n.cancelReasonShopDelay;
      case 'Unexpected emergency':
        return l10n.cancelReasonEmergency;
      default:
        return l10n.cancelReasonOther;
    }
  }

  Future<void> _cancelBooking() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      // Online customers do not have Firestore write permission on
      // security_deposits or finance_transfers; only walk-in/owner
      // flows release counter deposits directly.
      await BookingCancelService.cancelBooking(
        booking: widget.booking,
        reason: _selectedReason,
        releaseDeposit: BookingCancelService.isWalkInBooking(widget.booking),
      );

      if (mounted) {
        AppFeedback.showInfo(context, l10n.cancelDone);
        widget.onCancelled?.call();
      }
    } catch (e) {
      debugPrint('Booking cancel failed: $e');
      if (mounted) AppFeedback.showError(context, l10n.cancelFailedGeneric);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // MinimalAppBar owns the top inset — SafeArea(top: false)
      // avoids the double status-bar band (SH-M3 class).
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.cancelTitle,
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainerFor(
                            Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                AppColors.accentDanger.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.cancelWhatHappens,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppColors.dangerTextFor(
                                          Theme.of(context).brightness))),
                          const SizedBox(height: 6),
                          // Worker B: the old copy claimed no
                          // deposit was ever collected ("deposits
                          // are only taken at handover") — false
                          // for walk-ins, whose Security is taken
                          // at the counter. A cancelled booking's
                          // Security is refunded in full; the
                          // advance went straight to the showroom's
                          // own account, so the showroom decides
                          // any refund of it. The .arb values for
                          // these two keys are updated by the
                          // labels worker to say exactly that.
                          Text(
                            widget.booking.advancePaid > 0
                                ? l10n.cancelAdvancePaid(formatRs(widget.booking.advancePaid))
                                : l10n.cancelNoAdvanceNote,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(l10n.cancelReasonLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: RadioGroup<String>(
                          groupValue: _selectedReason,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedReason = val);
                            }
                          },
                          child: Column(
                            children: _reasons.map((r) {
                              return RadioListTile<String>(
                                value: r,
                                title: Text(_reasonLabel(l10n, r),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: _isSubmitting ? l10n.cancelCancelling : l10n.cancelConfirm,
                // White on accentDanger #EF4444 is ~3.9:1 — below AA
                // for the 14 sp label. errorDark #DC2626 is ~4.9:1.
                backgroundColor: AppColors.errorDark,
                icon: Icons.cancel_outlined,
                isLoading: _isSubmitting,
                onPressed: _cancelBooking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
