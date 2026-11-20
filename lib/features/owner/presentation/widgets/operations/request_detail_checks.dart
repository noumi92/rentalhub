import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../blacklist/data/datasources/blacklist_remote_data_source.dart';

/// O17: the blacklist result line on the request detail.
///
/// There is no stored blacklist verdict on the booking — the
/// creation-time check ([BookingRemoteDataSource.createBookingRequest])
/// throws for a blacklisted CNIC, so a stored booking passed it when
/// it was created. This is a live re-check against the same shared
/// list ([BlacklistRemoteDataSource.isCnicBlacklisted], the check the
/// manual flow and the CNIC scan view use): a record can have been
/// filed since the booking was created, and the walk-in path fails
/// open when offline, so re-checking at decision time is the honest
/// reading. A null result — no CNIC on the booking, or the list
/// could not be read — renders nothing, never a claimed verdict.
class RequestBlacklistLine extends StatefulWidget {
  const RequestBlacklistLine({
    super.key,
    required this.cnic,
    this.isBlacklisted,
    this.dataSource,
  });

  final String? cnic;

  /// Deterministic override for widget tests (and embeds that
  /// already hold the result). When null the live check runs.
  final bool? isBlacklisted;

  final BlacklistRemoteDataSource? dataSource;

  @override
  State<RequestBlacklistLine> createState() => _RequestBlacklistLineState();
}

class _RequestBlacklistLineState extends State<RequestBlacklistLine> {
  late final Future<bool?> _checked;

  @override
  void initState() {
    super.initState();
    final cnic = widget.cnic?.trim() ?? '';
    if (cnic.isEmpty) {
      _checked = Future.value(null);
    } else if (widget.isBlacklisted != null) {
      _checked = Future.value(widget.isBlacklisted);
    } else {
      _checked = _liveCheck(cnic);
    }
  }

  Future<bool?> _liveCheck(String cnic) async {
    try {
      final ds = widget.dataSource ?? sl<BlacklistRemoteDataSource>();
      return await ds.isCnicBlacklisted(cnic);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _checked,
      builder: (context, snapshot) {
        final blacklisted = snapshot.data;
        if (blacklisted == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final brightness = Theme.of(context).brightness;
        final (Color bg, Color fg, IconData icon, String label) =
            blacklisted
                ? (
                  Theme.of(context).colorScheme.errorContainer,
                  Theme.of(context).colorScheme.onErrorContainer,
                  Icons.block_rounded,
                  l10n.requestsBlacklisted,
                )
                : (
                  AppColors.successContainerFor(brightness),
                  AppColors.successTextFor(brightness),
                  Icons.verified_user_rounded,
                  l10n.requestsNotBlacklisted,
                );
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
