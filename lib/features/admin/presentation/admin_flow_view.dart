import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/mock_data.dart';

class AdminFlowView extends StatefulWidget {
  final String initialAnchor;
  const AdminFlowView({super.key, this.initialAnchor = 'ANC-17'});

  @override
  State<AdminFlowView> createState() => _AdminFlowViewState();
}

class _AdminFlowViewState extends State<AdminFlowView> {
  late String _activeSection; // 'dashboard', 'accreditation', 'blacklist', 'subscriptions'

  // Admin interactive state
  final Set<String> _accreditedShops = {};
  final Set<String> _liftedBans = {};
  int _activeRentalsCount = 412;
  int _blacklistCount = 29;

  @override
  void initState() {
    super.initState();
    _setSectionFromAnchor(widget.initialAnchor);
  }

  void _setSectionFromAnchor(String anchor) {
    switch (anchor) {
      case 'ANC-18':
        _activeSection = 'accreditation';
        break;
      case 'ANC-19':
        _activeSection = 'blacklist';
        break;
      case 'ANC-20':
        _activeSection = 'subscriptions';
        break;
      case 'ANC-17':
      default:
        _activeSection = 'dashboard';
        break;
    }
  }

  @override
  void didUpdateWidget(covariant AdminFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAnchor != widget.initialAnchor) {
      setState(() {
        _setSectionFromAnchor(widget.initialAnchor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Row(
            children: [
              // Desktop Left Sidebar (240px)
              _buildSidebar(),

              // Main Dynamic Content Area
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                        child: _buildCurrentSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppColors.midnightNavyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.sunsetOrange, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RentalHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Super Admin Control', style: TextStyle(color: AppColors.textLavender, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Sidebar Navigation Links
          _buildSidebarLink('Overview Dashboard', Icons.dashboard_rounded, 'dashboard', isAnchor17: true),
          _buildSidebarLink('Shop Accreditations (12)', Icons.verified_rounded, 'accreditation', isAnchor18: true),
          _buildSidebarLink('National Blacklist Registry', Icons.gavel_rounded, 'blacklist', isAnchor19: true),
          _buildSidebarLink('Host Subscriptions & Quota', Icons.card_membership_rounded, 'subscriptions', isAnchor20: true),

          const Spacer(),
          const Divider(color: Colors.white12),

          // Logged in User Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.sunsetOrange,
                  radius: 16,
                  child: Icon(Icons.security, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Master Super Admin', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('superadmin@rentalhub.pk', style: TextStyle(color: AppColors.textLavender.withOpacity(0.7), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarLink(String title, IconData icon, String sectionKey, {bool isAnchor17 = false, bool isAnchor18 = false, bool isAnchor19 = false, bool isAnchor20 = false}) {
    final isSelected = _activeSection == sectionKey;
    return InkWell(
      onTap: () => setState(() => _activeSection = sectionKey),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sunsetOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textLavender.withOpacity(0.8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textLavender.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 350,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Search CNIC (35201-...), phone, shop, or booking...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.emeraldSoftBg, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.emeraldGreen, size: 14),
                SizedBox(width: 4),
                Text('All Systems Operational (cPanel + Firebase)', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_activeSection) {
      case 'accreditation':
        return _buildAccreditationQueue();
      case 'blacklist':
        return _buildBlacklistRegistry();
      case 'subscriptions':
        return _buildSubscriptionsView();
      case 'dashboard':
      default:
        return _buildDashboardSection();
    }
  }

  // ==========================================
  // ANC-17 / A-02: Super Admin Operations Dashboard
  // ==========================================
  Widget _buildDashboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Operations & Telemetry',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
        ),
        const Text('National automotive rental governance, NADRA verification, and dispute tribunal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        // 4 Dark KPI Cards
        Row(
          children: [
            _buildAdminKpiCard('Total Verified Shops', '184', '+8 this week', Icons.store, AppColors.emeraldGreen),
            const SizedBox(width: 12),
            _buildAdminKpiCard('Active Rentals Today', '$_activeRentalsCount', 'Across 4 cities', Icons.directions_car, AppColors.sunsetOrange),
            const SizedBox(width: 12),
            _buildAdminKpiCard('Blacklisted CNICs', '$_blacklistCount', 'Nationwide Ban', Icons.gavel, AppColors.crimsonRed),
            const SizedBox(width: 12),
            _buildAdminKpiCard('Pending Accreditations', '12', 'Requires Review', Icons.verified_user, AppColors.amberWarning),
          ],
        ),

        const SizedBox(height: 20),

        // Two Column Tables
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Shop Accreditation Preview
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pending Shop Accreditations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        TextButton(
                          onPressed: () => setState(() => _activeSection = 'accreditation'),
                          child: const Text('View All (12) →', style: TextStyle(fontSize: 12, color: AppColors.sunsetOrange)),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildShopApprovalRow('Lahore Wheels & Rentals', 'M. Tariq (35201-8931201-9)', 'Lahore (Gulberg)', '24 Cars', 's_lahore'),
                    _buildShopApprovalRow('Capital Executive Cruisers', 'Usman Shah (61101-4491023-5)', 'Islamabad (F-10)', '18 Cars', 's_isb'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Right Column: Fraud Blacklist Central Tribunal
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fraud Blacklist Central Tribunal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        TextButton(
                          onPressed: () => setState(() => _activeSection = 'blacklist'),
                          child: const Text('Manage Ledger →', style: TextStyle(fontSize: 12, color: AppColors.crimsonRed)),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildBlacklistPreviewRow('35201-9918234-1', 'Hamza Shafiq', 'Absconded with car / unpaid PKR 45k', 'Al-Falah Motors'),
                    _buildBlacklistPreviewRow('42201-5501928-7', 'Zubair Ahmed', 'Tampered GPS tracker', 'Rehman Motors'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminKpiCard(String label, String value, String subtitle, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopApprovalRow(String shopName, String owner, String location, String fleet, String key) {
    final isApproved = _accreditedShops.contains(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('$owner • $location • $fleet', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (isApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.emeraldSoftBg, borderRadius: BorderRadius.circular(8)),
              child: const Text('Accredited ✓', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.w800, fontSize: 11)),
            )
          else
            ElevatedButton(
              onPressed: () {
                setState(() => _accreditedShops.add(key));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accredited $shopName! Verified badge granted.')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Accredit', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildBlacklistPreviewRow(String cnic, String name, String reason, String reporter) {
    final isReverted = _liftedBans.contains(cnic);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(cnic, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.crimsonRed)),
                    const SizedBox(width: 6),
                    Text('($name)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                Text('$reason • Reported by $reporter', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (isReverted)
            const Text('Ban Lifted', style: TextStyle(fontSize: 11, color: AppColors.emeraldGreen, fontWeight: FontWeight.w700))
          else
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _liftedBans.add(cnic);
                  _blacklistCount--;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lifted blacklist on CNIC $cnic')));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: const Text('Lift Ban', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-18 / A-03: Shop Accreditation Queue
  // ==========================================
  Widget _buildAccreditationQueue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop Accreditation & Document Audit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                Text('12 rental shops waiting for business compliance & SECP review', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported Compliance Ledger to CSV.')));
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Shop Entity')),
              DataColumn(label: Text('Owner CNIC')),
              DataColumn(label: Text('City')),
              DataColumn(label: Text('Fleet Size')),
              DataColumn(label: Text('SECP / NTN')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              _buildDataRow('Lahore Wheels', '35201-8931201-9', 'Lahore', '24 Cars', 'Verified', 'k1'),
              _buildDataRow('Capital Executive Cruisers', '61101-4491023-5', 'Islamabad', '18 Cars', 'Pending Check', 'k2'),
              _buildDataRow('Karachi Coastline Drive', '42201-9018273-3', 'Karachi', '35 Cars', 'Verified', 'k3'),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(String name, String cnic, String city, String fleet, String status, String key) {
    final isDone = _accreditedShops.contains(key);
    return DataRow(
      cells: [
        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
        DataCell(Text(cnic)),
        DataCell(Text(city)),
        DataCell(Text(fleet)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.emeraldSoftBg, borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: const TextStyle(fontSize: 11, color: AppColors.emeraldGreen, fontWeight: FontWeight.w700)),
        )),
        DataCell(
          isDone
              ? const Text('Accredited ✓', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.w800))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                      onPressed: () {
                        setState(() => _accreditedShops.add(key));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accredited $name!')));
                      },
                      child: const Text('Accredit', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ==========================================
  // ANC-19 / A-05: National Blacklist Registry
  // ==========================================
  Widget _buildBlacklistRegistry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('National Rental Blacklist Registry & Inquest Tribunal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const Text('Centralized fraud prevention database preventing delinquent renters across Pakistan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Flagged CNIC')),
              DataColumn(label: Text('Customer Name')),
              DataColumn(label: Text('Reporting Host')),
              DataColumn(label: Text('Violation Summary')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Override')),
            ],
            rows: MockDatabase.blacklist.map((entry) {
              final isReverted = _liftedBans.contains(entry.cnic);
              return DataRow(
                cells: [
                  DataCell(Text(entry.cnic, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.crimsonRed))),
                  DataCell(Text(entry.fullName)),
                  DataCell(Text(entry.reportedBy)),
                  DataCell(Text(entry.incidentCategory)),
                  DataCell(Text(isReverted ? 'Ban Lifted' : entry.status, style: TextStyle(fontWeight: FontWeight.w700, color: isReverted ? AppColors.emeraldGreen : AppColors.crimsonRed))),
                  DataCell(
                    isReverted
                        ? const Text('Settled', style: TextStyle(fontSize: 11, color: AppColors.textMuted))
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                            onPressed: () {
                              setState(() {
                                _liftedBans.add(entry.cnic);
                                _blacklistCount--;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tribunal lifted blacklist on ${entry.fullName}')));
                            },
                            child: const Text('Lift Ban', style: TextStyle(fontSize: 10)),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ANC-20 / A-08: Subscriptions & Fleet Quotas
  // ==========================================
  Widget _buildSubscriptionsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Host Subscription Tiers & Quota Governance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const Text('Manage the 3-car freemium barrier, Pro Garage, and Enterprise Fleet tiers in Pakistan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        Row(
          children: [
            _buildTierCard('Free Starter Tier', 'Max 3 Cars', 'PKR 0 / month', '112 Active Shops', false),
            const SizedBox(width: 14),
            _buildTierCard('Pro Garage Tier', 'Up to 15 Cars', 'PKR 5,000 / month', '54 Active Shops', true),
            const SizedBox(width: 14),
            _buildTierCard('Enterprise Fleet', 'Unlimited Cars', 'PKR 15,000 / month', '18 Active Shops', false),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hosts Approaching Freemium Limit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const Divider(),
              _buildUpgradeLead('Al-Falah Rent a Car', 'Lahore', '3 / 3 Cars (100% Limit)', 'Free Starter'),
              _buildUpgradeLead('Capital Cruisers', 'Islamabad', '14 / 15 Cars (93% Limit)', 'Pro Garage'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard(String name, String quota, String price, String activeCount, bool isPopular) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPopular ? AppColors.sunsetOrange : AppColors.border, width: isPopular ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.sunsetOrange, borderRadius: BorderRadius.circular(6)),
                    child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
            Text(quota, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sunsetOrange)),
            const Divider(height: 18),
            Text(activeCount, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeLead(String shop, String city, String usage, String tier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text('$city • $usage • Current: $tier', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldGreen,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispatched Pro Upgrade proposal to $shop via WhatsApp.')));
            },
            icon: const Icon(Icons.send, size: 12),
            label: const Text('Send Pro Upgrade', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

