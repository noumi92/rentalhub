import 'package:flutter/material.dart';


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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a route',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: originController,
                decoration: const InputDecoration(
                    labelText: 'From (city)',
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                initialValue: destination,
                decoration: const InputDecoration(
                    labelText: 'To (city)', border: OutlineInputBorder()),
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
                decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Fixed price (Rs.)',
                    border: OutlineInputBorder()),
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
            label: const Text('Add Fixed Route'),
          ),
        ),
      ],
    );
  }
}
