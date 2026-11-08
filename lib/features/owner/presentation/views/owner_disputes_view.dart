import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
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

  const OwnerDisputesView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerDisputesView> createState() => _OwnerDisputesViewState();
}

class _OwnerDisputesViewState extends State<OwnerDisputesView> {
  List<DisputeRecord> _items = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items =
          await sl<DisputeRemoteDataSource>().getShopDisputes(widget.shopId);
      if (mounted) setState(() => _items = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DisputeRecord> get _visible => _filter == 'all'
      ? _items
      : _items.where((d) => d.status == _filter).toList();

  int _count(String status) => _items.where((d) => d.status == status).length;

  Future<void> _open(DisputeRecord d) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DisputeDetailSheet(
        dispute: d,
        onStatusChanged: (status) async {
          await sl<DisputeRemoteDataSource>().updateDisputeStatus(d.id, status);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
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
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              l10n.disputesOwnerEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      : _visible.isEmpty
                          ? Center(
                              child: Text(
                                _filter == 'open' ? l10n.disputesNoneOpen : _filter == 'in_review' ? l10n.disputesNoneInReview : l10n.disputesNoneResolved,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w700),
                              ),
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
      selectedColor: AppColors.primary,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface),
    );
  }
}
