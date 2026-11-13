import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The one success banner (OW-M5/M6, 2026-11-13 audit): the agreement-signed
/// and rental-started screens each had their own fixed-light
/// `Colors.green.shade50` slab with a theme-styled subtitle — invisible
/// in dark mode. Both screens now share this banner so they cannot
/// drift again.
///
/// Colours are brightness-aware: the pale/dark success container +
/// border come from the `*For(brightness)` tokens. The text/icon
/// colour deliberately does NOT use `successOnContainerFor` in light
/// mode — its light value is `accentSuccess` #10B981, only ~2.5:1 on
/// the pale container, too light for text. `accentSuccessStrong`
/// #047857 (5.21:1 on the light container) and the dark
/// `successOnContainerDark` #86EFAC are the readable pair.
class SuccessBanner extends StatelessWidget {
  const SuccessBanner({
    super.key,
    required this.title,
    this.lines = const [],
    this.lastLineBold = false,
  });

  /// The banner headline (e.g. "Agreement Signed").
  final String title;

  /// Body lines under the headline, in order.
  final List<String> lines;

  /// When true, the last body line renders bold (e.g. the return-due
  /// line on the Rental Started banner).
  final bool lastLineBold;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final onContainer = brightness == Brightness.dark
        ? AppColors.successOnContainerDark
        : AppColors.accentSuccessStrong;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successContainerFor(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successBorderFor(brightness)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 56, color: onContainer),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: onContainer,
                ),
          ),
          for (var i = 0; i < lines.length; i++) ...[
            const SizedBox(height: 8),
            Text(
              lines[i],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: lastLineBold && i == lines.length - 1
                        ? FontWeight.w700
                        : null,
                    color: onContainer,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
