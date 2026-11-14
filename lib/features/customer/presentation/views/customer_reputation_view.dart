import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../../trust/data/services/trust_score_service.dart';
import '../widgets/reputation_score_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

// H3: reputation from the real `reviews` collection — the ratings
// showrooms gave this customer (H4's owner half) — plus the real
// trust score from the user's own record. The old hardcoded
// '4.8 / 5.0', '8 showroom bookings', the four invented score bars
// and the "instant 5-minute approvals with zero security deposit
// surcharges" promise are all gone.
class CustomerReputationView extends StatefulWidget {
  final VoidCallback? onBack;

  const CustomerReputationView({super.key, this.onBack});

  @override
  State<CustomerReputationView> createState() => _CustomerReputationViewState();
}

class _CustomerReputationViewState extends State<CustomerReputationView> {
  bool _loading = true;
  double? _trustScore;
  List<Map<String, dynamic>> _ownerReviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // FirebaseAuth.instance throws in widget tests (no Firebase app
    // initialised) — treat that as "no signed-in user", like the
    // other customer views do.
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    double? trustScore;
    List<Map<String, dynamic>> reviews = [];
    if (uid != null) {
      try {
        // Live first (shared TrustScoreService, same as the admin
        // panel); the stored `trust_score` is only the fallback.
        trustScore = (await const TrustScoreService().compute(uid))?.breakdown.total;
      } catch (_) {}
      trustScore ??= await _storedTrustScore(uid);
      try {
        reviews = await sl<ReviewRemoteDataSource>().getCustomerReviews(uid, onlyOwnerRated: true);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _trustScore = trustScore;
        _ownerReviews = reviews;
        _loading = false;
      });
    }
  }

  /// Stored `trust_score` from the `users` doc, used only when the
  /// live computation cannot run (reads the raw doc, so a missing
  /// score stays null instead of defaulting to 5.0).
  Future<double?> _storedTrustScore(String uid) async {
    try {
      if (!sl.isRegistered<FirestoreService>()) return null;
      return (await sl<FirestoreService>().getUser(uid))?.trustScore;
    } catch (_) {
      return null;
    }
  }

  double _average(String field) {
    final values = _ownerReviews
        .map((r) => (r[field] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final care = _average('careRating');
    final punctuality = _average('punctualityRating');
    final behavior = _average('behaviorRating');
    final overall =
        _ownerReviews.isEmpty ? null : (care + punctuality + behavior) / 3;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.reputationTitle,
              onBack: widget.onBack,
            ),
            Expanded(
              child: _loading
                  ? const AppLoadingState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSuccess
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.verified_rounded,
                                      color: AppColors.successTextFor(
                                          Theme.of(context).brightness),
                                      size: 50),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  overall == null
                                      ? '— / 5.0'
                                      : '${overall.toStringAsFixed(1)} / 5.0',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _trustScore == null
                                      ? l10n.reputationTrustScoreDash
                                      : l10n.reputationTrustScoreValue(_trustScore!.toStringAsFixed(1)),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.successTextFor(
                                              Theme.of(context).brightness)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _ownerReviews.isEmpty
                                      ? l10n.reputationEmpty
                                      : l10n.reputationBasedOnReviews(_ownerReviews.length),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_ownerReviews.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppCardDecoration.shadow(context),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.reputationShopRatings,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 14),
                                  ReputationScoreBar(
                                      label: l10n.reputationVehicleCare,
                                      ratio: care / 5,
                                      score: care),
                                  const SizedBox(height: 10),
                                  ReputationScoreBar(
                                      label: l10n.reputationPunctuality,
                                      ratio: punctuality / 5,
                                      score: punctuality),
                                  const SizedBox(height: 10),
                                  ReputationScoreBar(
                                      label: l10n.reputationStaffBehavior,
                                      ratio: behavior / 5,
                                      score: behavior),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_rounded, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.reputationVisibleNote,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
