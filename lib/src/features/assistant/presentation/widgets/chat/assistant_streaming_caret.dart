import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_stream_reveal_scope.dart';

/// The end of a reply that is still being written. Steady, not blinking:
/// the thinking dots are the loader, the caret only marks "still writing"
/// (docs/motion §9.6 §2.3). When the stream ends it fades out over
/// `fast` ([AssistantStreamRevealScope.caret]) instead of snapping away.
/// Const, so the text span around it compares equal on every rebuild (a
/// word's fade stays a paint change). Hidden from screen readers.
class AssistantStreamingCaret extends StatelessWidget {
  const AssistantStreamingCaret({super.key});

  @override
  Widget build(BuildContext context) {
    const bar = ExcludeSemantics(
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
    final fade = AssistantStreamRevealScope.maybeOf(context)?.caret;
    if (fade == null) return bar;
    return FadeTransition(opacity: fade, child: bar);
  }
}
