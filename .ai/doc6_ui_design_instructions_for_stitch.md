# DOC-6: UI Design Instructions for Stitch & AI UI Tools
## Project: RentalHub (`rentalhub`)

---

## 1. Global Design System Tokens

The RentalHub design system strictly adheres to the **authentic Project Requirements UI color scheme** (as specified in `.ai/project_requirements_ui/`), while adopting the **screen dimensional curvature and layout proportions** from [ui_ref.jpg](file:///e:/Commercial/Gari%20App/.ai/project_requirements_ui/ui_ref.jpg).

### 1.1 Color Tokens (Light & Dark Theme)

| Token Name | Light Mode Value | Dark Mode Value | Usage Context |
| :--- | :--- | :--- | :--- |
| `primaryDark` | `#16194F` (Midnight Navy Dark) | `#0B0D26` (Obsidian Navy) | Header gradients, brand crowns, top bars |
| `primary` | `#1B1E5C` (Royal Navy Blue) | `#252B7A` (Deep Royal Navy) | Primary brand color, headers, title bars |
| `primaryLight` | `#EEF0FF` (Lavender Mist) | `#1A1D42` (Muted Navy Container)| Highlight cards, selected tabs |
| `secondary` | `#F95700` (Vibrant Sunset Orange) | `#FF6D24` (Bright Orange) | Primary CTA buttons ("Book Now", "Pay Advance", "Confirm") |
| `secondaryLight` | `#FFF3EB` (Soft Orange Mist) | `#3D1B08` (Dark Orange Tint) | Warning highlights, advance fee banners |
| `background` | `#F8FAFC` (Slate Off-White)| `#0A0B1A` (Midnight Dark Background) | Scaffold root background |
| `surface` | `#FFFFFF` (Pure White) | `#13152C` (Midnight Charcoal Surface) | Content cards, bottom sheets, dialogs |
| `surfaceElevated` | `#F1F5F9` (Light Slate) | `#1C1F3D` (Elevated Navy Surface)| Secondary cards, pill containers |
| `textPrimary` | `#0F172A` (Slate 900) | `#F8FAFC` (Slate 50) | Primary titles, price figures |
| `textSecondary` | `#64748B` (Slate 500) | `#94A3B8` (Slate 400) | Subtitles, specifications, hints |
| `borderSubtle` | `#E2E8F0` (Border Light) | `#23274D` (Border Dark) | Card dividers, input borders |
| `accentSuccess` | `#10B981` (Emerald Green) | `#34D399` (Bright Mint) | "Verified" badges, paid state |
| `accentDanger` | `#EF4444` (Ruby Crimson) | `#F87171` (Coral Red) | "Blacklisted" alert, error borders |

---

### 1.2 Typography Scale (Inter & Noto Nastaliq Urdu)
* **Font Family**: Primary Latin: `Inter` (Google Fonts); Urdu Script: `Noto Nastaliq Urdu`.

| Style Name | Size | Weight | Line Height | Letter Spacing | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 28px | Bold (700) | 34px | -0.5px | Hero greeting, balance display |
| `titleLarge` | 20px | Semi-Bold (600) | 26px | -0.2px | Section headers, shop names |
| `titleMedium` | 16px | Semi-Bold (600) | 22px | 0.0px | Vehicle titles, package labels |
| `bodyLarge` | 15px | Regular (400) | 22px | 0.0px | Primary form labels, descriptions |
| `bodyMedium` | 13px | Regular (400) | 18px | 0.0px | Vehicle specs (Seats, Fuel, AC) |
| `labelSmall` | 11px | Medium (500) | 14px | +0.5px | Status badges, distance pills |

---

### 1.3 Spacing, Radii & Elevation Shadows
* **Spacing Scale**: `4px` (xs), `8px` (sm), `12px` (md), `16px` (lg), `24px` (xl), `32px` (xxl).
* **Border Radii**:
  - Small elements (pills, badges): `8px`.
  - Cards, input fields, and standard buttons: `16px`.
  - Content containers overlapping header: `24px`.
  - Curved Header bottom edge: `28px` downward curve.
* **Elevation & Box Shadows**:
  - `Card Shadow`: `box-shadow: 0px 8px 24px rgba(27, 30, 92, 0.08);`
  - `Floating Nav Shadow`: `box-shadow: 0px -4px 20px rgba(0, 0, 0, 0.08);`

---

## 2. Screen Dimensional Specifications & Header Architecture

Directly conforming to the dimensional ratios of [ui_ref.jpg](file:///e:/Commercial/Gari%20App/.ai/project_requirements_ui/ui_ref.jpg):

```
+-------------------------------------------------------------+
|  [Status Bar: Transparent / Time: 9:30 / WiFi / Battery]    |
|                                                             |
|  (Avatar) [Hi, Ahmed Khan]                (Search) (Bell)   |
|  [Verified Badge]                                           |
|                                                             |
|  [Pill Switcher: Active Bookings  |  Past Trips]            |
|                                                             |
|  ~~~~~~~~~~~~ Curved Baseline Radius: 28px ~~~~~~~~~~~~~~~~ |
+-------------------------------------------------------------+
|    +---------------------------------------------------+    |
|    | FLOATING HERO CARD (Top Margin: -24px Overlap)    |    |
|    | Active Booking: Al-Falah Rent a Car               |    |
|    | Pickup Countdown: 01:45:20 | QR Pass CTA          |    |
|    +---------------------------------------------------+    |
|                                                             |
|    [Radius Filter Pills: 1 km | 2 km | 3 km | 5 km]         |
|    [Toggle Switch: List View | Map View]                    |
|                                                             |
|    [Section Header: Nearby Verified Shops]                  |
|    [Shop Cards: Al-Falah Rent a Car, 1.2 km away]           |
|                                                             |
+-------------------------------------------------------------+
|  [Floating Curved Bottom Bar: Home | Shops | Book | ... ]   |
+-------------------------------------------------------------+
```

### Key Dimensional Parameters:
1. **Header Height**: `230px` total vertical height (inclusive of `MediaQuery.padding.top`).
2. **Header Gradient**: `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF16194F), Color(0xFF242875)])`.
3. **Hero Overlap**: The primary active card uses `Transform.translate(offset: Offset(0, -28))` to overlap the curved header seamlessly.
4. **Bottom Navigation**: Raised floating bar with a centered action button (e.g. Scan QR / Book). Height: `68px`, margin: `16px`, corner radius: `32px`, primary Navy background with active Orange indicator.

---

## 3. Core Component Library Specifications

### 3.1 Buttons
* **Primary Action CTA**: Background `secondary` (`#F95700` Vibrant Orange), text white, height `54px`, radius `16px`. Used for "Book Now", "Pay Advance", "Confirm Location", "Submit Proof". Debounced by 400ms.
* **Secondary / Brand Button**: Background `primary` (`#1B1E5C` Midnight Navy), text white, height `54px`, radius `16px`. Used for "View Shop", "My Bookings", "Directions".
* **Outline / Ghost Button**: Border `1.5px solid #1B1E5C`, transparent background, text `#1B1E5C`.
* **WhatsApp Button**: Background `#25D366`, white icon + label, height `44px`, radius `12px`. Conditional: only active for verified users.

### 3.2 Form Inputs & Text Fields
* Height: `52px`, background `surface`, border `1px solid #E2E8F0`, focused border `2px solid #1B1E5C`.
* Prefix icon in `textSecondary`, clean error text below field.

### 3.3 Status Badges
* **Verified Badge**: Emerald pill, icon `check_circle`, label "Verified", background `#EEFDF5`, text `#10B981`.
* **Blacklisted Badge**: Crimson banner, icon `warning`, label "BLACKLISTED - Risk Alert", background `#FEE2E2`, text `#EF4444`.
* **Pending / In Review**: Amber pill, label "Pending Review", background `#FEF3C7`, text `#D97706`.

---

## 4. Core Anchor Screens Architecture & Pattern Coverage Matrix

To maximize design fidelity while avoiding API quota exhaustion and redundant generation of 132 micro-variation sub-states, RentalHub employs the **Core Anchor Screens Strategy**. Under this architecture, **20 master anchor screens** establish 100% of the UI design patterns, tokens, and widget hierarchies in Google Stitch. All remaining sub-states and dialogs derive directly from these anchors in Flutter code.

### 4.1 Master Anchor Matrix (20 Production Anchors)

| Anchor ID | Module | Screen Ref | Anchor Screen Title | Design Patterns Established | Generation Status | Local Artifact Deliverables |
| :-: | :---: | :---: | :--- | :--- | :---: | :--- |
| **ANC-01** | Customer | `C-07` | **Customer Discovery & Floating Nav** | 230px Curved Header, Floating Hero Overlap (-24px), Radius Chips, Verified Shop Cards, Floating Bottom Nav. | **`GENERATED`** | [01_customer_discovery.html](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.png) |
| **ANC-02** | Customer | `C-12` | **Vehicle Detail & Rent Packages** | Vehicle Studio Showcase, Spec Chips, Duration Package Grid (1h/3h/6h/24h), Sticky Orange Checkout Bar. | **`GENERATED`** | [02_vehicle_detail_packages.html](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.png) |
| **ANC-03** | Customer | `C-19` | **Upload Payment Proof (Advance)** | Payout Accounts List (JazzCash/EasyPaisa/Meezan), Notice Banner (#FFF3EB), Dashed Screenshot Dropzone, TxID Input. | **`GENERATED`** | [03_upload_payment_proof.html](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.png) |
| **ANC-04** | Customer | `C-15` | **Review & Send Reservation Request** | Pricing Breakdown Card, Security Advance Calculation, Special Host Notes Input, Advance Terms Notice. | **`GENERATED`** | [04_review_reservation_request.html](file:///e:/Commercial/Gari%20App/.stitch/04_review_reservation_request.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/04_review_reservation_request.png) |
| **ANC-05** | Customer | `C-20` | **Pickup Pass & Digital QR Pass** | Perforated Boarding Pass UI, Scannable QR Code, Realtime Countdown Timer, Map Directions Action. | **`GENERATED`** | [05_pickup_countdown_pass.html](file:///e:/Commercial/Gari%20App/.stitch/05_pickup_countdown_pass.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/05_pickup_countdown_pass.png) |
| **ANC-06** | Customer | `C-21` | **Customer Dashboard & Live Trip** | Active Trip Card, Emergency SOS Trigger, Multi-metric Stats (Trips/Trust/Spent), Quick Category Grid. | **`GENERATED`** | [06_customer_active_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/06_customer_active_dashboard.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/06_customer_active_dashboard.png) |
| **ANC-07** | Customer | `C-29` | **Identity Documents (KYC) Upload** | Multi-slot Private Document Upload, Verification Pills (Verified vs Pending), Camera Capture Surface. | **`GENERATED`** | [07_kyc_document_upload.html](file:///e:/Commercial/Gari%20App/.stitch/07_kyc_document_upload.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/07_kyc_document_upload.png) |
| **ANC-08** | Customer | `C-26` | **Rate Trip & Vehicle Condition** | Dual 5-Star Interactive Rating Bars, Quick Tag Feedback Pills, Verified Renter Review Submission. | **`GENERATED`** | [08_rate_trip_feedback.html](file:///e:/Commercial/Gari%20App/.stitch/08_rate_trip_feedback.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/08_rate_trip_feedback.png) |
| **ANC-09** | Owner | `O-01` | **Shop Onboarding & Payouts Setup** | Multi-step Stepper Header, Shop Physical Address & Landmark, Copyable Payout Account Configuration. | **`GENERATED`** | [09_owner_shop_onboarding.html](file:///e:/Commercial/Gari%20App/.stitch/09_owner_shop_onboarding.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/09_owner_shop_onboarding.png) |
| **ANC-10** | Owner | `O-04` | **Owner Fleet Dashboard & KPIs** | 2x2 Dark Metric Cards, Live Vehicles on Road Counter, Cash Flow Ticker, Fast Action Navigation. | **`GENERATED`** | [10_owner_fleet_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/10_owner_fleet_dashboard.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/10_owner_fleet_dashboard.png) |
| **ANC-11** | Owner | `O-05` | **Fleet Inventory Management** | Vehicle Status Chips (Available/Rented/Maintenance), Fleet Card Layout, Quick Rate Modifier. | **`GENERATED`** | [11_owner_fleet_inventory.html](file:///e:/Commercial/Gari%20App/.stitch/11_owner_fleet_inventory.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/11_owner_fleet_inventory.png) |
| **ANC-12** | Owner | `O-07` | **Add Vehicle Wizard & Rate Matrix** | In-City vs Out-of-City Tier Grid, Self-Drive vs Chauffeur Toggles, Freemium 3-Car Usage Guard. | **`GENERATED`** | [12_owner_rate_matrix.html](file:///e:/Commercial/Gari%20App/.stitch/12_owner_rate_matrix.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/12_owner_rate_matrix.png) |
| **ANC-13** | Owner | `O-09` | **Incoming Booking Requests Triage** | Customer Trust Score Card, NADRA Verification Audit, One-tap Approve / Decline Controls. | **`GENERATED`** | [13_owner_booking_requests.html](file:///e:/Commercial/Gari%20App/.stitch/13_owner_booking_requests.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/13_owner_booking_requests.png) |
| **ANC-14** | Owner | `O-12` | **Vehicle Handover & Dual Signatures** | Odometer/Fuel Gauge Pickers, 4-Quadrant Damage Wireframe, Dual Touch Signature Canvas, PDF Generation CTA. | **`GENERATED`** | [14_vehicle_handover_signature.html](file:///e:/Commercial/Gari%20App/.stitch/14_vehicle_handover_signature.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/14_vehicle_handover_signature.png) |
| **ANC-15** | Owner | `O-14` | **Vehicle Return & Settlement Balance** | Odometer/Fuel Differential Calculator, Penalty Surcharge Matrix, Final Cash Settle Voucher. | **`GENERATED`** | [15_owner_return_settlement.html](file:///e:/Commercial/Gari%20App/.stitch/15_owner_return_settlement.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/15_owner_return_settlement.png) |
| **ANC-16** | Owner | `O-16` | **Fraud Blacklist Reporting Desk** | High-Risk Alert Theme, Incident Category Picker, Police FIR Attachment, Instant Platform Blacklist Gate. | **`GENERATED`** | [16_owner_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/16_owner_fraud_blacklist.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/16_owner_fraud_blacklist.png) |
| **ANC-17** | Admin | `A-02` | **Super Admin Operations Dashboard** | 1440px Desktop Grid, Midnight Navy Sidebar, Platform Telemetry KPI Cards, Two-Column Live Table. | **`GENERATED`** | [17_admin_web_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/17_admin_web_dashboard.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/17_admin_web_dashboard.png) |
| **ANC-18** | Admin | `A-03` | **Shop Accreditation Queue & Doc Modal** | Desktop Verification Table, SECP/NTN Inspection Viewer, Compliance Approval Modal. | **`GENERATED`** | [18_admin_shop_accreditation.html](file:///e:/Commercial/Gari%20App/.stitch/18_admin_shop_accreditation.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/18_admin_shop_accreditation.png) |
| **ANC-19** | Admin | `A-05` | **National Blacklist Registry & Tribunal** | Centralized Fraud Registry, National CNIC Search Bar, Dispute Inquest & Admin Revert Overrides. | **`GENERATED`** | [19_admin_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/19_admin_fraud_blacklist.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/19_admin_fraud_blacklist.png) |
| **ANC-20** | Admin | `A-08` | **Platform Disputes & Subscriptions** | Dispute Arbitration Tribunal, Evidence Comparison Drawer, Host Freemium & Subscription Quota Control. | **`GENERATED`** | [20_admin_subscription_tiers.html](file:///e:/Commercial/Gari%20App/.stitch/20_admin_subscription_tiers.html) • [PNG](file:///e:/Commercial/Gari%20App/.stitch/20_admin_subscription_tiers.png) |

---

## 5. Production Screen Generation Prompts for Stitch

Prompts are organized section-wise into **Customer App Screens**, **Owner App Screens**, and **Super Admin Web Panel Screens**. Each prompt contains complete, production-ready UI specifications for Google Stitch (`generate_screen_from_text`). Core Anchor screens are designated with the `[CORE ANCHOR]` tag.

---

### 5.1 Section A: Customer App Screens (35 Screens)

#### [C-01] Splash Screen (`/splash`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a modern mobile splash screen for "RentalHub" on an Android device (393x852).
Background: Deep midnight navy (#16194F to #1B1E5C) full-screen linear gradient.
Center Content:
- Glowing modern logo icon featuring a stylized car silhouette merged with a location pin in vibrant sunset orange (#F95700) and crisp white (#FFFFFF).
- App title "RentalHub" in bold, elegant typography (32px, white).
- Subtitle: "Pakistan's Trusted Car Rental Network" in soft lavender (#EEF0FF, 14px).
Bottom: Sleek modern dot activity indicator with subtle pulsing glow and version label "v1.0.0 • Secured with Firebase".
```

#### [C-02] Sign In with Google / Email (`/auth/login`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an authentication login screen for "RentalHub - Welcome Back" on an Android device (393x852).
Header: Curved app bar (230px, 28px bottom border radius) with deep midnight navy gradient (#16194F to #242875). Inside the header: white RentalHub logo, title "Welcome Back", and subtitle "Sign in to book or manage your rentals".
Content Body (overlapping header by 24px on white card):
- Social Auth Button: Full-width elevated white button with official Google "G" logo: "Continue with Google" (height 54px, 16px radius, subtle border #E2E8F0).
- Divider: "Or continue with email" with slate lines.
- Email Input Field: Label "Email Address", placeholder "name@domain.com", mail prefix icon.
- Password Input Field: Label "Password", placeholder "••••••••", lock prefix icon, eye toggle suffix.
- Forgot Password link in midnight navy (#1B1E5C) right-aligned.
- Primary CTA Button: Vibrant sunset orange (#F95700) button "Sign In" (height 54px, 16px radius).
- Bottom Text: "Don't have an account? Sign up" with orange highlight.
```

#### [C-03] Complete Customer Profile (`/onboarding/customer`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a profile completion onboarding screen for "RentalHub - Customer Profile Setup" on an Android device (393x852).
Header: Deep midnight navy (#16194F) curved header (28px radius) with back arrow and title "Complete Your Profile".
Content Body:
- Circular Avatar Picker: Center avatar (90px) with placeholder icon and a small vibrant orange camera edit badge.
- Full Name Field: "Ahmed Khan", person icon prefix.
- WhatsApp Number Field: "+92 300 1234567" with Pakistan flag icon and verification hint ("Used for instant booking updates & digital agreements").
- City Dropdown: Selector with "Lahore", "Karachi", "Islamabad", "Rawalpindi", "Faisalabad".
- CNIC Number Field: "35201-1234567-1" with ID card icon.
- Terms Checkbox: "I agree to RentalHub Terms of Service & Rental Safety Guidelines."
- Primary Action Button: Vibrant sunset orange (#F95700) button "Save & Find Cars".
```

#### [C-04] Set Location Prompt (`/customer/location-prompt`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a location discovery prompt screen for "RentalHub - Find Nearby Shops" on an Android device (393x852).
Background: Off-white slate background (#F8FAFC) with a soft map graphic pattern in the upper half.
Center Card: Floating elevated white card with 24px radius:
- Icon: Large pulsing location pin icon in deep midnight navy with vibrant orange center ring.
- Headline: "Find Rental Cars Near You" (24px, bold navy #0F172A).
- Description: "RentalHub uses your live location to display verified rental shops within 1 to 5 kilometers of your doorstep in Pakistan."
- Primary Button: Vibrant sunset orange (#F95700) full-width button "Use Current Location" with GPS target icon.
- Secondary Button: Outline navy button "Enter City / Area Manually".
- Guarantee text: "Your location is only shared during active bookings."
```

#### [C-05] Location Permission Modal (`Dialog`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a modern mobile permission dialog modal for "RentalHub - Allow Location Access" over a darkened background on Android.
Dialog Box: Centered rounded dialog (28px radius, white surface):
- Illustrated top icon: Stylized map badge with emerald shield and orange pin.
- Title: "Enable Precise Location" (20px, bold navy).
- Body: "To show available fleet, verified vendors in Gulberg / DHA, and calculate accurate distances, allow RentalHub to access device location."
- Action Buttons:
  * "While using the app" (Primary vibrant orange #F95700 button, 50px height).
  * "Only this time" (Soft lavender container #EEF0FF with navy text).
  * "Don't allow" (Text button in slate gray #64748B).
```

#### [C-06] Location Confirmed (Map Anchor) (`/customer/location-confirm`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a location confirmation screen for "RentalHub - Confirm Your Pickup Zone" on an Android device (393x852).
Full-screen interactive map centered on Lahore (Gulberg III) with clean custom map styling.
Top Overlay: Deep midnight navy pill with back button, current location text "Gulberg III, Main Boulevard, Lahore", and "Change" link.
Map Center: High-contrast pin with an orange dot and a circular animated radar pulse ring.
Bottom Floating Card (overlapping bottom 180px):
- Title: "Browsing Near Gulberg III"
- Subtitle: "18 verified rental shops within 3 km"
- Quick Radius Chips: "1 km", "2 km", "3 km" (selected in navy), "5 km".
- Primary Action CTA: Vibrant sunset orange (#F95700) button "Explore Available Fleet".
```

#### [C-07] Nearby Shops (List View & Discovery) (`/customer/home`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[STATUS: GENERATED & SAVED IN .STITCH/]`
* **Files**: [01_customer_discovery.html](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.html) | [01_customer_discovery.png](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.png)
* **Prompt**:
```text
Design a modern Android mobile screen for "RentalHub - Customer Discovery".
Theme: Deep Midnight Navy Blue (#16194F) and Crisp White palette with Vibrant Orange (#F95700) action accents.
Header: Immersive custom curved app bar with 28px bottom border radius. Deep midnight navy gradient (#16194F to #242875). Inside the header: circular user avatar with emerald verified checkmark, greeting text "Good afternoon, Ahmed", search icon, notification bell with vibrant orange badge.
Floating Hero Section: White rounded card overlapping the curved header by 24px with soft drop shadow, displaying "Active Booking" for "Al-Falah Rent a Car", countdown timer "01:45:20", car thumbnail of white Toyota Corolla, and action buttons "Show QR Pass" (navy outline) and "Directions" (vibrant orange).
Middle Section: Radius filter pills ("1 km", "2 km", "3 km", "5 km" active with navy background and white text), toggle switch for "List | Map".
List Content: Card for "Al-Falah Rent a Car", rating "4.7 (128 reviews)", distance badge "1.2 km away", "Verified" green badge, 12 cars available, and direct action icons for "Call" (navy) and "WhatsApp" (green).
Bottom Bar: Floating rounded bottom navigation bar with midnight navy background and vibrant orange active indicator for Home, Shops, Book (elevated center button), Bookings, and Profile.
Visual Style: High contrast, clean automotive aesthetic matching Pakistan car rental market.
```

#### [C-08] Nearby Shops (Interactive Map View) (`/customer/home/map`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an interactive map discovery screen for "RentalHub - Nearby Shops Map" on an Android device (393x852).
Full Screen Map with custom clean road vector styling showing street layout of Lahore.
Top Floating Overlay: Curved mini-header in deep midnight navy (#16194F) with back arrow, search bar "Search by car model or shop name", and filter button.
Map Markers: 4 custom map pins shaped like cars with navy bubbles; 1 active pin highlighted in vibrant sunset orange (#F95700) showing price "Rs 3,500/day".
Bottom Horizontal Carousel Card: Sliding preview card for the selected pin:
- Shop: "Al-Falah Rent a Car" with emerald verified badge.
- Distance: "1.2 km away • Gulberg III".
- Thumbnail: Red Honda Civic 2021.
- Rate: "Rs 3,500 / 3 hrs".
- Action Buttons: "View Garage" (navy button) and "WhatsApp" (green icon).
Floating Bottom Nav: Rounded floating navigation bar matching the design system.
```

#### [C-09] No Shop Found (Empty State) (`Subview`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an empty state discovery screen for "RentalHub - No Shops Found" on an Android device (393x852).
Header: Deep midnight navy curved header (28px radius) with title "Nearby Rental Shops" and active radius pill "1 km".
Content Body:
- Empty state illustration: Stylized radar scanner with zero car pings in soft lavender and slate tones.
- Title: "No Rental Shops Within 1 km" (22px, bold navy #0F172A).
- Subtitle: "We couldn't find any registered rental hosts within 1 km of your current pin in Model Town, Lahore."
- Action Buttons:
  * Primary Button: Vibrant sunset orange (#F95700) button "Expand Search Radius to 5 km".
  * Secondary Button: Outline navy button "Browse All Lahore Garages".
- Help text: "Are you a rental shop owner? Tap here to register your fleet."
```

#### [C-10] Shop Profile Page (`/customer/shop/:id`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a comprehensive shop profile screen for "RentalHub - Al-Falah Rent a Car" on an Android device (393x852).
Header: Hero photo of modern clean car showroom in Lahore with gradient overlay, back button, favorite heart button, and share icon.
Floating Shop Info Card (overlapping hero):
- Shop Name: "Al-Falah Rent a Car" with prominent emerald "VERIFIED VENDOR" badge.
- Rating & Stats: "★ 4.8 (142 reviews) • 18 Fleet Vehicles • 98% On-Time Handover".
- Physical Address: "Shop #4, Main Boulevard, Gulberg III, Lahore • 1.2 km away".
- Operating Hours: "Open 24/7 • Quick Pickup".
- Action Row: "Call Host" (Navy button) and "WhatsApp Host" (Emerald green button, active for verified user).
Content Tabs: Segmented tab bar ["Available Cars (18)", "Customer Reviews (142)", "Shop Policies & Deposit"].
Preview List: Category chips ("All", "Sedan", "SUV", "Hiace") and top car cards.
```

#### [C-11] Shop Available Fleet (Category Tabs) (`/customer/shop/:id/cars`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a fleet catalog screen for "RentalHub - Al-Falah Fleet" on an Android device (393x852).
Header: Deep midnight navy (#16194F) curved header with shop title "Al-Falah Fleet", search bar, and filter icon.
Category Filter Chips Row: Horizontal scrolling chips: "All (18)", "Sedan (8)" [selected in navy with orange dot], "SUV (4)", "Hiace / Van (3)", "Luxury (3)".
Car Grid / List: Vertical list of elevated white cards:
- Card 1: Toyota Yaris 2022 (White) • Automatic • Petrol • 5 Seats • "Rs 2,800 / 3 hrs" • "Rs 7,000 / day".
- Card 2: Honda Civic Oriel 2021 (Red) • Automatic • Sunroof • "Rs 3,500 / 3 hrs" • "Rs 9,000 / day".
- Card 3: Toyota Fortuner 2023 (Black) • 4x4 • 7 Seats • "Rs 8,000 / 3 hrs" • "Rs 22,000 / day".
Each card features high-res car photo, transmission badge, rating, and orange "Select Package" button.
```

#### [C-12] Vehicle Detail & Rent Packages (`/customer/car/:id`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[STATUS: GENERATED & SAVED IN .STITCH/]`
* **Files**: [02_vehicle_detail_packages.html](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.html) | [02_vehicle_detail_packages.png](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.png)
* **Prompt**:
```text
Design an Android mobile screen for "RentalHub - Vehicle Detail & Rent Packages".
Theme: Clean white surface with Deep Midnight Navy (#1B1E5C) typography and Vibrant Orange (#F95700) CTA buttons.
Top App Bar: Clean white bar with back arrow, heart favorite icon, and title "Honda Civic 2021".
Hero: High-resolution red Honda Civic sedan studio photo with subtle reflection.
Specs Row: Rounded soft gray chips with navy icons for "Automatic Transmission", "Petrol Engine", "5 Seats", "AC Chilled", "Bluetooth".
Rate Selection Section: Segmented toggle switch between "Self Drive (Rs 9,000/day)" and "With Driver (Rs 11,000/day)".
Rental Packages Grid: 4 selectable rounded cards:
- "1 Hour" -> "Rs 1,500"
- "3 Hours" -> "Rs 3,500" (Active selected with vibrant orange border and orange badge)
- "6 Hours" -> "Rs 6,000"
- "Full Day (24h)" -> "Rs 9,000"
Pickup Selector: Horizontal date picker showing day and date cards.
Sticky Bottom Bar: White container with total price "Rs 3,500" in bold midnight navy, primary vibrant orange CTA button "Book Now", and WhatsApp icon button.
```

#### [C-13] Choose Rent Package (1h/3h/6h/24h) (`/customer/book/:carId/pkg`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a package comparison screen for "RentalHub - Choose Rental Package" on an Android device (393x852).
Header: Deep midnight navy curved header (28px radius) with title "Select Rental Tier" and car summary pill "Honda Civic 2021".
Drive Mode Selector: Two full-width segmented cards:
- "Self-Drive": "Rent and drive yourself • CNIC & License required".
- "With Driver": "Chauffeur included • Fuel and toll separate".
Package Options Grid (2x2 layout):
- Card 1: "1 Hour Quick Trip" • Rs 1,500 • Ideal for local pickup/drop.
- Card 2: "3 Hours City Errand" • Rs 3,500 • [POPULAR] highlighted with orange border and badge.
- Card 3: "6 Hours Half Day" • Rs 6,000 • Free 80 km mileage included.
- Card 4: "24 Hours Full Day" • Rs 9,000 • Unlimited in-city driving.
Footer: Sticky bar displaying "Selected: 3 Hours (Rs 3,500)" and vibrant orange button "Proceed to Schedule".
```

#### [C-14] Booking Date & Time Picker (`/customer/book/:carId/time`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a date and time scheduling screen for "RentalHub - Select Trip Time" on an Android device (393x852).
Header: Deep midnight navy curved header (28px radius) with back arrow, step indicator "Step 2 of 3", and title "Schedule Pickup & Return".
Content Body:
- Calendar Widget: Modern calendar view for current month with selected start date and end date highlighted in navy and orange.
- Pickup Time Selector: Horizontal scrolling time slots: "09:00 AM", "10:00 AM", "02:00 PM" [selected in orange], "04:00 PM".
- Duration Summary: Elevated card calculating total trip hours ("3 Hours • Oct 29, 02:00 PM to 05:00 PM").
- Pickup Location Note: Shop pickup address "Al-Falah Motors, Gulberg III, Lahore" with map thumbnail.
- Sticky Bottom Bar: Total amount "PKR 3,500" and vibrant orange button "Review Reservation".
```

#### [C-15] Review & Send Reservation Request (`/customer/book/:carId/review`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a reservation review screen for "RentalHub - Review & Submit Request" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Review Booking Request".
Content Cards:
- Vehicle & Shop Card: Red Honda Civic 2021, "Al-Falah Rent a Car", 3-Hour package, Self-Drive.
- Schedule Card: Oct 29, 2024 • 02:00 PM - 05:00 PM (3 Hours total).
- Price Breakdown Card:
  * Rental Fee: PKR 3,500
  * Security Advance Required: PKR 1,000 (Payable upon owner approval)
  * Balance Due at Pickup: PKR 2,500
- Special Notes Input: Text area "Add a message or flight/train delay notice for host...".
- Advance Notice Banner: Soft orange container (#FFF3EB) explaining advance deposit policy.
- Bottom Bar: Sticky footer with primary vibrant orange (#F95700) button "Send Request to Host".
```

#### [C-16] Reservation Request Sent Confirmation (`/customer/book/success`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a success confirmation screen for "RentalHub - Request Sent" on an Android device (393x852).
Background: Clean slate background with subtle decorative burst in brand navy and orange.
Center Card: Floating white card with 24px radius:
- Animated green checkmark badge with subtle glow.
- Headline: "Reservation Request Sent!" (24px, bold navy).
- Booking Reference: "Booking #RH-84920".
- Status Pill: Amber pill "Waiting for Host Approval (Avg 12 mins)".
- Host Details: "Al-Falah Rent a Car" • Host phone "+92 300 1234567".
- WhatsApp Alert: "You will receive a notification and WhatsApp message once Muhammad Bilal confirms vehicle availability."
- Action Buttons:
  * "Message Host on WhatsApp" (Emerald green button with WhatsApp icon).
  * "Track Booking in My Trips" (Midnight navy outline button).
```

#### [C-17] Reservation Approved Screen (Advance Due) (`/customer/bookings/:id/approved`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a booking approved status screen for "RentalHub - Host Approved Your Booking" on an Android device (393x852).
Header: Deep midnight navy curved header (28px radius) with title "Booking Approved!" and green checkmark badge.
Content Body:
- Countdown Timer Card: "Advance Payment Window: 54 mins remaining to hold reservation".
- Vehicle Summary: Honda Civic 2021 • Al-Falah Rent a Car • Oct 29, 2:00 PM.
- Payment Request Card:
  * Total Rent: PKR 3,500
  * Required Advance Deposit: PKR 1,000 (Bold vibrant orange)
  * Remaining Balance: PKR 2,500 (Payable at vehicle handover)
- Payment Instructions: "Transfer PKR 1,000 to the owner's JazzCash, EasyPaisa, or Meezan Bank account and upload screenshot."
- Primary CTA Button: Full-width vibrant sunset orange (#F95700) button "View Owner Accounts & Pay Advance".
```

#### [C-18] Owner Payment Accounts Display (`/customer/payment/:id/accounts`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a payment accounts display screen for "RentalHub - Host Payout Accounts" on an Android device (393x852).
Header: Deep midnight navy curved header with back arrow and title "Transfer Advance (PKR 1,000)".
Content Body:
- Host Card: "Al-Falah Rent a Car" with verified checkmark and contact info.
- Account Option 1: JazzCash Wallet Card • Title: "Muhammad Bilal" • Number: "0300-1234567" • Copy Button.
- Account Option 2: EasyPaisa Wallet Card • Title: "Muhammad Bilal" • Number: "0333-9876543" • Copy Button.
- Account Option 3: Meezan Bank Card • Title: "Al-Falah Motors" • Account #: "01020304050607" • IBAN: "PK45MEZN0001020304050607" • Copy Button.
- Copy toast confirmation indicator.
- Footer Button: Vibrant sunset orange button "I Have Transferred - Upload Receipt".
```

#### [C-19] Upload Payment Proof (Advance) (`/customer/payment/:id/upload`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[STATUS: GENERATED & SAVED IN .STITCH/]`
* **Files**: [03_upload_payment_proof.html](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.html) | [03_upload_payment_proof.png](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.png)
* **Prompt**:
```text
Create a mobile app screen for "RentalHub - Upload Payment Proof" on an Android device (393x852).
Header: Deep midnight navy (#16194F to #242875) curved header (28px bottom border radius) with back button, screen title "Submit Advance Payment", and booking summary chip ("Booking #RH-84920 • Rs 1,000 Advance").
Content Body:
- Owner Bank & Wallet Accounts Card: Elevated white card displaying owner payout channels for "Al-Falah Rent a Car":
  * JazzCash: Account Title "Muhammad Bilal", Mobile Number "0300-1234567" with a sleek copy button.
  * EasyPaisa: Account Title "Muhammad Bilal", Mobile Number "0333-9876543" with copy button.
  * Meezan Bank: Title "Al-Falah Motors", Account # "01020304050607", IBAN "PK45MEZN0001020304050607" with copy button.
- Notice Banner: Soft orange container (#FFF3EB) with orange icon explaining: "Please deposit the required advance of PKR 1,000 to hold this vehicle reservation. Upload the transfer screenshot below for vendor verification."
- Screenshot Upload Card: Prominent dashed-border dropzone box with an upload cloud icon, "Tap to upload receipt / screenshot from gallery", supported formats "PNG, JPG up to 5MB".
- Transaction ID (TxID) Input Field: Rounded modern text input with label "Transaction Reference / TID (Optional but recommended)", placeholder "e.g. 2938472910".
- Bottom Bar: Sticky footer with a vibrant sunset orange (#F95700) primary button: "Submit Payment Proof for Approval".
```

#### [C-20] Pickup Countdown Pass & Digital QR (`/customer/bookings/:id/pass`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a digital boarding pass screen for "RentalHub - Vehicle Pickup Pass" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Your Rental Pass" and status pill "PAID & CONFIRMED".
Main Card: Elevated white boarding pass card with perforated dashed notch divider:
- Top Section: Large scannable QR Code centered with RentalHub mini logo, Booking #RH-84920.
- Countdown Clock: Digital timer displaying "01:28:45 until pickup" in bold midnight navy.
- Vehicle Specs: Honda Civic 2021 (LEA-4820), Red, Automatic.
- Shop Location: Al-Falah Rent a Car, Main Boulevard, Gulberg III, Lahore.
- Quick Actions: "Get Directions on Google Maps" (orange button) and "Call Host" (navy outline button).
- Security Notice: "Present this QR code to the shop host during physical handover."
```

#### [C-21] Customer Home Dashboard (Active Trips & Stats) (`/customer/dashboard`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an active dashboard screen for "RentalHub - Customer Dashboard" on an Android device (393x852).
Header: Deep midnight navy curved header (230px, 28px radius) with user avatar, greeting "Welcome back, Ahmed", verified badge, and notification bell.
Stats Row: 3 compact cards overlapping header: "Total Trips: 8", "Trust Score: 4.9 ★", "Saved Garages: 5".
Active Rental Banner: Elevated card showing live trip in progress: "Honda Civic 2021 • Return in 2h 15m • Host: Al-Falah Motors • Emergency SOS button".
Quick Action Grid: 4 square icons ("Book a Car", "My Documents", "Saved Shops", "Support FAQ").
Recommended Fleets Section: Horizontal scrolling list of top-rated sedans and SUVs in Lahore with orange price tags.
Floating Navigation Bar: Standard floating rounded navy navbar with orange active dot.
```

#### [C-22] My Bookings (Tabbed Status View) (`/customer/bookings`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a bookings management screen for "RentalHub - My Bookings" on an Android device (393x852).
Header: Deep midnight navy curved header with title "My Bookings" and search icon.
Segmented Tabs: Horizontal pills ["Active (1)", "Pending Approval (1)", "Completed (6)", "Cancelled (0)"].
Booking Cards List:
- Card 1 (Active): Honda Civic 2021 • Oct 29, 2:00 PM • Status "ON TRIP" (Emerald green) • Action "View Digital Pass & Contract".
- Card 2 (Pending): Toyota Yaris 2022 • Nov 02, 10:00 AM • Status "Awaiting Approval" (Amber) • Action "Cancel Request".
- Card 3 (Completed): Suzuki Swift 2023 • Oct 15 • Status "COMPLETED" • Rating "Rated 5.0 ★" • Action "Rent Again".
Each card features car photo, dates, total PKR, and quick actions.
```

#### [C-23] Wallet, Invoices & Activity Log (`/customer/wallet`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a financial ledger screen for "RentalHub - Wallet & Invoices" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Wallet & Payments" and total spent counter "PKR 48,500 Transacted".
Summary Card: White card overlapping header showing "Total Advance Deposits Paid", "Active Security Deposits: PKR 0", and "Download Statement".
Transaction History: Vertical list of receipts:
- "Advance Paid - Booking #RH-84920" • -PKR 1,000 • JazzCash • Oct 28 • Status "Verified".
- "Full Rental Settlement - Booking #RH-71930" • -PKR 9,000 • Cash at Shop • Oct 15.
- "Refund Processed - Booking #RH-60291" • +PKR 1,000 • EasyPaisa • Sep 22.
Each entry has a PDF receipt download icon.
```

#### [C-24] Help & Support FAQ Center (`/customer/support`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a support center screen for "RentalHub - Help & Support" on an Android device (393x852).
Header: Deep midnight navy curved header with title "24/7 Customer Support" and search input "Search questions or policies...".
Emergency Hotline Card: Elevated orange card (#FFF3EB) with emergency headset icon: "Immediate Roadside Assistance: 042-111-RENT-HUB".
Quick Contact Row: Two buttons: "Live WhatsApp Support" (emerald green) and "Call Support" (midnight navy).
FAQ Accordion Section: Expandable question cards:
- "How does the PKR 1,000 advance deposit work?"
- "What documents do I need to present at vehicle pickup?"
- "What happens if I return the car with less fuel?"
- "How do I report a vehicle defect or breakdown?"
```

#### [C-25] Complaint & Dispute Filing (`/customer/dispute/new`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a dispute filing screen for "RentalHub - File a Complaint" on an Android device (393x852).
Header: Deep midnight navy curved header with back arrow and title "File Platform Dispute".
Content Body:
- Booking Selector Dropdown: "Booking #RH-84920 (Honda Civic • Al-Falah Rent a Car)".
- Dispute Category Chips: Multi-choice pills ["Vehicle Condition Issue", "Security Deposit Dispute", "Overcharging / Hidden Fee", "Host Unresponsive", "Other"].
- Detailed Explanation Field: Multi-line text box "Describe what happened in detail...".
- Evidence Photo Upload: Grid of 3 photo upload boxes (damage photo, payment receipt, chat screenshot).
- Notice: "RentalHub Admin reviews disputes within 24 hours. Both parties will be contacted."
- Primary Action Button: Vibrant sunset orange (#F95700) button "Submit Dispute for Arbitration".
```

#### [C-26] Rate Your Trip & Vehicle Condition (`/customer/rate/:id`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a review screen for "RentalHub - Rate Your Trip" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Trip Completed" and car photo (Honda Civic 2021).
Content Body:
- Dual Rating Section:
  * Rating 1: "Host Service & Punctuality" (5 large interactive golden stars).
  * Rating 2: "Vehicle Condition & Cleanliness" (5 large interactive golden stars).
- Quick Compliment Chips: Selectable tags ["Clean Interior", "Chilled AC", "Smooth Handover", "Polite Host", "Accurate Fuel"].
- Review Comment Box: Text area "Share your experience with other renters...".
- Host Tip: "Help Al-Falah Motors maintain their Top Host ranking in Lahore."
- Bottom CTA: Vibrant sunset orange (#F95700) button "Submit Verified Review".
```

#### [C-27] Cancel Booking & Refund Policy Sheet (`/customer/cancel/:id`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a cancellation sheet for "RentalHub - Cancel Reservation" on an Android device (393x852).
Modal Card surface with top drag handle:
- Warning Header: Amber warning icon with title "Cancel Booking #RH-84920?".
- Policy Breakdown:
  * "Cancelled > 2 hours before pickup: 100% advance deposit refunded to your wallet."
  * "Cancelled < 2 hours before pickup: 50% cancellation fee applies."
- Reason Radio Group:
  * "Change of travel plans"
  * "Found alternative transport"
  * "Host requested cancellation"
  * "Vehicle not needed anymore"
- Action Buttons:
  * Crimson danger button "Confirm Cancellation & Process Refund".
  * Slate outline button "Keep My Reservation".
```

#### [C-28] Customer Profile & Security Center (`/customer/profile`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a customer profile screen for "RentalHub - My Account" on an Android device (393x852).
Header: Deep midnight navy curved header (230px, 28px radius) with user avatar (Ahmed Khan), verified badge, phone "+92 300 1234567", and edit profile button.
Trust Score Card (overlapping header): "Customer Trust Score: 4.9 / 5.0 ★ • 8 Trips Completed • Zero Violations".
Menu Navigation List:
- "My KYC Documents (CNIC & License: Verified)" with green checkmark.
- "Saved Garages & Fleets" (Chevron right).
- "Payment Methods & Invoices" (Chevron right).
- "App Language (English / اردو)" with language badge.
- "Emergency Roadside SOS" with red icon.
- "Log Out" (Slate gray text).
- "Delete Account" (Small muted link).
```

#### [C-29] My Documents (KYC CNIC & License Upload) (`/customer/documents`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a KYC document management screen for "RentalHub - Identity Verification" on an Android device (393x852).
Header: Deep midnight navy curved header with back arrow, title "Identity Documents (KYC)", and status badge "2 of 3 Uploaded".
Security Banner: Soft navy container (#EEF0FF) explaining: "Documents are stored securely on private servers and only shared with hosts during active bookings."
Document Upload Slots:
- Slot 1: "CNIC Front" • Status "Verified" (Emerald pill) • Thumbnail of ID card with green check.
- Slot 2: "CNIC Back" • Status "Verified" (Emerald pill) • Thumbnail with green check.
- Slot 3: "Driving License" • Status "Pending Upload" (Amber pill) • Dashed upload box with camera icon "Tap to snap original license photo".
Bottom CTA: Vibrant sunset orange (#F95700) button "Upload & Submit for Verification".
```

#### [C-30] Saved & Favorite Shops Directory (`/customer/saved-shops`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a saved shops directory screen for "RentalHub - Favorite Rental Shops" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Saved Rental Shops" and counter "4 Garages Saved".
Shop Cards List:
- Card 1: "Al-Falah Rent a Car" • Gulberg III, Lahore • 18 cars • Rating 4.8 ★ • "Call" and "WhatsApp" buttons.
- Card 2: "Crown Executive Motors" • DHA Phase 5, Lahore • 24 cars • Rating 4.9 ★ • "Call" and "WhatsApp" buttons.
- Card 3: "Model Town Car Rentals" • Model Town, Lahore • 9 cars • Rating 4.6 ★.
Each card features a filled red heart icon to unfavorite, showroom photo, and "Browse Fleet" navy button.
```

#### [C-31] Settings & English/Urdu Bilingual Switcher (`/customer/settings`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a settings screen for "RentalHub - App Preferences" on an Android device (393x852).
Header: Deep midnight navy curved header with back arrow and title "App Settings".
Settings Sections:
- Localization Card:
  * "App Language": Toggle switch between "English (US)" and "اردو (Urdu RTL)".
  * Preview text displaying greeting in selected language.
- Notification Preferences:
  * "WhatsApp Booking Updates" (Toggle switch ON).
  * "Push Notifications (Promotions & Reminders)" (Toggle switch ON).
  * "SMS Backup Alerts" (Toggle switch OFF).
- Security & Privacy:
  * "Biometric / Fingerprint Unlock" (Toggle switch).
  * "Privacy Policy & Data Security".
- App Info: "RentalHub Version 1.0.0 • Made with pride in Pakistan".
```

#### [C-32] Emergency SOS & Roadside Safety Sheet (`/customer/sos`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an emergency assistance sheet for "RentalHub - Emergency SOS" on an Android device (393x852).
Full screen safety interface with high-contrast alert aesthetics.
Header: Deep crimson red header (#EF4444) with pulsing shield icon and title "Emergency & Roadside SOS".
Location Banner: Real-time GPS coordinates: "Lat 31.5204° N, Long 74.3587° E • Near Main Market, Gulberg, Lahore".
Emergency Action Cards:
- Button 1 (Large Red Button): "Call Police Emergency (15)" with direct dialer trigger.
- Button 2 (Large Orange Button): "Call Rental Host (Al-Falah Motors: 0300-1234567)".
- Button 3 (Emerald Green Button): "Broadcast Live GPS Location via WhatsApp to Host".
- Button 4 (Navy Button): "RentalHub 24/7 Roadside Tow Truck Dispatch".
Offline Notice: "Emergency calling works directly via SIM cellular network without mobile data."
```

#### [C-33] Owner Feedback Scores on Customer (`Read-only sheet`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an owner feedback score sheet for "RentalHub - Host Ratings on Ahmed Khan" on an Android device (393x852).
Modal sheet surface in crisp white with navy typography:
- Header: Title "Host Feedback History" and overall customer score "4.9 / 5.0 ★".
- 4-Dimensional Metrics Bars:
  * "Vehicle Care & Cleanliness": 98% (5.0 ★)
  * "On-Time Return": 96% (4.9 ★)
  * "Payment Promptness": 100% (5.0 ★)
  * "Communication & Behavior": 98% (4.9 ★)
- Host Endorsement Quotes:
  * "Excellent customer, returned car spotless and on time." - Al-Falah Motors
  * "Very polite and verified individual. Highly recommended." - Crown Executive
- Trust Badge: "RentalHub Verified Good Driver".
```

#### [C-34] Customer Reputation & Trust Score Badge (`/customer/reputation`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a customer reputation screen for "RentalHub - Renter Trust Score" on an Android device (393x852).
Header: Deep midnight navy curved header with circular animated score meter: "4.9 / 5.0" in large bold numbers, subtitle "Elite Verified Renter".
Reputation Pillars Grid: 4 elevated cards:
- "8 Completed Trips" (Zero cancellations).
- "NADRA CNIC Verified" (Emerald checkmark).
- "Verified Driving License" (Emerald checkmark).
- "Zero Negative Reports" (Clean record).
Benefits Section: "Why your score matters: Instant booking approvals, waived security advance at select shops, priority luxury car access."
Share Button: "Share My Renter Profile Link".
```

#### [C-35] Customer Public Profile Card for Hosts (`Modal Sheet`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a host-facing customer profile sheet for "RentalHub - Renter Verification Card" on an Android device (393x852).
Modal sheet designed for rental shop owners reviewing an incoming reservation request:
- Renter Identity: Avatar of Ahmed Khan, CNIC "35201-******-1", Phone "+92 300 1234567" (Masked until approved).
- Verification Status: Emerald pill "NADRA & License Verified".
- Trust Rating: "4.9 ★ (8 host reviews)".
- Host Score Breakdown: Punctuality 5.0 ★ • Car Care 4.9 ★ • Payment 5.0 ★.
- Blacklist Check: Green badge "CLEAN RECORD - Not on National Rental Blacklist".
- Action Row: "Approve Booking Request" (Vibrant orange button) and "Decline" (Crimson outline button).
```

---

### 5.2 Section B: Owner App Screens (16 Core Screens covering the 72 Mockup Variations)

#### [O-01] Owner Role Selection & Shop Onboarding Step 1 (`/onboarding/owner/step1`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an owner onboarding screen for "RentalHub - Register Your Rental Shop" on an Android device (393x852).
Header: Deep midnight navy curved header (28px radius) with title "Register as Shop Owner" and subtitle "Step 1 of 3 • Basic Details".
Content Body:
- Shop Name Field: "Al-Falah Rent a Car", store icon prefix.
- Owner Full Name Field: "Muhammad Bilal", user icon.
- CNIC Number Field: "35201-9876543-1".
- Mobile / WhatsApp Number: "+92 300 1234567".
- City Selector: Dropdown showing "Lahore", "Karachi", "Islamabad".
- Trade License / SECP Registration (Optional): Upload box for business registration doc.
- Next Button: Vibrant sunset orange (#F95700) button "Next: Set Physical Location".
```

#### [O-02] Shop Physical Address & Geo-Pin Drop Step 2 (`/onboarding/owner/step2`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a shop location onboarding screen for "RentalHub - Pin Your Shop Location" on an Android device (393x852).
Interactive map occupying top 50% of the screen with a draggable shop pin icon.
Bottom Form Card (overlapping map):
- Title: "Shop Physical Address (Step 2 of 3)".
- Address Line 1: "Shop #4, Ground Floor, Al-Rehman Plaza".
- Area / Landmark: "Main Boulevard, Gulberg III".
- City: "Lahore".
- Geo-Coordinates Indicator: "Lat 31.5204°, Long 74.3587° (Accurate for 1-5km customer discovery)".
- Next Button: Vibrant sunset orange button "Next: Add Payout Accounts".
```

#### [O-03] Shop Payout Accounts Setup Step 3 (`/onboarding/owner/step3`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create an owner payout accounts setup screen for "RentalHub - Configure Payment Accounts" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Customer Payment Accounts (Step 3 of 3)".
Explanation Banner: "Enter accounts where customers will deposit advance payments. These will be shown on customer booking invoices."
Input Sections:
- JazzCash Account: Title "Muhammad Bilal", Mobile Number "0300-1234567".
- EasyPaisa Account: Title "Muhammad Bilal", Mobile Number "0333-9876543".
- Bank Account (Meezan / HBL / Alfalah): Bank Name "Meezan Bank", Title "Al-Falah Motors", Account # "01020304050607", IBAN "PK45MEZN0001020304050607".
- Complete Button: Vibrant sunset orange button "Complete Onboarding & Launch Dashboard".
```

#### [O-04] Owner Home Dashboard (Fleet KPIs, Active Rentals, Revenue) (`/owner/dashboard`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a fleet management dashboard screen for "RentalHub - Host Control Hub" on an Android device (393x852).
Header: Deep midnight navy curved header (230px, 28px radius) with shop title "Al-Falah Rent a Car", verified badge, active fleet counter "14 / 18 Cars on Road", and notification bell.
KPI Cards Grid (2x2 layout, overlapping header):
- "Active Rentals Today": 14 Cars (Bold white text on navy card).
- "Pending Booking Requests": 3 Requests (Orange badge).
- "Today's Advance Transacted": PKR 14,000.
- "Pending Handover Inspections": 2 Due.
Quick Actions Row: 4 circular icons ["Add Vehicle", "Manual Walk-in", "Check Blacklist", "View Bookings"].
Active Trips Feed: Scrolling list of live vehicles on road with countdown timers and customer names.
Floating Bottom Navigation: Dashboard, Requests, Fleet, Finance, Profile.
```

#### [O-05] Fleet Management Inventory (Vehicles List & Status) (`/owner/fleet`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a vehicle fleet inventory screen for "RentalHub - Garage Fleet" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Fleet Inventory (18 Cars)", search bar, and "+ Add Car" orange button.
Filter Pills: "All (18)", "Available (4)" [green dot], "Rented Out (14)" [orange dot], "In Maintenance (0)".
Vehicle Inventory Cards:
- Card 1: Honda Civic 2021 (LEA-4820) • Status "RENTED OUT until 6:00 PM" • Customer "Ahmed Khan" • "View Trip Details".
- Card 2: Toyota Corolla 2022 (ICT-9912) • Status "AVAILABLE IN SHOP" • "Book Walk-In Customer".
- Card 3: Suzuki Alto 2023 (LHR-1029) • Status "RENTED OUT until Tomorrow 10:00 AM".
Each card displays photo, registration plate, daily rate, and edit specs trigger.
```

#### [O-06] Add Vehicle Wizard - Step 1: Specs & Registration (`/owner/fleet/add/specs`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a vehicle creation wizard screen for "RentalHub - Add Vehicle (Step 1)" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Add Vehicle Specs (Step 1 of 3)".
Form Inputs:
- Make & Model Dropdowns: Make "Honda", Model "Civic Oriel", Year "2021".
- Category Selector: Chips for "Sedan", "SUV", "Hatchback", "Hiace / Van", "Luxury".
- Registration Number: "LEA-4820" (City: Lahore).
- Transmission Selector: Radio buttons "Automatic" vs "Manual".
- Fuel Type: "Petrol", "Diesel", "Hybrid".
- Seating Capacity: "5 Seats".
- Features Checkbox: "AC Chilled", "Airbags", "Bluetooth / Android Auto", "Sunroof".
Next Button: Vibrant sunset orange (#F95700) button "Next: Configure Rates & Packages".
```

#### [O-07] Add Vehicle Wizard - Step 2: Rate Schedules (`/owner/fleet/add/rates`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a pricing schedule configuration screen for "RentalHub - Set Vehicle Rates (Step 2)" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Rental Rates & Tiers (Step 2 of 3)".
Content Body:
- Drive Mode Toggle: Checkbox for "Allow Self-Drive" and "Allow With-Driver".
- In-City vs Out-of-City Rates:
  * In-City Daily Rate (24h): PKR "9,000".
  * Out-of-City Daily Rate (24h): PKR "12,000".
- Hourly Packages Setup:
  * 1 Hour Quick Trip Rate: PKR "1,500".
  * 3 Hours Standard Rate: PKR "3,500".
  * 6 Hours Half-Day Rate: PKR "6,000".
- Advance Security Deposit Required: PKR "1,000" (Default platform standard).
- Mileage Limits: "Unlimited in-city" or "Max 150 km/day (PKR 35/km extra)".
Next Button: Vibrant sunset orange button "Next: Upload Photos & Finalize".
```

#### [O-08] Add Vehicle Wizard - Step 3: Photos & Freemium Guard (`/owner/fleet/add/photos`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a vehicle photo upload screen for "RentalHub - Upload Vehicle Photos (Step 3)" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Vehicle Photos (Step 3 of 3)".
Photo Upload Slots (Grid layout):
- Slot 1 (Primary Front-Right Angle): Uploaded photo of red Honda Civic with "Cover Photo" badge.
- Slot 2 (Rear View): Uploaded photo slot.
- Slot 3 (Interior / Dashboard): Uploaded photo slot.
- Slot 4 (Odometer Cluster): Empty slot with "+ Add Photo" icon.
Freemium Tier Indicator:
- Soft navy card: "Free Tier Fleet Usage: 2 / 3 Cars Used. You have 1 free car slot remaining."
- Upgrade link: "Want to register more than 3 cars? Upgrade to Pro Host."
Submit Button: Vibrant sunset orange (#F95700) button "Save & Publish Car to Catalog".
```

#### [O-09] Incoming Booking Requests Triage (`/owner/requests`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a booking requests triage screen for "RentalHub - Incoming Booking Requests" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Incoming Requests (3 Pending)" and filter pills ["New Requests", "Approved", "All"].
Request Cards List:
- Card 1: Renter "Ahmed Khan" • Booking #RH-84920 • Requested "Honda Civic 2021" • Package "3 Hours (Today 2:00 PM - 5:00 PM)" • Total "PKR 3,500".
  * Customer Trust Score: "4.9 ★ • NADRA Verified • Clean Record".
  * Actions: "View Full Profile" (navy text), "Decline" (crimson outline), "Approve Request" (vibrant orange button).
- Card 2: Renter "Usman Ali" • Requested "Toyota Yaris" • Package "Full Day" • Trust Score "4.7 ★".
  * Actions: "Decline" and "Approve Request".
```

#### [O-10] Payment Verification Desk (`/owner/payment/verify/:id`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a payment review desk screen for "RentalHub - Verify Advance Payment" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Verify Advance Deposit" and booking chip "#RH-84920 • PKR 1,000".
Content Body:
- Renter Submitted Info: Renter "Ahmed Khan", submitted via "JazzCash", TxID "TX987654321".
- Payment Screenshot Inspector: Large high-resolution zoomable image preview of the customer's mobile banking transfer receipt showing PKR 1,000 sent to Muhammad Bilal.
- Quick Payout Account Reference: Card reminding owner of their registered JazzCash number 0300-1234567.
- Action Buttons:
  * Primary Button: Vibrant sunset orange (#F95700) button "Verify & Confirm Booking" (Generates QR Pass for customer).
  * Secondary Button: Crimson text button "Reject Receipt (Invalid TxID / Amount)".
```

#### [O-11] Walk-in Manual Booking Wizard (`/owner/manual-booking`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a walk-in manual reservation screen for "RentalHub - Walk-in Customer Entry" on an Android device (393x852).
Header: Deep midnight navy curved header with title "New Walk-in Reservation" and car selector dropdown.
Content Body:
- Vehicle Selector: "Honda Civic 2021 (Available Now)".
- Customer Phone & CNIC: "+92 300 9876543" and "35201-1234567-1".
- Instant Blacklist Check: Green badge "Instant Check: CNIC Clean • Not Blacklisted".
- Duration & Rate: "Full Day (24 Hours) • PKR 9,000".
- Advance Cash Collected: Input field "Cash Deposit Received: PKR 1,000".
- Balance Due: "PKR 8,000 upon return".
- Action Button: Vibrant sunset orange (#F95700) button "Proceed to Vehicle Handover Inspection".
```

#### [O-12] Vehicle Handover & On-Screen Dual Signatures (`/owner/handover/:bookingId`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[STATUS: GENERATED & SAVED IN .STITCH/]`
* **Files**: [04_vehicle_handover_signature.html](file:///e:/Commercial/Gari%20App/.stitch/04_vehicle_handover_signature.html) | [04_vehicle_handover_signature.png](file:///e:/Commercial/Gari%20App/.stitch/04_vehicle_handover_signature.png)
* **Prompt**:
```text
Create a mobile app screen for "RentalHub - Vehicle Handover & On-Screen Signature" on an Android device (393x852).
Header: Deep midnight navy (#16194F to #242875) curved header with back icon, screen title "Vehicle Handover Inspection", and active vehicle badge ("Honda Civic 2021 • LEA-4820").
Content Body:
- Inspection Metrics Row: Two compact elevated cards side by side:
  * Left Card: "Current Odometer" with icon speedometer, display "42,850 km", with a "Capture Cluster Photo" thumbnail button.
  * Right Card: "Fuel Level" with fuel pump icon, 8-segment fuel gauge selector with 6/8 segments filled ("75% Full Tank").
- 4-Quadrant Damage Inspection Schematic: An interactive vehicle diagram (Top View, Front, Rear, Left, Right sides) with 2 red pin markers indicating pre-existing scratches: "Pin 1: Scuff on front bumper (Photo attached)", "Pin 2: Light scratch left door".
- Agreement Terms Checkbox: Styled agreement consent checkbox: "I verify that the vehicle condition, odometer, and fuel level recorded above accurately represent the vehicle state at handover."
- On-Screen Touch Signature Pad: Double signature container:
  * Customer Signature Canvas: Smooth vector stroke signature pad with clear button and status "Ahmed Khan (Customer Signed)".
  * Vendor Signature Canvas: Signature pad with status "Muhammad Bilal (Host Signed)".
- Bottom Bar: Sticky footer with a vibrant sunset orange (#F95700) primary button: "Generate & Sign Digital Agreement (PDF)".
```

#### [O-13] Printable A4 Digital Legal Contract Preview (PDF) (`/owner/contract/:bookingId`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a document preview screen for "RentalHub - Printable A4 Rental Agreement" on an Android device (393x852).
Header: Deep midnight navy bar with back arrow, document title "Signed Agreement #RH-84920", and "Print / Share" icon.
Document Preview Area: Realistic rendering of an authentic printable A4 rental contract on crisp white paper with subtle page shadow:
- Top Header: RentalHub official logo + Al-Falah Motors showroom logo, NTN, and contact numbers.
- Table 1: Renter Information (Name: Ahmed Khan, CNIC: 35201-1234567-1, License: LHR-98765, Phone).
- Table 2: Vehicle Specs (Honda Civic 2021, LEA-4820, Engine #, Chassis #).
- Table 3: Handover Metrics (Odometer: 42,850 km, Fuel: 75% Full, 2 Scratches logged with photo thumbnails).
- Table 4: Financials (Total Rent: PKR 3,500, Advance Paid: PKR 1,000, Balance Due: PKR 2,500).
- Signature Boxes: Embedded vector signatures for Renter and Host with timestamp.
Bottom Action Bar: "Send PDF to Customer via WhatsApp" (Emerald green button) and "Save PDF" (Navy button).
```

#### [O-14] Vehicle Return Inspection & Overtime/Fuel Settlement (`/owner/return/:bookingId`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a vehicle return inspection screen for "RentalHub - Vehicle Return & Settlement" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Vehicle Return Inspection" and car badge "Honda Civic 2021 (LEA-4820)".
Metrics Comparison Cards:
- Odometer Card: Handover KM: "42,850 km" -> Return KM input: "42,920 km" (Distance driven: 70 km • Within limit).
- Fuel Level Card: Handover Fuel: "75% (6/8)" -> Return Fuel selector: "75% (6/8)" (Zero fuel deficit penalty).
- New Damage Check: Toggle "Any new damage observed during trip?" (Selected: No new damage).
Final Settlement Balance Card:
- Base Rental Balance Due: PKR 2,500
- Overtime / Late Charges: PKR 0
- Fuel Deficit Charges: PKR 0
- Total Cash to Collect: PKR 2,500 (Bold vibrant orange)
Action Button: Vibrant sunset orange (#F95700) button "Collect PKR 2,500 & Complete Rental".
```

#### [O-15] Rate Customer Performance & Trust Score Review (`/owner/rate-customer/:bookingId`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a host feedback screen for "RentalHub - Rate Renter (Ahmed Khan)" on an Android device (393x852).
Header: Deep midnight navy curved header with title "Rate Renter Experience" and customer avatar.
Rating Rubric (4 Star Categories):
- "Vehicle Care & Cleanliness" (5 Stars).
- "On-Time Return" (5 Stars).
- "Payment Behavior" (5 Stars).
- "Politeness & Trust" (5 Stars).
Quick Positive Tags: Multi-choice chips ["Returned Clean", "Punctual", "Followed Speed Rules", "Polite"].
Flag Risk Toggle: Muted red toggle switch "Report Customer for Severe Breach / Non-Payment".
Submit Button: Vibrant sunset orange (#F95700) button "Submit Host Review".
```

#### [O-16] Fraud Blacklist Reporting Desk (`/owner/blacklist/report`)
* **Device**: Mobile (Android, 393x852)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a fraud reporting screen for "RentalHub - Report Customer to Blacklist" on an Android device (393x852).
Header: Deep crimson red header (#EF4444) with warning icon and title "Report to National Rental Blacklist".
Warning Banner: Soft amber container: "Reporting a customer silently restricts their ability to rent from other shops across Pakistan. False reporting may lead to shop suspension."
Form Inputs:
- Customer CNIC: "35201-9918234-1" (Auto-populates if linked to booking).
- Customer Name: "Hamza Shafiq".
- Incident Reason Category: Dropdown ["Absconded with vehicle", "Unpaid balance > PKR 20,000", "Severe accident hit-and-run", "Tampered with GPS / Tracker", "Forged CNIC / License"].
- Incident Narrative: Text area describing details and dates.
- Evidence Photo Slots: Upload police report FIR copy, unpaid invoice, or damage photo.
Action Button: Crimson red button "Submit Blacklist Report for Super Admin Review".
```

---

### 5.3 Section C: Super Admin Web Panel Screens (10 Screens covering the 25 Desktop Views)

#### [A-01] Super Admin Login Screen (`/admin/login`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a responsive desktop login screen (1440x900) for "RentalHub - Super Admin Command Center".
Split Screen Layout:
- Left Column (40% width): Deep midnight navy (#16194F) branded showcase featuring RentalHub logo, title "RentalHub Admin Portal", subtitle "National automotive rental governance, NADRA KYC verification, and fraud tribunal", and glowing telemetry graph.
- Right Column (60% width): Crisp white surface with centered login card:
  * Title: "Super Admin Authentication" (24px, bold navy #0F172A).
  * Email Field: "superadmin@rentalhub.pk" with shield lock icon.
  * Password Field: "••••••••••••" with visibility toggle.
  * Security Notice: "Access restricted strictly to master administrative accounts."
  * Primary Action CTA: Vibrant sunset orange (#F95700) button "Authenticate & Enter Control Center" (height 52px).
```

#### [A-02] Executive Operations Control Dashboard (`/admin/dashboard`)
* **Device**: Desktop (1440x900)
* **Status**: `[STATUS: GENERATED & SAVED IN .STITCH/]`
* **Files**: [05_admin_web_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/05_admin_web_dashboard.html) | [05_admin_web_dashboard.png](file:///e:/Commercial/Gari%20App/.stitch/05_admin_web_dashboard.png)
* **Prompt**:
```text
Create a responsive desktop web dashboard (1440x900) for "RentalHub - Super Admin Web Panel".
Layout & Color Scheme:
- Left Sidebar: Deep midnight navy (#16194F) sidebar with RentalHub logo in white and orange, menu links: "Overview", "Shop Approvals (12 pending)", "Fleet Registry", "Blacklist & Fraud", "Financial Audits", "Settings", and bottom profile card "Master Super Admin (superadmin@rentalhub.pk)".
- Top Bar: Search bar for searching any CNIC, phone number, or booking reference, city selector (Lahore, Karachi, Islamabad), and notification bell.
- KPI Cards Row: 4 sleek dark cards with orange and emerald accent numbers:
  * "Total Verified Shops": 184 (+8 this week)
  * "Active Rentals Today": 412 vehicles
  * "Blacklisted CNICs": 29 records (1 under dispute)
  * "Pending Payout Verifications": 16 transactions
- Main Content Area (Two Columns):
  - Left Column: "Shop Approval Queue" data table displaying Shop Name, Owner CNIC, City, Registered Fleet, Trade Docs, and "Approve" (emerald) / "Reject" (crimson) action buttons.
  - Right Column: "Fraud Blacklist Central Tribunal" displaying recently flagged customers with CNIC, reason ("Absconded with vehicle / Unpaid balance"), reporting vendor, and "Admin Revert / Lift Ban" button.
```

#### [A-03] Shop Verification & Accreditation Queue (`/admin/shops`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a desktop accreditation queue view (1440x900) for "RentalHub - Shop Accreditation Queue".
Layout: Midnight navy sidebar on left + top bar with search and city filter.
Main Content:
- Header: "Shop Verification Queue (12 Pending Clearances)" with export CSV button.
- Comprehensive Data Table:
  * Columns: Shop Name, Owner Name & CNIC, City / Hub, Registered Fleet Count, Trade License / SECP, Submission Date, Compliance Status, Actions.
  * Row 1: "Lahore Wheels & Rentals" • M. Tariq (35201-8931201-9) • Lahore (Gulberg) • 24 Cars • SECP Verified • "Inspect Documents" (Navy button) • "Approve" (Emerald) • "Reject" (Crimson).
  * Row 2: "Capital Cruisers" • Usman Shah • Islamabad (F-10) • 18 Cars • Police Character Pending.
  * Row 3: "Karachi Coastline Drive" • Farhan Ali • Karachi (Clifton) • 35 Cars • All Docs Clean.
- Pagination controls: "Showing 1 to 10 of 12 pending shops".
```

#### [A-04] Shop Detailed Inspection & Document Viewer Modal (`/admin/shops/:id`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a desktop document audit modal (1440x900) for "RentalHub - Shop Document Inspector".
Modal Dialog centered over admin dashboard:
- Header: "Audit Registration: Al-Falah Rent a Car (Lahore)" with close icon.
- Split View Layout:
  * Left Panel (45% width): Business Dossier (NTN, Trade License #, Shop Geo-Coordinates on embedded map, Owner CNIC Front/Back photos, Registered Fleet list).
  * Right Panel (55% width): High-resolution zoomable PDF/Image viewer showing original SECP incorporation certificate.
- Decision Action Bar:
  * "Accredit & Grant Verified Badge" (Emerald green button).
  * "Request Resubmission (e.g. Unclear CNIC)" (Amber button).
  * "Reject & Ban Registration" (Crimson button).
```

#### [A-05] Centralized Fraud Blacklist Registry & Tribunal (`/admin/blacklist`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a desktop fraud registry screen (1440x900) for "RentalHub - National Rental Blacklist".
Layout: Midnight navy sidebar on left + top bar.
Main Content:
- Header: "National Rental Blacklist Registry (29 Records)" with "+ Manual Add CNIC" red button.
- Search Bar: "Search by CNIC (35201-xxxxxxx-x) or Phone Number".
- Registry Data Table:
  * Columns: Flagged CNIC, Full Name, Reporting Rental Shop, Offense Summary, Evidence Files, Flagged Date, Status, Admin Overrides.
  * Row 1: "35201-9918234-1" • Hamza Shafiq • Al-Falah Rent a Car • Absconded with car / unpaid PKR 85,000 • FIR Copy attached • Active Ban • "Admin Revert / Lift Ban" button.
  * Row 2: "42201-5501928-7" • Zubair Ahmed • Rehman Motors • Tampered GPS tracker • Active Ban • "Admin Revert" button.
- Admin Revert Confirmation Dialog preview in corner with reason input.
```

#### [A-06] National Vehicle Fleet Live Telemetry Monitor (`/admin/fleet`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a desktop fleet monitoring view (1440x900) for "RentalHub - National Fleet Telemetry".
Layout: Standard midnight navy sidebar + map view occupying right main area.
Top Controls: City selector ("All Pakistan", "Lahore", "Karachi", "Islamabad"), Category filter ("Sedan", "SUV", "Luxury"), Status filter ("On Trip (412)", "Available (820)").
Main Dashboard:
- Interactive Pakistan Map with cluster pins showing vehicle concentrations across Lahore, Rawalpindi, Islamabad, Karachi.
- Sliding Fleet Drawer: Table showing live vehicle registration (LEA-4820), host shop, active renter, trip start time, and estimated return time.
```

#### [A-07] Platform Disputes & Arbitration Resolution Tribunal (`/admin/disputes`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a desktop dispute tribunal screen (1440x900) for "RentalHub - Dispute Arbitration Tribunal".
Main Content:
- Header: "Active Disputes & Support Escalations (4 Cases)" with urgency tags.
- Dispute Case Cards:
  * Case 1: "Dispute #DSP-1092 • Booking #RH-84920"
  * Complainant: Ahmed Khan (Customer) vs Al-Falah Rent a Car (Shop).
  * Issue: "Customer claims PKR 1,000 advance not refunded after timely cancellation."
  * Evidence Tabs: Customer WhatsApp Chat, Bank Screenshot, Shop Cancellation Timestamp.
  * Administrative Judgment Actions: "Force Refund PKR 1,000 from Host Wallet", "Uphold Host Retention Policy", "Dismiss Dispute".
```

#### [A-08] Shop Subscription Plans & Freemium Enforcement (`/admin/subscriptions`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a subscription management screen (1440x900) for "RentalHub - Host Subscription Tier Control".
Main Content:
- Header: "Host Subscription Tiers & Quota Governance".
- Tier Configuration Cards:
  * Card 1: "Free Starter Tier" • Quota: Max 3 Cars • Platform Commission: 0% • Active Shops: 112 • Edit Limits.
  * Card 2: "Pro Garage Tier" • Quota: Max 15 Cars • Monthly Fee: PKR 5,000 • Active Shops: 54 • Edit Features.
  * Card 3: "Enterprise Fleet Tier" • Quota: Unlimited Cars • Monthly Fee: PKR 15,000 • Active Shops: 18 • Priority WhatsApp Routing.
- Quota Enforcement Table: List of shops currently approaching the 3-car limit with one-click upgrade triggers.
```

#### [A-09] Transactional WhatsApp Gateway & Cloud Function Monitor (`/admin/whatsapp`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a messaging gateway monitoring view (1440x900) for "RentalHub - Meta WhatsApp Cloud API Health".
Main Content:
- Header: "Transactional WhatsApp Engine & Cloud Function Logs".
- Telemetry Metrics:
  * "Total Messages Dispatched Today": 1,280 templates.
  * "Delivery Success Rate": 99.8% (Emerald indicator).
  * "Meta System User Token Status": Healthy (Expires in 58 days).
  * "Avg Dispatch Latency": 820ms via Firebase Cloud Functions.
- Live Realtime Dispatch Stream: Table displaying Timestamp, Recipient (+92 300 xxxxxxx), Template ("booking_advance_paid_pdf"), Booking Ref, Delivery Status ("Delivered • Read").
```

#### [A-10] Emergency System Broadcast & Global Audit Logs (`/admin/broadcast`)
* **Device**: Desktop (1440x900)
* **Status**: `[PENDING GENERATION]`
* **Prompt**:
```text
Create a system broadcast and audit logging screen (1440x900) for "RentalHub - System Broadcast & Audit Logs".
Main Content:
- Left Column: "Push Notification Broadcast Console"
  * Audience Selector: "All Users", "Verified Customers Only", "Shop Owners Only".
  * Message Title & Body (English & Urdu inputs).
  * Send Push Alert Button (Vibrant orange #F95700).
- Right Column: "Immutable Super Admin Audit Trail"
  * Table of system events: "Super Admin (superadmin@rentalhub.pk) lifted blacklist on CNIC 35201-9918234-1 • Reason: Vendor settled dispute", "Shop Al-Falah accredited", "System backup created on cPanel".
```

---

---

## 6. Accessibility & Localization Standards

1. **Urdu Localization (RTL Support)**:
   - When Urdu is active, all screen layouts mirror horizontally (`Directionality.rtl`).
   - Text inputs right-align; chevron arrows flip direction (`Icons.chevron_left` becomes forward).
   - Numerals support standard Arabic/Urdu numeral rendering.
2. **Touch Targets & Overflow Safety**:
   - Minimum touch target for all buttons and interactive chips is **48x48dp**.
   - All text widgets wrapped in `Flexible` or `Expanded` with `TextOverflow.ellipsis` to safeguard against German/Urdu long-word overflows.
3. **Contrast Compliance**:
   - All primary text on surfaces adheres to WCAG AA standard (contrast ratio > 4.5:1).

---

## 7. Generated Stitch Project & Screen Asset Registry

* **Stitch Project ID**: `12014751675325012201` (`projects/12014751675325012201`, Title: `RentalHub`)
* **Design System**: `Midnight Velocity` (`assets/21af2363de734dcab35f8303757ffc9a`)
* **Local Artifacts Directory**: `.stitch/` in workspace root.

| # | Screen ID / Code | Screen Title | Device | Generation Status | Local HTML Asset | Local High-Res PNG |
| :-: | :--- | :--- | :---: | :---: | :--- | :--- |
| **01** | `C-07` / `ANC-01` | Customer Discovery & Floating Nav | Mobile (Android) | **`GENERATED`** | [01_customer_discovery.html](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.html) | [01_customer_discovery.png](file:///e:/Commercial/Gari%20App/.stitch/01_customer_discovery.png) |
| **02** | `C-12` / `ANC-02` | Vehicle Detail & Rent Packages | Mobile (Android) | **`GENERATED`** | [02_vehicle_detail_packages.html](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.html) | [02_vehicle_detail_packages.png](file:///e:/Commercial/Gari%20App/.stitch/02_vehicle_detail_packages.png) |
| **03** | `C-19` / `ANC-03` | Upload Payment Proof (Advance) | Mobile (Android) | **`GENERATED`** | [03_upload_payment_proof.html](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.html) | [03_upload_payment_proof.png](file:///e:/Commercial/Gari%20App/.stitch/03_upload_payment_proof.png) |
| **04** | `C-15` / `ANC-04` | Review & Send Reservation Request | Mobile (Android) | **`GENERATED`** | [04_review_reservation_request.html](file:///e:/Commercial/Gari%20App/.stitch/04_review_reservation_request.html) | [04_review_reservation_request.png](file:///e:/Commercial/Gari%20App/.stitch/04_review_reservation_request.png) |
| **05** | `C-20` / `ANC-05` | Pickup Pass & Digital QR Pass | Mobile (Android) | **`GENERATED`** | [05_pickup_countdown_pass.html](file:///e:/Commercial/Gari%20App/.stitch/05_pickup_countdown_pass.html) | [05_pickup_countdown_pass.png](file:///e:/Commercial/Gari%20App/.stitch/05_pickup_countdown_pass.png) |
| **06** | `C-21` / `ANC-06` | Customer Dashboard & Live Trip | Mobile (Android) | **`GENERATED`** | [06_customer_active_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/06_customer_active_dashboard.html) | [06_customer_active_dashboard.png](file:///e:/Commercial/Gari%20App/.stitch/06_customer_active_dashboard.png) |
| **07** | `C-29` / `ANC-07` | Identity Documents (KYC) Upload | Mobile (Android) | **`GENERATED`** | [07_kyc_document_upload.html](file:///e:/Commercial/Gari%20App/.stitch/07_kyc_document_upload.html) | [07_kyc_document_upload.png](file:///e:/Commercial/Gari%20App/.stitch/07_kyc_document_upload.png) |
| **08** | `C-26` / `ANC-08` | Rate Trip & Vehicle Condition | Mobile (Android) | **`GENERATED`** | [08_rate_trip_feedback.html](file:///e:/Commercial/Gari%20App/.stitch/08_rate_trip_feedback.html) | [08_rate_trip_feedback.png](file:///e:/Commercial/Gari%20App/.stitch/08_rate_trip_feedback.png) |
| **09** | `O-01` / `ANC-09` | Shop Onboarding & Payouts Setup | Mobile (Android) | **`GENERATED`** | [09_owner_shop_onboarding.html](file:///e:/Commercial/Gari%20App/.stitch/09_owner_shop_onboarding.html) | [09_owner_shop_onboarding.png](file:///e:/Commercial/Gari%20App/.stitch/09_owner_shop_onboarding.png) |
| **10** | `O-04` / `ANC-10` | Owner Fleet Dashboard & KPIs | Mobile (Android) | **`GENERATED`** | [10_owner_fleet_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/10_owner_fleet_dashboard.html) | [10_owner_fleet_dashboard.png](file:///e:/Commercial/Gari%20App/.stitch/10_owner_fleet_dashboard.png) |
| **11** | `O-05` / `ANC-11` | Fleet Inventory Management | Mobile (Android) | **`GENERATED`** | [11_owner_fleet_inventory.html](file:///e:/Commercial/Gari%20App/.stitch/11_owner_fleet_inventory.html) | [11_owner_fleet_inventory.png](file:///e:/Commercial/Gari%20App/.stitch/11_owner_fleet_inventory.png) |
| **12** | `O-07` / `ANC-12` | Add Vehicle Wizard & Rate Matrix | Mobile (Android) | **`GENERATED`** | [12_owner_rate_matrix.html](file:///e:/Commercial/Gari%20App/.stitch/12_owner_rate_matrix.html) | [12_owner_rate_matrix.png](file:///e:/Commercial/Gari%20App/.stitch/12_owner_rate_matrix.png) |
| **13** | `O-09` / `ANC-13` | Incoming Booking Requests Triage | Mobile (Android) | **`GENERATED`** | [13_owner_booking_requests.html](file:///e:/Commercial/Gari%20App/.stitch/13_owner_booking_requests.html) | [13_owner_booking_requests.png](file:///e:/Commercial/Gari%20App/.stitch/13_owner_booking_requests.png) |
| **14** | `O-12` / `ANC-14` | Vehicle Handover & On-Screen Signature | Mobile (Android) | **`GENERATED`** | [14_vehicle_handover_signature.html](file:///e:/Commercial/Gari%20App/.stitch/14_vehicle_handover_signature.html) | [14_vehicle_handover_signature.png](file:///e:/Commercial/Gari%20App/.stitch/14_vehicle_handover_signature.png) |
| **15** | `O-14` / `ANC-15` | Vehicle Return & Settlement Balance | Mobile (Android) | **`GENERATED`** | [15_owner_return_settlement.html](file:///e:/Commercial/Gari%20App/.stitch/15_owner_return_settlement.html) | [15_owner_return_settlement.png](file:///e:/Commercial/Gari%20App/.stitch/15_owner_return_settlement.png) |
| **16** | `O-16` / `ANC-16` | Fraud Blacklist Reporting Desk | Mobile (Android) | **`GENERATED`** | [16_owner_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/16_owner_fraud_blacklist.html) | [16_owner_fraud_blacklist.png](file:///e:/Commercial/Gari%20App/.stitch/16_owner_fraud_blacklist.png) |
| **17** | `A-02` / `ANC-17` | Super Admin Operations Dashboard | Desktop (1440px) | **`GENERATED`** | [17_admin_web_dashboard.html](file:///e:/Commercial/Gari%20App/.stitch/17_admin_web_dashboard.html) | [17_admin_web_dashboard.png](file:///e:/Commercial/Gari%20App/.stitch/17_admin_web_dashboard.png) |
| **18** | `A-03` / `ANC-18` | Shop Accreditation Queue & Doc Modal | Desktop (1440px) | **`GENERATED`** | [18_admin_shop_accreditation.html](file:///e:/Commercial/Gari%20App/.stitch/18_admin_shop_accreditation.html) | [18_admin_shop_accreditation.png](file:///e:/Commercial/Gari%20App/.stitch/18_admin_shop_accreditation.png) |
| **19** | `A-05` / `ANC-19` | National Blacklist Registry & Tribunal | Desktop (1440px) | **`GENERATED`** | [19_admin_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/19_admin_fraud_blacklist.html) | [19_admin_fraud_blacklist.png](file:///e:/Commercial/Gari%20App/.stitch/19_admin_fraud_blacklist.png) |
| **20** | `A-08` / `ANC-20` | Platform Disputes & Subscriptions | Desktop (1440px) | **`GENERATED`** | [20_admin_subscription_tiers.html](file:///e:/Commercial/Gari%20App/.stitch/20_admin_subscription_tiers.html) | [20_admin_subscription_tiers.png](file:///e:/Commercial/Gari%20App/.stitch/20_admin_subscription_tiers.png) |

---

## 8. Document Revision History
| Version | Date | Author / Agent | Change Type | Summary of Changes |
| :--- | :--- | :--- | :--- | :--- |
| **1.0.0** | 2026-10-31 | Lead Architect (Antigravity) | Initial Creation | Initial creation matching ui_ref.jpg dimensions. |
| **1.1.0** | 2026-10-31 | Lead Architect (Antigravity) | Type F (Design System) | Corrected color palette to authentic Project Requirements UI: Deep Midnight Navy (#1B1E5C) and Vibrant Orange (#F95700). |
| **1.2.0** | 2026-10-31 | Lead Architect (Antigravity) | Type F (Design System) | Generated initial 5 core production screens in Google Stitch and documented asset registry in `.stitch/`. |
| **1.3.0** | 2026-10-31 | Lead Architect (Antigravity) | Type F (Design System) | Comprehensive expansion: Added exhaustive production prompts for ALL screens grouped by Customer App (C-01 to C-35), Owner App (O-01 to O-16), and Admin Web Panel (A-01 to A-10), marking generated assets. |
| **1.4.0** | 2026-10-31 | Lead Architect (Antigravity) | Type F (Design System) | Established 20 Core Anchor Screens Architecture & Pattern Coverage Matrix to govern execution without API exhaustion. |
| **1.5.0** | 2026-10-31 | Lead Architect (Antigravity) | Type F (Design System) | 100% Generation & Verification of all 20 Core Anchor Screens (8 Customer, 8 Owner, 4 Admin Web) saved in `.stitch/` with responsive HTML and high-res PNG pairs. |
