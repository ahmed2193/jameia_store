import 'package:flutter/widgets.dart';

/// One banner of the hero carousel: full size in the middle, a step smaller
/// as it moves off to the side, so the peeking neighbours sit a little back
/// and grow into place as they arrive.
class HomeCarouselPage extends StatelessWidget {
  const HomeCarouselPage({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  /// How much smaller a banner is a whole banner away from the middle.
  static const double _shrink = 0.06;

  /// How far the banner at [index] is from the middle: 0 there, ±1 a whole
  /// banner away, and no further.
  static double offsetOf(PageController controller, int index) {
    final page = controller.hasClients ? controller.page : null;
    final current = page ?? controller.initialPage.toDouble();
    return (current - index).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, child) => Transform.scale(
      scale: 1 - _shrink * offsetOf(controller, index).abs(),
      child: child,
    ),
  );
}
