import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Action chosen from [showCustomerAddedBottomSheet].
enum CustomerAddedSheetAction { startBooking, viewProfile, done }

/// Clean modal bottom sheet shown right after adding a walk-in customer so
/// there is never a dead-end full-screen message: the owner can start a
/// booking, view the profile, tap Done, or swipe down to return to Customers.
Future<CustomerAddedSheetAction> showCustomerAddedBottomSheet(
  BuildContext context, {
  required CustomerEntity customer,
}) async {
  final result = await showModalBottomSheet<CustomerAddedSheetAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentSuccessStrong,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                customer.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.customerAddedReady(customer.name),
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              DebouncedButton(
                text: l10n.customerAddedStartBooking,
                icon: Icons.calendar_month_rounded,
                onPressed: () =>
                    Navigator.of(ctx).pop(CustomerAddedSheetAction.startBooking),
              ),
              const SizedBox(height: 10),
              DebouncedButton(
                text: l10n.customerAddedViewProfile,
                icon: Icons.person_rounded,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                onPressed: () =>
                    Navigator.of(ctx).pop(CustomerAddedSheetAction.viewProfile),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(CustomerAddedSheetAction.done),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l10n.done),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? CustomerAddedSheetAction.done;
}
