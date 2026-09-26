import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import 'assistant_rich_block_view.dart';

/// A reply's text, block by block (parsed in the domain, never here). While
/// [caret] is on, the last block ends with the streaming caret.
class AssistantRichTextView extends StatelessWidget {
  const AssistantRichTextView({
    super.key,
    required this.richText,
    this.caret = false,
    this.color = AppColors.primaryText,
  });

  final AssistantRichText richText;
  final bool caret;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final blocks = richText.blocks;
    final replyRtl =
        richText.isRtl ?? Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, block) in blocks.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: index == 0
                  ? 0
                  : block.isListItem
                  ? AppSpacing.s4
                  : AppSpacing.s8,
            ),
            child: AssistantRichBlockView(
              block: block,
              isRtl: block.isRtl ?? replyRtl,
              caret: caret && index == blocks.length - 1,
              color: color,
            ),
          ),
      ],
    );
  }
}
