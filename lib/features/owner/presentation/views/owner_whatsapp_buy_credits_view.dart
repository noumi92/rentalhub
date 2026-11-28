import 'package:flutter/material.dart';

import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/subscription_data_source.dart';
import '../widgets/coming_soon_banner.dart';
import '../widgets/whatsapp_packages_preview_list.dart';

/// W2 — WhatsApp Credit Packages preview (initial launch phase):
/// Shows all defined credit packs (Bronze / Silver / Gold) with Coming Soon
/// badges and hides the Buy / Purchase button until WhatsApp Cloud API launches.
class OwnerWhatsappBuyCreditsView extends StatefulWidget {
  const OwnerWhatsappBuyCreditsView({super.key});

  @override
  State<OwnerWhatsappBuyCreditsView> createState() =>
      _OwnerWhatsappBuyCreditsViewState();
}

class _OwnerWhatsappBuyCreditsViewState
    extends State<OwnerWhatsappBuyCreditsView> {
  final _subs = SubscriptionDataSource();
  String _tier = 'free';

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    try {
      final state = await _subs.getShopSubscription(currentShopId());
      if (mounted) setState(() => _tier = state.tier);
    } catch (_) {}
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
              title: l10n.adminTabWhatsappPackages,
              subtitle: l10n.packagesComingSoonBadge,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  ComingSoonBanner(
                    title: l10n.whatsappFeatureComingSoonTitle,
                    body: l10n.whatsappFeatureComingSoonBody,
                  ),
                  const SizedBox(height: 14),
                  WhatsappPackagesPreviewList(tier: _tier),
                  const SizedBox(height: 12),
                  Text(
                    l10n.creditsOneMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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
