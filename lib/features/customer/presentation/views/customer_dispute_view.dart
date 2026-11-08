import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/dispute_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../widgets/dispute_form_fields.dart';
import '../widgets/my_disputes_list.dart';

class CustomerDisputeView extends StatefulWidget {
  final String? initialBookingId;
  final VoidCallback? onDisputeSubmitted;
  final VoidCallback? onBack;

  const CustomerDisputeView({
    super.key,
    this.initialBookingId,
    this.onDisputeSubmitted,
    this.onBack,
  });

  @override
  State<CustomerDisputeView> createState() => _CustomerDisputeViewState();
}

class _CustomerDisputeViewState extends State<CustomerDisputeView> {
  final _bookingIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Deposit Withheld';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Deposit Withheld', 'Unfair Damage Penalty', 'Showroom Overcharge',
    'Vehicle Breakdown Delay', 'Rude / Unprofessional Staff',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialBookingId != null) {
      _bookingIdController.text = widget.initialBookingId!;
    }
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    final bId = _bookingIdController.text.trim();
    final desc = _descriptionController.text.trim();
    if (bId.isEmpty) {
      AppFeedback.showError(context, 'Please enter your Booking ID.');
      return;
    }
    if (desc.isEmpty) {
      AppFeedback.showError(context, 'Please explain the issue encountered.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String uid = 'cust-101';
      try {
        final u = FirebaseAuth.instance.currentUser;
        if (u != null) uid = u.uid;
      } catch (_) {}

      // The booking is resolved so the dispute carries the showroom
      // it belongs to — the owner's disputes inbox reads it straight
      // off the record. Best effort: when the booking cannot be
      // resolved the dispute is still filed and the inbox attributes
      // it from the booking document instead.
      String? shopId;
      try {
        final booking =
            await sl<BookingRemoteDataSource>().getBookingById(bId);
        shopId = booking?.shopId;
      } catch (_) {}
      // G4: the dispute is filed through the data source (Firestore
      // with an in-memory fallback). The message says honestly whether
      // it reached the cloud or only this device — the old code
      // swallowed a failed write and claimed an arbitration team was
      // notified.
      final filed = await sl<DisputeRemoteDataSource>().fileDispute(
        bookingId: bId,
        customerId: uid,
        category: _selectedCategory,
        description: desc,
        shopId: shopId,
      );
      if (mounted) {
        if (filed.synced) {
          AppFeedback.showSuccess(
            context,
            'Dispute filed. The showroom can see it in their disputes inbox.',
          );
        } else {
          AppFeedback.showWarning(
            context,
            'Dispute saved on this device — it will reach the showroom once you are back online.',
          );
        }
        widget.onDisputeSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to file dispute: $e');
      }
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
                'File Complaint / Dispute',
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
                    DisputeFormFields(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                      bookingIdController: _bookingIdController,
                      descriptionController: _descriptionController,
                    ),
                    const SizedBox(height: 20),
                    const MyDisputesList(),
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
                text: _isSubmitting ? 'Submitting Dispute...' : 'Submit Claim',
                icon: Icons.gavel_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitDispute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

