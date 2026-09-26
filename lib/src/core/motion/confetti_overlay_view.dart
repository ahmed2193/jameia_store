import 'package:flutter/widgets.dart';

import 'confetti_painter.dart';
import 'motion.dart';

/// What [ConfettiOverlay] inserts: plays [pieces] once over
/// [AppMotion.confetti], ignoring touches, then calls [onDone] (which removes
/// the entry). Its root is the `Positioned` an overlay needs.
class ConfettiOverlayView extends StatefulWidget {
  const ConfettiOverlayView({
    super.key,
    required this.pieces,
    required this.origin,
    required this.onDone,
  });

  final List<ConfettiPiece> pieces;

  /// Launch point as fractions of the screen.
  final Offset origin;
  final VoidCallback onDone;

  @override
  State<ConfettiOverlayView> createState() => _ConfettiOverlayViewState();
}

class _ConfettiOverlayViewState extends State<ConfettiOverlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.confetti,
  );

  void _onStatus(AnimationStatus status) {
    // Only a finished burst removes the entry, never a teardown.
    if (status.isCompleted) widget.onDone();
  }

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener(_onStatus)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ConfettiPainter(
            pieces: widget.pieces,
            progress: _controller,
            origin: widget.origin,
          ),
        ),
      ),
    ),
  );
}
