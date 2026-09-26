import 'package:flutter/material.dart';

import '../motion/haptics.dart';
import '../motion/motion.dart';

/// The emoji at the end of a collection's heading ("…near you 🔥"): it
/// wiggles once as the heading lands, and again when tapped. Decorative, so
/// it reads to nobody; still under reduced motion.
class CollectionHeroEmoji extends StatefulWidget {
  const CollectionHeroEmoji({
    super.key,
    required this.emoji,
    required this.style,
    this.delay = Duration.zero,
  });

  final String emoji;
  final TextStyle style;

  /// When the first wiggle starts (after the heading has landed).
  final Duration delay;

  @override
  State<CollectionHeroEmoji> createState() => _CollectionHeroEmojiState();
}

class _CollectionHeroEmojiState extends State<CollectionHeroEmoji>
    with SingleTickerProviderStateMixin {
  static const Duration _wiggleTime = Duration(milliseconds: 900);

  /// Left, right, a little less, a little less, still — with a grow.
  static final Animatable<double> _turns = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -0.05), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.03), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.02), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.02, end: 0), weight: 1),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));
  static final Animatable<double> _grow = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.2), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1), weight: 2),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));

  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: _wiggleTime,
  );
  bool _greeted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_greeted) return;
    _greeted = true;
    if (MotionGuard.reduced(context)) return;
    Future<void>.delayed(widget.delay, () {
      if (mounted) _wiggle.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _tap() {
    Haptics.tap();
    if (!MotionGuard.reduced(context)) _wiggle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _wiggle,
          child: Text(widget.emoji, style: widget.style),
          builder: (context, child) => Transform.rotate(
            angle: _turns.transform(_wiggle.value) * 2 * 3.141592653589793,
            child: Transform.scale(
              scale: _grow.transform(_wiggle.value),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
