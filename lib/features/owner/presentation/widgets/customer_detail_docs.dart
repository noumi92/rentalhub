import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_kyc_slots.dart';

/// Owner-deck finish (#35), restyled Phase 3: the documents/photo
/// section of the customer profile as a 3-column dashed upload grid
/// covering ALL 11 tracked slots (see [kycDocSlots] — the guide
/// shows only 6, but License Back, Signature, Utility Bill, Extra
/// Documents and the legacy Thumbprint are tracked slots too and
/// must stay visible). Tiles are display-only by default: upload
/// happens in the Add Customer wizard, not here. A missing file
/// shows an honest "Not provided" state, never a placeholder image.
/// URLs only — the record never carries bytes.
///
/// Walk-in CRM: with [onReplaceSlot] set (walk-in records only),
/// tapping a tile recaptures that one slot — same picker rules as
/// the wizard (CNIC gallery guarded by OCR, rest camera-only) —
/// and the tile updates as soon as the new URL lands.
class CustomerDetailDocs extends StatelessWidget {
  const CustomerDetailDocs({
    super.key,
    required this.customer,
    this.onReplaceSlot,
  });

  final CustomerEntity customer;

  /// Field name of the tapped slot (see [kycDocSlots]), or null
  /// to keep the grid display-only (online customers).
  final ValueChanged<String>? onReplaceSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slots = kycDocSlots(l10n, customer);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        // Tile: label (up to 2 lines) + image area; ~104 dp wide at
        // 360 px, ~120 dp tall.
        childAspectRatio: 0.85,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _tile(context, l10n, slot.field, slot.label, slot.url);
      },
    );
  }

  Widget _tile(
    BuildContext context,
    AppLocalizations l10n,
    String field,
    String label,
    String? url,
  ) {
    final hasFile = url != null && url.isNotEmpty;
    final tile = CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.borderSubtle,
        radius: 12,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Expanded(
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, Object error, StackTrace? stack) =>
                              Center(
                                  child: Text(l10n.customerDetailNoDocument,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall))),
                    )
                  : Center(
                      child: Text(l10n.customerDetailNoDocument,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall)),
            ),
          ],
        ),
      ),
    );
    final onReplace = onReplaceSlot;
    if (onReplace == null) return tile;
    return InkWell(
      key: ValueKey('kyc_replace_$field'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => onReplace(field),
      child: tile,
    );
  }
}

/// A dashed rounded-rectangle outline (Flutter has no dashed border
/// built in). Dashes are 4 dp long with a 4 dp gap, drawn along the
/// rounded-rect path.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final segment =
            metric.extractPath(distance, math.min(distance + 4, metric.length));
        canvas.drawPath(segment, paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
