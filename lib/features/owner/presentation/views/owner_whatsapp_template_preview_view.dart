import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// W5 — Template preview, booking confirmation (deck p.19 screen 5).
/// The bubbles render the template with {placeholders} for customer,
/// car, pickup time and amounts — template syntax, never fake data —
/// in English and Roman Urdu. "Send test to my number" is honestly
/// DISABLED until WhatsApp is connected (D2).
class OwnerWhatsappTemplatePreviewView extends StatelessWidget {
  const OwnerWhatsappTemplatePreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.creditsTemplateTitle,
              subtitle: l10n.creditsTitle,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.creditsTemplateNote,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Bubble(
                    text:
                        'Hello {customerName}, your booking is confirmed.\n'
                        'Car: {carName} ({plateNumber})\n'
                        'Pickup: {pickupTime}\n'
                        'Total: {totalAmount} · Advance paid: {advancePaid}\n'
                        'Shop: {shopName} · {shopPhone}',
                    isOwn: false,
                  ),
                  const SizedBox(height: 8),
                  _Bubble(
                    text:
                        'Assalam-o-Alaikum {customerName}, aap ki booking '
                        'confirm ho gayi hai.\n'
                        'Gaari: {carName} ({plateNumber})\n'
                        'Pickup: {pickupTime}\n'
                        'Kul: {totalAmount} · Advance: {advancePaid}\n'
                        'Shop: {shopName} · {shopPhone}',
                    isOwn: false,
                  ),
                  const SizedBox(height: 16),
                  DebouncedButton(
                    text: l10n.creditsSendTest,
                    icon: Icons.send_rounded,
                    onPressed: () => AppFeedback.showWarning(
                        context, l10n.creditsSendTestDisabled),
                  ),
                  Text(l10n.creditsSendTestDisabled,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isOwn;

  const _Bubble({required this.text, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOwn
              ? const Color(0xFFDCF8C6)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
