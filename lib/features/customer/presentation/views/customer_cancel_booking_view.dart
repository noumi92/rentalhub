import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

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

  Future<void> _cancelBooking() async {
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
        AppFeedback.showInfo(context, 'Reservation cancelled.');
        widget.onCancelled?.call();
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Cancellation failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Text(
                'Cancel Reservation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
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
                            color: AppColors.accentDanger.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What happens when you cancel',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentDanger)),
                          const SizedBox(height: 6),
                          // G5: there is no defined refund timetable in
                          // the app, so none is invented. What is true:
                          // no deposit was collected (deposits are taken
                          // at handover), and the advance went straight
                          // to the showroom's own account, so the
                          // showroom decides any refund.
                          Text(
                            widget.booking.advancePaid > 0
                                ? 'You paid Rs. ${widget.booking.advancePaid} advance directly to the showroom\'s account — the showroom decides the refund, so contact them about it. No security deposit was collected: deposits are only taken at handover.'
                                : 'No advance has been paid yet, so there is nothing to refund. No security deposit was collected: deposits are only taken at handover.',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Reason for Cancellation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
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
                                title: Text(r,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: _isSubmitting ? 'Cancelling...' : 'Confirm Cancellation',
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
