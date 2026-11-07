import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                            color: AppColors.borderSubtle,
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
                      border: Border.all(color: AppColors.borderSubtle),
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
                      border: Border.all(color: AppColors.borderSubtle),
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

