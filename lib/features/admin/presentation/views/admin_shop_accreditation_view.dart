import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../widgets/admin_desktop_header.dart';
import '../widgets/admin_sidebar_nav.dart';
import 'admin_dashboard_view.dart';
import 'admin_blacklist_tribunal_view.dart';
import 'admin_subscriptions_view.dart';
import 'admin_settings_view.dart';

class AdminShopAccreditationView extends StatefulWidget {
  const AdminShopAccreditationView({super.key});

  @override
  State<AdminShopAccreditationView> createState() => _AdminShopAccreditationViewState();
}

class _AdminShopAccreditationViewState extends State<AdminShopAccreditationView> {
  final List<Map<String, dynamic>> _shops = [
    {
      'id': 'shop-101',
      'name': 'Khyber Car Rentals',
      'city': 'Peshawar (University Rd)',
      'ntn': 'NTN-7749102-1',
      'owner': 'Javed Afridi',
      'status': 'pending',
    },
    {
      'id': 'shop-102',
      'name': 'Clifton Prestige Autos',
      'city': 'Karachi (DHA Phase 6)',
      'ntn': 'NTN-8812399-4',
      'owner': 'Shahmeer Khan',
      'status': 'pending',
    },
    {
      'id': 'shop-103',
      'name': 'Faisalabad Motors',
      'city': 'Faisalabad (D-Ground)',
      'ntn': 'NTN-4491021-9',
      'owner': 'Chaudhry Akram',
      'status': 'verified',
    },
  ];

  void _handleNavigation(String route) {
    if (route == 'accreditation') return;
    Widget destination;
    switch (route) {
      case 'dashboard':
        destination = const AdminDashboardView();
        break;
      case 'blacklist':
        destination = const AdminBlacklistTribunalView();
        break;
      case 'subscriptions':
        destination = const AdminSubscriptionsView();
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

  void _approveShop(int index) {
    setState(() {
      _shops[index]['status'] = 'verified';
    });
    AppFeedback.showSuccess(context, 'Showroom accredited! Digital license issued.');
  }

  void _rejectShop(int index) {
    setState(() {
      _shops[index]['status'] = 'rejected';
    });
    AppFeedback.showInfo(context, 'Accreditation rejected. Formal audit notice dispatched.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminSidebarNav(activeRoute: 'accreditation', onNavigate: _handleNavigation),
          Expanded(
            child: Column(
              children: [
                const AdminDesktopHeader(
                  title: 'Showroom Accreditation Queue',
                  subtitle: 'KYC Document Validation & Commercial Regulatory Approval',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: WidgetStateProperty.all(AppColors.backgroundLight),
                        columns: const [
                          DataColumn(label: Text('Showroom Name', style: TextStyle(fontWeight: FontWeight.w900))),
                          DataColumn(label: Text('City / District', style: TextStyle(fontWeight: FontWeight.w900))),
                          DataColumn(label: Text('Govt NTN / Reg', style: TextStyle(fontWeight: FontWeight.w900))),
                          DataColumn(label: Text('Proprietor', style: TextStyle(fontWeight: FontWeight.w900))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w900))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w900))),
                        ],
                        rows: _shops.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final s = entry.value;
                          final isVerified = s['status'] == 'verified';
                          final isPending = s['status'] == 'pending';

                          return DataRow(cells: [
                            DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w700))),
                            DataCell(Text(s['city'])),
                            DataCell(Text(s['ntn'], style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                            DataCell(Text(s['owner'])),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isVerified ? AppColors.emeraldGreen.withAlpha(25) : (isPending ? AppColors.softOrangeTint : Colors.red.withAlpha(25)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: isVerified ? AppColors.emeraldGreen : (isPending ? AppColors.sunsetOrange : Colors.red),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  if (isPending) ...[
                                    ElevatedButton(
                                      onPressed: () => _approveShop(idx),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen, foregroundColor: Colors.white),
                                      child: const Text('Accredit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: () => _rejectShop(idx),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    ),
                                  ] else
                                    const Text('Audit Complete', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                      ),
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
}
