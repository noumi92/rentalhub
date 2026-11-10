import 'package:flutter/material.dart';

/// The "no GPS permission" note shared by the Shops listing and the
/// full-screen map: the city menu above is the manual entry, never a
/// fake location.
class ShopsLocationNote extends StatelessWidget {
  const ShopsLocationNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
