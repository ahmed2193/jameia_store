import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_thought.dart';
import 'assistant_buddy_thought_badge.dart';
import 'assistant_buddy_thought_text.dart';

/// Inside the launcher's thought bubble: a badge saying what the line is
/// about, then a few dots while the mascot is [thinking] and [thought]
/// typing itself out. Each change cross-fades — the old content lifting
/// away, the new rising in — while the bubble eases to its new size from
/// its [alignment] corner. Reduced motion: it swaps.
class AssistantBuddyThoughtLine extends StatelessWidget {
  const AssistantBuddyThoughtLine({
    super.key,
    required this.thought,
    required this.thinking,
    required this.alignment,
    required this.onTyped,
  });

  final AssistantThought thought;
  final bool thinking;
  final Alignment alignment;
  final ValueChanged<AssistantThought> onTyped;

  static const double _dots = AppSize.s24;
  static const Offset _rise = Offset(0, 0.4);
  static const Offset _lift = Offset(0, -0.4);

  @override
  Widget build(BuildContext context) {
    final Widget content = thinking
        ? BrandedDotLoader(
            key: ValueKey<(String, AssistantThought)>(('dots', thought)),
            size: _dots,
            color: AppColors.primary,
          )
        : AssistantBuddyThoughtText(
            key: ValueKey<AssistantThought>(thought),
            text: thought.textKey.tr(),
            style: AppTextStyles.subheadingMedium.copyWith(
              color: AppColors.primaryText,
            ),
            onTyped: () => onTyped(thought),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AssistantBuddyThoughtBadge(topic: thought.topic, thinking: thinking),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          // An AnimatedSize of zero duration must not run.
          child: MotionGuard.reduced(context)
              ? content
              : AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasizedDecelerate,
                  alignment: alignment,
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,
                    switchInCurve: AppMotion.emphasizedDecelerate,
                    switchOutCurve: AppMotion.exit,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: alignment,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: child.key == content.key ? _rise : _lift,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: content,
                  ),
                ),
        ),
      ],
    );
  }
}
