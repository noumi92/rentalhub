import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../admin/data/repositories/platform_settings_repository.dart';
import '../../domain/entities/booking_entity.dart';
import '../../utils/unverified_shop_gate.dart';
import '../widgets/advance_deposit_notice_card.dart';
import '../widgets/booking_summary_card.dart';
import '../widgets/review_booking_submitter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

class ReviewBookingRequestView extends StatefulWidget {
  final Map<String, dynamic> bookingDraft;
  final Function(BookingEntity booking)? onRequestCreated;
  final VoidCallback? onBack;
  // Customer rework (Worker E): the shop's verification state when
  // the caller knows it (draft['shopIsVerified'] is the other
  // source). Null = unknown; the view looks the shop up and fails
  // open, so an unknown shop is never blocked. [bookingGate] is the
  // test seam — production resolves the platform settings through
  // the service locator.
  final bool? shopIsVerified;
  final UnverifiedShopBookingGate? bookingGate;

  const ReviewBookingRequestView({
    super.key,
    required this.bookingDraft,
    this.onRequestCreated,
    this.onBack,
    this.shopIsVerified,
    this.bookingGate,
  });

  @override
  State<ReviewBookingRequestView> createState() =>
      _ReviewBookingRequestViewState();
}

class _ReviewBookingRequestViewState extends State<ReviewBookingRequestView> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  // Null until the shop's verification state is known (an explicit
  // flag, or the `shops/{shopId}` lookup). Null renders no badge.
  bool? _shopIsVerified;

  @override
  void initState() {
    super.initState();
    final known = widget.shopIsVerified ??
        widget.bookingDraft['shopIsVerified'] as bool?;
    if (known != null) {
      _shopIsVerified = known;
    } else {
      _resolveShopVerification();
    }
  }

  UnverifiedShopBookingGate _defaultGate() {
    try {
      if (sl.isRegistered<PlatformSettingsRepository>()) {
        return UnverifiedShopBookingGate(
            settings: sl<PlatformSettingsRepository>());
      }
    } catch (_) {}
    return UnverifiedShopBookingGate();
  }

  Future<void> _resolveShopVerification() async {
    // CU-M12: no shop id, no lookup — the old 'shop-default'
    // fallback read a shop that does not exist. An incomplete draft
    // already shows the error state and hides the submit button.
    final shopId = widget.bookingDraft['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) return;
    final gate = widget.bookingGate ?? _defaultGate();
    final verified = await gate.isShopVerified(shopId: shopId);
    if (!mounted) return;
    setState(() => _shopIsVerified = verified);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    // CU-M12: refuse to submit a malformed draft — the submitter
    // also rejects it, but the button never fires in the first place.
    if (!_isDraftComplete) return;
    setState(() => _isSubmitting = true);
    try {
      final booking = await ReviewBookingSubmitter(
        bookingGate: widget.bookingGate,
      ).submit(
        context: context,
        draft: widget.bookingDraft,
        shopIsVerified: _shopIsVerified,
        notes: _notesController.text.trim(),
      );
      if (booking != null && mounted) {
        widget.onRequestCreated?.call(booking);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// CU-M12: the draft is only submittable when every field the
  /// booking needs is present — a missing draft is an error screen,
  /// never a booking with invented money, plate or shop.
  bool get _isDraftComplete =>
      ReviewBookingSubmitter.isDraftComplete(widget.bookingDraft);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.bookingDraft;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.reviewTitle,
              onBack: widget.onBack,
            ),
            // CU-M12: a missing draft shows an error and refuses to
            // submit — the summary card below needs real values.
            if (!_isDraftComplete)
              Expanded(
                child: AppErrorState(message: l10n.reviewDraftMissing),
              )
            else
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookingSummaryCard(
                      carName: d['carName'] as String? ?? '—',
                      plateNumber: d['plateNumber'] as String? ?? '—',
                      shopName: d['shopName'] as String? ?? '—',
                      isWithDriver: d['isWithDriver'] as bool? ?? false,
                      packageType: d['packageType'] as String? ?? '24h',
                      // CU-M12: no invented fallbacks — _isDraftComplete
                      // guarantees these are present (see above).
                      pickupTime: d['pickupTime'] as DateTime,
                      returnTime: d['returnTime'] as DateTime,
                      totalAmount: d['totalAmount'] as int,
                      advanceRequired: d['advanceRequired'] as int,
                      tripType: d['tripType'] as String? ?? 'in_city',
                      kmLimit: d['kmLimit'] as int?,
                      securityDepositPkr: d['securityDepositPkr'] as int?,
                      destinationCity: d['destinationCity'] as String?,
                    ),
                    // Customer rework (Worker E): the shop's
                    // unverified state is shown honestly during
                    // booking — a label, never a block while the
                    // platform setting is ON.
                    if (_shopIsVerified == false) ...[
                      const SizedBox(height: 10),
                      VerifiedBadge(
                        isVerified: false,
                        label: l10n.shops_unverified,
                      ),
                    ],
                    const SizedBox(height: 14),
                    AdvanceDepositNoticeCard(
                      isWithDriver: d['isWithDriver'] as bool? ?? false,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppCardDecoration.shadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reviewSpecialInstructions,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  l10n.reviewInstructionsHint,
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // CU-M12: no submit button for a missing draft — the
            // error state above is the whole screen.
            if (_isDraftComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, -3))
                  ],
                ),
                child: DebouncedButton(
                  text: _isSubmitting
                      ? l10n.reviewSending
                      : l10n.reviewSendRequest,
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitRequest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
