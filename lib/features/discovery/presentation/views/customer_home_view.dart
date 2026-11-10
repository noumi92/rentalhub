import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../customer/data/services/customer_home_service.dart';
import 'widgets/home_app_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = widget.homeService ?? CustomerHomeService.resolve();
    final data = service == null
        ? const CustomerHomeData(bookings: [])
        : await service.load(_uid());
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    await _load();
  }

  /// The signed-in uid, or the 'cust-101' fallback the bookings
  /// view and wallet service use when nobody is signed in.
  String _uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'cust-101';
    } catch (_) {
      return 'cust-101';
    }
  }

  /// The signed-in user's initial for the header avatar.
  /// Firebase is best-effort here — 'U' when there is no
  /// signed-in user yet.
  String _userInitial() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName ?? user?.email ?? '';
      if (name.isNotEmpty) return name[0];
    } catch (_) {}
    return 'U';
  }

  /// First name for the greeting subtitle, or null when unknown
  /// (no signed-in user) — the app bar then shows the title only.
  String? _greetingName() {
    try {
      final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
      if (name.isEmpty) return null;
      return name.split(' ').first;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _greetingName();
    final data = _data;
    return Scaffold(
      // Phase D (D2): the only tab root that lacked a SafeArea — the
      // header and content now clear the status bar like the other
      // nine tab roots do.
      body: SafeArea(
        child: Column(
          children: [
            CustomerHomeAppBar(
              title: l10n.homeTitle,
              subtitle:
                  name == null ? null : l10n.dashboardGreeting(name),
              userInitial: _userInitial(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      if (_loading)
                        const AppLoadingState()
                      else if (data != null) ...[
                        HomeKpiGrid(
                          activeBookings: data.activeBookings,
                          totalTrips: data.totalTrips,
                          walletTotal: data.walletTotal,
                          trustScore: data.trustScore,
                          onTrustTap: () => context
                              .push(RouteNames.customerReputation),
                        ),
                        const SizedBox(height: 12),
                        HomeKycCard(kyc: data.kyc),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        l10n.quickLinks,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const CustomerHomeQuickActions(),
                      if (!_loading && data != null) ...[
                        const SizedBox(height: 16),
                        if (!data.bookingsFailed)
                          HomeUpcomingEvents(data: data),
                        const SizedBox(height: 16),
                        HomeRecentBookings(data: data, onRetry: _reload),
                        const SizedBox(height: 12),
                      ],
                    ],
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
