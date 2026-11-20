import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../admin/domain/trust_score_calculator.dart';
import '../../../../trust/data/services/trust_score_service.dart';

/// Team B (UI/UX audit 2026-11-15, FG-4): the customer risk signal
/// on a triage card — live trust score, KYC badge and prior-trip
/// count, from the one shared [TrustScoreService] computation (the
/// same live score the admin panel and customer reputation show).
/// Loads lazily, once per card; while loading — or when the
/// computation cannot run (no Firestore) — it renders nothing, never
/// an invented score. The optional [trustScore] / [kycStatus] /
/// [completedTrips] overrides are the deterministic path for widget
/// tests (and embeds that already hold the result).
class TriageTrustRow extends StatefulWidget {
  const TriageTrustRow({
    super.key,
    required this.customerId,
    this.trustScore,
    this.kycStatus,
    this.completedTrips,
    this.trustService,
    this.cnicVerified,
    this.licenseVerified,
  });

  final String customerId;
  final double? trustScore;
  final String? kycStatus;
  final int? completedTrips;
  final TrustScoreService? trustService;

  /// O17: per-document verification overrides (tests / embeds that
  /// already hold the result). When null, the live path derives each
  /// document from the trust result — 'verified' status AND the
  /// document actually submitted — and the override path falls back
  /// to `kycStatus == 'verified'` for both.
  final bool? cnicVerified;
  final bool? licenseVerified;

  @override
  State<TriageTrustRow> createState() => _TriageTrustRowState();
}

class _TriageTrustRowState extends State<TriageTrustRow> {
  late final Future<TrustScoreResult?> _result;

  @override
  void initState() {
    super.initState();
    if (widget.trustScore != null) {
      _result = Future.value(_overrideResult());
    } else {
      _result = (widget.trustService ?? const TrustScoreService())
          .compute(widget.customerId);
    }
  }

  TrustScoreResult _overrideResult() {
    // The breakdown components are unknown on the override path;
    // only the total is shown, so they stay zero.
    return TrustScoreResult(
      breakdown: TrustScoreBreakdown(
        base: 0,
        kyc: 0,
        trips: 0,
        ratings: 0,
        punctuality: 0,
        conduct: 0,
        total: widget.trustScore!,
      ),
      bookings: const [],
      completedTrips: widget.completedTrips ?? 0,
      meanOwnerRating: null,
      kycStatus: widget.kycStatus ?? 'missing',
      kycCnicSubmitted:
          widget.cnicVerified ?? widget.kycStatus == 'verified',
      kycLicenseSubmitted:
          widget.licenseVerified ?? widget.kycStatus == 'verified',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrustScoreResult?>(
      future: _result,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final brightness = Theme.of(context).brightness;
        // O17: the single combined KYC badge is split — CNIC and
        // licence verify separately. On the live path a document is
        // verified only when the whole submission is 'verified' AND
        // that document was actually submitted (see
        // TrustScoreResult); an explicit per-document override (tests
        // / embeds) wins over the derivation. Anything else renders
        // as not verified, never as verified.
        final cnicVerified = widget.cnicVerified ??
            (result.kycStatus == 'verified' && result.kycCnicSubmitted);
        final licenseVerified = widget.licenseVerified ??
            (result.kycStatus == 'verified' && result.kycLicenseSubmitted);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.warningTextFor(brightness),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l10n.triageTrustScore(
                      result.breakdown.total.toStringAsFixed(1),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              _documentBadge(
                l10n,
                verified: cnicVerified,
                verifiedLabel: l10n.requestsKycCnicVerified,
                notVerifiedLabel: l10n.requestsKycCnicNotVerified,
              ),
              _documentBadge(
                l10n,
                verified: licenseVerified,
                verifiedLabel: l10n.requestsKycLicenseVerified,
                notVerifiedLabel: l10n.requestsKycLicenseNotVerified,
              ),
              Text(
                l10n.priorTripsCount(result.completedTrips),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _documentBadge(
    AppLocalizations l10n, {
    required bool verified,
    required String verifiedLabel,
    required String notVerifiedLabel,
  }) {
    final brightness = Theme.of(context).brightness;
    final (Color badgeBg, Color badgeFg) = verified
        ? (
            AppColors.successContainerFor(brightness),
            AppColors.successTextFor(brightness),
          )
        : (
            AppColors.warningContainerFor(brightness),
            AppColors.warningTextFor(brightness),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified
                ? Icons.verified_rounded
                : Icons.hourglass_top_rounded,
            size: 12,
            color: badgeFg,
          ),
          const SizedBox(width: 3),
          Text(
            verified ? verifiedLabel : notVerifiedLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: badgeFg,
                ),
          ),
        ],
      ),
    );
  }
}
