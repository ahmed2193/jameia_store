import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// The end of a reply that is still being written. Steady, not blinking: a
/// blink adds a ticker per frame and a flicker that competes with the text
/// (and reduced motion needs no special case). Hidden from screen readers.
class AssistantStreamingCaret extends StatelessWidget {
  const AssistantStreamingCaret({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: AppSpacing.s2),
        child: SizedBox(
          width: AppSize.s2,
          height: AppSize.s16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r1)),
            ),
          ),
        ),
      ),
    );
  }
}
