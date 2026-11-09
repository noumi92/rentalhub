import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/data/datasources/finance_category_data_source.dart';
import '../../../finance/domain/entities/finance_category_entity.dart';

/// Audit impl (O52): manage the income and expense categories the
/// ledger uses. The lists are the same ones the add-entry sheet
/// reads (seeded with the old hardcoded lists on first use), so an
/// edit here shows up in the sheet immediately. Deleting a category
/// never rewrites old ledger entries — they keep their stored code
/// and still render under that code.
class OwnerFinanceCategoriesView extends StatefulWidget {
  final String shopId;

  const OwnerFinanceCategoriesView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerFinanceCategoriesView> createState() =>
      _OwnerFinanceCategoriesViewState();
}

class _OwnerFinanceCategoriesViewState
    extends State<OwnerFinanceCategoriesView> {
  final _categoryDs = FinanceCategoryDataSource();
  List<FinanceCategoryEntity> _income = [];
  List<FinanceCategoryEntity> _expense = [];
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
      final income = await _categoryDs.getShopCategories(widget.shopId,
          kind: 'income');
      final expense = await _categoryDs.getShopCategories(widget.shopId,
          kind: 'expense');
      if (mounted) {
        setState(() {
          _income = income;
          _expense = expense;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory(String kind) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.financeCategoriesAddTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              labelText: l10n.financeCategoriesNameLabel,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.financeCategoriesAdd),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await _categoryDs.addCategory(
          shopId: widget.shopId, kind: kind, name: name);
      _load();
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    }
  }

  Future<void> _renameCategory(FinanceCategoryEntity category) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: category.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.financeCategoriesEditTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              labelText: l10n.financeCategoriesNameLabel,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == category.name) return;
    try {
      await _categoryDs.renameCategory(category.categoryId, name);
      _load();
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    }
  }

  Future<void> _deleteCategory(FinanceCategoryEntity category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: l10n.financeCategoriesDeleteTitle,
      message: l10n.financeCategoriesDeleteMessage(category.name),
      confirmLabel: l10n.financeCategoriesDelete,
      isDestructive: true,
    );
    if (confirmed != true) return;
    try {
      await _categoryDs.deleteCategory(category.categoryId);
      _load();
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
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
              title: l10n.financeCategoriesTitle,
              subtitle: l10n.financeCategoriesSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError, onRetry: _load)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _section(l10n, l10n.financeIncome, _income,
                                  'income'),
                              const SizedBox(height: 20),
                              _section(l10n, l10n.financeExpense, _expense,
                                  'expense'),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(AppLocalizations l10n, String title,
      List<FinanceCategoryEntity> categories, String kind) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.financeCategoriesAdd),
              onPressed: () => _addCategory(kind),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (categories.isEmpty)
          Text(l10n.financeCategoriesEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final category in categories)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(category.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.financeCategoriesEdit,
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _renameCategory(category),
                ),
                IconButton(
                  tooltip: l10n.financeCategoriesDelete,
                  icon: const Icon(Icons.delete_rounded),
                  onPressed: () => _deleteCategory(category),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
