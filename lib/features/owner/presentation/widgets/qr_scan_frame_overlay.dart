import 'package:flutter/material.dart';

/// Four corner brackets framing the QR scan area (§17).
class QrScanFrameOverlay extends StatelessWidget {
  const QrScanFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Each corner needs its own top/left flags; build them explicitly
    // so the painter draws the right two arms.
    return Stack(
      children: [
        _corner(top: true, left: true),
        _corner(top: true, left: false),
        _corner(top: false, left: true),
        _corner(top: false, left: false),
      ],
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return Positioned(
      top: top ? 20 : null,
      bottom: top ? null : 20,
      left: left ? 20 : null,
      right: left ? null : 20,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _CornerPainter(top: top, left: left),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final origin = Offset(left ? 0 : size.width, top ? 0 : size.height);
    canvas.drawLine(
        origin, Offset(left ? size.width : 0, top ? 0 : size.height), paint);
    canvas.drawLine(
        origin, Offset(left ? 0 : size.width, top ? size.height : 0), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
