import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/whatsapp_credits_data_source.dart';
import '../../../../core/theme/card_decoration.dart';

/// W1 — WhatsApp credits + auto-message toggles (deck p.19 screen 1;
/// also O53 toggles and O54 balance card — one screen covers all
/// three). Gated on D2 (Meta/WhatsApp): the balance is the REAL
/// `whatsapp_credits` balance (0 with an honest empty state — never
/// the deck's example 84), and every toggle carries the honest note
/// that messages send automatically only once WhatsApp is connected.
class OwnerWhatsappCreditsView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerWhatsappCreditsView({super.key, this.onBack});

  @override
  State<OwnerWhatsappCreditsView> createState() =>
      _OwnerWhatsappCreditsViewState();
}

class _OwnerWhatsappCreditsViewState
    extends State<OwnerWhatsappCreditsView> {
  final _dataSource = WhatsappCreditsDataSource();
  int? _balance;
  WhatsappAutoSettings _settings = const WhatsappAutoSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shopId = currentShopId();
    final balance = await _dataSource.getBalance(shopId);
    final settings = await _dataSource.getAutoSettings(shopId);
    if (mounted) {
      setState(() {
        _balance = balance;
        _settings = settings;
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    final previous = _settings;
    setState(() => _settings = _settings.copyWithKey(key, value));
    try {
      await _dataSource.saveAutoToggle(currentShopId(), key, value);
    } catch (_) {
      if (mounted) {
        setState(() => _settings = previous);
        AppFeedback.showError(
            context, AppLocalizations.of(context)!.shopSaveError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toggles = <({String key, String label, String? note, bool value})>[
      (
        key: 'bookingApproval',
        label: l10n.creditsToggleBooking,
        note: null,
        value: _settings.bookingApproval
      ),
      (
        key: 'advanceReceipt',
        label: l10n.creditsToggleAdvance,
        note: null,
        value: _settings.advanceReceipt
      ),
      (
        key: 'pickupReminder',
        label: l10n.creditsTogglePickup,
        note: l10n.creditsTogglePickupNote,
        value: _settings.pickupReminder
      ),
      (
        key: 'agreementPdf',
        label: l10n.creditsToggleAgreement,
        note: null,
        value: _settings.agreementPdf
      ),
      (
        key: 'returnReminder',
        label: l10n.creditsToggleReturn,
        note: null,
        value: _settings.returnReminder
      ),
      (
        key: 'depositRefunded',
        label: l10n.creditsToggleDeposit,
        note: null,
        value: _settings.depositRefunded
      ),
      (
        key: 'duesReminder',
        label: l10n.creditsToggleDues,
        note: l10n.creditsToggleDuesNote,
        value: _settings.duesReminder
      ),
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.creditsTitle,
              subtitle: l10n.creditsOneMessage,
              onBack: widget.onBack,
              actions: [
                IconButton(
                  tooltip: l10n.creditsViewHistory,
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                  onPressed: () =>
                      context.push(RouteNames.ownerWhatsappHistory),
                ),
                IconButton(
                  tooltip: l10n.creditsViewTemplates,
                  icon:
                      const Icon(Icons.preview_rounded, color: Colors.white),
                  onPressed: () =>
                      context.push(RouteNames.ownerWhatsappTemplate),
                ),
              ],
            ),
            Expanded(
              child: _balance == null
                  ? const AppLoadingState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      children: [
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
                                          fontWeight: FontWeight.w800)),
                              Text('$_balance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w900)),
                              if (_balance == 0)
                                Text(l10n.creditsEmpty,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              const SizedBox(height: 4),
                              Text(l10n.creditsOneMessage,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.creditsAutoMessages,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(l10n.creditsAutoNote,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        ...toggles.map((t) => SwitchListTile(
                              title: Text(t.label),
                              subtitle: t.note == null
                                  ? null
                                  : Text(t.note!),
                              value: t.value,
                              onChanged: (v) => _toggle(t.key, v),
                            )),
                        const SizedBox(height: 16),
                        DebouncedButton(
                          text: l10n.creditsBuy,
                          icon: Icons.add_shopping_cart_rounded,
                          onPressed: () => context
                              .push(RouteNames.ownerWhatsappBuyCredits),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
