import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../widgets/dashboard/subscription_tier_card.dart';

class OwnerSubscriptionView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerSubscriptionView({super.key, this.onBack});

  @override
  State<OwnerSubscriptionView> createState() => _OwnerSubscriptionViewState();
}

class _OwnerSubscriptionViewState extends State<OwnerSubscriptionView> {
  String _currentTier = 'basic';
  final _trxIdController = TextEditingController();
  final bool _isSubmitting = false;

  @override
  void dispose() {
    _trxIdController.dispose();
    super.dispose();
  }

  void _showUpgradeModal(String tierName, int price) {
  final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.subscriptionUpgradeTo(tierName),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                IconButton(
                    tooltip: l10n.subscriptionClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                l10n.subscriptionTransfer(price),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bank: Meezan Bank Ltd.',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Title: RentalHub Pakistan PVT Ltd.',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('IBAN: PK64MEZN0001234567890123',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _trxIdController,
              decoration: InputDecoration(
                labelText: l10n.subscriptionTrxLabel,
                hintText: l10n.subscriptionTrxHint,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            DebouncedButton(
              text: l10n.subscriptionSubmit,
              icon: Icons.check_circle_rounded,
              isLoading: _isSubmitting,
              onPressed: () {
                if (_trxIdController.text.trim().isEmpty) {
                  AppFeedback.showError(ctx, l10n.subscriptionEnterTrx);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _currentTier = tierName.toLowerCase());
                AppFeedback.showSuccess(context,
                    l10n.subscriptionRequested);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      tooltip: l10n.back,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.subscriptionTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.subscriptionSubtitle,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  SubscriptionTierCard(
                    title: 'Starter Freemium',
                    price: 'Rs. 0',
                    billingPeriod: l10n.subscriptionForeverFree,
                    isCurrent: _currentTier == 'basic',
                    features: [
                      l10n.subscriptionFeatureMax3,
                      l10n.subscriptionFeatureAgreements,
                      l10n.subscriptionFeatureVerification,
                    ],
                    onSelect: () {},
                  ),
                  const SizedBox(height: 14),
                  SubscriptionTierCard(
                    title: 'Pro Showroom',
                    price: 'Rs. 4,999',
                    billingPeriod: l10n.subscriptionPerMonth,
                    isPopular: true,
                    isCurrent: _currentTier == 'pro',
                    features: [
                      l10n.subscriptionFeatureUnlimited,
                      l10n.subscriptionFeatureRadar,
                      l10n.subscriptionFeatureWhatsappInvoicing,
                      l10n.subscriptionFeaturePricingMatrix,
                    ],
                    onSelect: () => _showUpgradeModal('Pro', 4999),
                  ),
                  const SizedBox(height: 14),
                  SubscriptionTierCard(
                    title: 'Enterprise Fleet',
                    price: 'Rs. 12,999',
                    billingPeriod: l10n.subscriptionPerMonth,
                    isCurrent: _currentTier == 'enterprise',
                    features: [
                      l10n.subscriptionFeatureMultiBranch,
                      l10n.subscriptionFeatureManager,
                      l10n.subscriptionFeatureGps,
                      l10n.subscriptionFeatureTribunal,
                    ],
                    onSelect: () => _showUpgradeModal('Enterprise', 12999),
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
