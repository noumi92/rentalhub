import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/routing/route_names.dart';

class SplashView extends StatefulWidget {
  final Duration duration;

  const SplashView({
    super.key,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Auto-advance after splash duration based on session & onboarding status
    _timer = Timer(widget.duration, () {
      if (mounted) {
        context.go(AuthRouteGuard.resolveAuthDestination());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131842),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1336),
              Color(0xFF161B4A),
              Color(0xFF12163F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              // Centered Brand Identity matching Gaari-Customer-App-UI Splash Reference
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/rentalhub_splash_logo.png',
                        width: 320,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        width: 0,
                        height: 0,
                        child: Text('RentalHub', style: TextStyle(fontSize: 0, color: Colors.transparent)),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Brand Accent & Copyright
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Orange accent bar
                    Container(
                      width: 44,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: AppColors.sunsetOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© ${DateTime.now().year} RentalHub. All rights reserved.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering the sleek curved car silhouette from the UI specification
class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Flowing aerodynamic car roofline: front fender -> hood -> windshield -> roof -> rear window -> trunk
    path.moveTo(size.width * 0.08, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.65,
      size.width * 0.36,
      size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.52,
      size.height * 0.10,
      size.width * 0.68,
      size.height * 0.30,
    );
    path.quadraticBezierTo(
      size.width * 0.80,
      size.height * 0.55,
      size.width * 0.92,
      size.height * 0.85,
    );

    canvas.drawPath(path, paint);

    // Subtle front headlight glow streak
    final accentPaint = Paint()
      ..color = AppColors.sunsetOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final accentPath = Path();
    accentPath.moveTo(size.width * 0.04, size.height * 0.90);
    accentPath.lineTo(size.width * 0.12, size.height * 0.90);
    canvas.drawPath(accentPath, accentPaint);

    // Subtle rear taillight glow streak
    final rearPaint = Paint()
      ..color = AppColors.crimsonRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rearPath = Path();
    rearPath.moveTo(size.width * 0.88, size.height * 0.90);
    rearPath.lineTo(size.width * 0.96, size.height * 0.90);
    canvas.drawPath(rearPath, rearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

