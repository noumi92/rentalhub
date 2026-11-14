import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PakistaniPlateWidget extends StatelessWidget {
  final String plateNumber;
  final String provinceCode;
  final bool isCompact;

  const PakistaniPlateWidget({
    super.key,
    required this.plateNumber,
    this.provinceCode = 'PUNJAB',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIslamabad =
        plateNumber.toUpperCase().startsWith('ICT') || provinceCode == 'ICT';
    // Audit SH-N1: the strip colours lived as hardcoded hex here;
    // they are real plate colours, named in AppColors.
    final Color stripColor = isIslamabad
        ? AppColors.plateStripIslamabad
        : AppColors.plateStripDefault;
    final String stripLabel = isIslamabad ? 'ICT' : 'PK';

    return Container(
      constraints: BoxConstraints(minHeight: isCompact ? 26 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.primaryDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: isCompact ? 22 : 26,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: stripColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(3.5),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: isCompact ? 8 : 10,
                  color: Colors.white,
                ),
                Text(
                  stripLabel,
                  style: TextStyle(
                    fontSize: isCompact ? 7 : 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 7 : 10),
            child: Text(
              plateNumber.toUpperCase(),
              style: (isCompact
                      ? Theme.of(context).textTheme.labelSmall
                      : Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

