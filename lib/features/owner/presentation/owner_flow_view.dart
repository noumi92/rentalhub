import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/curved_header.dart';
import '../../../core/widgets/fuel_gauge_widget.dart';
import '../../../core/widgets/signature_pad.dart';
import '../../../core/widgets/vehicle_damage_schematic_widget.dart';

class OwnerFlowView extends StatefulWidget {
  final String initialAnchor;
  const OwnerFlowView({super.key, this.initialAnchor = 'ANC-10'});

  @override
  State<OwnerFlowView> createState() => _OwnerFlowViewState();
}

class _OwnerFlowViewState extends State<OwnerFlowView> {
  late String
  _activeScreen; // 'onboarding', 'dashboard', 'fleet', 'rates', 'requests', 'handover', 'return', 'blacklist'
  int _activeNavIndex = 0;

  // Requests state
  String _requestStatus1 = 'Pending';
  int _pendingCount = 3;

  // Handover state
  int _fuelBars = 6;
  int _odometerCurrent = 42850;
  bool _customerSigned = true;
  bool _hostSigned = true;

  // Return state
  int _returnOdometer = 42920;
  int _returnFuelBars = 6;
  bool _newDamage = false;

  @override
  void initState() {
    super.initState();
    _setScreenFromAnchor(widget.initialAnchor);
  }

  void _setScreenFromAnchor(String anchor) {
    switch (anchor) {
      case 'ANC-09':
        _activeScreen = 'onboarding';
        break;
      case 'ANC-11':
        _activeScreen = 'fleet';
        break;
      case 'ANC-12':
        _activeScreen = 'rates';
        break;
      case 'ANC-13':
        _activeScreen = 'requests';
        break;
      case 'ANC-14':
        _activeScreen = 'handover';
        break;
      case 'ANC-15':
        _activeScreen = 'return';
        break;
      case 'ANC-16':
        _activeScreen = 'blacklist';
        break;
      case 'ANC-10':
      default:
        _activeScreen = 'dashboard';
        break;
    }
  }

  @override
  void didUpdateWidget(covariant OwnerFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAnchor != widget.initialAnchor) {
      setState(() {
        _setScreenFromAnchor(widget.initialAnchor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: _buildCurrentScreen()),
          if (_activeScreen == 'dashboard' || _activeScreen == 'fleet')
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: _buildOwnerBottomNav(),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_activeScreen) {
      case 'onboarding':
        return _buildOnboardingScreen();
      case 'fleet':
        return _buildFleetInventoryScreen();
      case 'rates':
        return _buildAddVehicleRatesScreen();
      case 'requests':
        return _buildBookingRequestsScreen();
      case 'handover':
        return _buildHandoverScreen();
      case 'return':
        return _buildReturnScreen();
      case 'blacklist':
        return _buildBlacklistReportScreen();
      case 'dashboard':
      default:
        return _buildOwnerDashboardScreen();
    }
  }

  // ==========================================
  // ANC-10 / O-04: Owner Fleet Dashboard & KPIs
  // ==========================================
  Widget _buildOwnerDashboardScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurvedHeader(
            title: 'Al-Falah Rent a Car',
            subtitle: 'Gulberg III, Lahore • Verified Super Host',
            height: 250,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.sunsetOrange,
                size: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
            bottomContent: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppColors.emeraldGreen,
                        size: 10,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '14 / 18 Vehicles on Road',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Occupancy: 78%',
                    style: TextStyle(
                      color: AppColors.sunsetOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2x2 KPI Cards Grid (Overlapping Header by -24px)
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildKpiCard(
                    'Active Rentals Today',
                    '14 Cars',
                    Icons.directions_car,
                    isNavy: true,
                  ),
                  _buildKpiCard(
                    'Pending Requests',
                    '$_pendingCount New',
                    Icons.pending_actions,
                    isOrange: true,
                    onTap: () => setState(() => _activeScreen = 'requests'),
                  ),
                  _buildKpiCard(
                    "Today's Revenue",
                    'PKR 38,500',
                    Icons.payments_outlined,
                    subtitle: '+12% vs yesterday',
                  ),
                  _buildKpiCard(
                    'Handovers Slotted',
                    '2 Due Now',
                    Icons.qr_code_scanner,
                    isAmber: true,
                    onTap: () => setState(() => _activeScreen = 'handover'),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions Circular Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  'Add Vehicle',
                  Icons.add_circle,
                  AppColors.sunsetOrange,
                  () => setState(() => _activeScreen = 'rates'),
                ),
                _buildQuickAction(
                  'Fleet (18)',
                  Icons.directions_car,
                  AppColors.midnightNavy,
                  () => setState(() => _activeScreen = 'fleet'),
                ),
                _buildQuickAction(
                  'Blacklist',
                  Icons.shield_outlined,
                  AppColors.crimsonRed,
                  () => setState(() => _activeScreen = 'blacklist'),
                ),
                _buildQuickAction(
                  'Return Check',
                  Icons.assignment_turned_in,
                  AppColors.emeraldGreen,
                  () => setState(() => _activeScreen = 'return'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Live Rentals on Road Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Rentals on Road (14)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightNavy,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _activeScreen = 'fleet'),
                  child: const Text(
                    'View Fleet',
                    style: TextStyle(
                      color: AppColors.sunsetOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Trip 1 (Ahmed Khan)
          _buildLiveTripCard(
            vehicleName: 'Honda Civic Oriel 2021',
            plate: 'LEA-4820',
            renterName: 'Ahmed Khan (35201-*****-1)',
            status: '2h 45m left (Due 6:00 PM)',
            onHandover: () => setState(() => _activeScreen = 'handover'),
            onReturn: () => setState(() => _activeScreen = 'return'),
          ),

          const SizedBox(height: 10),

          // Live Trip 2 (Usman Ali)
          _buildLiveTripCard(
            vehicleName: 'Toyota Corolla Grande 2022',
            plate: 'ICT-9912',
            renterName: 'Usman Ali (61101-*****-3)',
            status: 'Due Tomorrow 10:00 AM',
            onHandover: () => setState(() => _activeScreen = 'handover'),
            onReturn: () => setState(() => _activeScreen = 'return'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon, {
    bool isNavy = false,
    bool isOrange = false,
    bool isAmber = false,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNavy ? AppColors.midnightNavyDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNavy ? AppColors.midnightNavyDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isNavy
                      ? Colors.white70
                      : isOrange
                      ? AppColors.sunsetOrange
                      : isAmber
                      ? AppColors.amberWarning
                      : AppColors.midnightNavy,
                ),
                if (isOrange)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetOrange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACT NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isNavy ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isNavy ? Colors.white70 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTripCard({
    required String vehicleName,
    required String plate,
    required String renterName,
    required String status,
    required VoidCallback onHandover,
    required VoidCallback onReturn,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Text(
                vehicleName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.midnightNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.sunsetOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Plate: $plate • Renter: $renterName',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onHandover,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Handover Signatures',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onReturn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Return & Settle',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-11 / O-05: Fleet Inventory
  // ==========================================
  Widget _buildFleetInventoryScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Fleet Inventory (18 Cars)',
              subtitle: 'Al-Falah Rent a Car • Realtime Fleet Status',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.sunsetOrange,
                  ),
                  tooltip: 'Add Vehicle',
                  onPressed: () => setState(() => _activeScreen = 'rates'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('All (18)', true),
                        _buildFilterPill(
                          'Available (4)',
                          false,
                          color: AppColors.emeraldGreen,
                        ),
                        _buildFilterPill(
                          'Rented Out (14)',
                          false,
                          color: AppColors.sunsetOrange,
                        ),
                        _buildFilterPill('Maintenance (0)', false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Vehicle items
                  _buildInventoryTile(
                    'Honda Civic Oriel 2021',
                    'LEA-4820',
                    'PKR 9,000 / day',
                    'RENTED OUT (Due 6:00 PM)',
                    AppColors.sunsetOrange,
                    onAction: () => setState(() => _activeScreen = 'handover'),
                  ),
                  const SizedBox(height: 10),
                  _buildInventoryTile(
                    'Toyota Corolla Grande 2022',
                    'ICT-9912',
                    'PKR 8,500 / day',
                    'AVAILABLE IN SHOP',
                    AppColors.emeraldGreen,
                    onAction: () => setState(() => _activeScreen = 'rates'),
                  ),
                  const SizedBox(height: 10),
                  _buildInventoryTile(
                    'Suzuki Alto VXL 2023',
                    'LHR-1029',
                    'PKR 3,500 / day',
                    'RENTED OUT (Due Tomorrow)',
                    AppColors.sunsetOrange,
                    onAction: () => setState(() => _activeScreen = 'return'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.midnightNavy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTile(
    String name,
    String plate,
    String rate,
    String status,
    Color statusColor, {
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car,
              color: AppColors.midnightNavy,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$plate • $rate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Manage', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-13 / O-09: Booking Requests Triage
  // ==========================================
  Widget _buildBookingRequestsScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Booking Requests Triage',
              subtitle: '$_pendingCount Pending Review • High Demand',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Card 1 (Ahmed Khan)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _requestStatus1 == 'Approved'
                            ? AppColors.emeraldGreen
                            : AppColors.border,
                        width: _requestStatus1 == 'Approved' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Booking #RH-84920',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _requestStatus1 == 'Approved'
                                    ? AppColors.emeraldSoftBg
                                    : AppColors.orangeSoftBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _requestStatus1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _requestStatus1 == 'Approved'
                                      ? AppColors.emeraldGreen
                                      : AppColors.sunsetOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.midnightNavy,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ahmed Khan (35201-1234567-1)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Trust Score: 4.9 ★ • NADRA Verified • Clean Record',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.emeraldGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        const Text(
                          'Requested: Honda Civic 2021 (LEA-4820)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Package: 3-Hour QuickRide (Today 2:00 PM - 5:00 PM)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Text(
                          'Total Fare: PKR 3,500 • Advance Token: PKR 1,000',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.midnightNavy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_requestStatus1 == 'Pending')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _requestStatus1 = 'Declined';
                                      _pendingCount--;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Reservation request declined.',
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.crimsonRed,
                                    side: const BorderSide(
                                      color: AppColors.crimsonRed,
                                    ),
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _requestStatus1 = 'Approved';
                                      _pendingCount--;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Approved! WhatsApp alert dispatched with JazzCash deposit details.',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Approve & Request Token ✓',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _activeScreen = 'handover'),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Open Vehicle Handover Screen →'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ANC-14 / O-12: Vehicle Handover & Signatures
  // ==========================================
  Widget _buildHandoverScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Vehicle Handover Inspection',
              subtitle: 'Honda Civic 2021 • LEA-4820 • Renter: Ahmed Khan',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Odometer & Fuel metrics row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Odometer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_odometerCurrent km',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnightNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cluster photo verified!'),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Cluster Photo ✓',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fuel Tank Level',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_fuelBars / 8 Bars (75%)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnightNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(8, (i) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: i < _fuelBars
                                            ? AppColors.sunsetOrange
                                            : AppColors.border,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Calibrated 8-Segment Interactive Fuel Gauge
                  FuelGaugeWidget(
                    fuelLevel: _fuelBars / 8.0,
                    onChanged: (val) =>
                        setState(() => _fuelBars = (val * 8).round()),
                  ),

                  const SizedBox(height: 14),

                  // Interactive 4-Quadrant Damage Schematic
                  const VehicleDamageSchematicWidget(),

                  const SizedBox(height: 14),

                  // Dual Touch Signatures
                  SignaturePadWidget(
                    signerLabel: 'Renter Digital Signature',
                    signerName: 'Ahmed Khan (Customer)',
                    onSignedChange: (val) => _customerSigned = val,
                  ),

                  const SizedBox(height: 12),

                  SignaturePadWidget(
                    signerLabel: 'Host Digital Signature',
                    signerName: 'Muhammad Bilal (Al-Falah Motors)',
                    onSignedChange: (val) => _hostSigned = val,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (!_customerSigned || !_hostSigned) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please ensure both Renter and Host signatures are completed.',
                    ),
                    backgroundColor: AppColors.crimsonRed,
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Handover verified! Legal A4 agreement PDF generated & sent to customer WhatsApp.',
                  ),
                ),
              );
              setState(() => _activeScreen = 'dashboard');
            },
            child: const Text('Generate & Sign Digital Agreement (PDF) ✓'),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ANC-15 / O-14: Vehicle Return & Settlement
  // ==========================================
  Widget _buildReturnScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Vehicle Return & Settlement',
              subtitle: 'Honda Civic 2021 (LEA-4820) • Close Booking',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Odometer Comparison Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Odometer Audit',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Handover KM: 42,850 km',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Return KM: $_returnOdometer km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.midnightNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Distance Driven: 70 km (Within 150 km limit • Extra km Fee: PKR 0)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.emeraldGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Fuel Comparison Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fuel Level Return',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Handover: 75% -> Return: ${_returnFuelBars == 6 ? "75%" : "${_returnFuelBars * 100 ~/ 8}%"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _newDamage ? AppColors.crimsonSoftBg : AppColors.emeraldSoftBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _newDamage ? 'Damage Reported' : 'Matched (Zero Fee)',
                            style: TextStyle(
                              color: _newDamage ? AppColors.crimsonRed : AppColors.emeraldGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Final Cash Settlement Ledger
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Final Financial Settlement',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.midnightNavy,
                          ),
                        ),
                        const Divider(height: 20),
                        _buildRow('Agreed Trip Fare', 'PKR 3,500'),
                        _buildRow(
                          'Less Advance Token Paid',
                          '- PKR 1,000',
                          color: AppColors.emeraldGreen,
                        ),
                        _buildRow('Overtime / Penalty Charges', 'PKR 0'),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cash Balance to Collect',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'PKR 2,500',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: AppColors.sunsetOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Collected PKR 2,500! Booking closed & vehicle released back to available fleet.',
                  ),
                ),
              );
              setState(() => _activeScreen = 'dashboard');
            },
            child: const Text('Collect PKR 2,500 & Close Booking ✓'),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-16 / O-16: Fraud Blacklist Report
  // ==========================================
  Widget _buildBlacklistReportScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Report to National Blacklist',
              subtitle: 'Centralized Fraud Prevention Desk',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonSoftBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.crimsonRed.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.crimsonRed),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: Reporting restricts this CNIC across Pakistan. False reports will lead to host shop suspension.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.crimsonRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildFormField('Customer CNIC', '35201-9918234-1'),
                  _buildFormField('Customer Full Name', 'Hamza Shafiq'),
                  _buildFormField(
                    'Violation Category',
                    'Absconded with vehicle / Tracker tampered',
                  ),
                  _buildFormField(
                    'Incident Narrative',
                    'Failed to return vehicle after 48 hours. Unpaid balance PKR 45,000.',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Evidence Attached: FIR-492-Gulberg.pdf (Verified)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimsonRed,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Blacklist case submitted to Super Admin Tribunal!',
                  ),
                ),
              );
              setState(() => _activeScreen = 'dashboard');
            },
            child: const Text('Submit to Super Admin Tribunal ⚠️'),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ANC-09 / O-01: Shop Onboarding
  // ==========================================
  Widget _buildOnboardingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          children: [
            CurvedHeader(
              title: 'Register as Shop Owner',
              subtitle: 'Step 1 of 3 • Basic Shop Details',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFormField('Shop / Garage Name', 'Al-Falah Rent a Car'),
                  _buildFormField('Owner Full Name', 'Muhammad Bilal'),
                  _buildFormField('CNIC Number', '35201-9876543-1'),
                  _buildFormField('WhatsApp Mobile', '+92 300 1234567'),
                  _buildFormField(
                    'City / Operating Area',
                    'Lahore • Gulberg III',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Onboarding details saved!')),
              );
              setState(() => _activeScreen = 'dashboard');
            },
            child: const Text('Save & Launch Host Dashboard →'),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ANC-12 / O-07: Add Vehicle Rate Matrix
  // ==========================================
  Widget _buildAddVehicleRatesScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          children: [
            CurvedHeader(
              title: 'Vehicle Rates & Packages',
              subtitle: 'Honda Civic 2021 • LEA-4820',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFormField('In-City Daily Rate (24h)', 'PKR 9,000'),
                  _buildFormField('Out-of-City Daily Rate (24h)', 'PKR 12,000'),
                  _buildFormField('1-Hour Quick Booking Rate', 'PKR 1,500'),
                  _buildFormField('3-Hour Standard Booking Rate', 'PKR 3,500'),
                  _buildFormField(
                    'Mandatory Advance Token',
                    'PKR 1,000 (Default)',
                  ),
                  _buildFormField(
                    'Daily Mileage Limit',
                    '150 km / day (PKR 35/extra km)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rates published to catalog!')),
              );
              setState(() => _activeScreen = 'fleet');
            },
            child: const Text('Save & Publish Rates ✓'),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, String value, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.midnightNavyDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            0,
            Icons.dashboard,
            'Dashboard',
            () => setState(() => _activeScreen = 'dashboard'),
          ),
          _buildNavItem(
            1,
            Icons.inbox,
            'Requests',
            () => setState(() => _activeScreen = 'requests'),
          ),
          _buildNavItem(
            2,
            Icons.directions_car,
            'Fleet',
            () => setState(() => _activeScreen = 'fleet'),
          ),
          _buildNavItem(
            3,
            Icons.shield_outlined,
            'Blacklist',
            () => setState(() => _activeScreen = 'blacklist'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isSelected = _activeNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _activeNavIndex = index);
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.sunsetOrange : Colors.white70,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.sunsetOrange : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
