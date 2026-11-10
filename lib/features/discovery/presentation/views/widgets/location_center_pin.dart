import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// The centre pin of the set-location flow: the label + pin that
/// marks the chosen point. It is DRAGGABLE, like the "you are here"
/// pin on the Nearby map — [onDrag] pans the map under the pin.
/// (Panning the map itself moves the same point; both stay in sync
/// because the pin always sits at the map centre.)
class LocationCenterPin extends StatelessWidget {
  const LocationCenterPin({
    super.key,
    required this.label,
    required this.onDrag,
  });

  final String label;
  final GestureDragUpdateCallback onDrag;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionalTranslation(
        translation: const Offset(0.0, -0.5),
        // E3: the draggable pin is a labelled button for screen
        // readers; the drag behaviour is unchanged.
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onPanUpdate: onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.location_on_rounded,
                    size: 46, color: AppColors.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
