import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../widgets/admin_desktop_header.dart';
import '../widgets/admin_sidebar_nav.dart';
import 'admin_dashboard_view.dart';
import 'admin_shop_accreditation_view.dart';
import 'admin_blacklist_tribunal_view.dart';
import 'admin_settings_view.dart';

class AdminSubscriptionsView extends StatefulWidget {
  const AdminSubscriptionsView({super.key});

  @override
  State<AdminSubscriptionsView> createState() => _AdminSubscriptionsViewState();
}

class _AdminSubscriptionsViewState extends State<AdminSubscriptionsView> {
  int _whatsAppCredits = 14200;
  int _smsCredits = 8450;

  void _handleNavigation(String route) {
    if (route == 'subscriptions') return;
    Widget destination;
    switch (route) {
      case 'dashboard':
        destination = const AdminDashboardView();
        break;
      case 'accreditation':
        destination = const AdminShopAccreditationView();
        break;
      case 'blacklist':
        destination = const AdminBlacklistTribunalView();
        break;
      case 'settings':
        destination = const AdminSettingsView();
        break;
      default:
        destination = const AdminDashboardView();
        break;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  void _topUpCredits(String gateway) {
    setState(() {
      if (gateway == 'WhatsApp') {
        _whatsAppCredits += 5000;
      } else {
        _smsCredits += 5000;
      }
    });
    AppFeedback.showSuccess(context, '$gateway gateway balance topped up by +5,000 units.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminSidebarNav(activeRoute: 'subscriptions', onNavigate: _handleNavigation),
          Expanded(
            child: Column(
              children: [
                const AdminDesktopHeader(
                  title: 'Subscriptions & Messaging Gateway Credit',
                  subtitle: 'Showroom Tier Monetization & Telecommunication Infra Balances',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Showroom Membership Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _tierCard('Basic Freemium', '58 Shops', 'Max 3 cars each', AppColors.midnightNavy),
                            const SizedBox(width: 16),
                            _tierCard('Pro Showroom (Rs. 4.9k/mo)', '24 Shops', 'Rs. 119,976/mo MRR', AppColors.sunsetOrange),
                            const SizedBox(width: 16),
                            _tierCard('Enterprise Fleet (Rs. 13k/mo)', '5 Showrooms', 'Rs. 64,995/mo MRR', AppColors.emeraldGreen),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text('Nationwide Messaging Gateway Reserves', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _gatewayCard('WhatsApp Meta Cloud API', '$_whatsAppCredits msgs', Icons.chat_bubble_rounded, const Color(0xFF25D366), () => _topUpCredits('WhatsApp')),
                            const SizedBox(width: 16),
                            _gatewayCard('Telenor / Jazz OTP SMS Gateway', '$_smsCredits units', Icons.sms_rounded, Colors.purple, () => _topUpCredits('SMS')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(String title, String count, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 6),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _gatewayCard(String name, String balance, IconData icon, Color color, VoidCallback onTopUp) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: color.withAlpha(25), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                  Text('Balance: $balance', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTopUp,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
              child: const Text('Top Up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
