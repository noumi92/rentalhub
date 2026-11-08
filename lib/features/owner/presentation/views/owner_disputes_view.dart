import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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
      final items = await sl<DisputeRemoteDataSource>()
          .getShopDisputes(widget.shopId);
      if (mounted) setState(() => _items = items);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DisputeRecord> get _visible => _filter == 'all'
      ? _items
      : _items.where((d) => d.status == _filter).toList();

  int _count(String status) =>
      _items.where((d) => d.status == status).length;

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
          await sl<DisputeRemoteDataSource>()
              .updateDisputeStatus(d.id, status);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disputes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Complaints from your customers',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All (${_items.length})'),
                    const SizedBox(width: 8),
                    _filterChip('open', 'Open (${_count('open')})'),
                    const SizedBox(width: 8),
                    _filterChip(
                        'in_review', 'In review (${_count('in_review')})'),
                    const SizedBox(width: 8),
                    _filterChip(
                        'resolved', 'Resolved (${_count('resolved')})'),
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
                              'No disputes yet — customer disputes for your showroom will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      : _visible.isEmpty
                          ? Center(
                              child: Text(
                                'No ${_filter == 'in_review' ? 'in-review' : _filter} disputes.',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface),
    );
  }
}
