import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_kyc_slots.dart';

/// 2×2 dashed upload grid covering ONLY the 4 CNIC & Driving License KYC
/// slots (CNIC Front, CNIC Back, Driving License Front, Driving License Back).
class CustomerDetailDocs extends StatelessWidget {
  const CustomerDetailDocs({
    super.key,
    required this.customer,
    this.onReplaceSlot,
  });

  final CustomerEntity customer;
  final ValueChanged<String>? onReplaceSlot;

  static IconData _iconFor(String field) => switch (field) {
        'cnicFrontUrl' => Icons.badge_outlined,
        'cnicBackUrl' => Icons.credit_card_outlined,
        'licenseFrontUrl' => Icons.directions_car_outlined,
        'licenseBackUrl' => Icons.drive_eta_outlined,
        _ => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slots = kycDocSlots(l10n, customer);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = url != null && url.isNotEmpty;
    final canUpload = onReplaceSlot != null;

    final tile = CustomPaint(
      painter: _DashedBorderPainter(
        color: isDark ? cs.outlineVariant : AppColors.borderSubtle,
        radius: 14,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(10),
        child: hasFile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, Object error, StackTrace? stack) =>
                            Center(
                          child: Text(
                            l10n.customerDetailNoDocument,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(field),
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    canUpload
                        ? l10n.customerDetailTapToUpload
                        : l10n.customerDetailNoDocument,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
      ),
    );
    final onReplace = onReplaceSlot;
    if (onReplace == null) return tile;
    return InkWell(
      key: ValueKey('kyc_replace_$field'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => onReplace(field),
      child: tile,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final segment =
            metric.extractPath(distance, math.min(distance + 5, metric.length));
        canvas.drawPath(segment, paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
