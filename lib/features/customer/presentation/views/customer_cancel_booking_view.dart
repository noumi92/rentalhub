import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../l10n/app_localizations.dart';

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
      final ds = sl<BookingRemoteDataSource>();
      // G5: the reason travels with the cancellation (stored on the
      // booking's rejectionReason field, which the detail screen and
      // the owner triage both read).
      await ds.updateBookingStatus(
        bookingId: widget.booking.bookingId,
        status: 'cancelled',
        rejectionReason: _selectedReason,
      );

      if (mounted) {
        AppFeedback.showInfo(context, l10n.cancelDone);
        widget.onCancelled?.call();
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.cancelFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                        color: AppColors.errorContainer,
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
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.dangerTextFor(
                                          Theme.of(context).brightness))),
                          const SizedBox(height: 6),
                          // G5: there is no defined refund timetable in
                          // the app, so none is invented. What is true:
                          // no deposit was collected (deposits are taken
                          // at handover), and the advance went straight
                          // to the showroom's own account, so the
                          // showroom decides any refund.
                          Text(
                            widget.booking.advancePaid > 0
                                ? l10n.cancelAdvancePaid(widget.booking.advancePaid)
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
                            ?.copyWith(fontWeight: FontWeight.w800)),
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
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: _isSubmitting ? l10n.cancelCancelling : l10n.cancelConfirm,
                backgroundColor: AppColors.accentDanger,
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
