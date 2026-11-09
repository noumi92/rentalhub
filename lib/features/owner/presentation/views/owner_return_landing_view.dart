import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/operations/return_inspection_sections.dart';

/// Finish build (O25): the return landing screen — the booking
/// summary with its return-due line and the "Start Return Inspection"
/// entry. This used to be a section at the top of
/// [OwnerReturnSettlementView]; it is now its own route
/// (`/owner/return-landing/:id`, Requests branch, via
/// `BookingRouteLoader` like `ownerReturn`), and the contract view's
/// "Proceed to Return" lands here. The return view itself now starts
/// directly at the inspection.
class OwnerReturnLandingView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerReturnLandingView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.returnLandingTitle,
              subtitle: l10n.returnTripAudit(booking.bookingId),
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: ReturnLandingSection(
                  booking: booking,
                  onStart: () => context.push(
                    RouteNames.ownerReturn
                        .replaceFirst(':id', booking.bookingId),
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
