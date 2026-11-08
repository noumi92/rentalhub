import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final service = CustomerWalletService(
        bookings: sl<BookingRemoteDataSource>(),
        deposits: sl<SecurityDepositDataSource>(),
      );
      final summary = await service.load(CustomerWalletService.currentUid());
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summary;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              titleWidget: Text(
                l10n.walletTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(18),
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
                          Text(
                            l10n.walletActiveEscrow,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryContainer),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            // E1: the balance is masked until the user
                            // taps the eye; the eye stays light on the
                            // navy card.
                            child: MaskedValue(
                              value: 'Rs. ${summary?.total ?? 0}',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white),
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
                                    value: 'Rs. ${summary?.advancesPaid ?? 0}'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _EscrowPill(
                                    label: l10n.walletSecurityEscrow,
                                    value: 'Rs. ${summary?.escrowHeld ?? 0}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.walletLedger,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.primaryContainer)),
          // E1: pill amounts are masked like the main balance.
          MaskedValue(
            value: value,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
            iconColor: AppColors.primaryContainer,
            iconSize: 18,
            showTooltip: l10n.walletShowAmount,
            hideTooltip: l10n.walletHideAmount,
          ),
        ],
      ),
    );
  }
}
