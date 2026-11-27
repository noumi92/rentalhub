import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_support_data_source.dart';
import 'admin_list_card.dart';

/// Phase 3 (3.2) — one announcement card in the history, extracted
/// from [AdminAnnouncementsView] so the view stays under the
/// 250-line cap with its pagination. Tapping the card opens the
/// announcement detail route; the send buttons keep their Phase 1
/// behaviour (a test send goes only to the calling admin, a real
/// send is confirmed first, and sent / pending_whatsapp items
/// cannot be sent again).
class AdminAnnouncementCard extends StatelessWidget {
  const AdminAnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
    required this.onSendTest,
    required this.onSendNow,
  });

  final AdminAnnouncement announcement;
  final VoidCallback onTap;
  final VoidCallback onSendTest;
  final VoidCallback onSendNow;

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final a = announcement;
    // Phase 4 (4.1) — the card shell is the shared shape; the
    // body stays custom (title/body/actions are not a ListTile row).
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: adminCardShape(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.titleEn, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(a.bodyEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              // AD-m11: the authored Urdu copy was never previewed —
              // show it under the English so the admin can check it.
              if (a.titleUr.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(a.titleUr,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 14)),
              ],
              if (a.bodyUr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(a.bodyUr,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 6),
              Text(
                '${a.audienceRole} • ${a.audienceCity} • ${a.audiencePlan} • ${a.channel} • ${a.status} • ${l10n.admin2_anncSentCount(a.sent)} • ${l10n.adminAnncDeliveredNotTracked} • ${l10n.admin2_anncOpenedCount(a.opened)}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    // AD-m20: no test send on an already-sent
                    // announcement.
                    onPressed: a.status == 'sent' ? null : onSendTest,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    child: Text(l10n.admin2_anncSendTest),
                  ),
                  FilledButton(
                    // F-M14: a `pending_whatsapp` announcement
                    // already had its push delivered — "Send now"
                    // would push-notify everyone a second time. Only
                    // drafts and scheduled (due) announcements can
                    // be sent.
                    onPressed: a.status == 'sent' ||
                            a.status == 'pending_whatsapp'
                        ? null
                        : onSendNow,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    child: Text(l10n.admin2_anncSendNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
