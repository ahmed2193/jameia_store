import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../assistant_word_reveal.dart';

/// The customer's question in the ask demo, coming in word by word in a
/// brand-tinted bubble ([AssistantWordReveal] on the demo's clock — whole
/// words, so Arabic keeps its joined forms). The whole line holds the
/// bubble's size from the first word, so nothing around it moves.
class AssistantOnboardingTypedBubble extends StatelessWidget {
  const AssistantOnboardingTypedBubble({
    super.key,
    required this.text,
    required this.typed,
    required this.appear,
  });

  final String text;

  /// Share of the reveal so far, `0 → 1`.
  final double typed;

  /// The bubble's scale as it pops in from its tail.
  final double appear;

  static const double _maxWidth = AppSize.s260;
  static const int _maxLines = 2;
  static const BorderRadiusDirectional _shape = BorderRadiusDirectional.only(
    topStart: Radius.circular(SuiRadius.bubble),
    topEnd: Radius.circular(SuiRadius.bubble),
    bottomStart: Radius.circular(SuiRadius.bubble),
    bottomEnd: Radius.circular(AppSize.r4),
  );

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.primaryText,
    );
    return Transform.scale(
      scale: appear,
      alignment: AlignmentDirectional.bottomEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.brandLightBg,
            borderRadius: _shape,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            child: AssistantWordReveal.at(
              text: text,
              progress: typed,
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
