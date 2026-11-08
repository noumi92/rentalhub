import 'package:flutter/material.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upgrade to $tierName', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Transfer Rs. $price via Raast / IBAN to activate instant showroom accreditation.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bank: Meezan Bank Ltd.', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Title: RentalHub Pakistan PVT Ltd.', style: Theme.of(context).textTheme.bodySmall),
                  Text('IBAN: PK64MEZN0001234567890123', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _trxIdController,
              decoration: InputDecoration(
                labelText: 'Bank Transfer Transaction ID / Reference',
                hintText: 'e.g. TRX-998822',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            DebouncedButton(
              text: 'Submit Upgrade Verification',
              icon: Icons.check_circle_rounded,
              isLoading: _isSubmitting,
              onPressed: () {
                if (_trxIdController.text.trim().isEmpty) {
                  AppFeedback.showError(ctx, 'Please enter transaction ID');
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _currentTier = tierName.toLowerCase());
                AppFeedback.showSuccess(context, 'Upgrade requested! Super Admin review in progress.');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Showroom Membership Plans', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Grow Your Showroom Fleet with RentalHub', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  SubscriptionTierCard(
                    title: 'Starter Freemium',
                    price: 'Rs. 0',
                    billingPeriod: 'Forever Free',
                    isCurrent: _currentTier == 'basic',
                    features: const [
                      'Max 3 Showroom Vehicles',
                      'Standard Digital Agreements',
                      'Customer Verification Check',
                    ],
                    onSelect: () {},
                  ),
                  const SizedBox(height: 14),
                  SubscriptionTierCard(
                    title: 'Pro Showroom',
                    price: 'Rs. 4,999',
                    billingPeriod: '/ month',
                    isPopular: true,
                    isCurrent: _currentTier == 'pro',
                    features: const [
                      'Unlimited Fleet Vehicles',
                      'Real-time National Blacklist Radar',
                      'WhatsApp Automated Invoicing & Pass',
                      'Custom Multi-tier Pricing Matrix',
                    ],
                    onSelect: () => _showUpgradeModal('Pro', 4999),
                  ),
                  const SizedBox(height: 14),
                  SubscriptionTierCard(
                    title: 'Enterprise Fleet',
                    price: 'Rs. 12,999',
                    billingPeriod: '/ month',
                    isCurrent: _currentTier == 'enterprise',
                    features: const [
                      'Multi-branch Fleet Synchronization',
                      'Dedicated Account Manager',
                      'GPS Telematics API Integration',
                      'Priority Dispute Tribunal Hearings',
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

