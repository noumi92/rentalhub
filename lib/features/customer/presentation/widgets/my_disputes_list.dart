import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../owner/presentation/widgets/dispute_list_tile.dart';
import '../../data/datasources/dispute_remote_data_source.dart';
import 'dispute_category_chips.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// G4: the customer's own disputes with their statuses, newest first.
/// Extracted from [CustomerDisputeView] so the view stays under the
/// 250-line cap.
class MyDisputesList extends StatefulWidget {
  const MyDisputesList({super.key});

  @override
  State<MyDisputesList> createState() => _MyDisputesListState();
}

class _MyDisputesListState extends State<MyDisputesList> {
  List<DisputeRecord>? _disputes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<DisputeRecord> list = [];
    try {
      // CU-m3: signed out — the old 'cust-101' fallback read
      // another user's disputes. The list simply stays empty.
      String? uid;
      try {
        uid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      if (uid != null) {
        list = await sl<DisputeRemoteDataSource>().getCustomerDisputes(uid);
      }
    } catch (_) {}
    if (mounted) setState(() => _disputes = list);
  }

  Color _statusColor(BuildContext context, String status) {
    final brightness = Theme.of(context).brightness;
    switch (status) {
      case 'resolved':
        return AppColors.successTextFor(brightness);
      case 'in_review':
        return AppColors.warningTextFor(brightness);
      default:
        // CU-M1: the old default was AppColors.secondary (white-on-
        // orange 3.29:1 as small text) — open disputes read as the
        // same pending amber as in-review.
        return AppColors.warningTextFor(brightness);
    }
  }

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'resolved':
        return l10n.disputeResolved;
      case 'in_review':
        return l10n.inReview;
      default:
        return l10n.disputeOpen;
    }
  }

  /// F-M9: the admin decision on a resolved dispute, as the customer
  /// reads it — the label, the amount, and the admin note.
  String _decisionLabel(String decision) {
    final l10n = AppLocalizations.of(context)!;
    return switch (decision) {
      'full_to_customer' => l10n.disputeDecisionFullToCustomer,
      'full_to_owner' => l10n.disputeDecisionFullToOwner,
      'partial' => l10n.disputeDecisionPartial,
      _ => decision,
    };
  }

  /// AC-13: the dispute detail — a bottom sheet with the status
  /// timeline (filed → in review → resolved, with the dates the
  /// record actually carries) and the resolution note. The record
  /// has no updatedAt, so the last update is resolvedAt when
  /// resolved, otherwise the filed time.
  Future<void> _openDetail(DisputeRecord d) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    String fmt(DateTime? t) =>
        t == null ? '—' : DateFormat.yMMMd(locale).format(t);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(disputeCategoryLabel(l10n, d.category),
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l10n.bookingDetailTitle(d.bookingId),
                  style: Theme.of(sheetContext).textTheme.labelSmall),
              const SizedBox(height: 12),
              _timelineRow(sheetContext, l10n.disputeOpen, fmt(d.createdAt),
                  done: true),
              if (d.status != 'open')
                _timelineRow(sheetContext, l10n.inReview,
                    fmt(d.status == 'resolved' ? d.resolvedAt : null),
                    done: true),
              if (d.status == 'resolved')
                _timelineRow(sheetContext, l10n.disputeResolved,
                    fmt(d.resolvedAt),
                    done: true),
              const SizedBox(height: 12),
              Text(d.description,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.4)),
              if (d.status == 'resolved' && d.decision != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${_decisionLabel(d.decision!)}${d.decisionAmount == null ? '' : ' • ${l10n.amountRs(formatRs(d.decisionAmount!))}'}',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (d.adminNote != null && d.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.disputeDecisionNote}: ${d.adminNote}',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.4),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineRow(
      BuildContext context, String label, String date, {required bool done}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: done
                ? AppColors.successTextFor(Theme.of(context).brightness)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(date, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final disputes = _disputes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.disputesMyTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (disputes == null)
          // DS-11: the shared loading state at list level, not a
          // bare spinner.
          const AppLoadingState()
        else if (disputes.isEmpty)
          // DS-11: the shared empty state, not a hand-rolled box.
          AppEmptyState(title: l10n.disputesEmpty)
        else
          ...disputes.map((d) {
            // CU-m13: rows used to stay inert — AC-13 makes them open
            // the detail sheet. The record carries no updatedAt, so
            // the row shows the last honest timestamp (resolved, else
            // filed) alongside the existing filed/SLA line.
            final sla = DisputeListTile.slaLine(l10n, d.createdAt);
            final lastUpdate = d.resolvedAt ?? d.createdAt;
            return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppCardDecoration.shadow(context)
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openDetail(d),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            disputeCategoryLabel(l10n, d.category),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(context, d.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(d.status),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: _statusColor(context, d.status)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.bookingDetailTitle(d.bookingId),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (sla != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sla,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    // AC-13: the last-update timestamp on the row.
                    if (lastUpdate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.disputeLastUpdated(
                            DateFormat.yMMMd(locale).format(lastUpdate)),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      d.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                    if (d.status == 'resolved' && d.decision != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_decisionLabel(d.decision!)}${d.decisionAmount == null ? '' : ' • ${l10n.amountRs(formatRs(d.decisionAmount!))}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (d.adminNote != null && d.adminNote!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.disputeDecisionNote}: ${d.adminNote}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ],
                    ],
                  ],
                ),
                    ),
                  ),
                ),
              );
          }),
      ],
    );
  }
}
