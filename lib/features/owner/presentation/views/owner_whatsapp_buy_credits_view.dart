import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/manual_bank_transfer_sheet.dart';
import '../services/subscription_data_source.dart';
import '../services/whatsapp_credits_data_source.dart';
import '../../../../core/theme/card_decoration.dart';

/// W2 — Buy credits (deck p.19 screen 2). Pack cards with the deck's
/// prices, free monthly credits per plan, and a Buy button that opens
/// the manual bank-transfer flow — never Google Play, which is not
/// connected (D1/D2). After submitting, the owner sees the honest
/// "request submitted" state (W3), not a fake "credits added".
class OwnerWhatsappBuyCreditsView extends StatefulWidget {
  const OwnerWhatsappBuyCreditsView({super.key});

  @override
  State<OwnerWhatsappBuyCreditsView> createState() =>
      _OwnerWhatsappBuyCreditsViewState();
}

class _OwnerWhatsappBuyCreditsViewState
    extends State<OwnerWhatsappBuyCreditsView> {
  final _credits = WhatsappCreditsDataSource();
  final _subs = SubscriptionDataSource();
  WhatsappCreditPack _selected = whatsappCreditPacks[2];
  String _tier = 'free';

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final state = await _subs.getShopSubscription(currentShopId());
    if (mounted) setState(() => _tier = state.tier);
  }

  void _buy(WhatsappCreditPack pack) {
    final l10n = AppLocalizations.of(context)!;
    ManualBankTransferSheet.show(
      context,
      title: '${l10n.creditsBuy} · ${pack.credits}',
      amount: pack.price,
      note: l10n.creditsPayByBank,
      onSubmit: (trxId) => _credits.submitCreditPurchaseRequest(
        shopId: currentShopId(),
        pack: pack.credits,
        amount: pack.price,
        transactionId: trxId,
      ),
      onSubmitted: () {
        AppFeedback.showSuccess(context, l10n.creditsRequestSubmittedTitle);
        context.push(RouteNames.ownerWhatsappCreditsAdded, extra: {
          'requestSubmitted': true,
          'pack': pack.credits,
          'price': pack.price,
        });
      },
    );
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
              title: l10n.creditsBuyTitle,
              subtitle: l10n.creditsTitle,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  ...whatsappCreditPacks.map((pack) {
                    final selected = pack == _selected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selected = pack),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                            boxShadow: AppCardDecoration.shadow(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${pack.credits} ${l10n.creditsTitle}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w900)),
                                  if (pack.bestValue)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(l10n.creditsPackBestValue,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w900)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${l10n.amountRs(formatRs(pack.price))} · ${l10n.amountRs(pack.perMessage)} ${l10n.creditsPerMessage}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Text(l10n.creditsFreeMonthly,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l10n.creditsFreePlanFree,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(l10n.creditsFreePlanPro,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(l10n.creditsFreePlanBusiness,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                      '${l10n.creditsFreeLabel}: ${freeMonthlyCreditsForTier(_tier)}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  DebouncedButton(
                    text: l10n.creditsBuyPack,
                    icon: Icons.add_shopping_cart_rounded,
                    onPressed: () => _buy(_selected),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.creditsOneMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
