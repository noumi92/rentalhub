# DOC-12: RentalHub Comprehensive Rulebook

## Project: RentalHub (`rentalhub`) — noumi92/rentalhub, `master`

| | |
|---|---|
| Version | 1.0.4 |
| Date | 2026-11-08 |
| Author | Muse (for Nouman Karim) |
| Status | **Binding.** Every change to the app, tests, or docs must follow this rulebook. Where it conflicts with an older doc, this rulebook wins until the older doc is amended (see §11). |
| Sources | DOC-0 Change SOP, DOC-1 PRD, DOC-2 Architecture, DOC-3 Database Schema, DOC-4 App Flow, DOC-5 Implementation Plan, DOC-6 UI Design Instructions, `.ai/project_requirements_ui/` (Gaari UI specs: Admin 25 screens, Customer 35, Owner 72 + variants), the `test/` suite and `lib/` as they exist at `master` `af8c73c`. |

## How to use this rulebook

1. **Before any work**, read the section that governs it (architecture, language, theme, testing, change process).
2. **Work one item at a time** (user decision 2026-11-06). One screen/flow per item, finished and tested before the next starts.
3. **A change is not done** until it passes §7 (tests), §10 (docs updated), and the Definition of Done in §12.
4. **If a rule cannot be followed**, do not silently break it: record the exception in the Known Debt Register (§13) with a reason and an owner, and fix it in the next item that touches that area. Debt may only shrink — never grow.
5. **No placeholders.** Never leave `TODO`, `TBD`, `...`, hardcoded demo data, or snackbar-only actions in shipped code (DOC-0).

---

## 1. Architecture — non-negotiable tenets

1.1 **Feature-driven Clean Architecture.** Every feature lives in `lib/features/<feature>/` with exactly three layers:
- `data/` — `datasources/` (remote Firestore/cPanel, local Hive/SharedPreferences), `models/` (DTOs with `fromFirestore`/`toFirestore`/`fromJson`), `repositories/` (implements domain contracts).
- `domain/` — `entities/` (immutable, pure Dart), `repositories/` (abstract contracts), `usecases/` (single-responsibility).
- `presentation/` — `cubit/` (Bloc/Cubit + state classes), `views/` (screens < 250 lines), `widgets/` (granular decomposed components).

1.2 **Layer rules.**
- Domain has **zero Flutter imports**. No `flutter/material.dart` (or any `flutter/*`) in `domain/`. Enforced by test.
- Presentation never talks to Firestore/HTTP directly. It calls a Cubit/UseCase; the data layer owns all I/O.
- Data implements the repository interfaces defined in domain. No new collection, field, or status enum without a DOC-3 update first (DOC-0 Type D).

1.3 **State management:** `flutter_bloc` Cubit only. One Cubit per screen/flow, state classes immutable (`equatable`).

1.4 **Dependency injection:** `get_it` in `lib/core/di/injection_container.dart`. Every data source, repository, and use case is registered there. Tests substitute mocks through GetIt — never by editing production code.

1.5 **Routing:** `go_router` only, in `lib/core/routing/`. No `Navigator.push` for top-level navigation except inside a flow that the router already owns (and then only to a screen the router also knows). Every route in DOC-2 §5.1 must match DOC-4 exactly (route, name, parameters). If they disagree, fix the docs first — do not add a third variant in code.
- Role guards: `AuthRouteGuard` is the single gate. Unauthenticated users go to `/auth`; incomplete onboarding to `/onboarding/profile`; logged-in users to their role dashboard (customer `/customer/home`, owner `/owner/dashboard`, super-admin `/admin/dashboard`). Admin routes require `super_admin` role — the guard must actually call `AdminGuard`, not just define it.
- **No orphan screens.** A view file that no route (and no routed view) reaches is unfinished work, not a feature. Do not ship new orphan views; wire each one in the same item that creates it.

1.6 **One app, three roles.** Customer, Owner, and Admin are one Flutter app (mobile) plus the Flutter-web admin panel. No separate customer/owner apps. Role is chosen once at onboarding and is immutable afterwards.

1.7 **Offline-first.** Field operations (inspection, odometer, signatures, photos) must work fully offline, queue in local storage (Hive/SharedPreferences), and sync automatically within 30 seconds of reconnection. Never lose user-entered data on a network drop.

1.8 **Zero secrets in the client.** No WhatsApp token, cPanel master key, API key, or service-account credential in `lib/`, `assets/`, or committed config. Secrets live in Firebase Cloud Functions / Secret Manager only. Enforced by test (secret-pattern scan).

## 2. Project structure & file rules

2.1 Layout (DOC-2 §2): `lib/` = `firebase_options.dart`, `main.dart`, `core/` (`constants/`, `di/`, `error/`, `models/`, `network/`, `routing/`, `theme/`, `utils/`, `widgets/`), `features/` (admin, auth, blacklist, bookings, customer, discovery, fleet, handover, owner, payments, trust — plus `finance` and `subscription` when those features are built; they do not exist yet).

2.2 **View files: maximum 250 lines.** This is the DOC-0/DOC-2 rule (250, not 300). Decompose into `views/<screen>/widgets/` or `core/widgets/`. The old test cap of 300 is wrong and is replaced by the rulebook tests (§7).
- Flow/container files in `presentation/` (not `views/`) count too — a 2,000-line flow view is the same violation in a different folder.

2.3 **No mock/demo data in production code.** `lib/core/models/mock_data.dart` and any `MockDatabase` usage are banned in `lib/` (tests may use them as fixtures). Real data comes from Firestore/cPanel through the data layer. Hardcoded sample shops, vehicles, bookings, or users in a shipped screen are a defect, not a placeholder. See §13 for the current debt.

2.4 **No fake actions.** A button that only shows a snackbar ("Calling…", "Sending…", "Exported!") without performing the action is not implemented. Either wire the real action (with `launchUrl`/`tel:`, a repository call, or a file download) or do not ship the button.

2.5 **Naming.** Features, files, routes, Firestore collections, and doc terms use one vocabulary (`rentalhub.pk`, `shop` not `vendor` in user-facing text where the spec says shop, `booking` not `rental` for the entity). Field names, types, and status enums must match identically across DOC-3, code, and tests.

2.6 **Imports.** Relative imports inside a feature; `package:rentalhub/...` across features/core. No circular imports. `flutter analyze --no-fatal-infos` must report zero errors (warnings/infos are not a pass — fix them or record why).

## 3. Data, Firestore & backend

3.1 Firestore is the source of truth for realtime metadata (users, shops, vehicles, bookings, disputes, blacklist, subscriptions). Private media (KYC, photos, PDFs) goes to the cPanel storage API, never to public storage; access is via short-lived signed URLs (15 min) or an authenticated header.

3.2 **Field & enum discipline.** Every collection/field/status value is defined in DOC-3 before code uses it. Writers and readers must agree on field names — a rename touches the writer, the reader, the model, the tests, and DOC-3 in the same item.

3.3 **Transactions for money/state changes.** Booking confirmation, payment verification, cancellation, and return settlement change vehicle availability and booking status together — use a Firestore transaction. Cancelling/declining a booking frees the vehicle; completing a return frees it and advances mileage to the return odometer reading.

3.4 **Cloud Functions (backend/functions, TypeScript v2)** own: WhatsApp dispatch (Firestore triggers), push notifications (FCM), and anything needing a secret. The mobile app never calls the Meta WhatsApp API directly. Functions deploy separately from Firestore rules/indexes: `firebase deploy --only firestore:rules,firestore:indexes` and `firebase deploy --only functions` are different steps — pushing code does not deploy either.

3.5 **Rules & indexes.** New collections need Firestore rules (owner-scoped, least privilege) and any composite indexes the queries need, shipped in the same item as the code that uses them.

## 4. UI & design system

4.1 **Source of truth for screens:** `.ai/project_requirements_ui/` (Gaari specs) + DOC-4 inventories (Admin 25, Customer 35, Owner 72 + variants). DOC-6 is the design-system authority. If a spec page and a doc disagree, the spec page wins for that screen and the doc is amended.

4.2 **Colour tokens — 13 tokens, light and dark (DOC-6 §1.1, DOC-2 §9.2).** Use `AppColors` constants only; never hardcode a hex value in a view.

| Token | Light | Dark | Use |
|---|---|---|---|
| `primaryDark` | `#16194F` | `#0B0D26` | Header gradients, top bars |
| `primary` | `#1B1E5C` | `#252B7A` | Brand, headers, title bars |
| `primaryLight` / `primaryContainer` | `#EEF0FF` | `#1A1D42` | Selected chips, pill badges |
| `secondary` | `#F95700` | `#FF6D24` | Primary CTAs |
| `secondaryLight` | `#FFF3EB` | `#3D1B08` | Warning highlights, advance-fee banners |
| `background` | `#F8FAFC` | `#0A0B1A` | Scaffold background |
| `surface` | `#FFFFFF` | `#13152C` | Cards, bottom sheets, dialogs |
| `surfaceElevated` | `#F1F5F9` | `#1C1F3D` | Secondary cards, pill containers |
| `textPrimary` / `onSurface` | `#0F172A` | `#F8FAFC` | Titles, prices |
| `textSecondary` / `onSurfaceVariant` | `#64748B` | `#94A3B8` | Subtitles, hints |
| `borderSubtle` | `#E2E8F0` | `#23274D` | Dividers, input borders |
| `accentSuccess` / `success` | `#10B981` | `#34D399` | Verified badges, paid state |
| `accentDanger` / `error` | `#EF4444` | `#F87171` | Blacklist alerts, error borders |

Naming ruling (§11): code uses the DOC-6 names (`primaryLight`, `secondaryLight`, `textPrimary`, `textSecondary`, `accentSuccess`, `accentDanger`) as `AppColors` constants; `ThemeData` maps them to the Material slots (`primaryContainer`, `onSurface`, `onSurfaceVariant`, `success`, `error`). One naming set, no duplicates.

Container / on-container tokens (Phase A3, dark-mode readability). The pale light containers glare in dark mode, so dark mode uses darker slabs with a light on-container colour for the text/icons on them. All values verified against `AppColors` (`lib/core/constants/app_colors.dart`) 2026-11-08, Phase G (G1), and pinned name → value by `rulebook_theme_test.dart`. The 13-token table above was re-verified against `AppColors` on the same date — every row matches.

| `AppColors` constant | Light | Dark | Use |
|---|---|---|---|
| `successContainer` / `successContainerDark` | `#ECFDF5` | `#123524` | Success slabs, WhatsApp buttons |
| `successOnContainerDark` (light: `accentSuccess` via `successOnContainerFor`) | `#10B981` | `#86EFAC` | Text/icons on a success slab |
| `errorContainer` / `errorContainerDark` | `#FEF2F2` | `#3B1215` | Error slabs |
| `errorOnContainerDark` (light: `accentDanger` via `errorOnContainerFor`) | `#EF4444` | `#FCA5A5` | Text/icons on an error slab |
| `warningContainer` / `warningContainerDark` | `#FFFBEB` | `#3A2A05` | Warning slabs |
| `warningOnContainerDark` (light: `warning` via `warningOnContainerFor`) | `#F59E0B` | `#FCD34D` | Text/icons on a warning slab |
| `surfaceContainer` (`surfaceElevated` light) / `surfaceContainerDark` | `#F1F5F9` | `#171A30` | Secondary containers (M3 `surfaceContainer`) |
| `surfaceContainerHighestLight` / `surfaceContainerHighestDark` | `#F8FAFC` | `#1E2138` | Form-field fills, highest containers |
| `primaryFocusedOnDark` | — | `#6C72D9` | Focused input border in dark mode (`primaryOnDark` is invisible against the dark field fill) |
| `headerGradientEnd` | `#242875` | — | Header gradient end (§4.3 light gradient) |

**Orange / success text-and-fill tokens (owner visual audit C3, 2026-11-08).** White on `secondary` `#F95700` is only 3.29:1 and white on `secondaryDark` `#FF6D24` is 2.81:1 — both fail WCAG AA (4.5:1) for small text, so `#F95700` / `#FF6D24` stay brand / large-fill tokens only and must **never carry small white text**. Small orange text uses `orangeTextFor(brightness)` — `orangeText` `#C2410C` in light (5.18:1 on white, 4.75:1 on `#FFF3EB`), `orangeTextDark` `#FB923C` in dark (7.92:1 on dark surface `#13152C`, 6.83:1 on the dark orange container `#3D1B08`). Filled chips and buttons with small white text use `orangeFill` `#C2410C` in both modes (white on it is 5.18:1). The same rule applies to green: white on `accentSuccess` `#10B981` is only 2.54:1 and must never carry button text; success buttons with white text use `accentSuccessStrong` `#047857` in both modes (white on it is 5.48:1; 5.48:1 as text on white, 5.21:1 on the light success container `#ECFDF5`). Stepper circles follow the same rule: current step `orangeFill`, done step `accentSuccessStrong`. **Never white text on `#F95700` / `#FF6D24` / `#10B981`.**

4.3 **Header:** `MinimalAppBar` (`lib/core/widgets/minimal_app_bar.dart`) — flat solid `primaryDark` (`#16194F`), full-bleed, no curve, no gradient, no overlap, no shadow. Content height 56 px minimum below the status-bar inset (grows past 56 px at large text scales instead of clipping); content starts immediately below. Bold white title 18 sp / w900, subtitle 12 sp white 70% when present. Back arrow (`arrow_back_ios_new_rounded`, white, 20) exactly when the route can pop (explicit `onBack` wins, else auto) — tab roots show no arrow. **Inset rule (owner visual audit C1, 2026-11-08): `MinimalAppBar` owns the top inset — it adds `MediaQuery.padding.top` itself — so every view wraps its `Scaffold` body in `SafeArea(top: false)`; a second top `SafeArea` in a view adds a ~24 dp dead navy band under the header on all screens. The shell likewise consumes the top inset once (see §4.4).** **The login hero is the only exception:** `CustomCurvedHeader` hero variant (230 px incl. status-bar padding, curved bottom radius 28 px, gradient `#16194F → #242875` light / `#0B0D26 → #16194F` dark, hero card overlapping by **-28 px**) survives for the login screen only; every other screen uses `MinimalAppBar`. (Phone-test #16, 2026-11-08 — the curved header on every other screen is gone; #8 is moot, tab screens get a pinned 56 px bar by design.)

4.4 **Layout & components.**
- Bottom nav: flush bar attached to the bottom edge, 56 px content height, no margin, no radius, no floating pill; navy background, orange active indicator. **Implemented 2026-11-07, Phase C, redesigned 2026-11-08 (phone-test #16): `AppShellNav` (`lib/core/widgets/app_shell_nav.dart`, 56, navy `primary` / orange `secondary` from the theme), owned by `AppShell` (`lib/core/routing/app_shell.dart`) behind the two `StatefulShellRoute` shells (customer + owner, five branches each); the 10 tab screens embed no nav widget — enforced by `rulebook_architecture_test.dart` (nav-shell scan).** The bar is visible exactly on the 10 tab roots and hidden on every sub-screen (phone-test #17, user rule: a screen with a back arrow gets no bottom navigation) — one path-set check in `AppShell` (`tabRootPaths`), not one route move per sub-screen. **Gesture-bar decision (owner visual audit, 2026-11-08 — supersedes the §4.4 "no SafeArea" wording of v1.0.3): on gesture-navigation devices the flush bar sat under the Android system gesture pill, hiding the tab labels. The fix keeps the 56 px content height and adds `MediaQuery.padding.bottom` below it (the bar becomes 56 px + inset), so the #16 "flush, no floating margin" intent is preserved and the labels clear the gesture pill. At large text scales the content grows past 56 px instead of clipping (the bar height is `max(56, 40 + scaled 12 sp label)` + inset).**
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 px. Radii: pills/badges 8, cards/inputs/buttons 16, login hero curve 28 (§4.3 — the only curved header left).
- Primary CTA: `secondary` `#F95700`, white text, height 54 px, radius 16 px, **debounced 400 ms** (`DebouncedButton` — every submit/booking/payment button uses it, not a plain button).
- Secondary button: `primary`, white text, 54 px, 16 px radius. Outline: 1.5 px `primary` border, transparent, navy text.
- WhatsApp button: `#25D366`, 44 px, 12 px radius, only for verified users.
- Inputs: height 52 px, `surface` background, 1 px `borderSubtle` border, focused 2 px `primary` border, prefix icon in `textSecondary`.
- Badges: Verified — emerald pill `#ECFDF5` / `#10B981`; Blacklisted — crimson banner `#FEF2F2` / `#EF4444`; Pending — amber pill `#FFFBEB` / `#F59E0B`. (Backgrounds are the canonical `successContainer` / `errorContainer` / `warningContainer` tokens, §4.2; the previous values `#EEFDF5` / `#FEE2E2` / `#FEF3C7` / `#D97706` appeared nowhere in `lib/` and were corrected 2026-11-08, Phase G.)
- Shadows: card `0 8 24 rgba(27,30,92,0.08)`.

4.5 **Typography:** Inter (Latin) / Noto Nastaliq Urdu (Urdu) — see §5. Scale: displayLarge 28/Bold/34, titleLarge 20/600/26, titleMedium 16/600/22, bodyLarge 15/400/22, bodyMedium 13/400/18, labelSmall 11/500/14. All text in `Flexible`/`Expanded` with `TextOverflow.ellipsis` (Urdu/German long-word safety).

**Money formatting (owner visual audit C5, 2026-11-08).** Every rupee amount in the app is grouped with thousands separators: `formatRs(x)` (`lib/core/utils/money_format.dart`, `NumberFormat('#,##0', 'en')` — Western digits and comma grouping in both English and Urdu, locale-pinned so the grouping never follows the device locale) renders `4820000` as `4,820,000`. Amounts are rendered **only** through a localised money key — `l10n.amountRs(formatRs(x))` or another money key — and **every money placeholder in the `.arb` files is typed `String`**, so the grouped string is what the key receives. Never interpolate a raw int (`'Rs. $amount'` renders `Rs. 4820000`), and never write the inline `'Rs. ${formatRs(x)}'` form: it hardcodes the English word order and renders `{amount} روپے` wrong in Urdu composite strings (the Urdu `amountRs` is `{amount} روپے`). Count / percent / km / date placeholders stay `int`; only money is `String`. Amount columns use tabular figures where the widget supports them.

4.6 **Accessibility:** WCAG AA contrast > 4.5:1. Minimum touch target 48×48 dp. Every image/icon button has a semantic label. No colour-only meaning (always pair with text/icon).

## 5. Language — English & Urdu (future requirement, binding)

5.1 **Scope (DOC-1 NFR): full bilingual support, whole app.** Dynamic switching between English (LTR) and Urdu (RTL), with localized typography and mirrored layouts. Target: > 35% of monthly active users in Pakistan using the Urdu RTL layout (DOC-1 KPI). This is not one screen and not a restart — it is the whole app, switchable at runtime.

5.2 **Mechanism (rulebook decision — no doc specified one).**
- Flutter localization: `flutter_localizations` + `intl` (already dependencies), `l10n.yaml` with `generate: true`, `lib/l10n/app_en.arb` and `lib/l10n/app_ur.arb`, generated `AppLocalizations`.
- `MaterialApp.router` gets `supportedLocales: [Locale('en'), Locale('ur')]`, `localizationsDelegates` (AppLocalizations + GlobalMaterial/Widgets/Cupertino), and a `locale` driven by app state — never hardcoded, never device-default-only.
- Key naming: `lowerCamelCase`, grouped by feature/screen (e.g. `bookingRequestSent`, `settingsAppLanguage`). Every user-visible string goes through `AppLocalizations` — **no hardcoded user-facing strings in new code** (enforced by test on new files; existing hardcoded strings migrate one screen at a time, §13).
- Fallback: missing Urdu key falls back to the English string and is logged in tests (a test fails if any Urdu key is missing — see §7).

5.3 **Urdu behaviour.**
- Urdu active ⇒ `Directionality.rtl` for the whole app: layouts mirror horizontally, text inputs right-align, chevron arrows flip (`chevron_left` becomes forward).
- Numerals render in standard Arabic/Urdu numerals where the spec shows them.
- Font: Noto Nastaliq Urdu for Urdu text (bundled in `assets/fonts/`, declared in `pubspec.yaml`); Inter for Latin. The theme switches font family by locale — Urdu text must never render in the default Material font.
- Long text: `Flexible`/`Expanded` + ellipsis everywhere (§4.5) — Urdu words are long and overflow is a defect.

5.4 **Where the switch lives:** Settings (`/customer/settings`, and the equivalent owner/admin settings when built) — "App Language" card with "English (US)" / "اردو (Urdu RTL)" toggle and a greeting preview in the selected language. The choice is **persisted** (SharedPreferences, key `app_locale`) and applied on next launch without asking again. The current fake toggle (local `setState` only, no persistence, no locale change) is debt (§13) and must be replaced, not copied.

5.5 **Bilingual content, not just UI:** admin broadcasts are authored with English **and** Urdu title/body (DOC-6 §5.3). WhatsApp templates exist in both languages. Numbers, dates, and currency (PKR) format per locale (`intl`).

5.6 **Gate:** DOC-5 Task 4.8 — a complete bilingual localization audit (English LTR and Urdu RTL, every screen) is required before release. No screen is "done" until it passes that audit in both languages.

## 6. Theme — light & dark (future requirement, binding)

6.1 **Modes:** Light, Dark, and System. Default is **Light** (phone-test #16, 2026-11-08 — was System; a saved user choice is untouched, only fresh installs / unknown stored values start in Light). The user can override in Settings with an explicit Light / Dark / System choice, persisted (SharedPreferences, key `app_theme_mode`) and applied on next launch.

6.2 **The dark theme must be reachable.** `themeMode: ThemeMode.light` hardcoded in `main.dart` is a defect (§13). `MaterialApp.router` gets `theme`, `darkTheme`, and a `themeMode` driven by the persisted choice.

6.3 **Tokens:** the 13 tokens in §4.2, both modes, defined once in `AppColors` and read by `AppTheme`. No inline hex literals in the dark theme (or anywhere else) — the current dark theme's hardcoded literals are debt. Missing dark tokens must be added: `error` dark `#F87171`, `success` dark `#34D399`.

6.4 **Theme coverage:** `AppTheme` must theme app bar, buttons, cards, inputs, chips, bottom navigation, dialogs, and snackbars — not just the three component themes it has today. A screen that looks right in light mode and falls back to Material defaults in dark mode is not done.

6.5 **Fonts in the theme:** `AppTheme` sets the text theme and font family (Inter for Latin; Noto Nastaliq Urdu when locale is Urdu). No screen sets its own font family ad hoc.

6.6 **Theme + language interact:** switching language must not reset the theme, and switching theme must not reset the language. Both preferences persist independently and survive app restart and offline use.

## 7. Testing & quality assurance

7.1 **CI is the gate.** `.github/workflows/ci.yml` — `lint_and_test` runs `flutter pub get`, `flutter analyze --no-fatal-infos`, `flutter test`. It gates the APK and web builds: any failing test blocks both. There is no coverage floor in CI yet; the rulebook target is ≥ 80% on `domain/` + `data/repositories/` (measured locally, not yet a CI gate — do not add a CI gate without a user decision).

7.2 **What every item must ship with:**
- Unit tests for new use cases, entities, and validators (pure Dart, no Flutter).
- Widget tests for new/changed screens: renders without overflow, buttons do the real action (or are disabled with a reason), error states render.
- Overflow tests for **every** touched view, at 360×640, 393×852, and 412×915, font scale 0.85×–1.35× (DOC-1 range, wider than DOC-2's 1.35× only), and with a 350 px keyboard overlay on every form screen. Use `TestHarness.pumpScreenMultiViewport` — the single-viewport check alone is not enough.
- A test for every rule in this rulebook that the item touches (see the rulebook test files).

7.3 **Debounce:** every submit/booking/payment button uses `DebouncedButton` (400 ms lockout). A test taps it 5 times rapidly and asserts exactly one event.

7.4 **Data tests:** repository tests use `fake_cloud_firestore` (`FakeFirebaseFirestore`) — add it to `dev_dependencies`. No test may depend on a live Firebase project, an emulator, or the in-memory fallback inside `FirestoreService` and call it a Firestore test. cPanel upload tests mock the HTTP client and cover 401 / 413 / 500 + retry backoff.

7.5 **Language tests:** switching locale changes the displayed strings (widget test, both locales), the choice persists across a restart (SharedPreferences mock), Urdu renders RTL (`Directionality` is RTL, inputs right-aligned), and the `.arb` files are complete (no missing Urdu keys, no unused keys).

7.6 **Theme tests:** light and dark token values match §4.2, `ThemeMode` switching changes the rendered theme, the persisted choice survives restart, and every themed component renders in both modes without falling back to Material defaults for colour.

7.7 **Static rulebook tests (in `test/`):** `rulebook_architecture_test.dart`, `rulebook_language_test.dart`, `rulebook_theme_test.dart`, `rulebook_testing_test.dart`. They read the repo (like `file_line_count_test.dart` does) and enforce: domain purity, 250-line view cap, no mock data in `lib/`, no secrets, token values, overflow coverage, and the debt register (§13) not growing. Target-state tests for work that does not exist yet (`.arb` files, `fake_cloud_firestore`, keyboard overlay) are written with `skip:` and the debt ID in the skip reason — they show as pending in test output, never as silent passes, and are un-skipped when the work lands. A skipped test is not a pass and must not be deleted to make CI green.

7.8 **Performance gates (DOC-1 NFRs):** first frame < 16 ms (60 FPS), cold start < 2.0 s on mid-tier Android, offline sync within 30 s of reconnection, zero overflow crashes on 4.5"–7" screens.

## 8. Security & privacy

8.1 Secrets only in Cloud Functions / Secret Manager (§1.8). No token, key, or password in code, assets, tests, or docs.
8.2 Firestore rules: least privilege, owner-scoped. Admin data (secrets, audit log) deny-all from clients.
8.3 CNIC / licence / payment data: never logged, never put in a filename or URL, only ever sent to the cPanel storage API over HTTPS with the HMAC token. Screenshots of KYC/payment screens are discouraged in bug reports.
8.4 2FA for admins (TOTP) and role checks on every admin route. Google Sign-In SHA-1/SHA-256 fingerprints are registered in Firebase for every signing key the app ships with.

## 9. Change management (DOC-0, binding)

9.1 **Authority order:** DOC-1 (business) → DOC-2 (architecture) → DOC-3 (data) → DOC-4 (flow) → DOC-5 (plan) → DOC-6 (UI) → DOC-7–11 (phase plans). DOC-0 is meta-governance above them. **This rulebook (DOC-12) sits alongside DOC-0 as governance** — it does not replace any doc, it enforces them and records the rulings in §11.

9.2 **Five-step procedure for every change:** (1) Read Before Writing — read the governing doc, check the feature isn't already defined or deliberately scoped out; (2) Classify (Type A–K); (3) Amend top-down — highest-authority doc first, propagate down, names/types/enums/routes identical everywhere; (4) Verify the chain & update revision logs in every modified doc; (5) Implement & test — code that diverges from the docs is rejected in review.

9.3 **Docs live in `.ai/` only.** Never generate docs in the project root. Every doc change updates its Revision History table (date, author/agent, change type, description).

9.4 **Pushes:** shared `master` branch, direct pushes only on explicit user approval, verify HEAD before pushing, verify on the branch after. Never force-push. CI must be green on the pushed commit (or the failure is reported to the user with the log).

## 10. Definition of Done (every item)

- [ ] Matches the Gaari spec screen(s) for that item, in both English and Urdu, in light and dark mode.
- [ ] Real data (Firestore/cPanel) — no mock data, no snackbar-only actions, no hardcoded sample content.
- [ ] Clean Architecture layers respected; view < 250 lines; `flutter analyze` zero errors.
- [ ] Routed (no orphan screens) and role-guarded.
- [ ] Tests added/updated per §7 and passing locally (`flutter analyze`, `flutter test`); overflow tested at 3 viewports + font scales + keyboard where it is a form.
- [ ] Docs updated (governing doc + this rulebook's debt register if anything changed) with revision-log entries.
- [ ] Pushed to `master` only after user approval; CI result checked and reported.

## 11. Rulings — contradictions resolved by this rulebook

| # | Contradiction | Ruling |
|---|---|---|
| R1 | View line limit: docs 250 vs test 300 | **250.** The test is changed to 250. |
| R2 | Hero overlap: DOC-6 -28 px vs DOC-2 -24 px | **-28 px** (DOC-6 is the design-system authority). |
| R3 | Token naming: DOC-6 vs DOC-2 names | **DOC-6 names** in `AppColors`; mapped to Material slots in `ThemeData`. |
| R4 | Overflow font scale: DOC-1 0.85–1.35× vs DOC-2 1.35× only | **0.85–1.35×** (DOC-1 outranks DOC-2). |
| R5 | Routes: DOC-2 §5.1 vs DOC-4 disagree | Neither wins yet — **reconcile DOC-2 and DOC-4 before any new route work**; the router is the third copy and must match the reconciled docs. |
| R6 | Language mechanism: no doc specifies one | **flutter_localizations + intl + .arb** (§5.2). |
| R7 | Theme switching: no doc specifies a toggle | **System by default + explicit Light/Dark/System toggle in Settings, persisted** (§6.1). |
| R8 | `fake_cloud_firestore` required by DOC-2, absent from tests | **Add it** to `dev_dependencies` and use it for repository tests (§7.4). |
| R9 | Screen counts: DOC-6 condensed (16 owner / 10 admin) vs DOC-4 full inventories | **DOC-4 inventories + `.ai/project_requirements_ui/`** are the source of truth for "done". |
| R10 | `hive` offline cache required by DOC-2, absent from pubspec | **Recorded as debt** (§13). Do not claim offline-first is implemented until Hive (or the chosen replacement) lands with tests. |

## 12. What "one by one" means in practice

Work proceeds in this order unless the user reorders it: (1) wire the already-built real views to the router (customer booking flow first), (2) replace the mock flow views, (3) owner finance, (4) admin panel, (5) language infrastructure, (6) theme completion. Each item removes its entries from §13. No item starts until the previous one meets §10.

## 13. Known Debt Register — as at 2026-11-06 (`master` `af8c73c`)

Debt may only shrink. A rulebook test fails if any entry below grows (new file, new import, new hardcoded string) — removing an entry is the goal.

| ID | Debt | Rule broken | Fix (one-by-one item) |
|---|---|---|---|
| D1 | ~~`CustomerFlowView` 2,479 lines, mock data~~ — **RESOLVED 2026-11-06, Customer Module Phase A**: file deleted, its routes now point at the real customer views (`CustomerDashboardView`, `CustomerHomeView`, `CustomerBookingsView`, `CustomerBookingDetailView`, `CustomerWalletView`, `CustomerSupportView`, `CustomerProfileView`, `CustomerSettingsView`, `CustomerReputationView`, `CustomerSavedShopsView`, `CustomerDocumentsView`, `CustomerSosView`, `CustomerDisputeView`, `CustomerCancelBookingView`, `CustomerRateTripView`, `CustomerActiveTripView`, `PickupCountdownPassView`, `CustomerHomeMapView`); `BookingRouteLoader`/`CustomerRouteLoaders` load entities by id with loading + not-found states | §2.2, §2.3 | — |
| D2 | ~~`OwnerFlowView` 2,008 lines, hardcoded sample data~~ — **RESOLVED 2026-11-06, Owner Module Phase A**: file deleted, its 6 routes now point at the real owner views (`OwnerDashboardView`, `OwnerBookingRequestsView`, `OwnerHandoverSignatureView`, `OwnerReturnSettlementView`, `OwnerContractView`, `OwnerCustomerRatingView`, `OwnerCustomerScanView`, `OwnerManualBookingView`, `OwnerRateMatrixView`), plus new routes for request detail, payment proof, contract, rating, customer scan, add-vehicle, subscription and WhatsApp logs; `BookingRouteLoader`/`VehicleRouteLoader` load entities by id with loading + not-found states; demo request fallback in the triage view removed | §2.2, §2.3 | — |
| D3 | ~~`AdminFlowView` 693 lines, mock data, snackbar-only actions~~ — RESOLVED 2026-11-07 (admin Phases A–E): the file was deleted and its routes now point at the real admin views | §2.2, §2.3, §2.4 | Replace with real admin views; delete the file |
| D4 | `mock_data.dart` has **0 importers in `lib/`** (corrected 2026-11-08, Phase G, G1 — the five discovery importers `shop_cars_view.dart`, `shop_detail_view.dart`, `vehicle_detail_view.dart`, `customer_vehicle_card.dart`, `vehicle_hero_card.dart` no longer reference it; enforced by `rulebook_architecture_test.dart` with an empty importer set). The file itself still exists as dead code | §2.3 | Delete `lib/core/models/mock_data.dart`, then remove the D4 test expectation in the same item |
| D5 | Urdu toggle in `customer_settings_view.dart` is local `setState` only — no locale change, no persistence, no RTL | §5.4 | Build §5.2 infrastructure; wire the toggle to it | RESOLVED 2026-11-06, Customer Module Phase H (H2): the customer settings screen now uses the same real `AppSettingsCubit` EN/UR toggle as the owner settings (persisted `app_locale`, applied app-wide, RTL works) — it is the second translated screen. |
| D6 | No `.arb` files, no `l10n.yaml`, no `AppLocalizations`, no `supportedLocales`/`locale` in `main.dart` | §5.2 | Build §5.2 infrastructure | PARTIAL 2026-11-06, Owner Module Phase G: `lib/l10n/app_en.arb` + `app_ur.arb`, `l10n.yaml`, `generate: true` in pubspec, `AppLocalizations` wired into `main.dart` with `supportedLocales` and the Material delegates. Only the owner and customer settings screens are translated so far (customer settings joined in Customer Module Phase H, H2); the rest of the app keeps hardcoded English — the full migration is the rulebook's own language track. |
| D7 | ~~No Noto Nastaliq / Inter font bundled; no `fontFamily` in theme~~ — **RESOLVED 2026-11-08, Phase G (G4)**: Inter (876 KB) + Noto Nastaliq Urdu (690 KB) are bundled at `assets/fonts/` and declared in pubspec (`family: Inter`, `family: Noto Nastaliq Urdu`); the theme wires the family per locale (`AppTheme.fontFamilyFor`, `main.dart` passes it from settings). Pinned by the un-skipped font test in `rulebook_language_test.dart` | §4.5, §5.3, §6.5 | — |
| D8 | `themeMode: ThemeMode.light` hardcoded in `main.dart`; dark theme unreachable | §6.1, §6.2 | Persisted Light/Dark/System choice | RESOLVED 2026-11-06, Owner Module Phase G: `AppSettingsCubit` persists `app_theme_mode` (Light/Dark/System, default System) and `main.dart` reads it. |
| D9 | ~~Dark theme hardcodes 6 colour literals inline; dark `error` `#F87171` and `success` `#34D399` missing from `AppColors`; `borderDark` in `AppColors` is `#2D3748`, not the doc's `#23274D`~~ — **RESOLVED 2026-11-08, Phase G (G1)**: the dark theme literals are gone — `lib/core/theme/app_theme.dart` contains zero `Color(0x...)` literals (the only match is the doc comment stating so; enforced by the whole-file scan in `rulebook_theme_test.dart`); dark `error`/`success` tokens are in `AppColors`; `borderDark` is `#23274D` | §6.3 | — |
| D10 | ~~Legacy `CurvedHeader` (235 px) duplicates `CustomCurvedHeader` (230 px); gradients differ from §4.3~~ — **RESOLVED 2026-11-06, Customer Module**: the customer flow view was the last importer and it was deleted in Phase A, so nothing imported the legacy header any more; the file `lib/core/widgets/curved_header.dart` was deleted and `CustomCurvedHeader` is now the only header. | §4.3 | — |
| D11 | Overflow tests cover 9 of 69 views; `pumpScreenMultiViewport` never called; no keyboard test | §7.2 | Add overflow tests per item until all 69 are covered |
| D12 | ~~No `fake_cloud_firestore` in tests; Firestore tests run against the in-memory fallback~~ — **RESOLVED 2026-11-11, shop-id fix**: `fake_cloud_firestore: ^3.1.0` is a dev dependency and `test/shop_id_resolution_test.dart` runs FleetRemoteDataSource tests against FakeFirebaseFirestore (doc-id + UID reads, canonical writes, free-tier cap); the D12 skip test in `rulebook_testing_test.dart` is un-skipped and asserts the dependency + test file | §7.4 | — |
| D13 | No `hive` offline cache (DOC-2 requires it) | §1.7, R10 | Add Hive (or approved replacement) with sync tests |
| D14 | ~~`file_line_count_test.dart` enforces 300, not 250~~ — **RESOLVED 2026-11-08, Phase G (G1)**: the test now enforces the 250-line cap (rulebook §2.2, R1); the single view still over the cap is a registered D19 exception inside that file, and the D14 skip test in `rulebook_testing_test.dart` is un-skipped and asserts the cap | §2.2, R1 | — |
| D15 | DOC-2 vs DOC-4 routes disagree; admin login/2FA, `/admin/disputes`, `/customer/bookings` etc. unreconciled | §1.5, R5 | Reconcile docs, then routes |
| D16 | Finance (17 owner screens) and subscription (Play Billing) have no feature folder and no tests | §2.1 | Build as their own items | PARTIAL 2026-11-06, Owner Module Phase H: `lib/features/finance/` now holds accounts, ledger, partners and cash closings with tests; the subscription half (Play Billing) is still gated on D1 (Phase I). |
| D17 | Admin panel: Phases A–E built 2026-11-07 (login/TOTP, roles, guard, team, activity log, dashboard, approvals, shops, cars, customers, trust score, blacklist, bookings, disputes, reviews, tickets, settings, announcements, reports). Remaining: subscriptions (F1) and WhatsApp credits (F2), both gated on D1 (Play Console) + D2 (Meta/WhatsApp) | §4.1 | Build as its own item(s) |
| D18 | ~~Discovery uses hardcoded seeded shops, not Firestore~~ — **RESOLVED 2026-11-06, Customer Module Phase B (B1)**: `DiscoveryRemoteDataSource.fetchNearbyShops` reads the real Firestore `shops` collection (verified only, haversine distance, nearest-first); the seeded shops are deleted. | §2.3 | — |
| D19 | 1 view file in `presentation/views/` exceeds 250 lines: `owner_add_vehicle_view.dart` (259). `owner_onboarding_view.dart` is now 250 and `customer_dispute_view.dart` is now 192 (shrunk in Phases C/D); `customer_dashboard_view.dart` (295) was deleted in Phase C; `owner_rate_matrix_view.dart` (229) and `owner_fleet_view.dart` (226) are under the cap. Counts corrected 2026-11-08, Phase G (G1); enforced by `rulebook_architecture_test.dart` (`kOverLimitViews`) and `file_line_count_test.dart` | §2.2, R1 | Split `owner_add_vehicle_view.dart` into widgets until ≤ 250 |
| D20 | No `Directionality`/RTL handling anywhere in `lib/`; no Urdu font; theme sets no `fontFamily`; hardcoded Urdu strings in 7 files (`custom_curved_header.dart`, `curved_header.dart`, `login_view.dart`, `onboarding_role_view.dart`, `customer_settings_view.dart`, `vehicle_detail_view.dart`, `customer_documents_view.dart`) | §4.5, §5.3, §6.5 | Build §5.2/§6.5 as part of the language item; move the 7 files' strings into `.arb` files |

## Revision History

| Version | Date | Author / Agent | Change Type | Summary |
|---|---|---|---|---|
| 1.0.4 | 2026-11-08 | Muse | Owner visual-audit fix batch (193 findings) | §4.2 orange/success text-and-fill tokens (`orangeText`/`orangeTextDark`/`orangeFill`/`accentSuccessStrong` + measured ratios; never white text on `#F95700`/`#FF6D24`/`#10B981`); §4.3 C1 inset rule (`MinimalAppBar` owns the top inset, views use `SafeArea(top: false)`); §4.4 gesture-bar decision (56 px content + `MediaQuery.padding.bottom` below it, flush intent preserved, grows at large text scales — supersedes the v1.0.3 "no SafeArea" wording); §4.5 `formatRs` rule (all money grouped; money `.arb` placeholders are `String`); §4.3/§4.4/§6.1 history stands (minimal 56 px `MinimalAppBar` except the login hero, flush 56 px tab bar on the 10 tab roots only, Light is the default theme). No new debt entries. |
| 1.0.3 | 2026-11-08 | Muse | Phone-test fix batch (#16/#17) | Header + nav redesign: §4.3 minimal 56 px `MinimalAppBar` everywhere except the login curved hero; §4.4 flush 56 px tab bar (was floating 68/16/32) visible only on the 10 tab roots (`AppShell.tabRootPaths`, #17); §6.1 Light is the default theme (was System; saved choices untouched). |
| 1.0.2 | 2026-11-08 | Muse | Phase G (G4) follow-up | D7 resolved (Inter + Noto Nastaliq Urdu bundled — font test un-skipped with real file/pubspec assertions); §4.4 badge hexes corrected to the canonical tokens (`successContainer #ECFDF5`, `errorContainer #FEF2F2`, `warningContainer #FFFBEB`, warning text `#F59E0B`) — the old values appeared nowhere in `lib/`. |
| 1.0.1 | 2026-11-08 | Muse | Phase G (G1) update | Rulebook test gates: nav-shell scan (§4.4), token name→value bindings + dark container tokens + whole-file literal scan (§4.2/§6.3), line-count test tightened to 250 with E/F shared-widget cap, overflow coverage + 200% text-scale pass; §4.2 container-token table added (values verified against `AppColors`); §4.4 nav marked implemented; §13 D9 resolved, D4 corrected to 0 importers, D14 resolved, D19 counts corrected. No new debt entries. |
| 1.0.0 | 2026-11-06 | Muse | Initial Creation | Comprehensive rulebook consolidating DOC-0–DOC-6, the Gaari UI specs, the `test/` suite and `lib/` at `af8c73c`; adds binding language (§5) and theme (§6) requirements and rulings R1–R10; opens the Known Debt Register (§13). |
