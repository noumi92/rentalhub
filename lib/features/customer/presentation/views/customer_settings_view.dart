import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';

class CustomerSettingsView extends StatefulWidget {
  final VoidCallback? onBack;

  const CustomerSettingsView({super.key, this.onBack});

  @override
  State<CustomerSettingsView> createState() => _CustomerSettingsViewState();
}

class _CustomerSettingsViewState extends State<CustomerSettingsView> {
  bool _isUrdu = false;
  bool _pushNotifications = true;
  bool _smsAlerts = true;

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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Text(
                'Settings & Preferences',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Language & Localization',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SwitchListTile(
                          activeColor: AppColors.sunsetOrange,
                          title: const Text('Urdu Interface (اردو)',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: const Text(
                              'Display app labels in authentic Nastaliq Urdu',
                              style: TextStyle(fontSize: 11)),
                          value: _isUrdu,
                          onChanged: (val) => setState(() => _isUrdu = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Alerts & Notifications',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              activeColor: AppColors.sunsetOrange,
                              title: const Text('Push Notifications',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              subtitle: const Text(
                                  'Instant booking approval & payment alerts',
                                  style: TextStyle(fontSize: 11)),
                              value: _pushNotifications,
                              onChanged: (val) =>
                                  setState(() => _pushNotifications = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              activeColor: AppColors.sunsetOrange,
                              title: const Text('WhatsApp Notifications',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              subtitle: const Text(
                                  'Digital agreement and handover receipt delivery',
                                  style: TextStyle(fontSize: 11)),
                              value: _smsAlerts,
                              onChanged: (val) =>
                                  setState(() => _smsAlerts = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('About & Legal',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Rental Agreement Terms',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Privacy Policy',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            const ListTile(
                              title: Text('App Version',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              trailing: Text('1.0.0 (Build 2026)',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
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
