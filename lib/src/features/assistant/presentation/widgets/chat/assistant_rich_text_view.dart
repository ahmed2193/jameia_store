import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import 'assistant_rich_block_view.dart';
import 'assistant_stream_reveal.dart';
import 'assistant_stream_reveal_scope.dart';

/// A reply's text, block by block (parsed in the domain, never here). While
/// [caret] is on — or the caret of a stream that just ended is still fading
/// out ([AssistantStreamRevealScope]) — the last block ends with it. Under
/// a stream reveal each block knows where its words sit in the reply
/// ([AssistantRichBlockView.firstWord]).
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

  /// Where each block's words start in the reply (only under a reveal).
  static List<int> _firstWords(List<AssistantRichBlock> blocks) {
    final starts = <int>[];
    var next = 0;
    for (final block in blocks) {
      starts.add(next);
      next += AssistantStreamReveal.wordsInBlock(block);
    }
    return starts;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = richText.blocks;
    final replyRtl =
        richText.isRtl ?? Directionality.of(context) == TextDirection.rtl;
    final reveal = AssistantStreamRevealScope.maybeOf(context);
    final showsCaret = caret || (reveal?.caretShown ?? false);
    final firstWords = reveal == null ? null : _firstWords(blocks);
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
              caret: showsCaret && index == blocks.length - 1,
              color: color,
              firstWord: firstWords?[index] ?? 0,
            ),
          ),
      ],
    );
  }
}
