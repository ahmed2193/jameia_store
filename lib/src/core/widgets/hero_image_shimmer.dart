import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import 'hero_image_shape.dart';
import 'hero_image_shimmer_painter.dart';
import 'hero_shimmer_clock.dart';
import 'hero_shimmer_mask.dart';
import 'hero_shimmer_run.dart';

/// The loading shimmer of an image whose network load is taking a while:
/// Hero's skeleton shimmer ([base] → [highlight] → [base], one sweep per
/// `AppMotion.shimmer`, entering from the start edge) over the tile, with
/// the Hero bag mark — the glyph `HeroImagePlaceholder` draws, by its size
/// rule — as a light emboss ([highlight] at 90 %) the band washes out as it
/// passes. Same box and shape as the image (and as `HeroImageStillBox`).
///
/// Every live shimmer rides ONE shared ticker ([HeroShimmerClock]); this one
/// joins it only while [animate], its `TickerMode` is on and the motion is
/// not reduced, for [HeroShimmerClock.laps] whole sweeps — then it rests
/// until it comes back on screen (or the tile's next attempt mounts a new
/// one). Otherwise it is a still frame — the base and the mark, no band —
/// that never ticks. One `CustomPaint`, no rebuild per frame; the painter
/// (and its size-keyed caches) is swapped only when its look changes. No
/// `RepaintBoundary` of its own: `HeroImage` has one per tile.
class HeroImageShimmer extends StatefulWidget {
  const HeroImageShimmer({
    super.key,
    this.shape = const HeroImageShape(),
    this.animate = true,
  });

  /// The skeleton family's base and highlight (`Skeletonized`).
  static const Color base = AppColors.divider;
  static const Color highlight = AppColors.smallBackground;

  /// The bag mark's tint: the highlight at 90 % (the reference's emboss).
  static const double markAlpha = 0.9;

  final HeroImageShape shape;

  /// False freezes the tile on its still frame (a tile past the fast-retry
  /// tier: the retries go on, the 60 fps do not).
  final bool animate;

  @override
  State<HeroImageShimmer> createState() => _HeroImageShimmerState();
}

class _HeroImageShimmerState extends State<HeroImageShimmer> {
  static final Color _markTint = HeroImageShimmer.highlight.withValues(
    alpha: HeroImageShimmer.highlight.a * HeroImageShimmer.markAlpha,
  );

  late final HeroShimmerRun _run = HeroShimmerRun(() => setState(() {}));
  ValueListenable<TickerModeData>? _tickerMode;
  bool _tickersOn = true;
  bool _reduced = false;
  Object? _look;
  HeroImageShimmerPainter? _painter;

  @override
  void initState() {
    super.initState();
    unawaited(HeroShimmerMask.ensureLoaded()); // a lookup once it is there
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
    _followTickerMode();
  }

  @override
  void activate() {
    super.activate();
    _followTickerMode(); // moved under another TickerMode
  }

  @override
  void didUpdateWidget(HeroImageShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) _syncClock();
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_onTickerMode);
    _run.detach();
    super.dispose();
  }

  void _followTickerMode() {
    final ValueListenable<TickerModeData> mode = TickerMode.getValuesNotifier(
      context,
    );
    if (!identical(mode, _tickerMode)) {
      _tickerMode?.removeListener(_onTickerMode);
      _tickerMode = mode..addListener(_onTickerMode);
    }
    _tickersOn = mode.value.enabled;
    _syncClock();
  }

  void _onTickerMode() {
    final bool on = _tickerMode?.value.enabled ?? true;
    if (on == _tickersOn) return;
    setState(() {
      _tickersOn = on;
      if (!on) _run.rearm(); // back on screen later: a fresh run
      _syncClock();
    });
  }

  void _syncClock() =>
      _run.sync(live: widget.animate && !_reduced && _tickersOn);

  HeroImageShimmerPainter _painterFor(TextDirection direction) {
    final int? start = _run.startUs;
    final Object look = (
      start,
      widget.shape.circular,
      widget.shape.borderRadius,
      direction,
    );
    final HeroImageShimmerPainter? kept = _painter;
    if (kept != null && look == _look) return kept;
    _look = look;
    return _painter = HeroImageShimmerPainter(
      clock: start == null ? null : HeroShimmerClock.now,
      startUs: start ?? 0,
      circular: widget.shape.circular,
      borderRadius: widget.shape.borderRadius,
      textDirection: direction,
      baseColor: HeroImageShimmer.base,
      highlightColor: HeroImageShimmer.highlight,
      markTint: _markTint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection direction =
        Directionality.maybeOf(context) ?? TextDirection.ltr;
    return SizedBox(
      width: widget.shape.width,
      height: widget.shape.height,
      child: CustomPaint(painter: _painterFor(direction)),
    );
  }
}
