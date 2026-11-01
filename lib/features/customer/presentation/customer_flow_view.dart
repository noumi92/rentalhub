import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/mock_data.dart';
import '../../../core/widgets/curved_header.dart';
import '../../../core/widgets/demo_hud_bar.dart';
import '../../../core/widgets/pakistani_plate_widget.dart';

class CustomerFlowView extends StatefulWidget {
  final String initialAnchor;
  const CustomerFlowView({super.key, this.initialAnchor = 'ANC-01'});

  @override
  State<CustomerFlowView> createState() => _CustomerFlowViewState();
}

class _CustomerFlowViewState extends State<CustomerFlowView> {
  late String
      _activeScreen; // 'discovery', 'detail', 'review', 'payment', 'pass', 'active', 'rate', 'kyc'
  MockVehicle _selectedVehicle = MockDatabase.vehicles.first;
  String _selectedPackage = '3-Hour QuickRide (PKR 3,500)';
  int _selectedFare = 3500;
  final int _advanceToken = 1000;
  int _activeNavIndex = 0;

  // Rating state
  int _hostStars = 5;
  int _carStars = 5;
  final Set<String> _selectedFeedbackTags = {'Spotless Interior', 'Chilled AC'};

  // Payment state
  String _enteredTxId = 'TX98412850';
  bool _proofAttached = true;

  @override
  void initState() {
    super.initState();
    _setScreenFromAnchor(widget.initialAnchor);
  }

  void _setScreenFromAnchor(String anchor) {
    switch (anchor) {
      case 'ANC-02':
        _activeScreen = 'detail';
        break;
      case 'ANC-03':
        _activeScreen = 'payment';
        break;
      case 'ANC-04':
        _activeScreen = 'review';
        break;
      case 'ANC-05':
        _activeScreen = 'pass';
        break;
      case 'ANC-06':
        _activeScreen = 'active';
        break;
      case 'ANC-07':
        _activeScreen = 'kyc';
        break;
      case 'ANC-08':
        _activeScreen = 'rate';
        break;
      case 'ANC-01':
      default:
        _activeScreen = 'discovery';
        break;
    }
  }

  @override
  void didUpdateWidget(covariant CustomerFlowView oldWidget) {
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
          // Main Scrollable Flow Content
          Positioned.fill(
            child: _buildCurrentScreen(),
          ),
          // Top Floating HUD Role Switcher
          const Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(child: DemoHudBar()),
          ),
          // Floating Bottom Navigation (Visible on Discovery and Active Dashboard)
          if (_activeScreen == 'discovery' || _activeScreen == 'active')
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: _buildFloatingBottomNav(),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_activeScreen) {
      case 'detail':
        return _buildVehicleDetailScreen();
      case 'review':
        return _buildReviewReservationScreen();
      case 'payment':
        return _buildUploadPaymentProofScreen();
      case 'pass':
        return _buildPickupPassScreen();
      case 'active':
        return _buildActiveTripDashboard();
      case 'rate':
        return _buildRateTripScreen();
      case 'kyc':
        return _buildKycUploadScreen();
      case 'discovery':
      default:
        return _buildCustomerDiscoveryScreen();
    }
  }

  // ==========================================
  // ANC-01 / C-07: Customer Discovery Screen
  // ==========================================
  Widget _buildCustomerDiscoveryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurvedHeader(
            title: 'RentalHub',
            subtitle: 'Verified Car Rentals Near You in Pakistan',
            height: 250,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on,
                  color: AppColors.sunsetOrange, size: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.verified_user_outlined,
                    color: AppColors.emeraldGreen),
                tooltip: 'KYC Status',
                onPressed: () => setState(() => _activeScreen = 'kyc'),
              ),
            ],
            bottomContent: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.midnightNavy),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search city, make, sedan or SUV...',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orangeSoftBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune,
                            color: AppColors.sunsetOrange, size: 14),
                        SizedBox(width: 4),
                        Text('Lahore',
                            style: TextStyle(
                                color: AppColors.sunsetOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Chips Row (Overlapping CurvedHeader by -24px per DOC-2)
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                          'All Cars (4)', Icons.directions_car, true),
                      _buildCategoryChip(
                          'Sedans', Icons.directions_car_filled, false),
                      _buildCategoryChip('SUVs', Icons.terrain, false),
                      _buildCategoryChip('Economy', Icons.electric_car, false),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Verified Rental Shops Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verified Rental Shops (Gulberg III)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(
                          color: AppColors.sunsetOrange,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: MockDatabase.shops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shop = MockDatabase.shops[index];
                return _buildShopCard(shop);
              },
            ),
          ),

          // Available Vehicles Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Featured Fleet Ready for Instant Rent',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnightNavy),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSoftBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('NADRA Protected',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldGreen)),
                ),
              ],
            ),
          ),

          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: MockDatabase.vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final vehicle = MockDatabase.vehicles[index];
              return _buildVehicleCard(vehicle);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.midnightNavy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected ? AppColors.midnightNavy : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
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

  Widget _buildShopCard(MockShop shop) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.midnightNavyDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.storefront, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.midnightNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      shop.city,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified,
                  color: AppColors.emeraldGreen, size: 16),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '★ ${shop.rating} (${shop.reviews} reviews)',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${shop.fleetCount} Cars',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sunsetOrange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(MockVehicle vehicle) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicle = vehicle;
          _activeScreen = 'detail';
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Visual Banner
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.directions_car_filled_rounded,
                        size: 90, color: vehicle.brandColor.withOpacity(0.8)),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: PakistaniPlateWidget(
                      plateNumber: vehicle.plate,
                      isCompact: true,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle.status == 'Available'
                            ? AppColors.emeraldSoftBg
                            : AppColors.orangeSoftBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: vehicle.status == 'Available'
                                ? AppColors.emeraldGreen
                                : AppColors.sunsetOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.status == 'Available'
                                ? 'Available Now'
                                : 'Rented (Due 6PM)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: vehicle.status == 'Available'
                                  ? AppColors.emeraldGreen
                                  : AppColors.sunsetOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.midnightNavyDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'PKR ${vehicle.dailyRate} / day',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vehicle.fullName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text('${vehicle.rating}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(' (${vehicle.tripCount} trips)',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle.shopName} • ${vehicle.shopAddress}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Feature Chips
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildMiniBadge(vehicle.transmission, Icons.settings),
                      _buildMiniBadge('${vehicle.seats} Seats',
                          Icons.airline_seat_recline_normal),
                      _buildMiniBadge(
                          vehicle.fuelType, Icons.local_gas_station),
                      if (vehicle.hasAC)
                        _buildMiniBadge('Chilled AC', Icons.ac_unit),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QuickRide Hourly Package',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                          Text('From PKR ${vehicle.hourlyRate1}/hr',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sunsetOrange,
                                  fontSize: 12)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedVehicle = vehicle;
                            _activeScreen = 'detail';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Packages →',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.midnightNavy),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-02 / C-12: Vehicle Detail & Packages
  // ==========================================
  Widget _buildVehicleDetailScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: _selectedVehicle.fullName,
              subtitle:
                  '${_selectedVehicle.plate} • ${_selectedVehicle.shopName}',
              height: 200,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'discovery'),
            ),

            // Car Studio Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.directions_car_filled_rounded,
                        size: 110, color: _selectedVehicle.brandColor),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSoftBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.emeraldGreen, size: 14),
                          SizedBox(width: 4),
                          Text('Handover Photo Verified',
                              style: TextStyle(
                                  color: AppColors.emeraldGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Packages Selection Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Rental Duration Package',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnightNavy),
                  ),
                  const SizedBox(height: 10),
                  _buildPackageOption(
                    '1-Hour Quick Booking',
                    'PKR ${_selectedVehicle.hourlyRate1}',
                    'Ideal for airport pick/drop or quick meeting in-city.',
                    _selectedVehicle.hourlyRate1,
                  ),
                  const SizedBox(height: 8),
                  _buildPackageOption(
                    '3-Hour Standard Trip',
                    'PKR ${_selectedVehicle.hourlyRate3}',
                    'Most popular for shopping & hospital visits.',
                    _selectedVehicle.hourlyRate3,
                    isPopular: true,
                  ),
                  const SizedBox(height: 8),
                  _buildPackageOption(
                    '6-Hour Half-Day Tour',
                    'PKR ${_selectedVehicle.hourlyRate6}',
                    'Flexible in-city errands with 60km included.',
                    _selectedVehicle.hourlyRate6,
                  ),
                  const SizedBox(height: 8),
                  _buildPackageOption(
                    '24-Hour Full Day Rental',
                    'PKR ${_selectedVehicle.dailyRate}',
                    'Standard 24-hour daily package (150 km included).',
                    _selectedVehicle.dailyRate,
                  ),

                  const SizedBox(height: 16),

                  // Host Shop Credentials Card
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
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.midnightNavy,
                              child: Icon(Icons.store,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedVehicle.shopName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    _selectedVehicle.shopAddress,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.verified,
                                color: AppColors.emeraldGreen, size: 18),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHostStat('4.9 ★', 'Host Rating'),
                            _buildHostStat('148', 'Trips Done'),
                            _buildHostStat('100%', 'Clean Record'),
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
                offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Package Price',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(
                  'PKR $_selectedFare',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy),
                ),
                Text('Advance Token: PKR $_advanceToken',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.sunsetOrange,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _activeScreen = 'review');
              },
              child: const Text('Proceed to Review →'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageOption(String title, String price, String desc, int fare,
      {bool isPopular = false}) {
    final bool isSelected = _selectedFare == fare;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPackage = '$title ($price)';
          _selectedFare = fare;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orangeSoftBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sunsetOrange : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.sunsetOrange : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      if (isPopular) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.sunsetOrange,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('POPULAR',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(price,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.midnightNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildHostStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.midnightNavy)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  // ==========================================
  // ANC-04 / C-15: Review & Send Reservation
  // ==========================================
  Widget _buildReviewReservationScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Review Reservation',
              subtitle: 'Step 1 of 2 • Pre-authorization Notice',
              height: 190,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'detail'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle summary card
                  Container(
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
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.directions_car,
                              color: AppColors.midnightNavy, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedVehicle.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              Text(
                                  '${_selectedVehicle.plate} • ${_selectedVehicle.shopName}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Package: $_selectedPackage',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sunsetOrange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Fare Breakdown
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
                        const Text('Trip Cost Breakdown',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.midnightNavy)),
                        const Divider(height: 18),
                        _buildLedgerRow(
                            'Base Package Rental Fare', 'PKR $_selectedFare'),
                        _buildLedgerRow('Security Advance (Payable Now)',
                            'PKR $_advanceToken',
                            highlight: true),
                        _buildLedgerRow('Remaining Balance upon Handover',
                            'PKR ${_selectedFare - _advanceToken}'),
                        const Divider(height: 18),
                        _buildLedgerRow(
                            'Total Trip Charge', 'PKR $_selectedFare',
                            isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Important Pakistani Rental Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoftBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.amberWarning.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.amberWarning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Advance token (PKR 1,000) is paid directly to host via JazzCash / EasyPaisa / Bank transfer to lock the vehicle schedule.',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                                height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Special Host Notes Input
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            'Add special notes for host (e.g. airport meetup time)...',
                        hintStyle:
                            TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      maxLines: 2,
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
                offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _activeScreen = 'payment');
            },
            child: const Text('Send Request & Pay Advance Token →'),
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerRow(String label, String value,
      {bool highlight = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color:
                  highlight ? AppColors.sunsetOrange : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: highlight ? AppColors.sunsetOrange : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-03 / C-19: Upload Payment Proof
  // ==========================================
  Widget _buildUploadPaymentProofScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Upload Payment Proof',
              subtitle: 'Transfer PKR $_advanceToken Advance Deposit',
              height: 190,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'review'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.orangeSoftBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.sunsetOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: AppColors.sunsetOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Transfer PKR $_advanceToken directly to host accounts below, then attach the transaction screenshot and TxID.',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Host Payment Accounts',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.midnightNavy)),
                  const SizedBox(height: 8),

                  _buildAccountTile(
                      'JazzCash', '0300-1234567', 'Muhammad Bilal'),
                  _buildAccountTile(
                      'EasyPaisa', '0333-9876543', 'Muhammad Bilal'),
                  _buildAccountTile('Meezan Bank', 'PK45MEZN0001020304050607',
                      'Al-Falah Motors'),

                  const SizedBox(height: 16),
                  const Text('Upload Transfer Receipt Screenshot',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.midnightNavy)),
                  const SizedBox(height: 8),

                  // Dropzone container
                  InkWell(
                    onTap: () {
                      setState(() => _proofAttached = !_proofAttached);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(_proofAttached
                                ? 'Screenshot receipt selected'
                                : 'Screenshot removed')),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _proofAttached
                              ? AppColors.emeraldGreen
                              : AppColors.border,
                          width: _proofAttached ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _proofAttached
                                  ? Icons.check_circle
                                  : Icons.cloud_upload_outlined,
                              size: 38,
                              color: _proofAttached
                                  ? AppColors.emeraldGreen
                                  : AppColors.sunsetOrange,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _proofAttached
                                  ? 'receipt_jazzcash_1000.png (Attached)'
                                  : 'Tap to snap or upload receipt screenshot',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _proofAttached
                                    ? AppColors.emeraldGreen
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const Text('JPG, PNG supported up to 5MB',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TxID Input
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: TextEditingController(text: _enteredTxId),
                      onChanged: (val) => _enteredTxId = val,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Transaction ID / Reference Number',
                        labelStyle: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.tag,
                            color: AppColors.midnightNavy, size: 20),
                      ),
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
                offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Payment proof submitted! Host Al-Falah notified via WhatsApp.')),
              );
              setState(() => _activeScreen = 'pass');
            },
            child: const Text('Submit Payment Proof & Generate Pass ✓'),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(String provider, String account, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.midnightNavy,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(provider,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.midnightNavy)),
                    const SizedBox(width: 6),
                    Text('($title)',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                Text(account,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.copy, size: 18, color: AppColors.sunsetOrange),
            tooltip: 'Copy Number',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $account to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ANC-05 / C-20: Pickup Pass & Countdown
  // ==========================================
  Widget _buildPickupPassScreen() {
    return Scaffold(
      backgroundColor: AppColors.midnightNavyDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
          child: Column(
            children: [
              // Boarding Pass Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Pass Header
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: AppColors.midnightNavy,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('VEHICLE PICKUP PASS',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Text('Booking #RH-84920',
                                  style: TextStyle(
                                      color: AppColors.textLavender
                                          .withOpacity(0.8),
                                      fontSize: 12)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.emeraldGreen,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('CONFIRMED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10)),
                          ),
                        ],
                      ),
                    ),

                    // Countdown Banner
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: AppColors.orangeSoftBg,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer,
                              color: AppColors.sunsetOrange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Pickup In: 01h 45m (Today 2:00 PM)',
                            style: TextStyle(
                                color: AppColors.sunsetOrange,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // Perforated line simulation
                    Row(
                      children: List.generate(
                        25,
                        (index) => Expanded(
                          child: Container(
                            height: 2,
                            color: index.isEven
                                ? Colors.transparent
                                : AppColors.border,
                          ),
                        ),
                      ),
                    ),

                    // QR Code & Renter Details
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Simulated QR Code
                          Container(
                            height: 160,
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2_rounded,
                                    size: 100, color: AppColors.midnightNavy),
                                const SizedBox(height: 4),
                                Text(
                                  'RH-84920-VERIFIED',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          AppColors.textMuted.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Show this QR to host at handover',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          const Divider(),
                          _buildLedgerRow('Assigned Vehicle',
                              'Honda Civic 2021 (LEA-4820)'),
                          _buildLedgerRow('Host Garage',
                              'Al-Falah Rent a Car (Gulberg III)'),
                          _buildLedgerRow(
                              'Renter', 'Ahmed Khan (35201-*****-1)'),
                          _buildLedgerRow(
                              'Advance Deposit', 'PKR 1,000 Verified ✓'),
                          _buildLedgerRow(
                              'Balance at Pickup', 'PKR 2,500 Cash / QR'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Opening Google Maps navigation to Gulberg III...')),
                        );
                      },
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setState(() => _activeScreen = 'active'),
                      icon: const Icon(Icons.speed, size: 18),
                      label: const Text('Active Trip Hub →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ANC-06 / C-21: Active Trip Dashboard & SOS
  // ==========================================
  Widget _buildActiveTripDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurvedHeader(
            title: 'Live Trip Control Hub',
            subtitle: 'Booking #RH-84920 • Handover Verified',
            height: 220,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _activeScreen = 'discovery'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.emergency_share,
                    color: AppColors.crimsonRed),
                tooltip: 'Emergency SOS',
                onPressed: _showSosModal,
              ),
            ],
            bottomContent: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.emeraldSoftBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.emeraldGreen, size: 16),
                      SizedBox(width: 6),
                      Text('Dual Signatures Recorded (Legal PDF Signed)',
                          style: TextStyle(
                              color: AppColors.emeraldGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ],
                  ),
                  Text('Active',
                      style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Trip Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Honda Civic Oriel 2021',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.midnightNavy)),
                              const Text('Plate: LEA-4820 • Red Sedan',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.orangeSoftBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('2h 45m left',
                                style: TextStyle(
                                    color: AppColors.sunsetOrange,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Trip telemetry row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTelemetryItem(
                              Icons.speed, '42,850 km', 'Initial Odometer'),
                          _buildTelemetryItem(Icons.local_gas_station,
                              '6 / 8 Bars', 'Handover Fuel (75%)'),
                          _buildTelemetryItem(
                              Icons.schedule, '06:00 PM', 'Return Time'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Calling Host Muhammad Bilal (+92 300 1234567)...')),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text('Call Host'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  setState(() => _activeScreen = 'rate'),
                              icon:
                                  const Icon(Icons.star_rate_rounded, size: 16),
                              label: const Text('End & Rate Trip'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Emergency SOS Banner
                InkWell(
                  onTap: _showSosModal,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonSoftBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.crimsonRed.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.crimsonRed, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Emergency Roadside SOS',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.crimsonRed)),
                              Text(
                                  'One-tap roadside assistance & police helpline in Pakistan',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.crimsonRed),
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

  Widget _buildTelemetryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.midnightNavy),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.midnightNavy)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  void _showSosModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.emergency, color: AppColors.crimsonRed),
              SizedBox(width: 8),
              Text('Emergency Roadside SOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'Do you need immediate roadside assistance or emergency support? This will transmit your vehicle telemetry to RentalHub support and notify your host.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimsonRed),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'SOS Alert Dispatched! RentalHub safety team is contacting you.')),
                );
              },
              child: const Text('Dispatch SOS Now'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // ANC-08 / C-26: Rate Trip & Condition
  // ==========================================
  Widget _buildRateTripScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Rate Your Trip',
              subtitle: 'Booking #RH-84920 • Handover Completed',
              height: 190,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'active'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle mini summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.emeraldGreen),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Honda Civic 2021 (LEA-4820) returned to Al-Falah Motors. Final balance PKR 2,500 settled.',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Host Rating Card
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
                        const Text('Host Service & Punctuality',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        const Text(
                            'Friendliness, timely meetup, and transparent agreement',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _hostStars
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () =>
                                  setState(() => _hostStars = index + 1),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Mechanical & Cleanliness Rating Card
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
                        const Text('Mechanical Condition & Cleanliness',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        const Text(
                            'Engine response, chilled AC, clean interior, and brakes',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _carStars
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () =>
                                  setState(() => _carStars = index + 1),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Feedback Chips
                  const Text('What stood out most?',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.midnightNavy)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Spotless Interior',
                      'Chilled AC',
                      'Smooth Handover',
                      'Polite Host',
                      'Accurate Fuel Level',
                      'Zero Hidden Charges',
                    ].map((tag) {
                      final isSelected = _selectedFeedbackTags.contains(tag);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(tag),
                        selectedColor: AppColors.orangeSoftBg,
                        checkmarkColor: AppColors.sunsetOrange,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.sunsetOrange
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFeedbackTags.add(tag);
                            } else {
                              _selectedFeedbackTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Thank you! Your verified review has been published on Al-Falah Motors profile.')),
              );
              setState(() => _activeScreen = 'discovery');
            },
            child: const Text('Submit Verified Review ✓'),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ANC-07 / C-29: Identity Documents (KYC)
  // ==========================================
  Widget _buildKycUploadScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurvedHeader(
              title: 'Identity Verification (KYC)',
              subtitle: 'NADRA CNIC & Driving License Registry',
              height: 190,
              showBack: true,
              onBack: () => setState(() => _activeScreen = 'discovery'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoftBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.emeraldGreen.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: AppColors.emeraldGreen),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your documents are encrypted and only accessible to accredited host shops during confirmed bookings.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDocSlot(
                      'CNIC Front', '35201-1234567-1 (Verified)', true),
                  _buildDocSlot('CNIC Back',
                      'Official Address: Gulberg III, Lahore', true),
                  _buildDocSlot(
                      'Driving License', 'LHR-987654 (Valid until 2028)', true),
                  _buildDocSlot('Passport (Optional)',
                      'Tap to upload international visitor ID', false),
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
                offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All KYC documents verified with NADRA!')),
              );
              setState(() => _activeScreen = 'discovery');
            },
            child: const Text('Save & Return to Discovery ✓'),
          ),
        ),
      ),
    );
  }

  Widget _buildDocSlot(String title, String subtitle, bool isVerified) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isVerified
                ? AppColors.emeraldGreen.withOpacity(0.4)
                : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isVerified ? AppColors.emeraldSoftBg : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVerified ? Icons.badge : Icons.add_a_photo,
              color:
                  isVerified ? AppColors.emeraldGreen : AppColors.midnightNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isVerified ? AppColors.emeraldSoftBg : AppColors.amberSoftBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isVerified ? 'VERIFIED' : 'PENDING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isVerified
                    ? AppColors.emeraldGreen
                    : AppColors.amberWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Bottom Navigation Widget
  Widget _buildFloatingBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.midnightNavyDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.explore, 'Explore',
              () => setState(() => _activeScreen = 'discovery')),
          _buildNavItem(1, Icons.receipt_long, 'My Pass',
              () => setState(() => _activeScreen = 'pass')),
          _buildNavItem(2, Icons.speed, 'Active Trip',
              () => setState(() => _activeScreen = 'active')),
          _buildNavItem(3, Icons.badge_outlined, 'KYC',
              () => setState(() => _activeScreen = 'kyc')),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, VoidCallback onTap) {
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
          Icon(icon,
              size: 20,
              color: isSelected ? AppColors.sunsetOrange : Colors.white70),
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
