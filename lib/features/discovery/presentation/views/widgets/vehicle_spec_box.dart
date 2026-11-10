import 'package:flutter/material.dart';

import '../../../../../core/theme/card_decoration.dart';

class VehicleSpecBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const VehicleSpecBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: AppCardDecoration.of(context, radius: 12),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

