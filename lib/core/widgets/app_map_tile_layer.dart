import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'app_feedback.dart';

/// Standard OpenStreetMap user-agent package identifier for RentalHub.
const String kOsmUserAgentPackageName = 'pk.rentalhub.rentalhub';

/// Standard OpenStreetMap tile URL template.
const String kOsmTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Subtle dark-mode color matrix for standard light OSM tiles: inverts
/// luminance and reduces glare so white tiles do not blast users in dark mode.
const ColorFilter _kDarkMapTileFilter = ColorFilter.matrix(<double>[
  -0.85, 0, 0, 0, 230,
  0, -0.85, 0, 0, 230,
  0, 0, -0.85, 0, 235,
  0, 0, 0, 1, 0,
]);

/// Shared OpenStreetMap [TileLayer] with consistent user-agent and
/// automatic dark-mode tile tinting.
class AppMapTileLayer extends StatelessWidget {
  const AppMapTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: kOsmTileUrlTemplate,
      userAgentPackageName: kOsmUserAgentPackageName,
      tileBuilder: isDark
          ? (context, tileWidget, tile) => ColorFiltered(
                colorFilter: _kDarkMapTileFilter,
                child: tileWidget,
              )
          : null,
    );
  }
}

/// Compact OpenStreetMap copyright attribution required by OSM's Tile Usage
/// Policy on every map surface.
class AppOsmAttribution extends StatelessWidget {
  const AppOsmAttribution({
    super.key,
    this.alignment = Alignment.bottomRight,
  });

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '© OpenStreetMap',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}

/// Opens turn-by-turn directions in Google Maps (or the device's default map
/// app) for the given coordinates or fallback street address.
Future<void> openMapDirections(
  BuildContext context, {
  double? lat,
  double? lng,
  String? address,
}) async {
  final l10n = AppLocalizations.of(context)!;
  String? destination;
  if (lat != null &&
      lng != null &&
      !(lat == 0.0 && lng == 0.0) &&
      !lat.isNaN &&
      !lng.isNaN) {
    destination = '$lat,$lng';
  } else if (address != null && address.trim().isNotEmpty) {
    destination = address.trim();
  }
  if (destination == null) {
    AppFeedback.showInfo(context, l10n.passNoLocation);
    return;
  }
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      AppFeedback.showError(context, l10n.passOpenMapsError);
    }
  }
}
