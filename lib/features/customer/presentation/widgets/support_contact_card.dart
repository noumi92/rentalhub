import 'package:flutter/material.dart';
import '../../../../core/theme/card_decoration.dart';


/// G1: one of the support screen's contact tiles (call / WhatsApp the
/// showroom). Extracted from [CustomerSupportView] so the view stays
/// under the 250-line cap.
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppCardDecoration.shadow(context)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context).textTheme.bodyMedium),
            Text(subtitle,
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
