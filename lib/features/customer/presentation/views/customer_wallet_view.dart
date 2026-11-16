import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/masked_value.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../data/services/customer_wallet_service.dart';
import '../widgets/wallet_ledger.dart';
import '../../../../l10n/app_localizations.dart';

// F1: the wallet shows the customer's real money — advances paid on
// their bookings and security deposits held on them — loaded from the
// booking and deposit records. The hardcoded Rs. 15,000 / 5,000 /
// 10,000 and the four const transaction tiles are gone.
class CustomerWalletView extends StatefulWidget {
  const CustomerWalletView({super.key});

  @override
  State<CustomerWalletView> createState() => _CustomerWalletViewState();
}

class _CustomerWalletViewState extends State<CustomerWalletView> {
  CustomerWalletSummary? _summary;
  bool _isLoading = true;
  // E2: a load failure used to render an empty ledger silently; it
  // now renders an error state with retry.
  bool _hasError = false;
  // AC-8: signed out — no wallet to load, and never another
  // customer's. Renders the sign-in state instead of subscribing.
  bool _signedOut = false;
  // Live updates (Item 2): the subscription behind the balance and
  // the ledger.
  StreamSubscription<CustomerWalletSummary>? _walletSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    super.dispose();
  }

  /// Live updates (Item 2): the wallet follows the wallet
  /// service's [CustomerWalletService.watch] stream — a booking
  /// submit, an owner payment verify, or a deposit change updates
  /// the balance and ledger while the wallet is open. The
  /// error-state retry re-runs this method, which re-subscribes.
  void _load() {
    _walletSub?.cancel();
    if (mounted) setState(() { _hasError = false; _signedOut = false; });
    // AC-8: no signed-in user means no wallet to load — never fall
    // back to another customer's uid.
    final uid = CustomerWalletService.currentUid();
    if (uid == null) {
      if (mounted) setState(() { _signedOut = true; _isLoading = false; });
      return;
    }
    try {
      final service = CustomerWalletService(
        bookings: sl<BookingRemoteDataSource>(),
        deposits: sl<SecurityDepositDataSource>(),
      );
      _walletSub = service.watch(uid).listen(
        (summary) {
          if (mounted) {
            setState(() {
              _summary = summary;
              _isLoading = false;
            });
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// Customer pass (2026-11-16): pull-to-refresh entry point —
  /// [_load] re-subscribes to the wallet stream; the indicator needs
  /// a Future to await.
  Future<void> _reload() async {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summary;
    return Scaffold(
      // Audit 2026-11-15 DS-14: top: false — the shell strips the
      // top inset; a bare SafeArea double-insets outside it.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.walletTitle,
            ),
            if (_signedOut)
              // AC-8: signed out — offer sign-in, never another
              // customer's wallet (same pattern as the Home PW-9 fix).
              Expanded(
                child: AppEmptyState(
                  title: l10n.signInRequiredGeneric,
                  icon: Icons.lock_rounded,
                  actionLabel: l10n.homeSignInButton,
                  actionIcon: Icons.login_rounded,
                  onAction: () => context.go(RouteNames.auth),
                ),
              )
            else
              Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: SingleChildScrollView(
                  // AlwaysScrollable: pull-to-refresh must work even
                  // when the ledger is shorter than the viewport.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        // CU-m15: was a degenerate gradient (primary
                        // twice) — a plain fill is the same look.
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.walletActiveEscrow, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.primaryContainer)),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            // E1: the balance is masked until the user taps the eye; the eye stays light on the navy card.
                            child: MaskedValue(
                              value: l10n.amountRs(formatRs(summary?.total ?? 0)),
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                              iconColor: AppColors.primaryContainer,
                              iconSize: 28,
                              showTooltip: l10n.walletShowBalance,
                              hideTooltip: l10n.walletHideBalance,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _EscrowPill(
                                    label: l10n.walletAdvancesPaid,
                                    value: l10n.amountRs(formatRs(summary?.advancesPaid ?? 0))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _EscrowPill(
                                    label: l10n.walletSecurityEscrow,
                                    value: l10n.amountRs(formatRs(summary?.escrowHeld ?? 0))),
                              ),
                            ],
                          ),
                          // PW-2/PW-12: deposit-refund terms under the deposit pill; the headline above is now plain language too.
                          const SizedBox(height: 10),
                          Text(l10n.depositRefundTerms, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.walletLedger, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    WalletLedger(
                      isLoading: _isLoading,
                      entries: summary?.entries ?? const [],
                      hasError: _hasError,
                      onRetry: _load,
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscrowPill extends StatelessWidget {
  final String label;
  final String value;

  const _EscrowPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
          // CU-m6: the pill amounts stay masked but carry no eye of their own — the wallet header has ONE visibility toggle (on the main balance above), not three independent ones.
          Text(MaskedValue.maskDigits(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }
}
