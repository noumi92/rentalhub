import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';

class CustomerSosView extends StatelessWidget {
  final VoidCallback? onBack;

  const CustomerSosView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: const Text(
                'Emergency SOS Assistance',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.crimsonRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.crimsonRed.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Broadcasting GPS distress location to showroom and emergency services...'),
                                backgroundColor: AppColors.crimsonRed,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(55),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              color: AppColors.crimsonRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66EF4444),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Press SOS in Emergency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.crimsonRed,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Instantly alerts your rental showroom and dispatches live GPS location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildEmergencyOption(
                      icon: Icons.local_police_rounded,
                      title: 'Call Police Emergency 15',
                      subtitle: 'Direct Punjab & Federal Police helpline',
                      color: AppColors.royalNavy,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dialing Police 15...')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildEmergencyOption(
                      icon: Icons.car_crash_rounded,
                      title: 'Call 24/7 Roadside Assistance',
                      subtitle: 'Flat tire, engine towing, battery jumpstart',
                      color: AppColors.sunsetOrange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Calling Roadside Recovery...')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildEmergencyOption(
                      icon: Icons.share_location_rounded,
                      title: 'Share Live Location via WhatsApp',
                      subtitle: 'Send real-time tracker pin to family',
                      color: AppColors.emeraldGreen,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sharing GPS pin via WhatsApp...')),
                        );
                      },
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

  Widget _buildEmergencyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.midnightNavy)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

