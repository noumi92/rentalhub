import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import 'admin_confirm_dialog.dart';
import 'admin_permission_check.dart';
import 'shop_fleet_photos.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../domain/admin_permissions.dart';

/// The B1 review sheet for one shop application: the 6-item checklist
/// (computed from the shop document), the KYC documents and bank
/// accounts on file, fleet photos (tap to zoom), and the decision —
/// Approve, Ask for more info, or Reject with a reason the owner sees.
class ShopApplicationDetailSheet extends StatefulWidget {
  const ShopApplicationDetailSheet({
    super.key,
    required this.shop,
    required this.onDecided,
  });

  final ShopModel shop;
  final VoidCallback onDecided;

  @override
  State<ShopApplicationDetailSheet> createState() =>
      _ShopApplicationDetailSheetState();
}

class _ShopApplicationDetailSheetState
    extends State<ShopApplicationDetailSheet> {
  final _reasonController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _decide(String decision) async {
    final reason = _reasonController.text.trim();
    if (decision != 'approved' && reason.isEmpty) {
      AppFeedback.showError(context,
          (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_shopAppReasonRequired);
      return;
    }
    // F-C1: super admin + operations only (decideVendor). A role
    // that lacks it is blocked here; an unknown role proceeds and
    // the data source decides (fail closed).
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.decideVendor);
    if (!check.proceed) return;
    if (!mounted) return;
    // Phase 1 (1.1): every decision notifies the owner — confirm
    // it first, naming the decision. (The reason field is required
    // for non-approved decisions; approval needs no reason.)
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final decisionLabel = decision == 'approved'
        ? l10n.admin2_approve
        : decision == 'info_requested'
            ? l10n.admin2_shopAppAskInfo
            : l10n.admin2_reject;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: l10n.admin2_shopAppConfirmTitle,
      body: l10n.admin2_shopAppConfirmBody(decisionLabel),
    );
    if (!confirmed) return;
    if (!mounted) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().decideShopApplication(
      shopId: widget.shop.shopId,
      decision: decision,
      reason: reason,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
          context, (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_decisionSaved);
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context,
          (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_serverUnreachableRetry);
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final checklist = ShopApplicationChecklist.fromShop(shop, l10n);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.shopName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 4),
            Text('${shop.city} • ${shop.address}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(
                l10n.admin2_shopAppOwner(shop.ownerName ?? '—',
                    shop.phoneNumber, shop.cnicNumber ?? '—'),
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text(l10n.admin2_shopAppChecklist(checklist.doneCount),
                style: const TextStyle(
                    fontSize: 14,
                    )),
            const SizedBox(height: 8),
            ...checklist.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        // Audit 2026-11-15 AC-4: green.shade700 /
                        // amber.shade800 fail AA as 18 px icons in
                        // light mode — the readable tokens instead.
                        color: item.done
                            ? AppColors.successTextFor(
                                Theme.of(context).brightness)
                            : AppColors.warningTextFor(
                                Theme.of(context).brightness),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.label)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            _section(l10n.admin2_shopAppKycDocs,
                shop.kycDocuments.isEmpty
                    ? [l10n.admin2_shopDetailNoneUploaded]
                    : shop.kycDocuments.keys.toList()),
            _section(l10n.admin2_shopDetailBankAccounts,
                shop.bankAccounts.isEmpty
                    ? [l10n.admin2_shopDetailNoneOnFile]
                    : shop.bankAccounts
                        .map((a) =>
                            '${a['type'] ?? l10n.admin2_shopDetailAccountType} — ${a['title'] ?? a['account'] ?? ''}')
                        .toList()),
            if (shop.fleetPhotos.isNotEmpty) ...[
              Text(l10n.admin2_shopAppFleetPhotos,
                  style: TextStyle(
                      fontSize: 14,
                      )),
              const SizedBox(height: 8),
              ShopFleetPhotos(photoUrls: shop.fleetPhotos),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.admin2_shopAppReasonLabel,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // Mobile-first: the three decisions stack full-width on
            // a phone — side by side each is ~100dp and "Ask for
            // more info" wraps to 4 lines. 48dp touch targets.
            if (windowSizeClassOf(context) ==
                WindowSizeClass.compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _approveButton(),
                  const SizedBox(height: 8),
                  _infoButton(),
                  const SizedBox(height: 8),
                  _rejectButton(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _approveButton()),
                  const SizedBox(width: 8),
                  Expanded(child: _infoButton()),
                  const SizedBox(width: 8),
                  Expanded(child: _rejectButton()),
                ],
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text(l10n.admin2_shopAppCallOwner),
                onPressed: shop.phoneNumber.isEmpty
                    ? null
                    : () async {
                        // AD-m16: check the launch result — a failed
                        // tel: launch used to fail silently.
                        final opened = await launchUrl(
                            Uri.parse('tel:${shop.phoneNumber}'));
                        if (!opened) {
                          if (!context.mounted) return;
                          AppFeedback.showError(
                              context,
                              AppLocalizations.of(context)
                                      ?.admin2_callFailed ??
                                  'Could not open the dialer.');
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _approveButton() => FilledButton(
        onPressed: _isWorking ? null : () => _decide('approved'),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        child: Text((AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_approve),
      );

  Widget _infoButton() => OutlinedButton(
        onPressed:
            _isWorking ? null : () => _decide('info_requested'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        child: Text((AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_shopAppAskInfo),
      );

  Widget _rejectButton() => OutlinedButton(
        onPressed: _isWorking ? null : () => _decide('rejected'),
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            minimumSize: const Size(0, 48)),
        child: Text((AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_reject),
      );

  Widget _section(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  )),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )),
        ],
      ),
    );
  }
}
