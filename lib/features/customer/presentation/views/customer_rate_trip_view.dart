import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
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
  // CU-m12: both ratings start UNSET (0) — the old 5-star pre-fill
  // filed a 5/5 review when the customer submitted without touching
  // anything. Pre-filled only from an existing review (see below).
  int _shopRating = 0;
  int _vehicleRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _loading = true;
  bool _alreadyRated = false;
  // F-M15: the admin's "Ask to edit" / "Warn" states are read here.
  // An edit-requested review re-opens for editing (submitting it
  // clears the request); a warned review shows the warning above
  // the read-only review.
  bool _editRequested = false;
  bool _warned = false;
  String _moderationReason = '';

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
            // Pre-fill only from the existing review — a missing
            // value stays unset (0), never a silent 5.
            _shopRating = (review['shopRating'] as num?)?.toInt() ?? 0;
            _vehicleRating = (review['vehicleRating'] as num?)?.toInt() ?? 0;
            _commentController.text =
                (review['customerComment'] as String?) ?? '';
            _moderationReason =
                ReviewRemoteDataSource.moderationReasonOf(review);
            _warned = ReviewRemoteDataSource.isWarned(review);
            // F-M15: an edit request re-opens the form — pre-filled,
            // but the stars/comment are editable and submit shows.
            if (ReviewRemoteDataSource.isEditRequested(review)) {
              _editRequested = true;
              _alreadyRated = false;
            }
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
    // CU-m12: a rating counts only when the customer tapped it — an
    // untouched (0) rating blocks submit instead of filing a 5.
    if (_shopRating <= 0 || _vehicleRating <= 0) {
      AppFeedback.showError(context, l10n.rateSelectBoth);
      return;
    }
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
                  ? const AppLoadingState()
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
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.orangeTextFor(Theme.of(context).brightness)),
                          ),
                          const SizedBox(height: 12),
                          if (_editRequested || _warned)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (_editRequested ? l10n.rateEditRequestedTitle : l10n.rateWarnedTitle) +
                                      (_moderationReason.isNotEmpty ? ': $_moderationReason' : ''),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          if (_alreadyRated)
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                l10n.rateAlreadyRated,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
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
