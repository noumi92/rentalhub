import 'package:flutter/material.dart';

import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';

/// The "add a route" form of [OwnerFixedRoutesView]. Extracted so the
/// view stays under the 250-line cap.
/// Audit §8: the destination is free text (no hardcoded English city
/// list, so any city — e.g. Sialkot — can be added); inputs use the
/// shared 52px filled style and the CTA is a 54dp [DebouncedButton].
class FixedRouteForm extends StatelessWidget {
  const FixedRouteForm({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.distanceController,
    required this.priceController,
    required this.onAdd,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final TextEditingController distanceController;
  final TextEditingController priceController;
  final VoidCallback onAdd;

  InputDecoration _decoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.fixedRouteAddTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: originController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(context, l10n.fixedRouteFromCity),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(context, l10n.fixedRouteToCity),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration: _decoration(context, l10n.fixedRouteDistance),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: _decoration(context, l10n.fixedRoutePrice),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DebouncedButton(
          text: l10n.fixedRouteAddButton,
          icon: Icons.add_rounded,
          onPressed: () async => onAdd(),
        ),
      ],
    );
  }
}
