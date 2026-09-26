import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import 'assistant_streaming_caret.dart';

/// One paragraph, heading or list item of a reply, in its own reading
/// direction (an English product line inside an Arabic reply stays LTR).
/// One `Text.rich` per block: a streamed word re-lays out only the block it
/// lands in.
class AssistantRichBlockView extends StatelessWidget {
  const AssistantRichBlockView({
    super.key,
    required this.block,
    required this.isRtl,
    this.caret = false,
    this.color = AppColors.primaryText,
  });

  final AssistantRichBlock block;

  /// The direction to use (the block's own, else the reply's, else the
  /// app's) — resolved by the caller.
  final bool isRtl;
  final bool caret;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final heading = block.kind == AssistantRichBlockKind.heading;
    final base =
        (heading ? AppTextStyles.headingSmall : AppTextStyles.bodyLarge)
            .copyWith(
              color: color,
              height: AppSize.lh1_5,
              leadingDistribution: TextLeadingDistribution.even,
            );
    final text = Text.rich(
      TextSpan(
        children: [
          for (final run in block.runs)
            TextSpan(
              text: run.text,
              style: run.bold
                  ? const TextStyle(fontWeight: AppTextStyles.bold)
                  : null,
            ),
          if (caret)
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AssistantStreamingCaret(),
            ),
        ],
      ),
      style: base,
    );
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: block.isListItem
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: AppSize.s16),
                  child: Text(block.displayMarker, style: base),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(child: text),
              ],
            )
          : text,
    );
  }
}
