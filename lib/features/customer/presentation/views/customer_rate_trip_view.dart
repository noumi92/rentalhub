import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/star_rating_bar.dart';

class CustomerRateTripView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onRatingSubmitted;
  final VoidCallback? onBack;

  const CustomerRateTripView({
    super.key,
    required this.booking,
    this.onRatingSubmitted,
    this.onBack,
  });

  @override
  State<CustomerRateTripView> createState() => _CustomerRateTripViewState();
}

class _CustomerRateTripViewState extends State<CustomerRateTripView> {
  int _shopRating = 5;
  int _vehicleRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.booking.bookingId)
            .update({
          'customerRating': {
            'shopRating': _shopRating,
            'vehicleRating': _vehicleRating,
            'comment': _commentController.text.trim(),
            'ratedAt': FieldValue.serverTimestamp(),
          },
        });
      } catch (_) {}

      if (mounted) {
        AppFeedback.showSuccess(
            context, 'Thank you! Your feedback helps the community.');
        widget.onRatingSubmitted?.call();
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Failed to save rating: $e');
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
                'Rate Your Experience',
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
                  children: [
                    Text(
                      'Trip Reference: ${widget.booking.bookingId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sunsetOrange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StarRatingBar(
                      title: 'Showroom Service Quality',
                      subtitle:
                          'Handover speed, staff behavior, transparency',
                      rating: _shopRating,
                      onRatingChanged: (r) => setState(() => _shopRating = r),
                    ),
                    const SizedBox(height: 12),
                    StarRatingBar(
                      title: 'Vehicle Condition & Cleanliness',
                      subtitle: 'AC cooling, tires, interior, mechanical health',
                      rating: _vehicleRating,
                      onRatingChanged: (r) =>
                          setState(() => _vehicleRating = r),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Feedback (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.midnightNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Share any highlights or suggestions for future renters...',
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
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
                text: _isSubmitting ? 'Submitting...' : 'Submit Trip Review',
                icon: Icons.check_circle_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitFeedback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

