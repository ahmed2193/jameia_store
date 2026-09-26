import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/motion/motion.dart';
import 'pro_brand_tile.dart';

/// An endless row of brand tiles that drifts by itself: [brands] repeat
/// forever, [reverse] drifts the other way (the second row), [shift] starts
/// the row on another brand. The drift pauses while the customer drags the
/// row and resumes from where they left it; under reduced motion the row
/// only moves by hand. For a screen-reader user the row stands still and
/// holds every brand once, so swiping through it ends.
class ProBrandMarquee extends StatefulWidget {
  const ProBrandMarquee({
    super.key,
    required this.brands,
    this.reverse = false,
    this.shift = 0,
  });

  final List<BrandEntity> brands;
  final bool reverse;
  final int shift;

  @override
  State<ProBrandMarquee> createState() => _ProBrandMarqueeState();
}

class _ProBrandMarqueeState extends State<ProBrandMarquee>
    with SingleTickerProviderStateMixin {
  /// Drift speed in logical pixels per second.
  static const double _speed = 24;
  static const double _gap = AppSpacing.s12;
  static const double _extent = ProBrandTile.side + _gap;

  /// The longest step one tick may drift. After the ticker was muted (the
  /// page covered by another route, the app in the background) the row
  /// resumes where it was instead of jumping ahead by the time it was away.
  static const Duration _maxStep = Duration(milliseconds: 50);

  late final ScrollController _controller;
  late final Ticker _ticker;

  /// Ticker time of the previous drift step.
  Duration _last = Duration.zero;

  /// The customer is dragging the row.
  bool _held = false;

  @override
  void initState() {
    super.initState();
    // The second row starts half a tile in, so the rows never line up. The
    // drifting offset is not worth restoring: skipping PageStorage keeps
    // every drift step from writing to it.
    _controller = ScrollController(
      initialScrollOffset: widget.reverse ? _extent / 2 : 0,
      keepScrollOffset: false,
    );
    _ticker = createTicker(_drift);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Runs the drift unless motion is reduced, a screen reader is on or the
  /// row is held.
  void _sync() {
    final run =
        !MotionGuard.reduced(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        !_held;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  /// Advances the row by the time since the previous tick (at most
  /// [_maxStep]), from wherever it is now.
  void _drift(Duration elapsed) {
    final step = elapsed - _last;
    _last = elapsed;
    if (!_controller.hasClients) return;
    final capped = step > _maxStep ? _maxStep : step;
    final seconds = capped.inMicroseconds / Duration.microsecondsPerSecond;
    _controller.jumpTo(_controller.offset + _speed * seconds);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _held = true;
      _sync();
    } else if (notification is ScrollEndNotification && _held) {
      _held = false;
      _sync();
    }
    // The row's own scrolling is nobody else's business (pull-to-refresh).
    return true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.brands;
    if (brands.isEmpty) return const SizedBox.shrink();
    final accessible = MediaQuery.accessibleNavigationOf(context);
    return RepaintBoundary(
      child: SizedBox(
        height: ProBrandTile.side,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            reverse: widget.reverse,
            itemExtent: _extent,
            // Endless for the eye; every brand once for a screen reader.
            itemCount: accessible ? brands.length : null,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsetsDirectional.only(end: _gap),
              child: ProBrandTile(
                brand: brands[(index + widget.shift) % brands.length],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
