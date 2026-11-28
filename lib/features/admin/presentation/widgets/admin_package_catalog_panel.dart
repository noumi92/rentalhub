import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_package_catalog_data_source.dart';
import 'admin_package_catalog_tab.dart';
import 'admin_package_editor_dialogs.dart';

/// Self-contained stateful panel for creating, editing, and deleting
/// Shop Subscription Packages and WhatsApp Credit Packages.
class AdminPackageCatalogPanel extends StatefulWidget {
  const AdminPackageCatalogPanel({
    super.key,
    required this.canManage,
    this.adminRole,
    this.dataSource,
  });

  final bool canManage;
  final String? adminRole;
  final AdminPackageCatalogDataSource? dataSource;

  @override
  State<AdminPackageCatalogPanel> createState() =>
      _AdminPackageCatalogPanelState();
}

class _AdminPackageCatalogPanelState extends State<AdminPackageCatalogPanel> {
  List<AdminShopPackage> _shopPackages = [];
  List<AdminWhatsappPackage> _waPackages = [];
  bool _isLoading = true;
  bool _hasError = false;

  AdminPackageCatalogDataSource get _ds =>
      widget.dataSource ??
      (sl.isRegistered<AdminPackageCatalogDataSource>()
          ? sl<AdminPackageCatalogDataSource>()
          : AdminPackageCatalogDataSource());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final results = await Future.wait([
        _ds.getShopPackages(),
        _ds.getWhatsappPackages(),
      ]);
      if (!mounted) return;
      setState(() {
        _shopPackages = results[0] as List<AdminShopPackage>;
        _waPackages = results[1] as List<AdminWhatsappPackage>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _report(bool ok, String successMsg) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (ok) {
      AppFeedback.showSuccess(context, successMsg);
      _load();
    } else {
      AppFeedback.showError(
        context,
        l10n?.adminPackagesActionFailed ?? 'Could not save this change.',
      );
    }
  }

  Future<bool> _confirmDelete(String name) async {
    final l10n = AppLocalizations.of(context);
    final deleteLabel = l10n?.financeCategoriesDelete ?? 'Delete';
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deleteLabel),
        content: Text('$deleteLabel "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(deleteLabel),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _saveShopPackage({AdminShopPackage? existing}) async {
    final pkg = await showAdminShopPackageEditorDialog(
      context,
      existing: existing,
    );
    if (pkg == null || !mounted) return;
    final ok = await _ds.saveShopPackage(pkg, adminRole: widget.adminRole);
    if (!mounted) return;
    _report(ok, AppLocalizations.of(context)?.adminPackageSaved ?? 'Package saved.');
  }

  Future<void> _deleteShopPackage(AdminShopPackage pkg) async {
    if (!await _confirmDelete(pkg.name) || !mounted) return;
    final ok = await _ds.deleteShopPackage(pkg.id, adminRole: widget.adminRole);
    if (!mounted) return;
    _report(ok, AppLocalizations.of(context)?.adminPackageDeleted ?? 'Package deleted.');
  }

  Future<void> _saveWhatsappPackage({AdminWhatsappPackage? existing}) async {
    final pkg = await showAdminWhatsappPackageEditorDialog(
      context,
      existing: existing,
    );
    if (pkg == null || !mounted) return;
    final ok = await _ds.saveWhatsappPackage(pkg, adminRole: widget.adminRole);
    if (!mounted) return;
    _report(ok, AppLocalizations.of(context)?.adminPackageSaved ?? 'Package saved.');
  }

  Future<void> _deleteWhatsappPackage(AdminWhatsappPackage pkg) async {
    if (!await _confirmDelete(pkg.name) || !mounted) return;
    final ok =
        await _ds.deleteWhatsappPackage(pkg.id, adminRole: widget.adminRole);
    if (!mounted) return;
    _report(ok, AppLocalizations.of(context)?.adminPackageDeleted ?? 'Package deleted.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoadingState();
    if (_hasError) {
      return AppErrorState(
        message: AppLocalizations.of(context)?.adminPackagesActionFailed ??
            'Could not load packages.',
        onRetry: _load,
      );
    }
    return AdminPackageCatalogTab(
      shopPackages: _shopPackages,
      whatsappPackages: _waPackages,
      canManage: widget.canManage,
      onCreateShopPackage: () => _saveShopPackage(),
      onEditShopPackage: (p) => _saveShopPackage(existing: p),
      onDeleteShopPackage: _deleteShopPackage,
      onCreateWhatsappPackage: () => _saveWhatsappPackage(),
      onEditWhatsappPackage: (p) => _saveWhatsappPackage(existing: p),
      onDeleteWhatsappPackage: _deleteWhatsappPackage,
    );
  }
}
