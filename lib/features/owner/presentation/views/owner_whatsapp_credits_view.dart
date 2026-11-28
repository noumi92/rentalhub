import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/whatsapp_credits_data_source.dart';
import '../widgets/coming_soon_banner.dart';
import '../widgets/whatsapp_packages_preview_list.dart';

/// W1 — Unified WhatsApp Packages & Coming Soon Hub:
/// Displays the Coming Soon notice, real credit balance, all defined
/// WhatsApp packages (Bronze / Silver / Gold) with Coming Soon badges,
/// and read-only automation preview toggles.
class OwnerWhatsappCreditsView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerWhatsappCreditsView({super.key, this.onBack});

  @override
  State<OwnerWhatsappCreditsView> createState() =>
      _OwnerWhatsappCreditsViewState();
}

class _OwnerWhatsappCreditsViewState extends State<OwnerWhatsappCreditsView> {
  final _dataSource = WhatsappCreditsDataSource();
  int? _balance;
  WhatsappAutoSettings _settings = const WhatsappAutoSettings();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final shopId = currentShopId();
      final balance = await _dataSource.getBalance(shopId);
      final settings = await _dataSource.getAutoSettings(shopId);
      if (mounted) {
        setState(() {
          _balance = balance;
          _settings = settings;
        });
      }
    } catch (e) {
      debugPrint('OwnerWhatsappCreditsView load failed: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toggles = <({String label, String? note, bool value})>[
      (label: l10n.creditsToggleBooking, note: null, value: _settings.bookingApproval),
      (label: l10n.creditsToggleAdvance, note: null, value: _settings.advanceReceipt),
      (label: l10n.creditsTogglePickup, note: l10n.creditsTogglePickupNote, value: _settings.pickupReminder),
      (label: l10n.creditsToggleAgreement, note: null, value: _settings.agreementPdf),
      (label: l10n.creditsToggleReturn, note: null, value: _settings.returnReminder),
      (label: l10n.creditsToggleDeposit, note: null, value: _settings.depositRefunded),
      (label: l10n.creditsToggleDues, note: l10n.creditsToggleDuesNote, value: _settings.duesReminder),
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.adminTabWhatsappPackages,
              subtitle: l10n.packagesComingSoonBadge,
              onBack: widget.onBack,
              actions: [
                IconButton(
                  tooltip: l10n.creditsViewTemplates,
                  icon: const Icon(Icons.preview_rounded, color: Colors.white),
                  onPressed: () =>
                      context.push(RouteNames.ownerWhatsappTemplate),
                ),
              ],
            ),
            Expanded(
              child: _hasError
                  ? AppErrorState(
                      message: l10n.whatsappCreditsLoadError, onRetry: _load)
                  : _balance == null
                      ? const AppLoadingState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          children: [
                            ComingSoonBanner(
                              title: l10n.whatsappFeatureComingSoonTitle,
                              body: l10n.whatsappFeatureComingSoonBody,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppCardDecoration.shadow(context),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.creditsBalance,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text('$_balance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  if (_balance == 0)
                                    Text(l10n.creditsEmpty,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  const SizedBox(height: 4),
                                  Text(l10n.creditsOneMessage,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const WhatsappPackagesPreviewList(),
                            const SizedBox(height: 16),
                            Text(l10n.creditsAutoMessages,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(l10n.creditsAutoNote,
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            ...toggles.map((t) => SwitchListTile(
                                  title: Text(t.label),
                                  subtitle: t.note == null ? null : Text(t.note!),
                                  value: t.value,
                                  // Read-only preview while WhatsApp Cloud API is Coming Soon.
                                  onChanged: null,
                                )),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
