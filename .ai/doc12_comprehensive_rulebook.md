# DOC-12: RentalHub Comprehensive Rulebook

## Project: RentalHub (`rentalhub`) — noumi92/rentalhub, `master`

| | |
|---|---|
| Version | 1.0.0 |
| Date | 2026-11-06 |
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

4.3 **Header:** `CustomCurvedHeader`, height 230 px (incl. status-bar padding), curved bottom radius 28 px, gradient `#16194F → #242875` (light) / `#0B0D26 → #16194F` (dark). Hero card overlaps the header by **-28 px** (`Transform.translate`, DOC-6 wins over DOC-2's -24). One header widget only — the legacy `CurvedHeader` is debt (§13).

4.4 **Layout & components.**
- Bottom nav: floating bar, height 68 px, margin 16 px, radius 32 px, navy background, orange active indicator.
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 px. Radii: pills/badges 8, cards/inputs/buttons 16, header-overlap containers 24, header curve 28.
- Primary CTA: `secondary` `#F95700`, white text, height 54 px, radius 16 px, **debounced 400 ms** (`DebouncedButton` — every submit/booking/payment button uses it, not a plain button).
- Secondary button: `primary`, white text, 54 px, 16 px radius. Outline: 1.5 px `primary` border, transparent, navy text.
- WhatsApp button: `#25D366`, 44 px, 12 px radius, only for verified users.
- Inputs: height 52 px, `surface` background, 1 px `borderSubtle` border, focused 2 px `primary` border, prefix icon in `textSecondary`.
- Badges: Verified — emerald pill `#EEFDF5` / `#10B981`; Blacklisted — crimson banner `#FEE2E2` / `#EF4444`; Pending — amber pill `#FEF3C7` / `#D97706`.
- Shadows: card `0 8 24 rgba(27,30,92,0.08)`; floating nav `0 -4 20 rgba(0,0,0,0.08)`.

4.5 **Typography:** Inter (Latin) / Noto Nastaliq Urdu (Urdu) — see §5. Scale: displayLarge 28/Bold/34, titleLarge 20/600/26, titleMedium 16/600/22, bodyLarge 15/400/22, bodyMedium 13/400/18, labelSmall 11/500/14. All text in `Flexible`/`Expanded` with `TextOverflow.ellipsis` (Urdu/German long-word safety).

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

6.1 **Modes:** Light, Dark, and System. Default is **System** (follow the device). The user can override in Settings with an explicit Light / Dark / System choice, persisted (SharedPreferences, key `app_theme_mode`) and applied on next launch.

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
| D1 | `CustomerFlowView` 2,479 lines, mock data | §2.2, §2.3 | Replace with real customer views; delete the file |
| D2 | ~~`OwnerFlowView` 2,008 lines, hardcoded sample data~~ — **RESOLVED 2026-11-06, Owner Module Phase A**: file deleted, its 6 routes now point at the real owner views (`OwnerDashboardView`, `OwnerBookingRequestsView`, `OwnerHandoverSignatureView`, `OwnerReturnSettlementView`, `OwnerContractView`, `OwnerCustomerRatingView`, `OwnerCustomerScanView`, `OwnerManualBookingView`, `OwnerRateMatrixView`), plus new routes for request detail, payment proof, contract, rating, customer scan, add-vehicle, subscription and WhatsApp logs; `BookingRouteLoader`/`VehicleRouteLoader` load entities by id with loading + not-found states; demo request fallback in the triage view removed | §2.2, §2.3 | — |
| D3 | `AdminFlowView` 693 lines, mock data, snackbar-only actions | §2.2, §2.3, §2.4 | Replace with real admin views; delete the file |
| D4 | `mock_data.dart` imported by 7 files in `lib/`: `admin_flow_view.dart`, `customer_flow_view.dart`, `shop_cars_view.dart`, `shop_detail_view.dart`, `vehicle_detail_view.dart`, `customer_vehicle_card.dart`, `vehicle_hero_card.dart` (Phase B, B1 removed the 3 owner importers) | §2.3 | Remove all `lib/` importers, then delete the file |
| D5 | Urdu toggle in `customer_settings_view.dart` is local `setState` only — no locale change, no persistence, no RTL | §5.4 | Build §5.2 infrastructure; wire the toggle to it | PARTIAL 2026-11-06, Owner Module Phase G: the owner settings screen has a real EN/UR toggle (persisted `app_locale`, applied app-wide via `AppSettingsCubit`, RTL works). The customer screen's fake toggle is still untouched — a customer-module item. |
| D6 | No `.arb` files, no `l10n.yaml`, no `AppLocalizations`, no `supportedLocales`/`locale` in `main.dart` | §5.2 | Build §5.2 infrastructure | PARTIAL 2026-11-06, Owner Module Phase G: `lib/l10n/app_en.arb` + `app_ur.arb`, `l10n.yaml`, `generate: true` in pubspec, `AppLocalizations` wired into `main.dart` with `supportedLocales` and the Material delegates. Only the owner settings screen is translated so far; the rest of the app keeps hardcoded English — the full migration is the rulebook's own language track. |
| D7 | No Noto Nastaliq / Inter font bundled; no `fontFamily` in theme | §4.5, §5.3, §6.5 | Bundle fonts, wire per-locale font |
| D8 | `themeMode: ThemeMode.light` hardcoded in `main.dart`; dark theme unreachable | §6.1, §6.2 | Persisted Light/Dark/System choice | RESOLVED 2026-11-06, Owner Module Phase G: `AppSettingsCubit` persists `app_theme_mode` (Light/Dark/System, default System) and `main.dart` reads it. |
| D9 | Dark theme hardcodes 6 colour literals inline; dark `error` `#F87171` and `success` `#34D399` missing from `AppColors`; `borderDark` in `AppColors` is `#2D3748`, not the doc's `#23274D` | §6.3 | Move dark theme to `AppColors`, add the missing dark tokens, align `borderDark` |
| D10 | Legacy `CurvedHeader` (235 px) duplicates `CustomCurvedHeader` (230 px); gradients differ from §4.3. Owner usage removed in Phase A (A2) — only `customer_flow_view.dart` still imports it | §4.3 | Keep one header, align gradient, delete the other |
| D11 | Overflow tests cover 9 of 69 views; `pumpScreenMultiViewport` never called; no keyboard test | §7.2 | Add overflow tests per item until all 69 are covered |
| D12 | No `fake_cloud_firestore` in tests; Firestore tests run against the in-memory fallback | §7.4 | Add dependency + repository tests |
| D13 | No `hive` offline cache (DOC-2 requires it) | §1.7, R10 | Add Hive (or approved replacement) with sync tests |
| D14 | `file_line_count_test.dart` enforces 300, not 250 | §2.2, R1 | Tighten to 250 (done by the rulebook tests) |
| D15 | DOC-2 vs DOC-4 routes disagree; admin login/2FA, `/admin/disputes`, `/customer/bookings` etc. unreconciled | §1.5, R5 | Reconcile docs, then routes |
| D16 | Finance (17 owner screens) and subscription (Play Billing) have no feature folder and no tests | §2.1 | Build as their own items | PARTIAL 2026-11-06, Owner Module Phase H: `lib/features/finance/` now holds accounts, ledger, partners and cash closings with tests; the subscription half (Play Billing) is still gated on D1 (Phase I). |
| D17 | Admin panel: 20 of 25 screens missing; only blacklist tribunal is real | §4.1 | Build as its own item(s) |
| D18 | Discovery uses hardcoded seeded shops, not Firestore | §2.3 | Wire `DiscoveryRemoteDataSource` to Firestore |
| D19 | 4 view files in `presentation/views/` exceed 250 lines: `customer_dashboard_view.dart` (295), `owner_onboarding_view.dart` (290), `owner_add_vehicle_view.dart` (259, down from 276 in Phase B, B1), `customer_dispute_view.dart` (260). `owner_rate_matrix_view.dart` is now 229 lines (was 261; split in Phase B, B2) and `owner_fleet_view.dart` is 226 lines (rewritten real in B1) | §2.2, R1 | Split each into widgets until ≤ 250, then tighten `file_line_count_test.dart` to 250 (D14) |
| D20 | No `Directionality`/RTL handling anywhere in `lib/`; no Urdu font; theme sets no `fontFamily`; hardcoded Urdu strings in 7 files (`custom_curved_header.dart`, `curved_header.dart`, `login_view.dart`, `onboarding_role_view.dart`, `customer_settings_view.dart`, `vehicle_detail_view.dart`, `customer_documents_view.dart`) | §4.5, §5.3, §6.5 | Build §5.2/§6.5 as part of the language item; move the 7 files' strings into `.arb` files |

## Revision History

| Version | Date | Author / Agent | Change Type | Summary |
|---|---|---|---|---|
| 1.0.0 | 2026-11-06 | Muse | Initial Creation | Comprehensive rulebook consolidating DOC-0–DOC-6, the Gaari UI specs, the `test/` suite and `lib/` at `af8c73c`; adds binding language (§5) and theme (§6) requirements and rulings R1–R10; opens the Known Debt Register (§13). |
