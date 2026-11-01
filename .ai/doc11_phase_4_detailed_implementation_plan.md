# DOC-11: Phase 4 Detailed Implementation Plan
## Admin Web Panel, Blacklist Registry, Hardening & Release
### Project: RentalHub (`rentalhub`)

---

## 1. Phase Objective & Definition of Done (DoD)

### 1.1 Objective
Build and deploy the **RentalHub Admin Web Panel** (Flutter Web deployed on cPanel) for the single `super_admin`, implement the centralized **Global Blacklist registry** with instant fraud prevention and admin reversal authority, execute comprehensive automated **UI overflow and debounce test suites**, perform full bilingual (English & Urdu) localization audits, and generate production release builds.

### 1.2 Definition of Done (DoD)
- [ ] Flutter Web Admin Panel compiles with `flutter build web --release --base-href /admin/` and deploys cleanly to cPanel `public_html/admin/` with SPA `.htaccess` routing.
- [ ] Admin access is strictly protected via Firebase Auth Custom Claims (`admin: true`), allowing login only to the single master `super_admin` account matching Stitch ANC-17 [17_admin_web_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/17_admin_web_dashboard.html).
- [ ] Super Admin can approve/reject pending shop registrations, inspect trade documents, and toggle verified badges matching Stitch ANC-18 [18_admin_shop_accreditation.html](file:///e:/Commercial/Gari%20App/.stitch/18_admin_shop_accreditation.html).
- [ ] Super Admin can audit and revert blacklist flags with mandatory audit justification matching Stitch ANC-19 [19_admin_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/19_admin_fraud_blacklist.html).
- [ ] Super Admin manages platform dispute tribunals and host subscription tiers matching Stitch ANC-20 [20_admin_subscription_tiers.html](file:///e:/Commercial/Gari%20App/.stitch/20_admin_subscription_tiers.html).
- [ ] Automated widget tests run on all screens at 360px viewport width, 1.35x font scale, and 350px keyboard insets with zero overflow exceptions.
- [ ] Button debouncing is 100% verified across all booking and payment submission forms.
- [ ] Full bilingual support verified: English (LTR) and Urdu (RTL) switch cleanly with mirrored UI.
- [ ] Signed production Android APK (`build/app/outputs/flutter-apk/app-release.apk`) generated and ready for distribution.

---

## 2. Infrastructure & UI Design Anchor Bindings

1. **cPanel Web Hosting (Stage 3)**: Flutter Web static hosting at `public_html/admin/` configured with URL rewrites for GoRouter routing.
2. **Firebase Auth Custom Claims**: Master `super_admin` role claim enforced via Firebase Admin SDK.
3. **Stitch UI Anchors in `.stitch/`**:
   - Operations Dashboard: ANC-17 ([17_admin_web_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/17_admin_web_dashboard.html))
   - Shop Accreditation Queue: ANC-18 ([18_admin_shop_accreditation.html](file:///e:/Commercial/Gari%20App/.stitch/18_admin_shop_accreditation.html))
   - Fraud Blacklist Registry: ANC-19 ([19_admin_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/19_admin_fraud_blacklist.html))
   - Disputes & Subscriptions: ANC-20 ([20_admin_subscription_tiers.html](file:///e:/Commercial/Gari%20App/.stitch/20_admin_subscription_tiers.html))

---

## 3. Directory Structure for Phase 4

```
lib/features/
├── admin/
│   ├── data/
│   │   ├── datasources/admin_remote_data_source.dart
│   │   └── repositories/admin_repository_impl.dart
│   ├── domain/
│   │   ├── repositories/admin_repository.dart
│   │   └── usecases/
│   │       ├── approve_shop_usecase.dart
│   │       ├── revert_blacklist_usecase.dart
│   │       └── resolve_dispute_usecase.dart
│   └── presentation/
│       ├── cubit/admin_cubit.dart
│       └── views/
│           ├── admin_login_view.dart
│           ├── admin_dashboard_view.dart
│           ├── shop_approvals_view.dart
│           ├── blacklist_manager_view.dart
│           ├── disputes_tribunal_view.dart
│           └── widgets/
│               ├── admin_sidebar_navigation.dart
│               ├── kpi_metric_card.dart
│               ├── shop_verification_row.dart
│               └── blacklist_revert_dialog.dart
└── blacklist/
    ├── data/
    │   ├── datasources/blacklist_remote_data_source.dart
    │   ├── models/blacklist_record_model.dart
    │   └── repositories/blacklist_repository_impl.dart
    ├── domain/
    │   ├── entities/blacklist_entity.dart
    │   └── usecases/
    │       ├── report_customer_fraud_usecase.dart
    │       └── check_customer_blacklist_status_usecase.dart
    └── presentation/
        ├── cubit/blacklist_cubit.dart
        └── views/
            ├── report_blacklist_view.dart
            └── widgets/blacklist_warning_banner.dart

web/
└── .htaccess                        # cPanel SPA rewrite rules for GoRouter
```

---

## 4. Detailed Step-by-Step Task Breakdown

### Task 4.1: cPanel Web Deployment Configuration (`.htaccess`)
Create `web/.htaccess` to enable Single Page Application (SPA) routing for GoRouter on Apache cPanel hosting:

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /admin/
  
  # If file or folder exists, serve directly
  RewriteCond %{REQUEST_FILENAME} -f [OR]
  RewriteCond %{REQUEST_FILENAME} -d
  RewriteRule ^ - [L]
  
  # Otherwise rewrite all requests to index.html
  RewriteRule ^ index.html [L]
</IfModule>

# Security Headers
<IfModule mod_headers.c>
  Header set X-Content-Type-Options "nosniff"
  Header set X-Frame-Options "SAMEORIGIN"
  Header set X-XSS-Protection "1; mode=block"
</IfModule>
```

---

### Task 4.2: Single `super_admin` Security Gate
Implement `AdminGuard` in `lib/core/routing/admin_guard.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGuard {
  static const String masterSuperAdminEmail = 'superadmin@rentalhub.pk';

  static Future<bool> isMasterSuperAdmin() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    if (currentUser.email != masterSuperAdminEmail) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    return doc.exists && doc.data()?['role'] == 'super_admin';
  }
}
```

---

### Task 4.3: Shop Approval Queue & Document Inspector
Implement `ShopApprovalsView` logic in `lib/features/admin/presentation/views/shop_approvals_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopApprovalsView extends StatelessWidget {
  const ShopApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .where('is_verified', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final shop = docs[index].data() as Map<String, dynamic>;
            final shopId = docs[index].id;

            return ListTile(
              title: Text(shop['shop_name'] ?? 'Unnamed Shop', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${shop['city']} • Phone: ${shop['phone_number']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Inspect documents in modal dialog
                    },
                    child: const Text('Inspect Docs'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B1E5C)),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('shops')
                          .doc(shopId)
                          .update({'is_verified': true});
                    },
                    child: const Text('Approve Shop'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

---

### Task 4.4: Centralized Blacklist & Reversal Tribunal
Implement instant fraud reporting and admin reversal in `lib/features/blacklist/data/datasources/blacklist_remote_data_source.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BlacklistRemoteDataSource {
  final FirebaseFirestore firestore;

  BlacklistRemoteDataSource(this.firestore);

  // Instant owner report: immediately flags customer across network
  Future<void> reportCustomerToBlacklist({
    required String reportedByShopId,
    required String cnicNumber,
    required String phoneNumber,
    required String reasonCategory,
    required String description,
    required List<String> evidenceUrls,
    String? customerUid,
  }) async {
    final batch = firestore.batch();
    final docRef = firestore.collection('blacklists').doc();

    batch.set(docRef, {
      'blacklist_id': docRef.id,
      'reported_by_shop_id': reportedByShopId,
      'cnic_number': cnicNumber,
      'phone_number': phoneNumber,
      'reason_category': reasonCategory,
      'description': description,
      'evidence_urls': evidenceUrls,
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
    });

    if (customerUid != null) {
      batch.update(firestore.collection('users').doc(customerUid), {
        'is_blacklisted': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Super Admin exclusive reversal
  Future<void> revertBlacklistRecord({
    required String blacklistId,
    required String adminUid,
    required String justification,
    String? customerUid,
  }) async {
    final batch = firestore.batch();

    batch.update(firestore.collection('blacklists').doc(blacklistId), {
      'is_active': false,
      'reverted_by_admin': adminUid,
      'reverted_reason': justification,
      'reverted_at': FieldValue.serverTimestamp(),
    });

    if (customerUid != null) {
      batch.update(firestore.collection('users').doc(customerUid), {
        'is_blacklisted': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
```

---

### Task 4.5: Exhaustive UI Overflow & Quality Assurance Test Suite
Implement automated regression test in `test/features/ui_overflow_regression_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import '../../core/test_harness.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/vehicle_detail_view.dart';
import 'package:rentalhub/features/payments/presentation/views/upload_payment_proof_view.dart';
import 'package:rentalhub/features/handover/presentation/views/vehicle_handover_view.dart';

void main() {
  group('UI Overflow & Responsiveness Tests Across Viewports', () {
    final screens = [
      {'name': 'Customer Home', 'widget': const CustomerHomeView()},
      {'name': 'Vehicle Detail', 'widget': const VehicleDetailView()},
      {'name': 'Payment Proof Upload', 'widget': const UploadPaymentProofView()},
      {'name': 'Vehicle Handover', 'widget': const VehicleHandoverView()},
    ];

    for (final screen in screens) {
      testWidgets('${screen['name']} renders with zero overflow on small screen (360x640) with 1.35x text scale', (tester) async {
        await TestHarness.pumpScreenWithOverflowCheck(
          tester: tester,
          screen: screen['widget'] as Widget,
          width: 360.0,
          height: 640.0,
          textScale: 1.35,
        );
      });
    }
  });
}
```

---

### Task 4.6: Bilingual (English LTR & Urdu RTL) Localization Audit
Verify `MaterialApp` localization configuration in `lib/main.dart`:

```dart
MaterialApp.router(
  routerConfig: AppRouter.router,
  locale: currentLocale, // Locale('en') or Locale('ur')
  supportedLocales: const [
    Locale('en', 'US'),
    Locale('ur', 'PK'),
  ],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
);
```

---

## 5. Production Build & Deployment Commands

### 5.1 Android Mobile Release Compilation
```bash
# Clean and fetch dependencies
flutter clean
flutter pub get

# Build production Android APK
flutter build apk --release --split-per-abi

# Output binary location:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### 5.2 Flutter Web Admin Panel Compilation & cPanel Deployment
```bash
# Build optimized web bundle
flutter build web --release --base-href "/admin/"

# Deploy to cPanel via FTP / SSH rsync:
# Upload contents of 'build/web/' to 'public_html/admin/'
```

Configure `public_html/admin/.htaccess` to preserve GoRouter SPA routing on page reload:
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /admin/
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /admin/index.html [L]
</IfModule>
```

---

## 6. Phase 4 Quality Gates & Deliverables

- [ ] Flutter Web Admin builds and runs on cPanel with working GoRouter SPA subpaths.
- [ ] Single `super_admin` master login operational.
- [ ] Blacklist flag applies instantly across network and reverts cleanly under Super Admin audit.
- [ ] All UI overflow test suites pass with zero overflow errors.
- [ ] Urdu RTL mirror layout displays native fonts without clipping.
- [ ] Production Android APK generated and signed.

---

## 7. Document Revision History
| Version | Date | Author / Agent | Change Type | Summary of Changes |
| :--- | :--- | :--- | :--- | :--- |
| **1.0.0** | 2026-10-31 | Lead Architect (Antigravity) | Initial Creation | Complete Phase 4 Detailed Implementation Plan for RentalHub. |
| **1.1.0** | 2026-11-01 | Lead Architect (Antigravity) | Type C & Type J | Linked cPanel Web Hosting deployment (.htaccess SPA rewrite rules) and mapped Stitch anchor screens ANC-17, ANC-18, ANC-19, and ANC-20. |
