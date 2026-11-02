import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../widgets/admin_desktop_header.dart';
import '../widgets/admin_sidebar_nav.dart';
import 'admin_dashboard_view.dart';
import 'admin_shop_accreditation_view.dart';
import 'admin_blacklist_tribunal_view.dart';
import 'admin_subscriptions_view.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  final _broadcastTitleController = TextEditingController();
  final _broadcastMsgController = TextEditingController();
  String _targetAudience = 'All Showrooms';
  bool _isBroadcasting = false;

  @override
  void dispose() {
    _broadcastTitleController.dispose();
    _broadcastMsgController.dispose();
    super.dispose();
  }

  void _handleNavigation(String route) {
    if (route == 'settings') return;
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
      case 'subscriptions':
        destination = const AdminSubscriptionsView();
        break;
      default:
        destination = const AdminDashboardView();
        break;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  void _sendBroadcast() {
    final title = _broadcastTitleController.text.trim();
    final msg = _broadcastMsgController.text.trim();
    if (title.isEmpty || msg.isEmpty) {
      AppFeedback.showError(context, 'Please enter broadcast title and message body.');
      return;
    }

    setState(() => _isBroadcasting = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isBroadcasting = false;
          _broadcastTitleController.clear();
          _broadcastMsgController.clear();
        });
        AppFeedback.showSuccess(context, 'System broadcast dispatched to $_targetAudience via push & SMS!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminSidebarNav(activeRoute: 'settings', onNavigate: _handleNavigation),
          Expanded(
            child: Column(
              children: [
                const AdminDesktopHeader(
                  title: 'System Broadcasts & Financial Exports',
                  subtitle: 'Platform-wide Communications & Regulatory Compliance Exports',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _broadcastComposer(),
                        const SizedBox(height: 24),
                        _exportSection(),
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

  Widget _broadcastComposer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compose Platform Push Broadcast', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _targetAudience,
            decoration: const InputDecoration(labelText: 'Target Audience Segment', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'All Showrooms', child: Text('All Registered Showrooms & Hosts')),
              DropdownMenuItem(value: 'All Customers', child: Text('All Verified Renters / Customers')),
              DropdownMenuItem(value: 'Nationwide All', child: Text('Platform-wide (Showrooms + Customers)')),
            ],
            onChanged: (v) => setState(() => _targetAudience = v ?? 'All Showrooms'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastTitleController,
            decoration: const InputDecoration(labelText: 'Broadcast Notification Title', hintText: 'e.g. Critical Eid Holiday Travel Guidelines', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastMsgController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message Body', hintText: 'Enter comprehensive bulletin text...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DebouncedButton(
            text: _isBroadcasting ? 'Broadcasting...' : 'Dispatch Platform Broadcast',
            icon: Icons.campaign_rounded,
            isLoading: _isBroadcasting,
            onPressed: _sendBroadcast,
          ),
        ],
      ),
    );
  }

  Widget _exportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial & Tribunal Audit Logs Export', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => AppFeedback.showSuccess(context, 'Exported all completed transactions to CSV!'),
                icon: const Icon(Icons.table_chart_rounded, size: 18),
                label: const Text('Export Ledger (CSV)', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => AppFeedback.showSuccess(context, 'Tribunal blacklist court bundle PDF generated!'),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Export Tribunal Dossier (PDF)', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

