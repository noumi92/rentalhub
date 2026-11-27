import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../widgets/sos_button.dart';
import '../widgets/sos_emergency_option.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../l10n/app_localizations.dart';

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
      // CU-m3: signed out — there is no booking to look the shop
      // up from, and the old 'cust-101' fallback read another
      // user's bookings. The contact cards simply stay empty.
      String? uid;
      try {
        uid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      if (uid == null) return;
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
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (mounted) {
        AppFeedback.showError(context, l10n.sosCallError(label));
      }
    }
  }

  Future<void> _confirmAndCallPolice() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(l10n.sosCallPoliceConfirm),
        content:  Text(
          l10n.sosCallPoliceConfirmHint,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:  Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:  Text(l10n.sosCallPolice),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _callNumber('15', l10n.sosPolice);
    }
  }

  Future<void> _shareLiveLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = (_shopPhone ?? '').trim();
    if (phone.isEmpty) {
      AppFeedback.showInfo(
        context,
        l10n.sosNoBookingHint,
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
          l10n.sosLocationPermission,
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
        AppFeedback.showError(context, l10n.sosLocationError(e.toString()));
      }
      return;
    }
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    final uri = whatsappUri(
      phone: phone,
      message: l10n.sosEmergencyMessage(mapsUrl),
    );
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, l10n.couldNotOpenWhatsapp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.sosTitle,
              onBack: widget.onBack,
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
                      l10n.sosPress,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.dangerTextFor(
                              Theme.of(context).brightness)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.sosExplainer,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SosEmergencyOption(
                      icon: Icons.local_police_rounded,
                      title: l10n.sosCallPoliceEmergency,
                      subtitle: l10n.sosPoliceSubtitle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primaryContainer
                          : AppColors.primary,
                      onTap: () => _callNumber('15', l10n.sosPolice),
                    ),
                    const SizedBox(height: 10),
                    SosEmergencyOption(
                      icon: Icons.medical_services_rounded,
                      title: l10n.sosCallRescue,
                      subtitle: l10n.sosRescueSubtitle,
                      color: AppColors.secondary,
                      onTap: () => _callNumber('1122', l10n.sosRescue),
                    ),
                    const SizedBox(height: 10),
                    SosEmergencyOption(
                      icon: Icons.share_location_rounded,
                      title: l10n.sosShareLocation,
                      subtitle: _shopName != null
                          ? l10n.sosSendToShopNamed(_shopName!)
                          : l10n.sosSendToShop,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.accentSuccessDark
                          : AppColors.accentSuccess,
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
