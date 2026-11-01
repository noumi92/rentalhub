# DOC-9: Phase 2 Detailed Implementation Plan
## Fleet Management, Booking Engine & Manual Payments
### Project: RentalHub (`rentalhub`)

---

## 1. Phase Objective & Definition of Done (DoD)

### 1.1 Objective
Implement fleet management for car rental owners with strict **Freemium tier enforcement (maximum 3 vehicles for free tier)**, multi-package rental rate schedules (1h, 3h, 6h, 24h, In-City vs Out-of-City, Self-Drive vs With-Driver), the customer reservation engine, and the complete localized **manual payment verification workflow** (JazzCash, EasyPaisa, Bank Meezan IBAN).

### 1.2 Definition of Done (DoD)
- [ ] Owners can add, edit, and archive vehicles with photos uploaded to cPanel `/storage/upload.php` (`category: vehicles`), specs, and rate packages matching Stitch ANC-11 [11_owner_fleet_inventory.html](file:///e:/Commercial/Gari%20App/.stitch/11_owner_fleet_inventory.html) and ANC-12 [12_owner_rate_matrix.html](file:///e:/Commercial/Gari%20App/.stitch/12_owner_rate_matrix.html).
- [ ] Freemium gate blocks owners on the Basic tier from adding a 4th vehicle with an upgrade prompt.
- [ ] Customers can select packages, dates, and submit reservation requests matching Stitch ANC-02 [02_vehicle_detail_packages.html](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.html) and ANC-04 [04_review_reservation_request.html](file:///e:/Commercial/Gari%20App/.stitch/04_review_reservation_request.html).
- [ ] Owners receive requests, inspect customer trust score/KYC, and Approve or Reject matching Stitch ANC-13 [13_owner_booking_requests.html](file:///e:/Commercial/Gari%20App/.stitch/13_owner_booking_requests.html) and ANC-10 [10_owner_fleet_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/10_owner_fleet_dashboard.html).
- [ ] Customers receive approved requests, view owner payment details (JazzCash, EasyPaisa, Meezan), upload receipt screenshots to cPanel `/storage/upload.php` (`category: payments`), and input TxIDs matching Stitch ANC-03 [03_upload_payment_proof.html](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.html).
- [ ] Owners verify payment screenshots with one click, shifting booking to `status: paid` and unlocking the pickup countdown timer and QR code pass matching Stitch ANC-05 [05_pickup_countdown_pass.html](file:///e:/Commercial/Gari%20App/.stitch/05_pickup_countdown_pass.html) and ANC-06 [06_customer_active_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/06_customer_active_dashboard.html).
- [ ] `DebouncedButton` verified across all action triggers with 400ms lockout.
- [ ] Automated tests validate the entire booking status state machine.

---

## 2. Infrastructure & UI Design Anchor Bindings

1. **Storage Endpoints**: Uses cPanel REST storage deployed in Phase 0 (`public_html/storage/upload.php`) with categories `vehicles` and `payments`.
2. **Firestore Realtime Listeners**: Leverages `bookings/{bookingId}` state streams with optimistic UI updates.
3. **Stitch UI Anchors in `.stitch/`**:
   - Customer Flow: ANC-02 (`02_vehicle_detail_packages.html`), ANC-03 (`03_upload_payment_proof.html`), ANC-04 (`04_review_reservation_request.html`), ANC-05 (`05_pickup_countdown_pass.html`), ANC-06 (`06_customer_active_dashboard.html`).
   - Owner Flow: ANC-10 (`10_owner_fleet_dashboard.html`), ANC-11 (`11_owner_fleet_inventory.html`), ANC-12 (`12_owner_rate_matrix.html`), ANC-13 (`13_owner_booking_requests.html`).

---

## 3. Directory Structure for Phase 2

```
lib/features/
├── fleet/
│   ├── data/
│   │   ├── datasources/fleet_remote_data_source.dart
│   │   ├── models/vehicle_model.dart
│   │   └── repositories/fleet_repository_impl.dart
│   ├── domain/
│   │   ├── entities/vehicle_entity.dart
│   │   └── usecases/
│   │       ├── add_vehicle_usecase.dart
│   │       └── get_shop_vehicles_usecase.dart
│   └── presentation/
│       ├── cubit/
│       │   ├── fleet_cubit.dart
│       │   └── fleet_state.dart
│       └── views/
│           ├── owner_fleet_view.dart
│           ├── add_vehicle_view.dart
│           └── widgets/
│               ├── vehicle_inventory_card.dart
│               ├── freemium_quota_banner.dart
│               ├── package_rate_input_row.dart
│               └── car_photo_picker_grid.dart
├── bookings/
│   ├── data/
│   │   ├── datasources/booking_remote_data_source.dart
│   │   ├── models/booking_model.dart
│   │   └── repositories/booking_repository_impl.dart
│   ├── domain/
│   │   ├── entities/booking_entity.dart
│   │   └── usecases/
│   │       ├── create_booking_request_usecase.dart
│   │       ├── update_booking_status_usecase.dart
│   │       └── get_customer_bookings_usecase.dart
│   └── presentation/
│       ├── cubit/
│       │   ├── booking_cubit.dart
│       │   └── booking_state.dart
│       └── views/
│           ├── customer_bookings_view.dart
│           ├── booking_request_view.dart
│           ├── owner_requests_view.dart
│           └── widgets/
│               ├── booking_status_chip.dart
│               ├── pickup_countdown_timer.dart
│               ├── digital_qr_pass.dart
│               └── customer_trust_score_badge.dart
└── payments/
    ├── data/
    │   ├── datasources/payment_remote_data_source.dart
    │   └── repositories/payment_repository_impl.dart
    ├── domain/
    │   └── usecases/
    │       ├── upload_payment_proof_usecase.dart
    │       └── verify_payment_usecase.dart
    └── presentation/
        ├── cubit/payment_cubit.dart
        └── views/
            ├── upload_payment_proof_view.dart
            ├── owner_payment_review_view.dart
            └── widgets/
                ├── owner_bank_account_card.dart
                ├── payment_proof_preview.dart
                └── copyable_iban_tile.dart
```

---

## 4. Detailed Step-by-Step Task Breakdown

### Task 2.1: Fleet Management & Freemium Quota Enforcement
Implement `AddVehicleUseCase` in `lib/features/fleet/domain/usecases/add_vehicle_usecase.dart` enforcing the 3-car limit for basic free tier:

```dart
import '../entities/vehicle_entity.dart';
import '../repositories/fleet_repository.dart';
import '../../../../core/error/exceptions.dart';

class AddVehicleUseCase {
  final FleetRepository repository;

  AddVehicleUseCase(this.repository);

  Future<void> call({required String shopId, required VehicleEntity vehicle}) async {
    final currentCount = await repository.getActiveVehicleCount(shopId);
    final subscriptionTier = await repository.getShopSubscriptionTier(shopId);

    // Freemium rule: Free tier max 3 vehicles
    if (subscriptionTier == 'basic' && currentCount >= 3) {
      throw BusinessRuleException(
        message: 'Freemium limit reached. Basic free plan allows up to 3 cars. Please upgrade to Pro to add more vehicles.',
      );
    }

    return repository.addVehicle(shopId: shopId, vehicle: vehicle);
  }
}
```

---

### Task 2.2: Rate Card Matrix Model (`VehicleModel`)
Implement flexible packages (1h, 3h, 6h, 24h, In-City vs Out-of-City) in `lib/features/fleet/data/models/vehicle_model.dart`:

```dart
class VehicleRatesModel {
  final int? hourly1;
  final int? hourly3;
  final int? hourly6;
  final int daily24;
  final int? outOfCityDaily;

  VehicleRatesModel({
    this.hourly1,
    this.hourly3,
    this.hourly6,
    required this.daily24,
    this.outOfCityDaily,
  });

  Map<String, dynamic> toMap() => {
    'hourly_1': hourly1,
    'hourly_3': hourly3,
    'hourly_6': hourly6,
    'daily_24': daily24,
    'out_of_city': outOfCityDaily,
  };

  factory VehicleRatesModel.fromMap(Map<String, dynamic> map) => VehicleRatesModel(
    hourly1: map['hourly_1'],
    hourly3: map['hourly_3'],
    hourly6: map['hourly_6'],
    daily24: map['daily_24'] ?? 0,
    outOfCityDaily: map['out_of_city'],
  );
}
```

---

### Task 2.3: Customer Booking Request Submission
Implement `BookingRemoteDataSource` in `lib/features/bookings/data/datasources/booking_remote_data_source.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRemoteDataSource {
  final FirebaseFirestore firestore;

  BookingRemoteDataSource(this.firestore);

  Future<String> createBookingRequest({
    required String customerId,
    required String shopId,
    required String vehicleId,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advanceRequired,
    String? messageForOwner,
  }) async {
    final docRef = firestore.collection('bookings').doc();
    await docRef.set({
      'booking_id': docRef.id,
      'customer_id': customerId,
      'shop_id': shopId,
      'vehicle_id': vehicleId,
      'package_type': packageType,
      'is_with_driver': isWithDriver,
      'pickup_datetime': Timestamp.fromDate(pickupTime),
      'return_datetime': Timestamp.fromDate(returnTime),
      'total_amount': totalAmount,
      'advance_required': advanceRequired,
      'advance_paid': 0,
      'remaining_balance': totalAmount - advanceRequired,
      'status': 'requested',
      'message_for_owner': messageForOwner,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}
```

---

### Task 2.4: Manual Payment Workflow (Upload Screenshot & TxID)
Implement `PaymentCubit` in `lib/features/payments/presentation/cubit/payment_cubit.dart`:

```dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../bookings/domain/repositories/booking_repository.dart';

abstract class PaymentState {}
class PaymentInitial extends PaymentState {}
class PaymentUploading extends PaymentState {}
class PaymentSubmittedSuccess extends PaymentState {}
class PaymentError extends PaymentState { final String message; PaymentError(this.message); }

class PaymentCubit extends Cubit<PaymentState> {
  final CPanelStorageClient storageClient;
  final BookingRepository bookingRepository;

  PaymentCubit({required this.storageClient, required this.bookingRepository}) : super(PaymentInitial());

  Future<void> submitPaymentProof({
    required String bookingId,
    required String customerUid,
    required File receiptScreenshot,
    required String transactionId,
  }) async {
    emit(PaymentUploading());
    try {
      // 1. Upload proof screenshot to cPanel private 'payments' folder
      final fileKey = await storageClient.uploadFile(
        file: receiptScreenshot,
        userUid: customerUid,
        folder: 'payments',
      );

      // 2. Update booking document status to 'payment_submitted'
      await bookingRepository.updatePaymentProof(
        bookingId: bookingId,
        paymentProofUrl: fileKey,
        transactionId: transactionId,
      );

      emit(PaymentSubmittedSuccess());
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
```

---

### Task 2.5: Owner Payment Verification Action
Implement one-click payment verification in `lib/features/payments/domain/usecases/verify_payment_usecase.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyPaymentUseCase {
  final FirebaseFirestore firestore;

  VerifyPaymentUseCase(this.firestore);

  Future<void> call({required String bookingId, required int advanceAmount}) async {
    await firestore.collection('bookings').doc(bookingId).update({
      'status': 'paid',
      'advance_paid': advanceAmount,
      'payment_verified_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
```

---

### Task 2.6: Custom `DebouncedButton` Component
Implement button debouncing preventing accidental double-taps in `lib/core/widgets/debounced_button.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class DebouncedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final int debounceMs;

  const DebouncedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.debounceMs = 400,
  });

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _isClickable = true;
  Timer? _timer;

  void _handleTap() {
    if (!_isClickable) return;
    setState(() => _isClickable = false);
    widget.onPressed();
    _timer = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (mounted) setState(() => _isClickable = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isClickable ? _handleTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor,
      ),
      child: Text(widget.label, style: TextStyle(color: widget.textColor)),
    );
  }
}
```

---

## 5. Phase 2 Testing & Verification Suite

### 5.1 Freemium Hard Cap Test
```dart
test('Owner on basic tier cannot add 4th vehicle', () async {
  final mockRepo = MockFleetRepository();
  when(mockRepo.getActiveVehicleCount('shop123')).thenAnswer((_) async => 3);
  when(mockRepo.getShopSubscriptionTier('shop123')).thenAnswer((_) async => 'basic');

  final useCase = AddVehicleUseCase(mockRepo);
  expect(
    () => useCase(shopId: 'shop123', vehicle: sampleVehicle),
    throwsA(isA<BusinessRuleException>()),
  );
});
```

### 5.2 Button Debounce Unit Test
```dart
testWidgets('DebouncedButton emits exactly 1 event on 5 rapid taps', (tester) async {
  int tapCount = 0;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DebouncedButton(
        label: 'Submit',
        onPressed: () => tapCount++,
        debounceMs: 400,
      ),
    ),
  ));

  // Tap 5 times within 100ms
  for (int i = 0; i < 5; i++) {
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 20));
  }

  expect(tapCount, equals(1));
});
```

---

## 6. Phase 2 Deliverables & Sign-Off Criteria

- [ ] Fleet inventory CRUD active with 3-car freemium cap enforced.
- [ ] Multi-package selector (1h, 3h, 6h, 24h, In-City vs Out-of-City) verified.
- [ ] Customer can upload transfer screenshot and submit TxID.
- [ ] Owner can inspect receipt and verify payment.
- [ ] Pickup countdown timer and QR code pass unlocked upon payment confirmation.

---

## 7. Document Revision History
| Version | Date | Author / Agent | Change Type | Summary of Changes |
| :--- | :--- | :--- | :--- | :--- |
| **1.0.0** | 2026-10-31 | Lead Architect (Antigravity) | Initial Creation | Complete Phase 2 Detailed Implementation Plan for RentalHub. |
| **1.1.0** | 2026-11-01 | Lead Architect (Antigravity) | Type C & Type J | Linked cPanel storage categories (vehicles, payments) and mapped Stitch anchor screens ANC-02, ANC-03, ANC-04, ANC-05, ANC-06, ANC-10, ANC-11, ANC-12, and ANC-13. |
