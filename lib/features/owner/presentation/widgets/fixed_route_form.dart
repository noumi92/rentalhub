import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';


/// The "add a route" form of [OwnerFixedRoutesView]. Extracted so the
/// view stays under the 250-line cap.
class FixedRouteForm extends StatelessWidget {
  const FixedRouteForm({
    super.key,
    required this.originController,
    required this.destination,
    required this.destinations,
    required this.distanceController,
    required this.priceController,
    required this.onDestinationChanged,
    required this.onAdd,
  });

  final TextEditingController originController;
  final String destination;
  final List<String> destinations;
  final TextEditingController distanceController;
  final TextEditingController priceController;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onAdd;

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
                decoration: InputDecoration(
                    labelText: l10n.fixedRouteFromCity,
                    border: const OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                initialValue: destination,
                decoration: InputDecoration(
                    labelText: l10n.fixedRouteToCity, border: const OutlineInputBorder()),
                items: destinations
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (d) {
                  if (d != null) onDestinationChanged(d);
                },
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
                decoration: InputDecoration(
                    labelText: l10n.fixedRouteDistance,
                    border: const OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: l10n.fixedRoutePrice,
                    border: const OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.fixedRouteAddButton),
          ),
        ),
      ],
    );
  }
}
