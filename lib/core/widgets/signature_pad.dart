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
          color: _isSigned ? AppColors.accentSuccess : AppColors.borderSubtle,
          width: _isSigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                    color: _isSigned ? AppColors.accentSuccess : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.signerLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      // The pad stays near-white for ink in both modes,
                      // so the label stays a fixed dark colour.
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
                    child: Text(
                      'Auto Sign',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
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
                    child: Text(
                      'Clear',
                      style: Theme.of(context).textTheme.bodySmall,
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
              border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6), style: BorderStyle.solid),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted.withValues(alpha: 0.7),
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
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (_isSigned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'NADRA Validated',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSuccess,
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
      ..color = AppColors.primaryDark
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
