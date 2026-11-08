import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../widgets/rate_trip_feedback_card.dart';
import '../widgets/star_rating_bar.dart';
import '../../../../l10n/app_localizations.dart';

// H4: a rating now writes a real `reviews/{bookingId}` document —
// one rating per booking per side — instead of a `customerRating`
// blob on the booking that nothing read. A failed write is shown
// as an error, never swallowed: the old inner try/catch reported
// success even when nothing was saved.
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
  bool _loading = true;
  bool _alreadyRated = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final review = await sl<ReviewRemoteDataSource>()
          .getReview(widget.booking.bookingId);
      if (review != null && review['customerRatedAt'] != null) {
        if (mounted) {
          setState(() {
            _alreadyRated = true;
            _shopRating = (review['shopRating'] as num?)?.toInt() ?? 5;
            _vehicleRating = (review['vehicleRating'] as num?)?.toInt() ?? 5;
            _commentController.text =
                (review['customerComment'] as String?) ?? '';
          });
        }
      }
    } catch (_) {
      // A failed read must not block rating; the submit will report
      // its own failure.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final synced = await sl<ReviewRemoteDataSource>().submitCustomerReview(
        bookingId: widget.booking.bookingId,
        shopId: widget.booking.shopId,
        customerId: widget.booking.customerId,
        customerName: widget.booking.customerName,
        vehicleName: widget.booking.vehicleName,
        shopRating: _shopRating,
        vehicleRating: _vehicleRating,
        comment: _commentController.text,
      );
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          synced
              ? l10n.rateSaved
              : l10n.rateSavedOffline,
        );
        widget.onRatingSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.rateSaveError(e.toString()));
      }
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
              title: l10n.rateTitle,
              onBack: widget.onBack,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Text(
                            l10n.rateTripRef(widget.booking.bookingId),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary),
                          ),
                          const SizedBox(height: 12),
                          if (_alreadyRated)
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                l10n.rateAlreadyRated,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          StarRatingBar(
                            title: l10n.rateShopService,
                            subtitle:
                                l10n.rateShopHint,
                            rating: _shopRating,
                            onRatingChanged: _alreadyRated
                                ? null
                                : (r) => setState(() => _shopRating = r),
                          ),
                          const SizedBox(height: 12),
                          StarRatingBar(
                            title: l10n.rateVehicleCondition,
                            subtitle:
                                l10n.rateVehicleHint,
                            rating: _vehicleRating,
                            onRatingChanged: _alreadyRated
                                ? null
                                : (r) => setState(() => _vehicleRating = r),
                          ),
                          const SizedBox(height: 14),
                          RateTripFeedbackCard(
                            controller: _commentController,
                            readOnly: _alreadyRated,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
            if (!_loading && !_alreadyRated)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  text: _isSubmitting ? l10n.rateSubmitting : l10n.rateSubmit,
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
