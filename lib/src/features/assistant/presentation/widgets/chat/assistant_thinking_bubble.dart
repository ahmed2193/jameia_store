import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import 'assistant_step_line.dart';

/// The reply before its first word (docs/motion §9.6 §2.2): the loader dots
/// — real work, the only loop on the chat — and the step line under way
/// ([AssistantStepLine]). The avatar beside it belongs to the reply row, so
/// it keeps its place when the words take over.
class AssistantThinkingBubble extends StatelessWidget {
  const AssistantThinkingBubble({super.key, this.toolName});

  final String? toolName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(SuiRadius.bubble)),
        boxShadow: AppShadows.low,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: RepaintBoundary(
                child: BrandedDotLoader(
                  size: AppSize.s28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Flexible(child: AssistantStepLine(toolName: toolName)),
          ],
        ),
      ),
    );
  }
}
