import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';

/// Audit §5 (P2-5): the Application Status step — the 3-step timeline
/// (Submitted ✓ / Under Review / Approved), the "Usually approved
/// within 24 hours" line, and a "Contact Admin on WhatsApp" button.
/// The admin number is read lazily from `platform_settings/global`
/// (field `adminWhatsapp`); when no number is stored there the button
/// says so honestly instead of opening a made-up number.
class ShopApprovalStatusStepWidget extends StatefulWidget {
  final VoidCallback onGoToFleet;

  const ShopApprovalStatusStepWidget({
    super.key,
    required this.onGoToFleet,
  });

  @override
  State<ShopApprovalStatusStepWidget> createState() =>
      _ShopApprovalStatusStepWidgetState();
}

class _ShopApprovalStatusStepWidgetState
    extends State<ShopApprovalStatusStepWidget> {
  late final Future<String?> _adminWhatsappFuture;

  @override
  void initState() {
    super.initState();
    _adminWhatsappFuture = _loadAdminWhatsapp();
  }

  /// Lazy Firestore read (try/catch → null): no number stored, no
  /// Firebase, or offline all resolve to "not set up yet".
  Future<String?> _loadAdminWhatsapp() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('global')
          .get();
      final data = doc.data();
      if (data == null) return null;
      for (final key in ['adminWhatsapp', 'adminWhatsApp', 'supportWhatsapp']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _contactAdmin(String? number) async {
    final l10n = AppLocalizations.of(context)!;
    if (number == null || number.isEmpty) {
      AppFeedback.showWarning(context, l10n.onboardingAdminWhatsappMissing);
      return;
    }
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppFeedback.showError(context, l10n.onboardingAdminWhatsappFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.successContainerFor(Theme.of(context).brightness),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.check_circle_rounded, size: 64, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.onboardingApprovalTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingApprovalMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingApprovalWithin24h,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // The 3-step application timeline: Submitted (done),
        // Under Review (current), Approved (pending).
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _timelineRow(context, Icons.check_circle_rounded, AppColors.accentSuccessStrong, l10n.onboardingTimelineSubmitted, l10n.onboardingTimelineSubmittedHint, true),
              _timelineConnector(context),
              _timelineRow(context, Icons.hourglass_top_rounded, AppColors.orangeFill, l10n.onboardingTimelineUnderReview, l10n.onboardingTimelineUnderReviewHint, true),
              _timelineConnector(context),
              _timelineRow(context, Icons.radio_button_unchecked_rounded, Theme.of(context).colorScheme.onSurfaceVariant, l10n.onboardingTimelineApproved, l10n.onboardingTimelineApprovedHint, false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<String?>(
          future: _adminWhatsappFuture,
          builder: (context, snapshot) {
            final number = snapshot.data;
            return DebouncedButton(
              text: l10n.onboardingContactAdminWhatsapp,
              icon: Icons.chat_rounded,
              onPressed: () async => _contactAdmin(number),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.secondary, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.onboardingFleetReady, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text(
                      l10n.onboardingFleetReadyHint,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: widget.onGoToFleet,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(l10n.onboardingManageFleet),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineRow(BuildContext context, IconData icon, Color color, String title, String hint, bool active) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: active ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(hint, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineConnector(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(left: 12),
      child: Container(width: 2, height: 14, color: Theme.of(context).dividerColor),
    );
  }
}
