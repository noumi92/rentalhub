import 'package:flutter/material.dart';

import '../../../../../core/theme/card_decoration.dart';

/// The empty-filter banner overlaid at the bottom of the Shops map
/// when the current filters match no shop.
class ShopsEmptyBanner extends StatelessWidget {
  const ShopsEmptyBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      // Canonical borderless card look (soft shadow, no raw black
      // shadow literal).
      decoration: AppCardDecoration.of(context, radius: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
