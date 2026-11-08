import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../customer/data/datasources/review_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/presentation/widgets/star_rating_bar.dart';

class OwnerCustomerRatingView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerCustomerRatingView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerCustomerRatingView> createState() => _OwnerCustomerRatingViewState();
}

class _OwnerCustomerRatingViewState extends State<OwnerCustomerRatingView> {
  int _punctualityRating = 5;
  int _careRating = 5;
  int _behaviorRating = 5;
  bool _flagForBlacklist = false;
  String _selectedReason = 'Payment Default / Refusal to Settle Penalty';
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// H4 mirror half: the owner's rating of the customer is persisted into the same `reviews/{bookingId}` document the customer rates into.
  /// The blacklist report uses the booking's real CNIC and phone (the old hardcoded CNIC/phone are gone); without a CNIC the report cannot
  /// be filed from here, and the switch is disabled.
  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    try {
      final synced =
          await sl<ReviewRemoteDataSource>().submitOwnerReview(
        bookingId: widget.booking.bookingId,
        shopId: widget.booking.shopId,
        customerId: widget.booking.customerId,
        punctualityRating: _punctualityRating,
        careRating: _careRating,
        behaviorRating: _behaviorRating,
        comment: _commentController.text,
      );
      bool blacklisted = false;
      if (_flagForBlacklist) {
        final cnic = widget.booking.customerCnic;
        final phone = widget.booking.customerPhone;
        if (cnic != null && cnic.isNotEmpty && phone != null && phone.isNotEmpty) {
          await sl<BlacklistRemoteDataSource>().reportCustomerToBlacklist(
            reportedByShopId: widget.booking.shopId,
            cnicNumber: cnic,
            phoneNumber: phone,
            reasonCategory: _selectedReason,
            description: _commentController.text.trim().isNotEmpty
                ? _commentController.text.trim()
                : 'Customer flagged during return settlement for $_selectedReason.',
          );
          blacklisted = true;
        }
      }

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          !synced
              ? 'Rating saved on this device — it will sync when you are back online.'
              : blacklisted
                  ? 'Rating saved and the customer was reported to the shared blacklist.'
                  : 'Your rating of the customer has been saved.',
        );
        // Flow complete: go to the Requests list (tab root); other tabs keep their state.
        context.go(RouteNames.ownerRequests);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Submission failed: $e');
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Reputation & Review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(widget.booking.customerName ?? 'Customer Review', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ratingsContainer(),
                    const SizedBox(height: 16),
                    _blacklistSection(),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: _isSubmitting ? 'Recording Rating...' : 'Submit Rating & Close Trip',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _submitRating,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingsContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Performance Feedback', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _starRow('Return Punctuality & Timekeeping', 'Vehicle returned as per agreed contract schedule', _punctualityRating, (r) => setState(() => _punctualityRating = r)),
          const SizedBox(height: 10),
          _starRow('Vehicle Care & Cleanliness', 'Interior cleanliness and scratch-free return', _careRating, (r) => setState(() => _careRating = r)),
          const SizedBox(height: 10),
          _starRow('Overall Behavior & Civility', 'Professionalism and adherence to showroom policies', _behaviorRating, (r) => setState(() => _behaviorRating = r)),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add optional feedback notes for community showroom records...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSubtle)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starRow(String label, String subtitle, int rating, ValueChanged<int> onChanged) {
    return StarRatingBar(
      title: label,
      subtitle: subtitle,
      rating: rating,
      onRatingChanged: onChanged,
    );
  }

  Widget _blacklistSection() {
    return Material(
      color: _flagForBlacklist ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _flagForBlacklist ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              activeThumbColor: Theme.of(context).colorScheme.error,
              contentPadding: EdgeInsets.zero,
              title: Text('Flag Customer to Shared Blacklist', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.error)),
              subtitle: Text(
                  widget.booking.customerCnic == null ||
                          widget.booking.customerCnic!.isEmpty
                      ? 'Needs the customer CNIC on this booking — none is recorded, so a report cannot be filed from here.'
                      : 'Other showrooms using RentalHub can see this report',
                  style: Theme.of(context).textTheme.labelSmall),
              value: _flagForBlacklist,
              onChanged: widget.booking.customerCnic == null ||
                      widget.booking.customerCnic!.isEmpty
                  ? null
                  : (val) => setState(() => _flagForBlacklist = val),
            ),
            if (_flagForBlacklist) ...[
              const SizedBox(height: 10),
              Text('Reason Category for Tribunal:', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                isExpanded: true,
                style: Theme.of(context).textTheme.bodySmall,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Payment Default / Refusal to Settle Penalty', child: Text('Payment Default / Refusal to Settle')),
                  DropdownMenuItem(value: 'Unauthorized Inter-provincial Border Crossing', child: Text('Unauthorized Border Crossing')),
                  DropdownMenuItem(value: 'Vehicle Abuse / Major Collision Abandonment', child: Text('Vehicle Abuse / Abandonment')),
                  DropdownMenuItem(value: 'Fake NADRA CNIC / Impersonation Fraud', child: Text('Fake Identity / Impersonation')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedReason = val);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
