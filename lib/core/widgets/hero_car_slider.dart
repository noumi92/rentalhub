import 'dart:async';
import 'package:flutter/material.dart';

/// Auto-playing car slider for the login hero (#1, #6): a swipeable
/// [PageView] over the car artwork already in the repo, advancing every
/// 3.5s with dot indicators. The timer is cancelled in [dispose];
/// widget tests must wrap teardown in `tester.runAsync` (see AGENTS.md).
class HeroCarSlider extends StatefulWidget {
  const HeroCarSlider({super.key, this.height = 110});

  final double height;

  static const List<String> slides = [
    'assets/images/honda_civic_hero.png',
    'assets/images/toyota_corolla.png',
    'assets/images/red_civic.png',
    'assets/images/white_sedan_hero.png',
  ];

  @override
  State<HeroCarSlider> createState() => _HeroCarSliderState();
}

class _HeroCarSliderState extends State<HeroCarSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % HeroCarSlider.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: HeroCarSlider.slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Image.asset(
              HeroCarSlider.slides[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            HeroCarSlider.slides.length,
            (i) => Container(
              width: _page == i ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _page == i
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
