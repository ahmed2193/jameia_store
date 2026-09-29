import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/vertical_swap_transition.dart';
import '../../../domain/entities/assistant_thought.dart';
import '../assistant_word_reveal.dart';
import 'assistant_buddy_thought_badge.dart';

/// Inside the launcher's thought bubble: a badge saying what the line is
/// about, then [thought] revealing word by word ([AssistantWordReveal];
/// [onRevealed] once every word is in). A line that takes over from the one
/// before swaps in place — the old words leave upwards, the new rise in
/// ([VerticalSwapTransition]) — while the bubble eases to its new size from
/// its [alignment] corner over [AppMotion.medium]. Reduced motion: it swaps.
class AssistantBuddyThoughtLine extends StatelessWidget {
  const AssistantBuddyThoughtLine({
    super.key,
    required this.thought,
    required this.alignment,
    required this.onRevealed,
  });

  final AssistantThought thought;
  final Alignment alignment;
  final ValueChanged<AssistantThought> onRevealed;

  @override
  Widget build(BuildContext context) {
    final Widget words = AssistantWordReveal(
      key: ValueKey<AssistantThought>(thought),
      text: thought.textKey.tr(),
      style: AppTextStyles.subheadingMedium.copyWith(
        color: AppColors.primaryText,
      ),
      textWidthBasis: TextWidthBasis.longestLine,
      onDone: () => onRevealed(thought),
    );
    final reduced = MotionGuard.reduced(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AssistantBuddyThoughtBadge(topic: thought.topic),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          // An AnimatedSize of zero duration must not run.
          child: reduced
              ? words
              : AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.signature,
                  alignment: alignment,
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,
                    switchInCurve: AppMotion.signature,
                    switchOutCurve: AppMotion.exit,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: alignment,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, animation) =>
                        VerticalSwapTransition(
                          animation: animation,
                          incoming: child.key == words.key,
                          child: child,
                        ),
                    child: words,
                  ),
                ),
        ),
      ],
    );
  }
}
