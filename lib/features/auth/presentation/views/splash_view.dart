import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final year = DateTime.now().year;
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Audit SH-N1: the gradient lived as hardcoded hex here;
            // it now lives in AppColors (splashGradient* tokens).
            colors: [
              AppColors.splashGradientTop,
              AppColors.splashGradientMiddle,
              AppColors.splashGradientBottom,
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
                      // Audit SH-N12: the brand text used to hide as
                      // a zero-size transparent Text node (a fontSize:0
                      // hack). It is a semantics label now: screen
                      // readers announce "RentalHub" for the logo
                      // image, with nothing rendered.
                      Semantics(label: 'RentalHub'),
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
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.authCopyright(year) ??
                          '© $year RentalHub. All rights reserved.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
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


