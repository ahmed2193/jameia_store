import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/ambient_loop.dart';
import '../../../../core/motion/motion.dart';

/// The short tag over a campaign headline ("Limited time"). A [beat] tag
/// gives a small double heartbeat every few seconds while it is on screen.
class HomeStripBadge extends StatelessWidget {
  const HomeStripBadge({
    super.key,
    required this.label,
    required this.fill,
    required this.ink,
    this.beat = false,
  });

  final String label;
  final Color fill;
  final Color ink;

  /// Beats now and then, for a deadline.
  final bool beat;

  /// A double beat: one burst, then the loop rests.
  /// One heartbeat, then a still rest twice as long.
  static const Duration _beat = Duration(milliseconds: 1200);
  static const Duration _beatRest = Duration(milliseconds: 2400);

  static final Animatable<double> _heartbeat = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.1, end: 1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.06), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 1),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionSmall.copyWith(
          color: ink,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
    if (!beat) return tag;
    return AmbientLoop.value(
      period: _beat,
      rest: _beatRest,
      valueBuilder: (context, t, tag) =>
          Transform.scale(scale: _heartbeat.transform(t), child: tag),
      child: tag,
    );
  }
}
