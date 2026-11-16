import 'package:flutter/material.dart';

import '../theme/card_decoration.dart';

/// Boarding-pass card (customer pickup pass): top + bottom sections
/// split by a perforated tear line with side notches.
///
/// Showroom redesign Phase 5 (2026-11-16): the outer card uses the
/// canonical [AppCardDecoration.of] (1 px hairline, radius 16,
/// elevation 1.5) like every other card; the tear-line notches are
/// still borderless scaffold-coloured circles, so the hairline is
/// interrupted exactly at the tear — the perforation look. The old
/// local radius-20 borderless decoration is gone.
class BoardingPassCard extends StatelessWidget {
  final Widget topSection;
  final Widget bottomSection;

  const BoardingPassCard({
    super.key,
    required this.topSection,
    required this.bottomSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardDecoration.of(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: topSection,
          ),
          // Perforated tear line with side semicircular notches
          SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final int dashCount =
                          (constraints.maxWidth / 10).floor();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(dashCount, (_) {
                          return Container(
                            width: 5,
                            height: 1.5,
                            color: Theme.of(context).dividerColor,
                          );
                        }),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: -14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      
                    ),
                  ),
                ),
                Positioned(
                  right: -14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: bottomSection,
          ),
        ],
      ),
    );
  }
}

