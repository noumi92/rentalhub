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
    final Color stripColor =
        isIslamabad ? const Color(0xFF1E3A8A) : const Color(0xFF15803D);
    final String stripLabel = isIslamabad ? 'ICT' : 'PK';

    return Container(
      constraints: BoxConstraints(minHeight: isCompact ? 26 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.midnightNavyDark, width: 1.5),
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
                    fontWeight: FontWeight.w900,
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
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isCompact ? 11.5 : 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.midnightNavyDark,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

