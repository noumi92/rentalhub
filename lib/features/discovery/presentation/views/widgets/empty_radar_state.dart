import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class EmptyRadarState extends StatelessWidget {
  final double currentRadiusKm;
  final VoidCallback onExpandRadius;

  const EmptyRadarState({
    super.key,
    required this.currentRadiusKm,
    required this.onExpandRadius,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.radar_rounded,
              size: 34,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.emptyRadarNoShops(currentRadiusKm.toInt()),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.emptyRadarExpandHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onExpandRadius,
            icon: const Icon(Icons.zoom_out_map_rounded, size: 16),
            label:  Text(l10n.emptyRadarExpand),
          ),
        ],
      ),
    );
  }
}

