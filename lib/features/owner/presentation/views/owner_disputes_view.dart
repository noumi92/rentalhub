import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../widgets/dispute_detail_sheet.dart';
import '../widgets/dispute_list_tile.dart';

/// The owner's disputes inbox: every dispute customers filed against
/// this showroom's bookings, newest first, with a status filter and
/// the detail sheet that moves a dispute open -> in review ->
/// resolved. This is what the customer dispute screen's "the showroom
/// can see it" promise points at.
class OwnerDisputesView extends StatefulWidget {
  final String shopId;

  const OwnerDisputesView({super.key, required this.shopId});

  @override
  State<OwnerDisputesView> createState() => _OwnerDisputesViewState();
}

class _OwnerDisputesViewState extends State<OwnerDisputesView> {
  List<DisputeRecord> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all';

  /// Item 2 deep link: the triage card's "View / Resolve Dispute"
  /// navigates here with `?bookingId=<id>` so that booking's
  /// dispute sheet opens on arrival. Read in
  /// [didChangeDependencies] (not initState — the route state is
  /// an inherited widget) and attempted at most once, so a status
  /// change reload never re-opens the sheet.
  String? _deepLinkBookingId;
  bool _deepLinkAttempted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deepLinkBookingId ??=
        GoRouterState.of(context).uri.queryParameters['bookingId'];
    _maybeAutoOpen();
  }

  void _maybeAutoOpen() {
    if (_deepLinkAttempted || _deepLinkBookingId == null || _isLoading) {
      return;
    }
    _deepLinkAttempted = true;
    final id = _deepLinkBookingId!;
    DisputeRecord? match;
    for (final d in _items) {
      if (d.bookingId == id) {
        match = d;
        break;
      }
    }
    if (match == null || !mounted) return;
    final target = match;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(target);
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final items =
          await sl<DisputeRemoteDataSource>().getShopDisputes(widget.shopId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      // Audit §30/C4: a failed load used to render as "no disputes".
      debugPrint('OwnerDisputesView load failed: $e'); // Audit 2026-11-15 DS-6: raw error logged; user sees only the localized per-screen message.
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    _maybeAutoOpen();
  }

  List<DisputeRecord> get _visible => _filter == 'all'
      ? _items
      : _items.where((d) => d.status == _filter).toList();

  int _count(String status) => _items.where((d) => d.status == status).length;

  Future<void> _open(DisputeRecord d) async {
    final l10n = AppLocalizations.of(context)!;
    // Item 2 navigate-back: a resolve action ("Mark in review" /
    // "Mark resolved") leaves the centre for All Bookings once
    // the sheet closes — that is what the rule requires, even
    // though it navigates away from the centre. Viewing without
    // changing anything stays put.
    var changed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DisputeDetailSheet(
        dispute: d,
        // Audit §30: the sheet used to pop even when the update
        // failed (and stranded when it threw). The callback now
        // reports success so the sheet can stay open on failure.
        onStatusChanged: (status) async {
          final ok = await sl<DisputeRemoteDataSource>()
              .updateDisputeStatus(d.id, status);
          if (!ok && mounted) {
            AppFeedback.showError(context, l10n.shopSaveError);
          }
          if (ok) changed = true;
          await _load();
          return ok;
        },
      ),
    );
    if (changed && mounted) goToAllOwnerBookings(context);
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.disputes,
              subtitle: l10n.disputesOwnerSubtitle,
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', l10n.disputesFilterAll(_items.length)),
                    const SizedBox(width: 8),
                    _filterChip('open', l10n.disputesFilterOpen(_count('open'))),
                    const SizedBox(width: 8),
                    _filterChip(
                        'in_review', l10n.disputesFilterInReview(_count('in_review'))),
                    const SizedBox(width: 8),
                    _filterChip('resolved', l10n.disputesFilterResolved(_count('resolved'))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.disputesLoadError,
                          onRetry: _load,
                        )
                      : _items.isEmpty
                          ? AppEmptyState(
                              title: l10n.disputesOwnerEmpty,
                              icon: Icons.report_problem_outlined,
                            )
                          : _visible.isEmpty
                              ? AppEmptyState(
                                  title: _filter == 'open'
                                      ? l10n.disputesNoneOpen
                                      : _filter == 'in_review'
                                          ? l10n.disputesNoneInReview
                                          : l10n.disputesNoneResolved,
                                  icon: Icons.report_problem_outlined,
                                )
                              : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              itemCount: _visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) => DisputeListTile(
                                dispute: _visible[i],
                                onTap: () => _open(_visible[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      // Audit 2026-11-15 DS-1: selected fill + label come from chipTheme
      // (navy fill + white label); no per-file override.
    );
  }
}
