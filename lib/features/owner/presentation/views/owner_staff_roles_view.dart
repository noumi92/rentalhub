import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/data/datasources/staff_data_source.dart';
import '../../../finance/domain/entities/staff_entity.dart';
import '../widgets/add_staff_dialog.dart';

/// Audit impl (O51): staff and roles — the shop's staff list, an
/// add-staff form, and per-person permission toggles (View
/// Bookings / Add Cars / Manage Finance). Stored in the `staff`
/// collection (see [StaffEntity] — the collection and field names
/// are a cross-worker contract, worker E reads them).
class OwnerStaffRolesView extends StatefulWidget {
  final String shopId;

  const OwnerStaffRolesView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerStaffRolesView> createState() => _OwnerStaffRolesViewState();
}

class _OwnerStaffRolesViewState extends State<OwnerStaffRolesView> {
  final _staffDs = StaffDataSource();
  List<StaffEntity> _staff = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final staff = await _staffDs.getShopStaff(widget.shopId);
      if (mounted) setState(() => _staff = staff);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addStaff() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showAddStaffDialog(context);
    if (result == null) return;
    try {
      await _staffDs.addStaff(
        shopId: widget.shopId,
        name: result.name,
        role: result.role,
        phone: result.phone,
        viewBookings: result.viewBookings,
        addCars: result.addCars,
        manageFinance: result.manageFinance,
      );
      _load();
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    }
  }

  Future<void> _togglePermission(
      StaffEntity member, String permission, bool value) async {
    try {
      await _staffDs.updatePermissions(
        staffId: member.staffId,
        viewBookings:
            permission == 'viewBookings' ? value : member.viewBookings,
        addCars: permission == 'addCars' ? value : member.addCars,
        manageFinance:
            permission == 'manageFinance' ? value : member.manageFinance,
      );
      _load();
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
            context, AppLocalizations.of(context)!.shopSaveError);
      }
    }
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
              title: l10n.staffTitle,
              subtitle: l10n.staffSubtitle,
              onBack: () => context.pop(),
              actions: [
                IconButton(
                  tooltip: l10n.staffAdd,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  onPressed: _addStaff,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError, onRetry: _load)
                      : _staff.isEmpty
                          ? AppEmptyState(
                              title: l10n.staffEmpty,
                              icon: Icons.group_rounded)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              itemCount: _staff.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final member = _staff[index];
                                return Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              child: Text(
                                                member.name.isNotEmpty
                                                    ? member.name[0]
                                                        .toUpperCase()
                                                    : '?',
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(member.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800)),
                                                  Text(member.role,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall),
                                                  if (member.phone.isNotEmpty)
                                                    Text(member.phone,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  l10n.staffDelete,
                                              icon: const Icon(
                                                  Icons.delete_rounded),
                                              onPressed: () async {
                                                await _staffDs.deleteStaff(
                                                    member.staffId);
                                                _load();
                                              },
                                            ),
                                          ],
                                        ),
                                        SwitchListTile(
                                          title: Text(l10n
                                              .staffPermissionViewBookings),
                                          value: member.viewBookings,
                                          onChanged: (v) =>
                                              _togglePermission(member,
                                                  'viewBookings', v),
                                        ),
                                        SwitchListTile(
                                          title: Text(l10n
                                              .staffPermissionAddCars),
                                          value: member.addCars,
                                          onChanged: (v) => _togglePermission(
                                              member, 'addCars', v),
                                        ),
                                        SwitchListTile(
                                          title: Text(l10n
                                              .staffPermissionManageFinance),
                                          value: member.manageFinance,
                                          onChanged: (v) =>
                                              _togglePermission(member,
                                                  'manageFinance', v),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
