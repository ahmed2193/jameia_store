import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/on_screen_gate.dart';
import '../../domain/entities/home_slide_entity.dart';
import 'home_carousel_page.dart';
import 'home_slide_card.dart';

/// The hero banners of the home feed (`slides[]`): wide rounded banners in a
/// [PageView] whose neighbours peek at the edges, a step smaller, while the
/// artwork drifts against the swipe. They advance by themselves — unless the
/// customer asked for reduced motion, a screen reader is on, or there is a
/// single slide — but not under a finger (letting go starts a full dwell on
/// the banner it left) nor while the banners are off screen, the tab is
/// hidden or the app is in the background ([OnScreenGate]). The banner
/// keeps the storefront's proportion at any screen width.
class HomeSlidesCarousel extends StatefulWidget {
  const HomeSlidesCarousel({super.key, required this.slides});

  final List<HomeSlideEntity> slides;

  @override
  State<HomeSlidesCarousel> createState() => _HomeSlidesCarouselState();
}

class _HomeSlidesCarouselState extends State<HomeSlidesCarousel>
    with OnScreenGate<HomeSlidesCarousel> {
  static const double _viewportFraction = 0.92;

  /// Half the room between two banners.
  static const double _pageGap = AppSpacing.s6;

  /// Width : height of a banner.
  static const double _aspectRatio = 2.35;

  final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
  );
  Timer? _autoAdvance;
  int _fingers = 0;

  /// Ambient motion is allowed here (not reduced, no screen reader, the tab
  /// on screen: `MotionGuard.ambientAllowed`).
  bool _allowed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allowed = MotionGuard.ambientAllowed(context);
    _rearm();
  }

  @override
  void onScreenChanged() => _rearm();

  /// A refresh hands the same widget a new slide list, so the timer has to be
  /// reconsidered: a feed that drops to one slide must stop advancing, and
  /// one that grows to two must start.
  @override
  void didUpdateWidget(covariant HomeSlidesCarousel old) {
    super.didUpdateWidget(old);
    if (old.slides.length != widget.slides.length) _rearm();
  }

  void _rearm() {
    _autoAdvance?.cancel();
    if (widget.slides.length < 2 || !_allowed || !onScreen || _fingers > 0) {
      return;
    }
    _autoAdvance = Timer.periodic(AppMotion.carousel, (_) => _next());
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _touch(PointerDownEvent event) {
    _fingers++;
    _autoAdvance?.cancel();
  }

  void _lift(PointerEvent event) {
    if (_fingers > 0) _fingers--;
    _rearm();
  }

  void _next() {
    // Hidden behind another shell tab (tickers muted): do not burn frames.
    if (!mounted ||
        !_controller.hasClients ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    final current = _controller.page?.round() ?? 0;
    _controller.animateToPage(
      (current + 1) % widget.slides.length,
      duration: AppMotion.page,
      curve: AppMotion.signature,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    if (slides.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerWidth =
            constraints.maxWidth * _viewportFraction - 2 * _pageGap;
        return SizedBox(
          height: bannerWidth / _aspectRatio,
          child: Listener(
            onPointerDown: _touch,
            onPointerUp: _lift,
            onPointerCancel: _lift,
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              itemBuilder: (context, index) => HomeCarouselPage(
                controller: _controller,
                index: index,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: _pageGap,
                  ),
                  child: HomeSlideCard(
                    slide: slides[index],
                    controller: _controller,
                    index: index,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
