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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _trxIdController.dispose();
    super.dispose();
  }

  void _showUpgradeModal(String tierName, int price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                Text('Upgrade to $tierName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Transfer Rs. $price via Raast / IBAN to activate instant showroom accreditation.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bank: Meezan Bank Ltd.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  Text('Title: RentalHub Pakistan PVT Ltd.', style: TextStyle(fontSize: 12)),
                  Text('IBAN: PK64MEZN0001234567890123', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sunsetOrange)),
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
      backgroundColor: AppColors.backgroundLight,
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
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Showroom Membership Plans', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('Grow Your Showroom Fleet with RentalHub', style: TextStyle(color: AppColors.textLavender, fontSize: 11.5)),
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

