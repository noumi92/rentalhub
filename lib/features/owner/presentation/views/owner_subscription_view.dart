import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../widgets/dashboard/subscription_tier_card.dart';
import '../../../../core/utils/money_format.dart';

class OwnerSubscriptionView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerSubscriptionView({super.key, this.onBack});

  @override
  State<OwnerSubscriptionView> createState() => _OwnerSubscriptionViewState();
}

class _OwnerSubscriptionViewState extends State<OwnerSubscriptionView> {
  // Audit §28: no stored current-tier source — shops start on Basic; pending upgrades track separately.
  final String _currentTier = 'basic';
  String? _pendingTier;
  final _trxIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingRequest();
  }

  // Audit §28: the upgrade was local `setState` only and reset on reopen; a pending record now persists.
  Future<void> _loadPendingRequest() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('subscription_requests')
          .where('shopId', isEqualTo: currentShopId())
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      final tier = snap.docs.firstOrNull?.data()['tier'] as String?;
      if (tier != null && tier.isNotEmpty && mounted) {
        setState(() => _pendingTier = tier);
      }
    } catch (_) {
      // No pending request visible (offline / no index yet) — tiers still render; the submit path reports its own error.
    }
  }

  @override
  void dispose() {
    _trxIdController.dispose();
    super.dispose();
  }

  void _showUpgradeModal(String tierId, String tierName, int price) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              Text(l10n.subscriptionTransfer(formatRs(price)),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    // Audit §28: was orange small text (~3.5:1); now
                    // `onSurface`. Still hardcoded — no bank-details
                    // field exists in `platform_settings/global`.
                    Text('IBAN: PK64MEZN0001234567890123',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _trxIdController,
                decoration: InputDecoration(
                  labelText: l10n.subscriptionTrxLabel,
                  hintText: l10n.subscriptionTrxHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              DebouncedButton(
                text: l10n.subscriptionSubmit,
                icon: Icons.check_circle_rounded,
                isLoading: _isSubmitting,
                onPressed: () async {
                  if (_trxIdController.text.trim().isEmpty) {
                    AppFeedback.showError(ctx, l10n.subscriptionEnterTrx);
                    return;
                  }
                  setModalState(() => _isSubmitting = true);
                  setState(() => _isSubmitting = true);
                  try {
                    await FirebaseFirestore.instance
                        .collection('subscription_requests')
                        .add({
                      'shopId': currentShopId(),
                      'tier': tierId,
                      'transactionId': _trxIdController.text.trim(),
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _trxIdController.clear();
                    if (mounted) {
                      setState(() => _pendingTier = tierId);
                      AppFeedback.showSuccess(
                          context, l10n.subscriptionRequested);
                    }
                  } catch (_) {
                    if (mounted) {
                      AppFeedback.showError(context, l10n.shopSaveError);
                    }
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
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
              title: l10n.subscriptionTitle,
              subtitle: l10n.subscriptionSubtitle,
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  SubscriptionTierCard(
                    title: l10n.subscriptionTierStarter,
                    pricePkr: 0,
                    billingPeriod: l10n.subscriptionForeverFree,
                    isCurrent: _currentTier == 'basic',
                    isPending: _pendingTier == 'basic',
                    features: [
                      l10n.subscriptionFeatureMax3,
                      l10n.subscriptionFeatureAgreements,
                      l10n.subscriptionFeatureVerification,
                    ],
                    onSelect: () {},
                  ),
                  const SizedBox(height: 14),
                  SubscriptionTierCard(
                    title: l10n.subscriptionTierPro,
                    pricePkr: 4999,
                    billingPeriod: l10n.subscriptionPerMonth,
                    isPopular: true,
                    isCurrent: _currentTier == 'pro',
                    isPending: _pendingTier == 'pro',
                    features: [
                      l10n.subscriptionFeatureUnlimited,
                      l10n.subscriptionFeatureRadar,
                      l10n.subscriptionFeatureWhatsappInvoicing,
                      l10n.subscriptionFeaturePricingMatrix,
                    ],
                    onSelect: () => _showUpgradeModal('pro', 'Pro', 4999),
                  ),
                  const SizedBox(height: 14),
                  SubscriptionTierCard(
                    title: l10n.subscriptionTierEnterprise,
                    pricePkr: 12999,
                    billingPeriod: l10n.subscriptionPerMonth,
                    isCurrent: _currentTier == 'enterprise',
                    isPending: _pendingTier == 'enterprise',
                    features: [
                      l10n.subscriptionFeatureMultiBranch,
                      l10n.subscriptionFeatureManager,
                      l10n.subscriptionFeatureGps,
                      l10n.subscriptionFeatureTribunal,
                    ],
                    onSelect: () => _showUpgradeModal('enterprise',
                        'Enterprise', 12999),
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
