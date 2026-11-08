import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/advance_deposit_notice_card.dart';
import '../widgets/booking_summary_card.dart';

class ReviewBookingRequestView extends StatefulWidget {
  final Map<String, dynamic> bookingDraft;
  final Function(BookingEntity booking)? onRequestCreated;
  final VoidCallback? onBack;

  const ReviewBookingRequestView({
    super.key,
    required this.bookingDraft,
    this.onRequestCreated,
    this.onBack,
  });

  @override
  State<ReviewBookingRequestView> createState() =>
      _ReviewBookingRequestViewState();
}

class _ReviewBookingRequestViewState extends State<ReviewBookingRequestView> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    try {
      // C2: the request is filed under the signed-in customer's own
      // record (name, phone, CNIC) when one exists. The placeholder
      // identity below is only for a signed-out/demo flow — a real
      // customer never sees it.
      String customerId = 'cust-101';
      String customerName = 'Valued Customer';
      String customerPhone = '+923001234567';
      String? customerCnic;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          customerId = user.uid;
          customerName = user.displayName ?? customerName;
          customerPhone = user.phoneNumber ?? customerPhone;
          if (sl.isRegistered<CustomerRemoteDataSource>()) {
            final record = await sl<CustomerRemoteDataSource>()
                .getCustomerById(user.uid);
            if (record != null) {
              customerName = record.name;
              customerPhone = record.phone;
              customerCnic = record.cnic;
            }
          }
        }
      } catch (_) {}

      final draft = widget.bookingDraft;
      final ds = sl<BookingRemoteDataSource>();

      final booking = await ds.createBookingRequest(
        customerId: customerId,
        shopId: draft['shopId'] as String? ?? 'shop-default',
        vehicleId: draft['carId'] as String? ?? 'car-default',
        packageType: draft['packageType'] as String? ?? '24h',
        isWithDriver: draft['isWithDriver'] as bool? ?? false,
        pickupTime: draft['pickupTime'] as DateTime? ?? DateTime.now(),
        returnTime: draft['returnTime'] as DateTime? ??
            DateTime.now().add(const Duration(days: 1)),
        totalAmount: draft['totalAmount'] as int? ?? 5000,
        advanceRequired: draft['advanceRequired'] as int? ?? 1000,
        vehicleName: draft['carName'] as String?,
        vehiclePlate: draft['plateNumber'] as String?,
        shopName: draft['shopName'] as String?,
        customerName: customerName,
        customerPhone: customerPhone,
        customerCnic: customerCnic,
        tripType: draft['tripType'] as String? ?? 'in_city',
        kmLimit: draft['kmLimit'] as int?,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        AppFeedback.showSuccess(context, 'Reservation request sent to showroom!');
        widget.onRequestCreated?.call(booking);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to submit booking: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.bookingDraft;
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
                'Review Reservation',
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
                    BookingSummaryCard(
                      carName: d['carName'] as String? ?? 'Vehicle',
                      plateNumber: d['plateNumber'] as String? ?? 'PAK-1234',
                      shopName: d['shopName'] as String? ?? 'Rental Showroom',
                      isWithDriver: d['isWithDriver'] as bool? ?? false,
                      packageType: d['packageType'] as String? ?? '24h',
                      pickupTime:
                          d['pickupTime'] as DateTime? ?? DateTime.now(),
                      returnTime: d['returnTime'] as DateTime? ??
                          DateTime.now().add(const Duration(days: 1)),
                      totalAmount: d['totalAmount'] as int? ?? 5000,
                      advanceRequired: d['advanceRequired'] as int? ?? 1000,
                      tripType: d['tripType'] as String? ?? 'in_city',
                      kmLimit: d['kmLimit'] as int?,
                      securityDepositPkr:
                          d['securityDepositPkr'] as int?,
                      destinationCity: d['destinationCity'] as String?,
                    ),
                    const SizedBox(height: 14),
                    AdvanceDepositNoticeCard(
                      isWithDriver: d['isWithDriver'] as bool? ?? false,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Instructions for Showroom',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'E.g. Clean car required, airport terminal pickup...',
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Theme.of(context).dividerColor),
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
                text: _isSubmitting ? 'Sending Request...' : 'Send Request to Owner',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
