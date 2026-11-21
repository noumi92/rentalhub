import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/signed_in_user.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/sync_status_cubit.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/live_booking_stream.dart';
import '../widgets/booking_ticket_card.dart';
import '../widgets/customer_bookings_list_helpers.dart';
import '../../../../l10n/app_localizations.dart';

class CustomerBookingsView extends StatefulWidget {
  final Function(BookingEntity booking)? onOpenBookingDetails;
  final Function(BookingEntity booking)? onPayAdvance;
  final Function(BookingEntity booking)? onViewPass;
  final Function(BookingEntity booking)? onViewActiveTrip;
  final Function(BookingEntity booking)? onRateTrip;
  final Function(BookingEntity booking)? onTrackDispute;

  /// The tab the list opens on (0 = All). Mirrors the owner's
  /// `initialFilter` plumbing: a save navigation back to this list
  /// passes 0 so the saved booking's new status is visible under
  /// All, instead of the tab the user happened to be on.
  final int initialTab;

  const CustomerBookingsView({
    super.key,
    this.onOpenBookingDetails,
    this.onPayAdvance,
    this.onViewPass,
    this.onViewActiveTrip,
    this.onRateTrip,
    this.onTrackDispute,
    this.initialTab = 0,
  });

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView> {
  int _selectedTab = 0;
  List<BookingEntity> _allBookings = [];
  bool _isLoading = true;
  // E2: a load failure used to clear the spinner silently; it now
  // renders an error state with retry.
  bool _hasError = false;
  // CU-m3: nobody signed in — the list must not load under the
  // shared 'cust-101' id.
  bool _signedOut = false;
  // Live updates (Item 2): the subscription behind the list.
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab >= 0 &&
        widget.initialTab < customerBookingTabsCount) {
      _selectedTab = widget.initialTab;
    }
    _fetchBookings();
  }

  @override
  void didUpdateWidget(covariant CustomerBookingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync unconditionally: go_router page keys are path-only, so a
    // `go()` with a new query string reuses this page — change
    // detection would miss consecutive saves landing on the same tab
    // (All = 0 is also the default). Plain pops never rebuild, so
    // back-from-detail keeps the selected tab.
    if (widget.initialTab >= 0 &&
        widget.initialTab < customerBookingTabsCount) {
      setState(() => _selectedTab = widget.initialTab);
    }
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  /// Live updates (Item 2): the list follows the customer's bookings stream — a submit on the review screen, or an owner approve / reject, re-renders it without leaving the tab. Pull-to-refresh and the error-state retry re-run this method, which re-subscribes.
  Future<void> _fetchBookings() async {
    await _bookingsSub?.cancel();
    _bookingsSub = null;
    if (mounted) setState(() { _hasError = false; _signedOut = false; });
    // CU-m3: a signed-out caller has no bookings to load — the old 'cust-101' fallback read another user's data.
    final uid = SignedInUser.uid();
    if (uid.isEmpty) {
      if (mounted) setState(() { _signedOut = true; _hasError = true; _isLoading = false; });
      return;
    }
    _bookingsSub = subscribeLiveBookings((ds) => ds.streamCustomerBookings(uid), (list) {
      if (!mounted) return;
      setState(() { _allBookings = list; _isLoading = false; _hasError = false; });
    }, onError: () {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    });
    // A null subscription means the data source could not be resolved
    // (missing DI) — a load failure, not an empty list: the error
    // state renders and its retry re-runs this method.
    if (_bookingsSub == null && mounted) {
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = filterCustomerBookings(_allBookings, _selectedTab);
    final tabs = customerBookingTabs(l10n);
    return Scaffold(
      // Audit 2026-11-15 DS-14: top: false — the shell strips the
      // top inset; a bare SafeArea double-insets outside it.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.bookingsTitle,
            ),
            // E3: 48dp chip + 8dp vertical padding each side — the
            // old 50dp row squeezed the filter chips to 34dp.
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = i == _selectedTab;
                  return ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    label: Text(tabs[i]),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedTab = i),
                    // Audit 2026-11-15 DS-1: no per-file labelStyle —
                    // the theme's chipTheme drives both modes (the old
                    // labelMedium override is deleted).
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  // E2: shared loading / error / empty states.
                  ?  AppLoadingState(
                      message: l10n.bookingsLoading,
                    )
                  : _hasError
                      ? AppErrorState(
                          message: _signedOut
                              ? l10n.signInRequiredGeneric
                              : l10n.bookingsLoadError,
                          onRetry: _fetchBookings,
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchBookings,
                          child: list.isEmpty
                              ? AppEmptyState(
                                  title:
                                      l10n.bookingsEmptyForTab(tabs[_selectedTab]),
                                  message:
                                      l10n.bookingsEmptyHint,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    final b = list[index];
                                    // Next-step batch: the card action
                                    // comes from the shared resolver —
                                    // paid opens the pass directly,
                                    // active opens the trip, disputed
                                    // tracks the dispute.
                                    final action = customerCardAction(
                                      l10n,
                                      b,
                                      onPayAdvance: widget.onPayAdvance,
                                      onViewPass: widget.onViewPass,
                                      onViewActiveTrip:
                                          widget.onViewActiveTrip,
                                      onRateTrip: widget.onRateTrip,
                                      onTrackDispute: widget.onTrackDispute,
                                    );

                                    Widget card(SyncEntryStatus status) =>
                                        BookingTicketCard(
                                          booking: b,
                                          onTap: () => widget
                                              .onOpenBookingDetails
                                              ?.call(b),
                                          actionLabel: action.label,
                                          onAction: action.callback,
                                          syncStatus: status,
                                        );

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      // Phase B (B5): the per-item sync chip
                                      // follows the queue state.
                                      child: Builder(
                                        builder: (context) {
                                          // Prefer a provided cubit, else
                                          // the DI singleton, else no
                                          // chip (never throw for a
                                          // missing provider).
                                          final syncCubit =
                                              resolveSyncStatusCubit(context);
                                          if (syncCubit == null) {
                                            return card(SyncEntryStatus.synced);
                                          }
                                          return BlocBuilder<SyncStatusCubit,
                                              SyncStatusState>(
                                            bloc: syncCubit,
                                            builder: (context, sync) => card(
                                                sync.byEntity[b.bookingId] ??
                                                    SyncEntryStatus.synced),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
