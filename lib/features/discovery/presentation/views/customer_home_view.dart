import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/signed_in_user.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../customer/data/services/customer_home_service.dart';
import '../../../notifications/data/services/customer_live_notifications.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_book_car_fab.dart';
import 'widgets/home_kpi_grid.dart';
import 'widgets/home_kyc_card.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_recent_bookings.dart';
import 'widgets/home_upcoming_events.dart';
import '../../../../l10n/app_localizations.dart';

/// Customer rework (Worker C): the customer Home is a dashboard now
/// — KPIs, KYC status, quick actions, upcoming events and recent
/// bookings, all from the real repositories through
/// [CustomerHomeService]. Shop discovery (list/map) moved to the
/// Shops tab (Worker B). The hero is unchanged — the MinimalAppBar
/// with map, bell and avatar — and the bell still opens the support
/// inbox as a sub-screen.
class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key, this.homeService});

  /// Injected in tests (in-memory data sources); the real app
  /// resolves the service from the locator.
  final CustomerHomeService? homeService;

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  CustomerHomeData? _data;
  bool _loading = true;
  // CU-m3: signed out — the old 'cust-101' fallback loaded another
  // user's bookings and KPIs. The home shows a sign-in error instead.
  bool _signedOut = false;
  // Live updates (Item 2): the subscription behind the KPIs,
  // upcoming events and recent bookings.
  StreamSubscription<CustomerHomeData>? _homeSub;
  final CustomerLiveNotifications _liveNotifications =
      CustomerLiveNotifications();
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeNotifications();
  }

  void _subscribeNotifications() {
    final uid = _uid();
    if (uid.isEmpty) return;
    _liveNotifications.subscribe(
      customerId: uid,
      onUnreadCount: (count) {
        if (mounted) setState(() => _unreadNotifications = count);
      },
      onNewArrival: (title, body, _, __) {
        if (mounted && title.isNotEmpty) {
          AppFeedback.showInfo(
            context,
            body.isEmpty ? title : '$title — $body',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _homeSub?.cancel();
    _liveNotifications.dispose();
    super.dispose();
  }

  /// Live updates (Item 2): Home follows the home service's
  /// [CustomerHomeService.watch] stream — a booking submitted on
  /// the review screen, or an owner approve / reject, updates the
  /// KPIs, upcoming events and recent bookings without leaving the
  /// tab. The error-state retry re-runs this method, which
  /// re-subscribes.
  void _load() {
    final uid = _uid();
    // An injected test service loads its own in-memory data without
    // auth; the real app path requires a signed-in user.
    if (uid.isEmpty && widget.homeService == null) {
      if (mounted) {
        setState(() {
          _signedOut = true;
          _loading = false;
        });
      }
      return;
    }
    final service = widget.homeService ?? CustomerHomeService.resolve();
    if (service == null) {
      if (mounted) {
        setState(() {
          _data = const CustomerHomeData(bookings: []);
          _loading = false;
          _signedOut = false;
        });
      }
      return;
    }
    _homeSub?.cancel();
    _homeSub = service.watch(uid).listen(
      (data) {
        if (mounted) {
          setState(() {
            _data = data;
            _loading = false;
            _signedOut = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _data = const CustomerHomeData(bookings: [], bookingsFailed: true);
            _loading = false;
          });
        }
      },
    );
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    _load();
    _subscribeNotifications();
  }

  /// The signed-in uid, or '' when nobody is signed in — never a
  /// demo fallback (CU-m3: 'cust-101' used to load a stranger's data).
  String _uid() => SignedInUser.uid();

  /// The signed-in user's initial for the header avatar.
  /// 'U' when there is no signed-in user yet.
  String _userInitial() {
    final user = SignedInUser.current();
    final name = user?.displayName ?? user?.email ?? '';
    if (name.isNotEmpty) return name[0];
    return 'U';
  }

  /// First name for the greeting subtitle, or null when unknown
  /// (no signed-in user) — the app bar then shows the title only.
  String? _greetingName() {
    final name = SignedInUser.current()?.displayName ?? '';
    if (name.isEmpty) return null;
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _greetingName();
    final data = _data;
    // DS-16 (UI/UX audit 2026-11-15): the KYC card is the one tile
    // that can block the user — it sits above the KPI grid when it
    // needs action (not submitted, or rejected), below it otherwise.
    final kycNeedsAction =
        data?.kyc == null || data?.kyc?.status == 'rejected';
    return Scaffold(
      // Customer pass (2026-11-16): "Book a Car" is the Home's
      // primary action — the extended floating button below (same
      // orange FAB language as the owner screens, same destination
      // as the quick-action tile it replaces: the Shops tab).
      floatingActionButton: const HomeBookCarFab(),
      // Phase D (D2): the only tab root that lacked a SafeArea — the
      // header and content now clear the status bar like the other
      // nine tab roots do.
      // Audit 2026-11-15 DS-14: top: false — the shell strips the
      // top inset from the whole branch subtree, so a bare SafeArea
      // would double-inset by a status-bar height outside the shell.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            CustomerHomeAppBar(
              title: l10n.homeTitle,
              subtitle:
                  name == null ? null : l10n.dashboardGreeting(name),
              userInitial: _userInitial(),
              unreadNotificationsCount: _unreadNotifications,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: SingleChildScrollView(
                  // AlwaysScrollable: pull-to-refresh must work even
                  // when the content is shorter than the viewport.
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      if (_loading)
                        const AppLoadingState()
                      else if (_signedOut)
                        // PW-9 (UI/UX audit 2026-11-15): the old retry
                        // just re-ran the load and re-produced the
                        // same signed-out error. The action is Sign
                        // in, routing to login.
                        AppErrorState(
                          message: l10n.signInRequiredGeneric,
                          onRetry: () => context.go(RouteNames.auth),
                          retryLabel: l10n.homeSignInButton,
                        )
                      else if (data != null) ...[
                        if (kycNeedsAction) HomeKycCard(kyc: data.kyc),
                        if (kycNeedsAction) const SizedBox(height: 12),
                        HomeKpiGrid(
                          activeBookings: data.activeBookings,
                          totalTrips: data.totalTrips,
                          walletTotal: data.walletTotal,
                          trustScore: data.trustScore,
                          onTrustTap: () => context
                              .push(RouteNames.customerReputation),
                          // CU-m14: every KPI tile opens where its
                          // number lives — bookings, wallet, bookings.
                          onBookingsTap: () =>
                              context.go(RouteNames.customerBookings),
                          onWalletTap: () =>
                              context.go(RouteNames.customerWallet),
                        ),
                        const SizedBox(height: 12),
                        if (!kycNeedsAction) HomeKycCard(kyc: data.kyc),
                        if (!kycNeedsAction) const SizedBox(height: 16),
                      ],
                      Text(
                        l10n.quickLinks,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const CustomerHomeQuickActions(),
                      if (!_loading && data != null) ...[
                        const SizedBox(height: 16),
                        if (!data.bookingsFailed)
                          HomeUpcomingEvents(data: data),
                        const SizedBox(height: 16),
                        HomeRecentBookings(data: data, onRetry: _reload),
                        const SizedBox(height: 84),
                      ],
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
