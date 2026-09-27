import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';
import 'motion.dart';
import 'sparkle_painter.dart';

/// A small celebration around a figure that just got better (a new saving
/// counting up): when [playKey] changes to a new non-null value (never on
/// mount) five four-point stars pop around the child, [spread] outside its
/// box, and are gone after [AppMotion.drawOn]. A `null` key never plays, so
/// a caller passes `null` for the changes that deserve nothing.
///
/// The stars are painted from the controller (no rebuild per frame) inside
/// their own [RepaintBoundary], ignore touches and semantics, and exist only
/// while they play. The child keeps one fixed slot of an always-built
/// `Stack`, so a burst never remounts it (a count-up inside keeps running).
///
/// Reduced motion → nothing. Inside a muted `TickerMode` (a covered page) a
/// burst waits and plays when the page is revealed.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({
    super.key,
    required this.playKey,
    required this.child,
    this.colors = defaultColors,
    this.spread = defaultSpread,
  });

  static const double defaultSpread = AppSize.s12;

  static const List<Color> defaultColors = <Color>[
    AppColors.proLime,
    AppColors.primary,
    AppColors.proAmber,
  ];

  final Object? playKey;
  final Widget child;
  final List<Color> colors;

  /// How far outside the child's box the stars reach.
  final double spread;

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  static const Key _childKey = ValueKey<String>('sparkle-child');
  static const Key _layerKey = ValueKey<String>('sparkle-layer');

  /// Built on the first burst: most figures never sparkle.
  AnimationController? _controller;
  bool _playing = false;

  AnimationController _ensureController() =>
      _controller ??= AnimationController(
        vsync: this,
        duration: AppMotion.drawOn,
      )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _playing = false);
  }

  /// A burst asked for while the tickers are muted (a covered page): it
  /// starts when they run again, so the whole burst is seen.
  bool _pending = false;

  void _play() {
    _pending = false;
    if (MotionGuard.reduced(context)) return;
    if (!TickerMode.valuesOf(context).enabled) {
      _pending = true;
      return;
    }
    _playing = true;
    _ensureController().forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pending) _play();
  }

  @override
  void didUpdateWidget(SparkleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    final key = widget.playKey;
    if (key == null || key == oldWidget.playKey) return;
    _play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spread = -widget.spread;
    final controller = _controller;
    final layer = Positioned(
      key: _layerKey,
      left: spread,
      top: spread,
      right: spread,
      bottom: spread,
      child: _playing && controller != null
          ? IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: SparklePainter(
                      progress: controller,
                      colors: widget.colors,
                      spread: widget.spread,
                      direction: Directionality.of(context),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        layer,
      ],
    );
  }
}
