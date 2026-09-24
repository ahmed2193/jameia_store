import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/paging_dots.dart';
import '../../domain/entities/home_slide_entity.dart';
import 'home_slide_card.dart';

/// The hero carousel of the home feed (`slides[]`): a peeking [PageView] with
/// paging dots that advances by itself — unless the customer asked for reduced
/// motion, or there is a single slide.
class HomeSlidesCarousel extends StatefulWidget {
  const HomeSlidesCarousel({super.key, required this.slides});

  final List<HomeSlideEntity> slides;

  @override
  State<HomeSlidesCarousel> createState() => _HomeSlidesCarouselState();
}

class _HomeSlidesCarouselState extends State<HomeSlidesCarousel> {
  static const double _viewportFraction = 0.92;

  final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
  );
  Timer? _autoAdvance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rearm();
  }

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
    if (widget.slides.length < 2 || MotionGuard.reduced(context)) return;
    _autoAdvance = Timer.periodic(AppMotion.carousel, (_) => _next());
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    super.dispose();
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
    return Column(
      children: [
        SizedBox(
          height: AppSize.s170,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s4,
              ),
              child: HomeSlideCard(slide: slides[index]),
            ),
          ),
        ),
        if (slides.length > 1)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.s8,
              bottom: AppSpacing.s4,
            ),
            child: PagingDots(controller: _controller, count: slides.length),
          ),
      ],
    );
  }
}
