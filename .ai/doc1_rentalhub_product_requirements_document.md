# DOC-1: Product Requirements Document (PRD)
## Project: RentalHub (`rentalhub`)

---

## 1. Executive Summary & One-Sentence Product Vision
**RentalHub** is an all-in-one digital car rental marketplace and fleet management ecosystem tailored for local car rental operators and renters, combining streamlined nearby vehicle discovery, on-screen digital rental contracts with touch signatures, manual payment verification via local Pakistani financial channels (JazzCash, EasyPaisa, Meezan Bank), offline-first inspection persistence, automated Meta WhatsApp Cloud API communications, and a centralized fraud prevention blacklist.

> **One-Sentence Product Vision**:  
> *"To eliminate paper-based rental fraud and operational friction for car rental businesses through digital agreements, localized manual payment auditing, verified-only WhatsApp communications, and a community-wide fraud prevention registry."*

---

## 2. User Personas, Roles & Access Matrix

RentalHub enforces a **strict single-role architecture** in the mobile app. Users choose their role during onboarding, which permanently locks their profile to that role.

### 2.1 Personas
1. **The Renter ("Customer")**: Individual seeking reliable self-drive or chauffeur-driven vehicles for personal, business, or inter-city travel within their vicinity. Demands verified shops, transparent hourly/daily packages, and rapid booking confirmation.
2. **The Rental Fleet Operator ("Owner")**: Local car rental business owner managing a fleet of 3 to 50+ vehicles. Needs digital vehicle tracking, walk-in and online reservation management, paperless legal agreements with customer signatures, and fraud protection against vehicle theft and non-payment.
3. **The Platform Master ("Super Admin")**: Platform owner managing platform health via Flutter Web on cPanel. Exercises sole oversight over shop verifications, subscription plan enforcement, dispute arbitration, and blacklist reversibility.

### 2.2 Role & Permission Matrix

| Feature / Action | Customer | Owner | Super Admin | Access Mechanism |
| :--- | :---: | :---: | :---: | :--- |
| Sign up (Google / Email+Password) | Yes | Yes | Pre-provisioned | Firebase Auth |
| Select Role (`customer` vs `owner`) | Once at Signup | Once at Signup | Locked | Firestore User Doc |
| Complete KYC (CNIC + Driving License) | Yes | Yes (Shop Docs) | N/A | Authenticated cPanel API |
| Browse Nearby Shops & Filter by Radius (1–5 km) | Yes | No | Yes (Directory) | Geolocator / Firestore GeoQuery |
| Submit Booking Request (Hourly / Full Day) | Yes | No | No | Firestore `bookings` |
| Upload Advance Payment Screenshot & TxID | Yes | No | No | Authenticated cPanel API |
| Chat via `wa.me` Direct WhatsApp Button | Yes (Verified only) | Yes | No | Deep Link with KYC Guard |
| Manage Fleet (Add/Edit/Archive Cars) | No | Yes | Yes (Read/Ban) | Firestore `vehicles` |
| Manual Walk-in Customer Booking | No | Yes | No | Firestore `bookings` |
| Conduct Vehicle Handover & Capture Photos | No | Yes | No | Local Cache + Firestore |
| Capture On-Screen Dual Signatures | Yes (Signee) | Yes (Signee) | No | Canvas Controller |
| Generate Printable A4 PDF Rental Agreement | Automated | Automated | View / Download | Flutter `pdf` + cPanel API |
| Approve / Reject Payment Invoices | No | Yes | Audit Log | Firestore State Machine |
| Flag Customer to Global Blacklist | No | Yes (Instant) | Full (Audit/Revert) | Firestore `blacklists` |
| Manage Shop Subscriptions (Freemium / Paid) | No | View / Upgrade | Full Management | Firestore `subscriptions` |
| Review / Resolve Customer Disputes | View Status | View Status | Full Arbitrator | Firestore `disputes` |
| Broadcast Push Notifications | No | No | Full Broadcast | Firebase Cloud Functions + FCM |

---

## 3. Goals, Success Metrics & Key Performance Indicators (KPIs)

| Business Goal | Measurable KPI | Target (Year 1) | Tracking Mechanism |
| :--- | :--- | :--- | :--- |
| **Paperless Digital Transformation** | % of handovers completed with digital signature & A4 PDF | > 95% of all rentals | Handover completion events in Firestore |
| **Fraud & Default Reduction** | Reduction in unpaid balances and vehicle absconding | > 80% decrease | Blacklist records & dispute ticket rates |
| **Rapid Onboarding** | Time required to register shop and list first 3 vehicles | < 7 minutes | Analytics funnel from auth to vehicle live |
| **High Payment Transparency** | Time from customer payment upload to owner verification | < 15 minutes average | Timestamp difference: `payment_uploaded` ➔ `payment_verified` |
| **Offline Reliability** | Handover success rate in zero-connectivity basements | 100% (zero lost data) | Local cache auto-sync queue audit |
| **Bilingual Adoption** | Monthly active users utilizing Urdu RTL layout | > 35% in Pakistan | User locale preference in settings |

---

## 4. Problem Statement & Market Opportunity
Traditional car rental operations in Pakistan and regional markets suffer from severe systemic vulnerabilities:
1. **Paper-based Handover Frauds**: Paper slips are easily forged, dispute-prone, and fail to capture high-resolution pre-existing vehicle damage.
2. **Fragmented Payment Proofs**: Rental shops receive advance payments via unlinked personal channels (JazzCash, EasyPaisa, bank IBAN) causing reconciliation chaos and booking disputes.
3. **No Centralized Blacklist**: Bad actors rent vehicles, default on charges, cause accidents, and move to the neighboring rental shop with zero friction.
4. **Communication Friction**: Customers demand immediate WhatsApp updates, yet shop owners get overwhelmed with non-verified spam inquiries.

**RentalHub’s Solution**: A unified digital platform providing instant geo-discovery, verified WhatsApp bridges, immutable digital contracts, localized manual transfer verification, and an instant community-wide fraud registry.

---

## 5. Detailed Functional Requirements

### Module 1: Authentication & Single-Role Onboarding
* **FR-1.1**: The application shall support authentication via **Google Sign-In** and **Email & Password** using Firebase Authentication.
* **FR-1.2**: Upon first login, users must complete a compulsory Onboarding Wizard where they select their immutable role: `Customer` or `Owner`.
* **FR-1.3**: Role selection is strictly one-way and cannot be toggled in the UI. A user desiring a different role must register a separate account.
* **FR-1.4**: Customer onboarding requires: Full Name, WhatsApp Number (formatted with Pakistan country code `+92`), and Profile Picture.
* **FR-1.5**: Owner onboarding requires: Shop Legal Name, Owner Contact, Physical Address, City, Geo-coordinates, and Business Registration / Shop Front Photo.

### Module 2: Customer Discovery & Vehicle Catalog
* **FR-2.1**: The app shall capture GPS coordinates via `geolocator` and allow manual location override (e.g. "Gulberg III, Lahore").
* **FR-2.2**: The discovery engine shall display nearby verified rental shops within a selectable radius: **1 km, 2 km, 3 km, and 5 km**.
* **FR-2.3**: Customers can toggle between **List View** and **Map View** with visual pins indicating verified shops.
* **FR-2.4**: Shop profiles must display: Shop Name, Verified Badge, Rating, Address, Operating Hours, Available Fleet Count, and direct action buttons (Directions, Call, WhatsApp).
* **FR-2.5**: Fleet catalogs shall be filterable by vehicle category: **Sedan, SUV, Hatchback, Hiace, Luxury**.
* **FR-2.6**: Each vehicle card must display high-resolution photos, transmission (Auto/Manual), fuel type (Petrol/Diesel/Hybrid), seating capacity, AC status, and dual rate cards: **Self-Drive** vs **With-Driver**.

### Module 3: Booking Engine & Package Selection
* **FR-3.1**: The system shall support flexible rental package tiers configured by the owner:
  - **1 Hour Package**
  - **3 Hours Package**
  - **6 Hours Package**
  - **Full Day (24 Hours) Package**
* **FR-3.2**: Vehicle pricing must support distinct rate schedules for **In-City** vs **Out-of-City** travel.
* **FR-3.3**: The customer selects pickup date/time, return date/time, rental package, self-drive/with-driver option, and optional special requests.
* **FR-3.4**: Upon submission, the booking is created in `status: requested` and the shop owner receives an instant FCM push notification and WhatsApp alert.

### Module 4: Manual Payment Verification Workflow
* **FR-4.1**: Owners can register up to 3 payout accounts in their shop profile:
  - **JazzCash Mobile Account** (Account Number, Account Title)
  - **EasyPaisa Mobile Account** (Account Number, Account Title)
  - **Bank Account / Meezan Bank** (Bank Name, Account Title, 24-character IBAN)
* **FR-4.2**: Once an owner approves a booking request (`status: approved`), the customer UI reveals the owner's payment accounts and specifies the **Required Advance Amount** (e.g. PKR 1,000) and **Remaining Balance Due at Pickup**.
* **FR-4.3**: The customer executes the transfer via their mobile banking app, uploads the payment screenshot (JPEG/PNG) to cPanel storage, and inputs the unique **Transaction ID (TxID)**.
* **FR-4.4**: The owner reviews the uploaded screenshot and TxID. If confirmed, the owner taps **"Verify Payment"**, shifting the booking to `status: paid`, which unlocks pickup instructions, shop navigation directions, and the pickup countdown timer.
* **FR-4.5**: If the transaction is invalid, the owner taps **"Reject Payment"** with a mandatory reason, notifying the customer to re-upload proof within a 30-minute grace window before auto-cancellation.

### Module 5: Handover, Digital Inspection & Legal Agreement
* **FR-5.1**: Handover is initiated via the owner app when the customer arrives at the shop. The customer presents a digital booking QR code for the owner to scan.
* **FR-5.2**: The owner completes a mandatory digital inspection checklist:
  - Initial Odometer / Mileage Reading (numeric + meter photo).
  - Fuel Level Indicator (quarter fractions: 25%, 50%, 75%, 100% + meter photo).
  - Pre-existing scratches/dents (marked on a 4-quadrant vehicle schematic + up to 6 photo attachments).
  - Spare tire, jack, tool kit, and vehicle registration card verification toggles.
* **FR-5.3**: **Dual On-Screen Signatures**:
  - The customer signs on a dedicated touch canvas in the app.
  - The owner signs on the touch canvas.
* **FR-5.4**: **A4 PDF Rental Agreement Generation**:
  - The system compiles all booking details, customer KYC data, vehicle specs, inspection checklist, damage photos, terms of service, and vector signatures into a formatted, printable A4 PDF agreement.
  - The PDF is uploaded to secure cPanel storage.
  - A secure download link is automatically dispatched to the customer's WhatsApp via Meta Cloud API and made available in the app under "My Agreements".
* **FR-5.5**: The booking transitions to `status: on_trip`.

### Module 6: Vehicle Return, Settlement & Mutual Reputation
* **FR-6.1**: Upon vehicle return, the owner conducts the check-in inspection:
  - Return Odometer Reading (calculates extra mileage fee if daily limit exceeded).
  - Return Fuel Level (calculates fuel top-up penalty if returned lower than handover level).
  - Return Damage Inspection (photo capture of any new damages).
* **FR-6.2**: **Settlement Invoice**:
  - The app calculates: Remaining Rental Balance + Overtime Charges + Fuel Deficit + Damage Surcharges.
  - Owner records payment mode (Cash, JazzCash, EasyPaisa, Bank) and closes booking (`status: completed`).
* **FR-6.3**: **Dual-Sided Reputation & Review System**:
  - **Owner Rates Customer**: 4 rating dimensions (Car Care, On-Time Return, Payment Honesty, Behavior: 1–5 stars) + Quick tags (`Returned Clean`, `Paid on Time`, `Late Return`, `Fuel not refilled`) + Freeform comment.
  - **Customer Rates Shop & Vehicle**: Shop service rating (1–5 stars) + Vehicle condition rating (1–5 stars) + Review comment.

### Module 7: Trust, KYC Verification & Emergency SOS
* **FR-7.1**: **Customer KYC**: Customers upload high-resolution images of their **CNIC Front**, **CNIC Back**, and **Driving License**.
* **FR-7.2**: Documents are stored securely on cPanel with restricted token access. Shop owners can inspect verified badges and KYC status before approving bookings.
* **FR-7.3**: **Emergency SOS Module**: An active trip presents an SOS button. Tapping SOS prompts:
  - Instant direct call to the shop owner's verified phone.
  - Auto-generated WhatsApp message dispatch containing live GPS coordinates and emergency alert message.

### Module 8: Instant Global Blacklist & Fraud Prevention
* **FR-8.1**: If a customer commits severe fraud (vehicle theft attempt, willful non-payment, major unregistered damage, criminal conduct), the shop owner can flag the customer to the **Global Blacklist**.
* **FR-8.2**: The owner must supply: Offender CNIC, Phone Number, Incident Category (`absconding`, `unpaid_debt`, `severe_damage`, `fake_documents`), Description, and supporting photo evidence.
* **FR-8.3**: **Silent Immediate Enforcement**: The blacklist takes effect immediately across RentalHub. When any shop in the network looks up that CNIC or receives a booking request from that account, a prominent red banner displays: `BLACKLISTED - Risk Alert`.
* **FR-8.4**: To prevent malicious mass panic, no platform-wide broadcast alerts are pushed to users.
* **FR-8.5**: **Super Admin Reversibility**: The single `super_admin` possesses exclusive authority to review blacklist appeals, inspect evidence, and revert/remove blacklist records.

### Module 9: Shop Monetization & Subscription Plans
* **FR-9.1**: RentalHub operates purely on a **Fixed Subscription Plan** model. **Zero commission (0%)** is deducted from rental transactions.
* **FR-9.2**: **Freemium Tier (Basic)**: Free perpetual plan allowing small operators to list up to **3 active vehicles**.
* **FR-9.3**: **Pro Fleet Tier**: Paid monthly/annual plan allowing up to **15 active vehicles**.
* **FR-9.4**: **Enterprise Fleet Tier**: Paid plan allowing **unlimited vehicles**, priority listing in search radius, and advanced financial analytics.
* **FR-9.5**: Subscription upgrades and validity are managed and audited via the Admin Web Panel.

### Module 10: WhatsApp Messaging & Communications
* **FR-10.1**: All transactional WhatsApp notifications (booking confirmation, payment invoice received, handover PDF contract link, return settlement) are executed server-side via **Firebase Cloud Functions calling Meta Cloud API**.
* **FR-10.2**: **Direct `wa.me` Deep Link Button**:
  - The customer can tap "WhatsApp Owner" directly from the shop or vehicle page.
  - **Security Constraint**: The `wa.me` button is strictly disabled/hidden for unverified customers. Only customers with verified profiles can initiate direct chats with shop owners to prevent commercial spam.

### Module 11: Admin Web Control Panel (Flutter Web on cPanel)
* **FR-11.1**: The admin portal is built with Flutter Web and deployed as static assets to cPanel.
* **FR-11.2**: Access is restricted strictly to a **single master `super_admin` account** configured in Firestore.
* **FR-11.3**: Admin functionalities:
  - Shop verification approval/rejection queue with document inspector.
  - Global vehicle registry monitoring.
  - Centralized Blacklist registry with search and revert controls.
  - Platform-wide dispute tribunal and resolution tools.
  - Shop subscription tier assignment and tracking.
  - Push notification broadcasting to all customers or all owners.

---

## 6. Non-Functional Requirements (NFRs)

| Category | Requirement | Specification |
| :--- | :--- | :--- |
| **Security** | API Secret Protection | Zero Meta WhatsApp tokens or cPanel storage master keys embedded in Android client. All executed via Cloud Functions. |
| **Media Security** | Authenticated Storage Access | cPanel media files protected against public indexing/scraping; served strictly to authenticated in-app/admin sessions. |
| **Performance** | Screen Render Latency | All screen view first frames render in < 16ms (60 FPS); cold startup under 2.0s on mid-tier Android devices. |
| **Offline Reliability** | Local Persistence | Inspection checklists, signature vectors, and photos saved locally in offline SQLite/Hive cache; syncs automatically within 30s of reconnection. |
| **Localization** | Full Bilingual Support | Complete dynamic switching between **English (LTR)** and **Urdu (RTL)** with localized typography and mirror layouts. |
| **UI Robustness** | Overflow & Scale Guards | Zero layout overflow crashes across 4.5" to 7" screens, font scales from 0.85x to 1.35x, and active virtual keyboard states. |
| **Interaction** | Button Debounce & Feedback | All action buttons debounced at 400ms to eliminate duplicate requests; active state indicators during async executions. |

---

## 7. Out of Scope (Current Release)
The following capabilities are deliberately excluded from the current phase:
1. Native iOS application build (deferred to Phase 5).
2. Live telematics hardware GPS tracking / remote vehicle immobilizers (architecture prepared, feature deferred).
3. Third-party automated payment card gateways (all payments are localized manual bank/wallet transfers).
4. Multi-tenant admin hierarchy with regional moderator roles (single `super_admin` only).

---

## 8. User Stories & Detailed Acceptance Criteria

### US-1: Customer Submits Booking Request
* **As a** verified customer,  
* **I want to** select an hourly or daily package for an available vehicle and submit a booking request,  
* **So that** the shop owner can review my profile and approve my reservation.
```gherkin
Scenario: Customer requests 3-hour self-drive package
  Given the customer is authenticated and has a completed profile
  And the vehicle "Honda Civic 2021" has status "available"
  When the customer selects the "3 Hours" package for "2026-11-05 14:00"
  And toggles "Self Drive" and submits the request
  Then a new booking document is created in Firestore with status "requested"
  And the owner receives an FCM push notification and a WhatsApp alert
  And the customer screen transitions to "Request Sent: Waiting for Approval"
```

### US-2: Owner Approves and Customer Pays Advance
* **As a** shop owner,  
* **I want to** approve a customer request and provide my JazzCash/EasyPaisa/Meezan accounts,  
* **So that** the customer can transfer the advance payment.
```gherkin
Scenario: Customer uploads valid payment proof
  Given the booking is in status "approved"
  When the customer uploads a transfer receipt screenshot and enters TxID "TXN987654"
  Then the booking transitions to status "payment_submitted"
  And the owner can view the screenshot in their verification view
  When the owner clicks "Verify Payment"
  Then the booking status changes to "paid"
  And the customer dashboard unlocks the pickup countdown timer and QR code pass
```

### US-3: Offline Handover & Digital Contract Generation
* **As an** owner operating in a basement with zero cellular signal,  
* **I want to** perform the vehicle inspection, record fuel/mileage, and capture signatures offline,  
* **So that** the rental handover is completed seamlessly without internet dependency.
```gherkin
Scenario: Handover completed offline with auto-sync
  Given the Android device is in airplane mode
  When the owner records odometer "45200" and fuel "75%"
  And both customer and owner provide signatures on the touch canvas
  Then the inspection data, photo paths, and signatures are persisted to local offline cache
  And the booking displays a local status "handover_cached"
  When internet connectivity is restored
  Then the background sync engine pushes data to cPanel and Firestore
  And the compiled A4 PDF contract link is dispatched to customer WhatsApp
```

---

## 9. Finalized Business Rules & Operational Constraints

1. **Role Immutability**: Role assigned at onboarding is permanent. No self-service role toggling exists in the mobile app.
2. **Freemium Vehicle Limit**: The basic free tier enforces a strict hard ceiling of **3 vehicles** per shop. Adding a 4th vehicle requires an active Pro/Enterprise subscription verified by `super_admin`.
3. **Manual Transfer Window**: Customers have exactly **60 minutes** from request approval to upload advance payment proof. If no proof is uploaded within 60 minutes, the booking is automatically flagged as `cancelled_timeout`.
4. **Instant Blacklist Transparency**: Blacklist records are immediately queryable across all shops to prevent fraud. However, no public alerts or notifications are broadcasted to avoid defamation disputes.
5. **Verified-Only Direct WhatsApp**: The `wa.me` deep-link button is rendered inactive or hidden unless `user.is_verified == true` (verified CNIC/phone).
6. **No Platform Commission**: RentalHub takes 0% commission on rental transactions. Shop owners retain 100% of their earnings.

---

## 10. Document Revision History
| Version | Date | Author / Agent | Change Type | Summary of Changes |
| :--- | :--- | :--- | :--- | :--- |
| **1.0.0** | 2026-10-31 | Lead Architect (Antigravity) | Initial Creation | Complete PRD for RentalHub aligned with UI specifications and architecture decisions. |
