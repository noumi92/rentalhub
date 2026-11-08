import 'package:flutter/material.dart';

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
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Account name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: type,
              decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder()),
              items: const ['cash', 'bank', 'jazzcash', 'easypaisa']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => type = v ?? 'cash',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          DebouncedButton(
            text: 'Save account',
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Partner name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Share (%)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          DebouncedButton(
            text: 'Save partner',
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
