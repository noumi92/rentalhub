import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../widgets/sos_button.dart';
import '../widgets/sos_emergency_option.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';

// G2: real emergency actions. Police 15 and Rescue 1122 are Pakistan's
// public emergency numbers (confirm them with the user — see the plan's
// D2). The SOS button calls Police 15 after one confirmation tap, so a
// pocket tap never dials the police by accident.
class CustomerSosView extends StatefulWidget {
  final VoidCallback? onBack;

  const CustomerSosView({super.key, this.onBack});

  @override
  State<CustomerSosView> createState() => _CustomerSosViewState();
}

class _CustomerSosViewState extends State<CustomerSosView> {
  String? _shopName;
  String? _shopPhone;

  @override
  void initState() {
    super.initState();
    _loadShopContact();
  }

  // The shop to share the live location with — the most recent booking's
  // showroom, the same lookup the support screen uses.
  Future<void> _loadShopContact() async {
    try {
      String uid = 'cust-101';
      try {
        uid = FirebaseAuth.instance.currentUser?.uid ?? uid;
      } catch (_) {}
      final bookings =
          await sl<BookingRemoteDataSource>().getCustomerBookings(uid);
      if (bookings.isEmpty) return;
      final latest = bookings.first;
      var phone = (latest.shopPhone ?? '').trim();
      var name = latest.shopName;
      if (phone.isEmpty) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('shops')
              .doc(latest.shopId)
              .get();
          phone = (snap.data()?['phone_number'] as String? ?? '').trim();
          name = snap.data()?['shop_name'] as String? ?? name;
        } catch (_) {}
      }
      if (mounted && phone.isNotEmpty) {
        setState(() {
          _shopName = name;
          _shopPhone = phone;
        });
      }
    } catch (_) {}
  }

  Future<void> _callNumber(String number, String label) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not call $label.');
      }
    }
  }

  Future<void> _confirmAndCallPolice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Police 15?'),
        content: const Text(
          'This dials the police emergency number (15). Use it only in a real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Call Police 15'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _callNumber('15', 'Police 15');
    }
  }

  Future<void> _shareLiveLocation() async {
    final phone = (_shopPhone ?? '').trim();
    if (phone.isEmpty) {
      AppFeedback.showInfo(
        context,
        'No booking yet — your live location is shared with your showroom once you have a booking.',
      );
      return;
    }
    // SOS is an explicit user action, so requesting location permission
    // here is appropriate (unlike the map screen, which never asks).
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Location permission is needed to share your live location.',
        );
      }
      return;
    }
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not get your location: $e');
      }
      return;
    }
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    final uri = whatsappUri(
      phone: phone,
      message: 'EMERGENCY — I need help. My live location: $mapsUrl',
    );
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not open WhatsApp.');
      }
    }
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Text(
                'Emergency SOS Assistance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    SosButton(onTap: _confirmAndCallPolice),
                    const SizedBox(height: 16),
                    Text(
                      'Press SOS in Emergency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.accentDanger),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The SOS button calls Police 15. You can also call Rescue 1122 or share your live location with your showroom.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SosEmergencyOption(
                      icon: Icons.local_police_rounded,
                      title: 'Call Police Emergency 15',
                      subtitle: 'Direct Punjab & Federal Police helpline',
                      color: AppColors.primary,
                      onTap: () => _callNumber('15', 'Police 15'),
                    ),
                    const SizedBox(height: 10),
                    SosEmergencyOption(
                      icon: Icons.medical_services_rounded,
                      title: 'Call Rescue 1122',
                      subtitle: 'Ambulance, fire and rescue services',
                      color: AppColors.secondary,
                      onTap: () => _callNumber('1122', 'Rescue 1122'),
                    ),
                    const SizedBox(height: 10),
                    SosEmergencyOption(
                      icon: Icons.share_location_rounded,
                      title: 'Share Live Location via WhatsApp',
                      subtitle: _shopName != null
                          ? 'Send your live location to $_shopName'
                          : 'Send your live location to your showroom',
                      color: AppColors.accentSuccess,
                      onTap: _shareLiveLocation,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

