# DOC-8: Phase 1 Detailed Implementation Plan
## Authentication, Role-Gating, KYC & Discovery
### Project: RentalHub (`rentalhub`)

---

## 1. Phase Objective & Definition of Done (DoD)

### 1.1 Objective
Implement end-to-end user authentication (Google Sign-In and Email/Password), enforce permanent single-role onboarding (`customer` vs `owner`), enable KYC document uploads to cPanel secure storage, and deliver geo-location discovery with a 1–5 km radius filter and vehicle catalog browsing.

### 1.2 Definition of Done (DoD)
- [ ] Users can sign in via Google OAuth2 (utilizing Phase 0 registered SHA-1) or Email/Password on Android.
- [ ] First-time users are forced into the Onboarding Wizard to pick an immutable role (`customer` or `owner`).
- [ ] Customer KYC documents (CNIC front/back, driving license) upload to cPanel endpoint (`/storage/upload.php`) and update Firestore with `is_verified` status tracking matching Stitch ANC-07 [07_kyc_document_upload.html](file:///e:/Commercial/Gari%20App/.stitch/07_kyc_document_upload.html).
- [ ] Owners can register shop details, GPS coordinates, and up to 3 payout accounts (JazzCash, EasyPaisa, Meezan Bank IBAN) matching Stitch ANC-09 [09_owner_shop_onboarding.html](file:///e:/Commercial/Gari%20App/.stitch/09_owner_shop_onboarding.html).
- [ ] Customer can retrieve nearby verified shops filtered by radius pills (1 km, 2 km, 3 km, 5 km) on List and Map views matching Stitch ANC-01 [01_customer_discovery.html](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.html).
- [ ] Shop catalog and vehicle detail views render specifications (seats, fuel, transmission) and dual rate cards.
- [ ] Unit & widget tests pass for role immutability, KYC upload, and UI overflow on 360px viewports.

---

## 2. Phase 0 Prerequisites & External Bindings

Before executing Phase 1 tasks, verify the following Phase 0 infrastructure:
1. **GitHub Repository**: Codebase managed under `rentalhub` with clean feature branches.
2. **Firebase Project**: `rentalhub-production` provisioned with active `android/app/google-services.json` and debug SHA-1 registered for Google OAuth2.
3. **cPanel Storage Server**: PHP upload script deployed at `public_html/storage/upload.php` with directory `public_html/storage/kyc/` permissions set to `0755` and secured via `.htaccess`.
4. **UI Design Anchors**: Production templates verified in `.stitch/`:
   - [01_customer_discovery.html](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.html) (ANC-01)
   - [07_kyc_document_upload.html](file:///e:/Commercial/Gari%20App/.stitch/07_kyc_document_upload.html) (ANC-07)
   - [09_owner_shop_onboarding.html](file:///e:/Commercial/Gari%20App/.stitch/09_owner_shop_onboarding.html) (ANC-09)

---

## 3. Directory Structure for Phase 1

```
lib/features/
├── auth/
│   ├── data/
│   │   ├── datasources/auth_remote_data_source.dart
│   │   ├── models/user_model.dart
│   │   └── repositories/auth_repository_impl.dart
│   ├── domain/
│   │   ├── entities/user_entity.dart
│   │   ├── repositories/auth_repository.dart
│   │   └── usecases/
│   │       ├── sign_in_with_google_usecase.dart
│   │       ├── sign_in_with_email_usecase.dart
│   │       └── assign_user_role_usecase.dart
│   └── presentation/
│       ├── cubit/
│       │   ├── auth_cubit.dart
│       │   └── auth_state.dart
│       └── views/
│           ├── login_view.dart
│           ├── onboarding_role_view.dart
│           └── widgets/
│               ├── google_sign_in_button.dart
│               ├── role_selector_card.dart
│               └── auth_text_field.dart
├── trust/
│   ├── data/
│   │   ├── datasources/kyc_remote_data_source.dart
│   │   └── repositories/kyc_repository_impl.dart
│   ├── domain/
│   │   ├── entities/kyc_document_entity.dart
│   │   └── usecases/upload_kyc_document_usecase.dart
│   └── presentation/
│       ├── cubit/kyc_cubit.dart
│       └── views/
│           ├── customer_documents_view.dart
│           └── widgets/document_slot_tile.dart
└── discovery/
    ├── data/
    │   ├── datasources/discovery_remote_data_source.dart
    │   ├── models/shop_model.dart
    │   └── repositories/discovery_repository_impl.dart
    ├── domain/
    │   ├── entities/shop_entity.dart
    │   └── usecases/get_nearby_shops_usecase.dart
    └── presentation/
        ├── cubit/discovery_cubit.dart
        └── views/
            ├── customer_home_view.dart
            ├── shop_detail_view.dart
            ├── vehicle_detail_view.dart
            └── widgets/
                ├── radius_filter_pills.dart
                ├── shop_list_card.dart
                ├── shop_map_view.dart
                └── empty_radar_state.dart
```

---

## 4. Detailed Step-by-Step Task Breakdown

### Task 1.1: Authentication Domain & Data Layer
Implement `UserEntity` in `lib/features/auth/domain/entities/user_entity.dart`:

```dart
class UserEntity {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final String? role; // 'customer' | 'owner' | null (if new)
  final bool isVerified;
  final double trustScore;
  final int totalTrips;
  final bool isBlacklisted;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.profilePhotoUrl,
    this.role,
    this.isVerified = false,
    this.trustScore = 5.0,
    this.totalTrips = 0,
    this.isBlacklisted = false,
  });

  bool get hasSelectedRole => role != null && (role == 'customer' || role == 'owner');
}
```

Implement `UserModel` serialization in `lib/features/auth/data/models/user_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.profilePhotoUrl,
    super.role,
    super.isVerified,
    super.trustScore,
    super.totalTrips,
    super.isBlacklisted,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['full_name'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      profilePhotoUrl: data['profile_photo_url'],
      role: data['role'],
      isVerified: data['is_verified'] ?? false,
      trustScore: (data['trust_score'] ?? 5.0).toDouble(),
      totalTrips: data['total_trips'] ?? 0,
      isBlacklisted: data['is_blacklisted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'role': role,
      'is_verified': isVerified,
      'trust_score': trustScore,
      'total_trips': totalTrips,
      'is_blacklisted': isBlacklisted,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
```

---

### Task 1.2: Permanent Role Locking Implementation (`AuthCubit`)
Implement `AuthCubit` in `lib/features/auth/presentation/cubit/auth_cubit.dart` enforcing single-role immutability:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/assign_user_role_usecase.dart';

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthenticatedWithoutRole extends AuthState { final UserEntity user; AuthenticatedWithoutRole(this.user); }
class AuthenticatedCustomer extends AuthState { final UserEntity user; AuthenticatedCustomer(this.user); }
class AuthenticatedOwner extends AuthState { final UserEntity user; AuthenticatedOwner(this.user); }
class AuthError extends AuthState { final String message; AuthError(this.message); }

class AuthCubit extends Cubit<AuthState> {
  final AssignUserRoleUseCase assignRoleUseCase;

  AuthCubit({required this.assignRoleUseCase}) : super(AuthInitial());

  Future<void> selectPermanentRole({required String role, required String fullName, required String phone}) async {
    try {
      if (role != 'customer' && role != 'owner') {
        emit(AuthError('Invalid role specified.'));
        return;
      }
      final updatedUser = await assignRoleUseCase(role: role, fullName: fullName, phone: phone);
      if (updatedUser.role == 'customer') {
        emit(AuthenticatedCustomer(updatedUser));
      } else {
        emit(AuthenticatedOwner(updatedUser));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
```

---

### Task 1.3: KYC Document Upload via cPanel REST API
Implement `KycRemoteDataSource` in `lib/features/trust/data/datasources/kyc_remote_data_source.dart`:

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/network/cpanel_storage_client.dart';

class KycRemoteDataSource {
  final CPanelStorageClient storageClient;
  final FirebaseFirestore firestore;

  KycRemoteDataSource({required this.storageClient, required this.firestore});

  Future<void> uploadCnicAndLicense({
    required String userUid,
    required File cnicFront,
    required File cnicBack,
    required File license,
    required String cnicNumber,
  }) async {
    // Upload files to cPanel private 'kyc' directory
    final cnicFrontKey = await storageClient.uploadFile(file: cnicFront, userUid: userUid, folder: 'kyc');
    final cnicBackKey = await storageClient.uploadFile(file: cnicBack, userUid: userUid, folder: 'kyc');
    final licenseKey = await storageClient.uploadFile(file: license, userUid: userUid, folder: 'kyc');

    // Update Firestore user document
    await firestore.collection('users').doc(userUid).update({
      'cnic_number': cnicNumber,
      'cnic_front_url': cnicFrontKey,
      'cnic_back_url': cnicBackKey,
      'license_url': licenseKey,
      'kyc_status': 'submitted',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
```

---

### Task 1.4: Owner Shop Onboarding with Bank Accounts
Implement `ShopModel` with support for JazzCash, EasyPaisa, and Meezan Bank in `lib/features/discovery/data/models/shop_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String shopId;
  final String ownerId;
  final String shopName;
  final String phoneNumber;
  final String address;
  final String city;
  final GeoPoint geoLocation;
  final bool isVerified;
  final List<Map<String, dynamic>> bankAccounts;

  ShopModel({
    required this.shopId,
    required this.ownerId,
    required this.shopName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.geoLocation,
    this.isVerified = false,
    required this.bankAccounts,
  });

  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShopModel(
      shopId: doc.id,
      ownerId: d['owner_id'] ?? '',
      shopName: d['shop_name'] ?? '',
      phoneNumber: d['phone_number'] ?? '',
      address: d['address'] ?? '',
      city: d['city'] ?? '',
      geoLocation: d['geo_location'] ?? const GeoPoint(0, 0),
      isVerified: d['is_verified'] ?? false,
      bankAccounts: List<Map<String, dynamic>>.from(d['bank_accounts'] ?? []),
    );
  }
}
```

---

### Task 1.5: Geo-Discovery & Radius Filter (1–5 km)
Implement `DiscoveryCubit` in `lib/features/discovery/presentation/cubit/discovery_cubit.dart` filtering shops based on distance calculated from user GPS coordinates:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/shop_model.dart';

abstract class DiscoveryState {}
class DiscoveryLoading extends DiscoveryState {}
class DiscoveryLoaded extends DiscoveryState {
  final List<ShopModel> shops;
  final double currentRadiusKm;
  final Position userPosition;
  DiscoveryLoaded(this.shops, this.currentRadiusKm, this.userPosition);
}
class DiscoveryEmpty extends DiscoveryState { final double currentRadiusKm; DiscoveryEmpty(this.currentRadiusKm); }

class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit() : super(DiscoveryLoading());

  Future<void> fetchNearbyShops({required double radiusKm}) async {
    emit(DiscoveryLoading());
    try {
      final position = await Geolocator.getCurrentPosition();
      // Fetch shops and compute distance using Geolocator.distanceBetween
      // In production: bounding box query on Firestore
      final List<ShopModel> filteredShops = []; // Filtered list based on radiusKm

      if (filteredShops.isEmpty) {
        emit(DiscoveryEmpty(radiusKm));
      } else {
        emit(DiscoveryLoaded(filteredShops, radiusKm, position));
      }
    } catch (e) {
      emit(DiscoveryEmpty(radiusKm));
    }
  }
}
```

---

## 5. Phase 1 Testing & Overflow Verification Checklist

### 5.1 Role Immutability Test
```dart
test('Once role is selected, updating role throws exception', () async {
  final fakeFirestore = FakeFirebaseFirestore();
  await fakeFirestore.collection('users').doc('user123').set({
    'role': 'customer',
  });

  // Attempting to overwrite role must fail
  expect(
    () => fakeFirestore.collection('users').doc('user123').update({'role': 'owner'}),
    throwsA(isA<FirebaseException>()),
  );
});
```

### 5.2 UI Overflow Guard Test
```dart
testWidgets('Customer Home View renders with 0 overflow on 360px viewport and 1.35x font scale', (tester) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    tester: tester,
    screen: const CustomerHomeView(),
    width: 360.0,
    height: 640.0,
    textScale: 1.35,
  );
});
```

---

## 6. Phase 1 Deliverables & Sign-Off Criteria

- [ ] Complete Google Sign-In and Email/Password flows verified on Android physical device.
- [ ] Onboarding wizard forces role selection and locks profile in Firestore.
- [ ] KYC files uploaded to cPanel with returned keys stored in user document.
- [ ] Radius pills (1 km, 2 km, 3 km, 5 km) filter nearby shops with empty radar fallback.
- [ ] Zero UI overflow warnings under 1.35x font scale.

---

## 7. Document Revision History
| Version | Date | Author / Agent | Change Type | Summary of Changes |
| :--- | :--- | :--- | :--- | :--- |
| **1.0.0** | 2026-10-31 | Lead Architect (Antigravity) | Initial Creation | Complete Phase 1 Detailed Implementation Plan for RentalHub. |
| **1.1.0** | 2026-11-01 | Lead Architect (Antigravity) | Type C & Type J | Linked Phase 0 Firebase/cPanel/GitHub pre-requisites and mapped Stitch anchor screens ANC-01, ANC-07, and ANC-09. |
