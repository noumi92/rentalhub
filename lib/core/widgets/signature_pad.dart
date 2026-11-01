import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignaturePadWidget extends StatefulWidget {
  final String signerLabel;
  final String signerName;
  final ValueChanged<bool>? onSignedChange;

  const SignaturePadWidget({
    super.key,
    required this.signerLabel,
    required this.signerName,
    this.onSignedChange,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<Offset?> _points = [];
  bool _isSigned = false;

  void _clear() {
    setState(() {
      _points.clear();
      _isSigned = false;
    });
    widget.onSignedChange?.call(false);
  }

  void _autoSign() {
    setState(() {
      _points.clear();
      // Draw a stylish signature path
      for (double x = 30; x <= 220; x += 5) {
        final y = 45 + (12 * (x % 20 == 0 ? 1 : -1)) + (x * 0.05);
        _points.add(Offset(x, y));
      }
      _isSigned = true;
    });
    widget.onSignedChange?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSigned ? AppColors.emeraldGreen : AppColors.border,
          width: _isSigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isSigned ? Icons.check_circle : Icons.draw_outlined,
                    color: _isSigned ? AppColors.emeraldGreen : AppColors.midnightNavy,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.signerLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _autoSign,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Auto Sign',
                      style: TextStyle(fontSize: 12, color: AppColors.sunsetOrange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clear,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.6), style: BorderStyle.solid),
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                final localPosition = details.localPosition;
                setState(() {
                  _points.add(localPosition);
                  _isSigned = true;
                });
                widget.onSignedChange?.call(true);
              },
              onPanEnd: (details) => _points.add(null),
              child: CustomPaint(
                painter: _SignaturePainter(points: _points),
                child: Center(
                  child: _points.isEmpty
                      ? Text(
                          'Sign here on screen (${widget.signerName})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Signed by: ${widget.signerName}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              if (_isSigned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSoftBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NADRA Validated',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldGreen,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.midnightNavyDark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
