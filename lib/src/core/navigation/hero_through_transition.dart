import 'package:flutter/material.dart';

/// The entrance of a page that passes THROUGH the one below instead of
/// sliding over it (Material shared axis / fade through):
///
/// 1. over the first [fadeOutShare] a backdrop in the scaffold colour fades
///    in over the page below (the outgoing page fades out, and never through
///    an empty frame, whatever page type is below);
/// 2. then the page fades in, sliding in from [shift] dp on the end side
///    (mirrored in RTL) and settling from [zoomFrom] to full size.
///
/// The pop plays the same backwards. [animation] is already eased (or linear
/// under a finger). Paint-only: two opacity layers and a transform.
class HeroThroughTransition extends StatefulWidget {
  const HeroThroughTransition({
    super.key,
    required this.animation,
    required this.child,
    this.shift = 0,
    this.zoomFrom = 1,
  });

  /// Share of the transition the outgoing page takes to fade out.
  static const double fadeOutShare = 0.3;

  final Animation<double> animation;
  final Widget child;

  /// Horizontal travel of the incoming page, from the end edge.
  final double shift;

  /// Scale the incoming page settles from (1 = none).
  final double zoomFrom;

  @override
  State<HeroThroughTransition> createState() => _HeroThroughTransitionState();
}

class _HeroThroughTransitionState extends State<HeroThroughTransition> {
  static const Interval _backdropSpan = Interval(
    0,
    HeroThroughTransition.fadeOutShare,
  );
  static const Interval _contentSpan = Interval(
    HeroThroughTransition.fadeOutShare,
    1,
  );

  late CurvedAnimation _backdrop;
  late CurvedAnimation _content;

  @override
  void initState() {
    super.initState();
    _makeCurves();
  }

  void _makeCurves() {
    _backdrop = CurvedAnimation(parent: widget.animation, curve: _backdropSpan);
    _content = CurvedAnimation(parent: widget.animation, curve: _contentSpan);
  }

  @override
  void didUpdateWidget(HeroThroughTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _backdrop.dispose();
      _content.dispose();
      _makeCurves();
    }
  }

  @override
  void dispose() {
    _backdrop.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toEnd = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _backdrop,
            child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
          ),
        ),
        FadeTransition(
          opacity: _content,
          child: ListenableBuilder(
            listenable: widget.animation,
            child: widget.child,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                (1 - widget.animation.value) * widget.shift * toEnd,
                0,
              ),
              child: Transform.scale(
                scale: widget.zoomFrom + (1 - widget.zoomFrom) * _content.value,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
