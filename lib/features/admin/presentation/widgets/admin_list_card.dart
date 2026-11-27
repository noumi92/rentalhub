import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Phase 4 (4.1) — the one shared admin list-card shell and fact
/// tile, replacing the inline rebuilds that used to live in the
/// bookings, cars, shops, disputes, KYC, announcements and
/// activity-log lists (and the customer tile, which shared the same
/// shell).
///
/// # Admin card scale (the single scale for admin cards/tiles)
///
/// Picked from the radii/paddings/type sizes the panel had drifted
/// across (radii 6/8/10/12/14/16/20, paddings 10/12/14/16/18/20,
/// value text 15/20/28sp) — every admin card widget touched in
/// Phase 4 now uses these, and nothing else in the app was
/// restyled:
///
/// * radii — list card and fact tile: **12**; status chip pill:
///   **20** (see [AdminStatusChip]); dashboard KPI card: **12**.
/// * padding — fact tile: **12 horizontal / 10 vertical**; list
///   cards use the [ListTile] defaults inside the shell; dashboard
///   KPI card: **16** all round.
/// * type — list title **14**, list subtitle **12**, fact label
///   **11**, fact value **15**; the dashboard KPI value stays the
///   display slot (**28**, displayLarge) — it is a headline, not a
///   dense fact tile.
RoundedRectangleBorder adminCardShape(BuildContext context) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Theme.of(context).dividerColor),
  );
}

/// One row of an admin list: the shared shell every admin list
/// uses — a flat [Card] (margin zero, elevation 0, radius 12,
/// divider border) with a [ListTile], a tinted [CircleAvatar]
/// leading icon, a 14sp title, a 12sp muted subtitle, and a
/// trailing widget (usually a status chip or the chevron).
///
/// Pass [subtitleWidget] instead of [subtitle] when the subtitle
/// needs more than one line of widgets (the bookings tile's compact
/// layout puts its status chip under the subtitle text).
class AdminListCard extends StatelessWidget {
  const AdminListCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.isThreeLine = false,
    this.maxTitleLines,
    this.borderColor,
    this.subtitleColor,
    this.subtitleFontWeight,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isThreeLine;
  final int? maxTitleLines;

  /// Border override — the ticket tile turns its border red once
  /// the SLA is breached; everything else uses the divider border.
  final Color? borderColor;

  /// Subtitle overrides — the ticket tile turns its subtitle red
  /// (and medium) once the SLA is breached; everything else uses
  /// the muted 12sp subtitle.
  final Color? subtitleColor;
  final FontWeight? subtitleFontWeight;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final subtitleWidget = this.subtitleWidget;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: borderColor == null
          ? adminCardShape(context)
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor!),
            ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon),
        ),
        title: Text(
          title,
          maxLines: maxTitleLines ?? 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: subtitleWidget ??
            (subtitle == null
                ? null
                : Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor ??
                            Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                        fontWeight: subtitleFontWeight),
                  )),
        isThreeLine: isThreeLine,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// The chevron every tappable admin list row ends with.
const Widget adminListChevron =
    Icon(Icons.arrow_forward_ios_rounded, size: 16);

/// One fact tile: a label (11sp) over a value (15sp) in a bordered
/// box (radius 12, padding 12 horizontal / 10 vertical). Merges
/// [AdminReportKpi] (reports screen) and the shop detail's `_fact`
/// tile, which were the same tile with different radii/padding.
class AdminFactTile extends StatelessWidget {
  const AdminFactTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
