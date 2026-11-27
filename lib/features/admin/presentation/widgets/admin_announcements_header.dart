import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import 'admin_sort_menu.dart';

/// Phase 4 (4.3) — the announcements history header, extracted
/// from [AdminAnnouncementsView] so the view stays under the
/// 250-line cap with its sort control: the "New announcement"
/// button and the sort menu (date orders by `created_at`, title by
/// `title_en`, status by `status` — all server-side).
class AdminAnnouncementsHeader extends StatelessWidget {
  const AdminAnnouncementsHeader({
    super.key,
    required this.onNew,
    required this.sort,
    required this.onSort,
  });

  final VoidCallback onNew;
  final String sort;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    // The announcements view is null-tolerant of localizations
    // (it falls back to English), so this header must be too.
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: Text(l10n.admin2_anncNew),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AdminSortMenu(
              options: [
                AdminSortOption(
                    id: AdminListSort.dateNewest,
                    label: l10n.adminSortDateNewest),
                AdminSortOption(
                    id: AdminListSort.dateOldest,
                    label: l10n.adminSortDateOldest),
                AdminSortOption(
                    id: AdminListSort.titleAsc,
                    label: l10n.adminSortTitleAsc),
                AdminSortOption(
                    id: AdminListSort.statusAsc,
                    label: l10n.adminSortStatus),
              ],
              selectedId: sort,
              onSelected: onSort,
            ),
          ],
        ),
      ],
    );
  }
}
