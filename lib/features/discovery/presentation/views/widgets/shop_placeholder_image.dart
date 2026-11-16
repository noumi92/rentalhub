import 'package:flutter/material.dart';

/// Customer pass (2026-11-16): the generic showroom placeholder.
///
/// When a shop owner provided no header photo, shop surfaces show
/// this bundled generic showroom photo instead of the dull grey
/// storefront-icon box. The photo is generic stock — it is never
/// presented as the shop's own showroom; it only fills the space a
/// missing photo leaves empty.
///
/// `assets/images/showroom_banner_1.jpg` (280x120) was chosen over
/// `showroom_banner_2.jpg` (300x90): the same photo, but banner 1's
/// 2.33:1 aspect matches the card banner area with far less cropping.
/// Both are bundled via the `assets/images/` pubspec entry, so no
/// pubspec change was needed.
class ShopPlaceholderImage extends StatelessWidget {
  const ShopPlaceholderImage({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
  });

  static const String asset = 'assets/images/showroom_banner_1.jpg';

  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      // If the bundled asset ever goes missing, fall back to the old
      // neutral box instead of a broken-image icon.
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width ?? double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.storefront_rounded, size: 48)),
      ),
    );
    final radius = borderRadius;
    if (radius == null) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}
