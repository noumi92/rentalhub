import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/data/datasources/shop_reset_data_source.dart';

/// Audit impl (O50): reset options — bookings, customers, cars, or
/// all data. Every reset is scoped to the current shop only and is
/// gated by the dangerous-action confirm dialog ("Are you sure?
/// This will permanently delete …"). The shop document and its
/// finance settings are never deleted: the shop stays, its data
/// goes.
class OwnerResetOptionsView extends StatefulWidget {
  final String shopId;

  const OwnerResetOptionsView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerResetOptionsView> createState() => _OwnerResetOptionsViewState();
}

class _OwnerResetOptionsViewState extends State<OwnerResetOptionsView> {
  final _resetDs = ShopResetDataSource();
  bool _isBusy = false;
  String? _busyOption;

  Future<void> _confirmAndReset(String option) async {
    final l10n = AppLocalizations.of(context)!;
    final what = switch (option) {
      'bookings' => l10n.resetBookings,
      'customers' => l10n.resetCustomers,
      'cars' => l10n.resetCars,
      _ => l10n.resetAllData,
    };
    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: l10n.resetConfirmTitle,
      message: l10n.resetConfirmMessage(what),
      confirmLabel: l10n.resetYesReset,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isBusy = true;
      _busyOption = option;
    });
    try {
      final deleted = switch (option) {
        'bookings' => await _resetDs.resetBookings(widget.shopId),
        'customers' => await _resetDs.resetCustomers(widget.shopId),
        'cars' => await _resetDs.resetCars(widget.shopId),
        _ => await _resetDs.resetAll(widget.shopId),
      };
      if (mounted) {
        AppFeedback.showSuccess(
            context, l10n.resetDone(deleted.toString()));
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.resetFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyOption = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.resetTitle,
              subtitle: l10n.resetSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.resetWarning,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 16),
                    _option(
                      l10n,
                      option: 'bookings',
                      icon: Icons.book_online_rounded,
                      title: l10n.resetBookings,
                      subtitle: l10n.resetBookingsHint,
                    ),
                    _option(
                      l10n,
                      option: 'customers',
                      icon: Icons.people_rounded,
                      title: l10n.resetCustomers,
                      subtitle: l10n.resetCustomersHint,
                    ),
                    _option(
                      l10n,
                      option: 'cars',
                      icon: Icons.directions_car_rounded,
                      title: l10n.resetCars,
                      subtitle: l10n.resetCarsHint,
                    ),
                    _option(
                      l10n,
                      option: 'all',
                      icon: Icons.delete_forever_rounded,
                      title: l10n.resetAllData,
                      subtitle: l10n.resetAllHint,
                      destructive: true,
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

  Widget _option(
    AppLocalizations l10n, {
    required String option,
    required IconData icon,
    required String title,
    required String subtitle,
    bool destructive = false,
  }) {
    final busy = _isBusy && _busyOption == option;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon,
            color: destructive
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary),
        title: Text(title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        subtitle: Text(subtitle),
        trailing: SizedBox(
          width: 96,
          child: DebouncedButton(
            text: l10n.resetAction,
            isLoading: busy,
            onPressed: _isBusy ? () {} : () => _confirmAndReset(option),
          ),
        ),
      ),
    );
  }
}
