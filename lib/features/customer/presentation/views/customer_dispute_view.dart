import 'package:flutter/material.dart';
import '../../../../core/auth/signed_in_user.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/dispute_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../widgets/dispute_form_fields.dart';
import '../widgets/my_disputes_list.dart';
import '../../../../l10n/app_localizations.dart';

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
    'Deposit Withheld',
    'Unfair Damage Penalty',
    'Showroom Overcharge',
    'Vehicle Breakdown Delay',
    'Rude / Unprofessional Staff',
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
    final l10n = AppLocalizations.of(context)!;
    final bId = _bookingIdController.text.trim();
    final desc = _descriptionController.text.trim();
    if (bId.isEmpty) {
      AppFeedback.showError(context, l10n.disputeEnterBookingId);
      return;
    }
    if (desc.isEmpty) {
      AppFeedback.showError(context, l10n.disputeExplainIssue);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // CU-m3: a signed-out caller cannot file a dispute — the old
      // 'cust-101' fallback filed it under a shared fake identity.
      final uid = SignedInUser.uid();
      if (uid.isEmpty) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          AppFeedback.showError(context, l10n.signInRequiredGeneric);
        }
        return;
      }

      // The booking is resolved so the dispute carries the showroom
      // it belongs to — the owner's disputes inbox reads it straight
      // off the record. Best effort: when the booking cannot be
      // resolved the dispute is still filed and the inbox attributes
      // it from the booking document instead.
      String? shopId;
      try {
        final booking = await sl<BookingRemoteDataSource>().getBookingById(bId);
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
            l10n.disputeFiled,
          );
        } else {
          AppFeedback.showWarning(
            context,
            l10n.disputeSavedOffline,
          );
        }
        widget.onDisputeSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.disputeFileError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.disputeTitle,
              onBack: widget.onBack,
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
                text: _isSubmitting ? l10n.disputeSubmitting : l10n.disputeSubmit,
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
