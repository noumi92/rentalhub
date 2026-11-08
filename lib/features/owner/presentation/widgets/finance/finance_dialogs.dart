import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import  '../../../../finance/data/datasources/finance_account_data_source.dart';
import  '../../../../finance/data/datasources/partner_share_data_source.dart';

/// Phase B (H1/H4): the add-account and add-partner dialogs,
/// extracted from [OwnerFinanceView] so the view stays under the
/// 250-line cap.
class FinanceDialogs {
  static Future<bool> showAddAccount(
      BuildContext context, String shopId) async {
    final nameController = TextEditingController();
    String type = 'cash';
    final l10n = AppLocalizations.of(context)!;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.financeAddAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                  labelText: l10n.financeAccountName, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: type,
              decoration: InputDecoration(
                  labelText: l10n.financeAccountTypeLabel, border: OutlineInputBorder()),
              items: const ['cash', 'bank', 'jazzcash', 'easypaisa']
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_accountTypeLabel(l10n, t))))
                  .toList(),
              onChanged: (v) => type = v ?? 'cash',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          DebouncedButton(
            text: l10n.financeSaveAccount,
            onPressed: () async {
              try {
                await sl<FinanceAccountDataSource>().saveAccount(
                  shopId: shopId,
                  name: nameController.text,
                  type: type,
                );
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, '$e');
                }
              }
            },
          ),
        ],
      ),
    );
    return saved == true;
  }

  static Future<bool> showAddPartner(
      BuildContext context, String shopId) async {
    final nameController = TextEditingController();
    final percentController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.financeAddPartner),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                  labelText: l10n.financePartnerName, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: l10n.financePartnerShare, border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          DebouncedButton(
            text: l10n.financeSavePartner,
            onPressed: () async {
              try {
                await sl<PartnerShareDataSource>().savePartner(
                  shopId: shopId,
                  partnerName: nameController.text,
                  sharePercent:
                      int.tryParse(percentController.text.trim()) ?? 0,
                );
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, '$e');
                }
              }
            },
          ),
        ],
      ),
    );
    return saved == true;
  }
}

/// Stored account-type codes mapped to localized labels — the stored
/// value itself is never changed.
String _accountTypeLabel(AppLocalizations l10n, String type) => {'cash': l10n.financeAccountTypeCash, 'bank': l10n.financeAccountTypeBank, 'jazzcash': l10n.financeAccountTypeJazzCash, 'easypaisa': l10n.financeAccountTypeEasyPaisa}[type] ?? type;
