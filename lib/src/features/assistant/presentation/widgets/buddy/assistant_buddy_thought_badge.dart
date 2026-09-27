import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_thought_topic.dart';

/// A small tinted disc at the start of the launcher's thought, saying at a
/// glance what the line is about — a magnifier for finding, a tag for an
/// offer, a bulb for choosing, a wrench for a problem… It pops in whenever
/// the [topic] changes and rocks gently while the mascot is still
/// [thinking]. Reduced motion: it just swaps.
class AssistantBuddyThoughtBadge extends StatefulWidget {
  const AssistantBuddyThoughtBadge({
    super.key,
    required this.topic,
    required this.thinking,
  });

  final AssistantThoughtTopic topic;
  final bool thinking;

  @override
  State<AssistantBuddyThoughtBadge> createState() =>
      _AssistantBuddyThoughtBadgeState();
}

class _AssistantBuddyThoughtBadgeState extends State<AssistantBuddyThoughtBadge>
    with SingleTickerProviderStateMixin {
  static const double _size = AppSize.s24;
  static const double _glyph = AppSize.s14;

  /// Rocking reach either way, in turns (≈ 8°).
  static const double _rock = 0.022;
  static const Duration _rockHalf = Duration(milliseconds: 380);

  late final AnimationController _rocking = AnimationController(
    vsync: this,
    duration: _rockHalf,
    value: 0.5,
  );
  late final Animation<double> _turns = _rocking.drive(
    Tween<double>(
      begin: -_rock,
      end: _rock,
    ).chain(CurveTween(curve: AppMotion.machEaseInOut)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRocking();
  }

  @override
  void didUpdateWidget(AssistantBuddyThoughtBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thinking != widget.thinking) _syncRocking();
  }

  void _syncRocking() {
    if (widget.thinking && !MotionGuard.reduced(context)) {
      if (!_rocking.isAnimating) _rocking.repeat(reverse: true);
    } else if (_rocking.value != 0.5) {
      _rocking.animateTo(0.5, duration: AppMotion.fast);
    }
  }

  static IconData _icon(AssistantThoughtTopic topic) => switch (topic) {
    AssistantThoughtTopic.greet => Icons.waving_hand_rounded,
    AssistantThoughtTopic.find => Icons.search_rounded,
    AssistantThoughtTopic.deals => Icons.local_offer_rounded,
    AssistantThoughtTopic.choose => Icons.lightbulb_rounded,
    AssistantThoughtTopic.ask => Icons.question_answer_rounded,
    AssistantThoughtTopic.fix => Icons.build_rounded,
    AssistantThoughtTopic.home => Icons.home_rounded,
    AssistantThoughtTopic.meals => Icons.restaurant_rounded,
    AssistantThoughtTopic.cart => Icons.shopping_basket_rounded,
    AssistantThoughtTopic.company => Icons.favorite_rounded,
  };

  @override
  void dispose() {
    _rocking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.topic == AssistantThoughtTopic.deals;
    final badge = SizedBox.square(
      key: ValueKey<AssistantThoughtTopic>(widget.topic),
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: deal ? AppColors.accent3Light : AppColors.brandLightBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _icon(widget.topic),
          size: _glyph,
          color: deal ? AppColors.accent3 : AppColors.primary,
        ),
      ),
    );
    return RotationTransition(
      turns: _turns,
      child: MotionGuard.reduced(context)
          ? badge
          : AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppSprings.snappy,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: badge,
            ),
    );
  }
}
