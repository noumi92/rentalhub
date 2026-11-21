import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Item 5 (2026-11-21): the customers-list filter chips, same
/// treatment as the fleet filter bar ([FleetFilterChips]) — one
/// horizontally scrollable row at full size, 14sp labels, never
/// shrunk, each segment carrying its count (the merged KPI).
///
/// Classification — every segment derives from data the list
/// already loads, never a new fetch:
/// * Regular = 2+ rentals, New = 0–1 rentals ([CustomerSummary.bookingCount]).
/// * Blacklisted = the customer's CNIC is on the active blacklist.
/// * With Dues = a booking in an approved/paid/active/completed
///   status with a remaining balance — the dues-screen definition.
///   (The old single `flagged` segment was exactly the union of
///   these two; it is split so the owner can tell them apart.)
/// * Pending Approval = the saved customer record's `approvalStatus`
///   is 'pending' AND the record is an ONLINE record
///   (`source == 'online'`). Walk-in records sit at 'pending'
///   forever (approve/reject was removed for walk-ins), so they
///   never match this segment.
/// * Blocked = the shop's stored per-shop status for the customer
///   is 'blocked' (`shopStatuses`, see `customer_status_helpers`).
///   Archived customers are hidden from the list entirely, so they
///   never appear as a segment.
/// Deliberately NOT covered: trust score (lives on the auth
/// `UserEntity`, not on any data this list loads — a filter on it
/// would need a new fetch per customer) and KYC-doc completeness
/// (no `isVerified` flag exists anywhere; doc presence on a saved
/// record is a weak proxy and would mislabel every booking-derived
/// row as "no KYC").
///
/// Like the fleet bar, the four alert segments (Blacklisted,
/// With Dues, Pending Approval, Blocked) only appear when their
/// count is above zero — or while selected, so the selection can
/// never strand the user on a hidden segment.
enum CustomerListFilter { all, regular, isNew, blacklisted, withDues, pendingApproval, blocked }

class CustomerListFilterChips extends StatelessWidget {
  const CustomerListFilterChips({
    super.key,
    required this.selected,
    required this.allCount,
    required this.regularCount,
    required this.newCount,
    required this.blacklistedCount,
    required this.withDuesCount,
    required this.pendingApprovalCount,
    required this.blockedCount,
    required this.onSelected,
  });

  final CustomerListFilter selected;
  final int allCount;
  final int regularCount;
  final int newCount;
  final int blacklistedCount;
  final int withDuesCount;
  final int pendingApprovalCount;
  final int blockedCount;
  final ValueChanged<CustomerListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      CustomerListFilter.all: l10n.customersFilterAll,
      CustomerListFilter.regular: l10n.customersFilterRegular,
      CustomerListFilter.isNew: l10n.customersFilterNew,
      CustomerListFilter.blacklisted: l10n.customersBlacklisted,
      CustomerListFilter.withDues: l10n.customersFilterWithDues,
      CustomerListFilter.pendingApproval: l10n.customerDetailApprovalPending,
      CustomerListFilter.blocked: l10n.customersFilterBlocked,
    };
    final counts = {
      CustomerListFilter.all: allCount,
      CustomerListFilter.regular: regularCount,
      CustomerListFilter.isNew: newCount,
      CustomerListFilter.blacklisted: blacklistedCount,
      CustomerListFilter.withDues: withDuesCount,
      CustomerListFilter.pendingApproval: pendingApprovalCount,
      CustomerListFilter.blocked: blockedCount,
    };
    // Alert segments join the bar only when they have rows (or
    // while selected) — the fleet bar's Maintenance rule.
    bool showAlert(CustomerListFilter f) => counts[f]! > 0 || selected == f;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _segment(context, l10n, CustomerListFilter.all, labels, counts),
          const SizedBox(width: 8),
          _segment(context, l10n, CustomerListFilter.regular, labels, counts),
          const SizedBox(width: 8),
          _segment(context, l10n, CustomerListFilter.isNew, labels, counts),
          if (showAlert(CustomerListFilter.blacklisted)) ...[
            const SizedBox(width: 8),
            _segment(context, l10n, CustomerListFilter.blacklisted, labels, counts),
          ],
          if (showAlert(CustomerListFilter.withDues)) ...[
            const SizedBox(width: 8),
            _segment(context, l10n, CustomerListFilter.withDues, labels, counts),
          ],
          if (showAlert(CustomerListFilter.pendingApproval)) ...[
            const SizedBox(width: 8),
            _segment(context, l10n, CustomerListFilter.pendingApproval, labels, counts),
          ],
          if (showAlert(CustomerListFilter.blocked)) ...[
            const SizedBox(width: 8),
            _segment(context, l10n, CustomerListFilter.blocked, labels, counts),
          ],
        ],
      ),
    );
  }

  /// The status dot per segment; All has none. Dots reuse the
  /// colours the row badges already use (Regular green, New orange,
  /// Blacklisted red) so chip and badge agree.
  static Color? _dotColor(CustomerListFilter filter) => switch (filter) {
        CustomerListFilter.regular => AppColors.accentSuccessStrong,
        CustomerListFilter.isNew => AppColors.orangeFill,
        CustomerListFilter.blacklisted => AppColors.errorDark,
        CustomerListFilter.withDues => AppColors.warningOnContainer,
        CustomerListFilter.pendingApproval => AppColors.primary,
        CustomerListFilter.blocked => AppColors.errorDark,
        _ => null,
      };

  Widget _segment(
    BuildContext context,
    AppLocalizations l10n,
    CustomerListFilter filter,
    Map<CustomerListFilter, String> labels,
    Map<CustomerListFilter, int> counts,
  ) {
    final dotColor = _dotColor(filter);
    // Full-size label: the bar scrolls instead of shrinking, so no
    // FittedBox here — the 14sp label (and the Urdu text) renders
    // at its real size at 360px.
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dotColor != null) ...[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(
          l10n.customersFilterChip(labels[filter]!, counts[filter]!),
          maxLines: 1,
          // Fleet bar spec: 14sp segment labels, set on the Text
          // itself so the theme chipTheme (navy fill + white label
          // selected, DS-1) still supplies the color and weight.
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
    return ChoiceChip(
      // E3 / accessibility: the padded tap target keeps every
      // segment at the 48dp minimum.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: labelWidget,
      selected: selected == filter,
      // Audit 2026-11-15 DS-1: no per-file selectedColor/labelStyle
      // — the theme's chipTheme is the one selected spec.
      onSelected: (_) => onSelected(filter),
    );
  }
}
