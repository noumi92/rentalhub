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
      await ds.updateBookingStatus(
        bookingId: widget.booking.bookingId,
        status: 'cancelled',
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
      backgroundColor: AppColors.backgroundLight,
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
              titleWidget: const Text(
                'Cancel Reservation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
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
                        color: AppColors.crimsonSoftBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.crimsonRed.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Cancellation Policy',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.crimsonRed)),
                          SizedBox(height: 6),
                          Text(
                            '• Cancellation > 12 hours before pickup: 100% advance refunded.\n'
                            '• Cancellation within 4-12 hours: 50% advance retained.\n'
                            '• Cancellation < 4 hours: Advance forfeited as showroom lock compensation.',
                            style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: AppColors.midnightNavy),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Reason for Cancellation',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: _reasons.map((r) {
                            return RadioListTile<String>(
                              value: r,
                              groupValue: _selectedReason,
                              activeColor: AppColors.crimsonRed,
                              title: Text(r,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedReason = val);
                                }
                              },
                            );
                          }).toList(),
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
                backgroundColor: AppColors.crimsonRed,
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
