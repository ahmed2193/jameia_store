import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';
import 'home_reveal_scope.dart';

/// A home block that enters when it is first seen: it fades in and rises
/// into place the first time its top edge comes on screen. The blocks on
/// screen at launch come in one after another, [order] beats apart; the rest
/// come in as the customer scrolls to them. The pieces inside (rail cards,
/// the header's icon and arrow) enter on the same clock through
/// [HomeRevealScope], which also tells their looping touches whether the
/// block is on screen right now.
///
/// Reduced motion or a screen reader: shown as is, and no clock runs. A
/// block waiting to come in still reads to assistive technology.
class HomeReveal extends StatefulWidget {
  const HomeReveal({super.key, required this.child, this.order = 0});

  final Widget child;

  /// The block's place in the feed, for the launch cascade.
  final int order;

  @override
  State<HomeReveal> createState() => _HomeRevealState();
}

class _HomeRevealState extends State<HomeReveal>
    with SingleTickerProviderStateMixin {
  /// Between two blocks of the launch cascade, which stops growing after
  /// [_maxBeats].
  static const Duration _beat = Duration(milliseconds: 70);
  static const int _maxBeats = 4;

  /// How far down the screen the top edge may be and count as seen.
  static const double _seenAt = 0.92;

  /// The rise, as a share of the block's own height.
  static const Offset _rise = Offset(0, 0.06);

  /// The block itself takes this share of the clock; its pieces run on to
  /// the end.
  static const double _blockShare = 0.6;

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: AppMotion.drawOn,
  );
  late final Animation<double> _fade = _clock.drive(
    CurveTween(
      curve: const Interval(
        0,
        _blockShare,
        curve: AppMotion.emphasizedDecelerate,
      ),
    ),
  );
  late final Animation<Offset> _slide = _fade.drive(
    Tween<Offset>(begin: _rise, end: Offset.zero),
  );

  /// The feed's scroll, to see the block come on screen and leave it.
  ScrollPosition? _position;
  Timer? _cascade;
  bool _measured = false;
  bool _seen = false;
  bool _onScreen = false;
  bool _tickersOn = true;
  double _screenHeight = 0;

  bool get _still =>
      MotionGuard.reduced(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight = MediaQuery.sizeOf(context).height;
    _tickersOn = TickerMode.valuesOf(context).enabled;
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (position != _position) {
      _position?.removeListener(_measureAfterLayout);
      // Measured after the frame's layout: during a scroll tick the blocks
      // still sit where the last layout put them.
      _position = position?..addListener(_measureAfterLayout);
    }
    if (_still) {
      _seen = true;
      _cascade?.cancel();
      _clock.value = 1;
    }
    _measureAfterLayout();
  }

  @override
  void didUpdateWidget(covariant HomeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _measureAfterLayout();
  }

  @override
  void dispose() {
    _position?.removeListener(_measureAfterLayout);
    _cascade?.cancel();
    _clock.dispose();
    super.dispose();
  }

  void _measureAfterLayout() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      // Not laid out yet: look again after the next frame.
      _measureAfterLayout();
      return;
    }
    final position = _position;
    final top = position == null ? 0.0 : box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    // No feed around it (a test, a preview): it is simply on screen.
    final onScreen = position == null || (top < _screenHeight && bottom > 0);
    // Measured before the feed has moved: this block is part of the launch.
    final atLaunch = !_measured && (position == null || position.pixels <= 0);
    _measured = true;
    // A short last block may never lift its top to the line even at the end
    // of the feed: being fully on screen counts as seen too.
    final seen =
        position == null ||
        top <= _screenHeight * _seenAt ||
        bottom <= _screenHeight;
    if (!_seen && seen) {
      _seen = true;
      _play(atLaunch: atLaunch);
    }
    if (onScreen != _onScreen) setState(() => _onScreen = onScreen);
  }

  void _play({required bool atLaunch}) {
    if (_clock.isCompleted) return;
    final beats = atLaunch ? widget.order.clamp(0, _maxBeats) : 0;
    if (beats == 0) {
      _clock.forward();
      return;
    }
    _cascade = Timer(_beat * beats, () {
      if (mounted) _clock.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scoped = HomeRevealScope(
      reveal: _clock,
      onScreen: _onScreen && _tickersOn,
      child: widget.child,
    );
    if (_still) return scoped;
    return FadeTransition(
      opacity: _fade,
      alwaysIncludeSemantics: true,
      child: SlideTransition(position: _slide, child: scoped),
    );
  }
}
