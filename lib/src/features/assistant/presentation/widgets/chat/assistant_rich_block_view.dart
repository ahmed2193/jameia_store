import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import '../assistant_stream_pace.dart';
import '../assistant_word_pace.dart';
import 'assistant_stream_reveal.dart';
import 'assistant_stream_reveal_scope.dart';
import 'assistant_streaming_caret.dart';

/// One paragraph, heading or list item of a reply, in its own reading
/// direction (an English product line inside an Arabic reply stays LTR).
/// One `Text.rich` per block: a streamed word re-lays out only the block it
/// lands in.
///
/// Under a stream reveal ([AssistantStreamRevealScope]) a block with a word
/// still fading follows the reveal's clock and draws each whole word at its
/// own alpha — a colour change only, so each frame is a repaint, not a
/// layout; a block whose words are all in is plain text and listens to
/// nothing.
class AssistantRichBlockView extends StatelessWidget {
  const AssistantRichBlockView({
    super.key,
    required this.block,
    required this.isRtl,
    this.caret = false,
    this.color = AppColors.primaryText,
    this.firstWord = 0,
  });

  final AssistantRichBlock block;

  /// The direction to use (the block's own, else the reply's, else the
  /// app's) — resolved by the caller.
  final bool isRtl;
  final bool caret;
  final Color color;

  /// The reply-wide ordinal of this block's first word (stream reveal).
  final int firstWord;

  static const WidgetSpan _caret = WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: AssistantStreamingCaret(),
  );

  static const TextStyle _bold = TextStyle(fontWeight: AppTextStyles.bold);

  /// The block's runs as written (no reveal, or every word in).
  List<InlineSpan> _plain() => [
    for (final run in block.runs)
      TextSpan(text: run.text, style: run.bold ? _bold : null),
    if (caret) _caret,
  ];

  /// The block's words at their reveal alpha at [now].
  List<InlineSpan> _revealed(AssistantStreamPace pace, Duration now) {
    var word = firstWord;
    final spans = <InlineSpan>[];
    for (final run in block.runs) {
      final words = AssistantWordPace.split(run.text);
      // A run of spaces only: no word to reveal, but its space stays.
      if (words.isEmpty) {
        spans.add(TextSpan(text: run.text));
        continue;
      }
      for (final token in words) {
        final alpha = pace.alphaAt(word++, now);
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: color.withValues(alpha: color.a * alpha),
              fontWeight: run.bold ? AppTextStyles.bold : null,
            ),
          ),
        );
      }
    }
    if (caret) spans.add(_caret);
    return spans;
  }

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
    final reveal = AssistantStreamRevealScope.maybeOf(context);
    final lastWord = firstWord + AssistantStreamReveal.wordsInBlock(block) - 1;
    final Widget text;
    if (reveal == null ||
        reveal.pace.settledThrough(lastWord, reveal.clock.value)) {
      text = Text.rich(TextSpan(children: _plain()), style: base);
    } else {
      text = ValueListenableBuilder<Duration>(
        valueListenable: reveal.clock,
        builder: (context, now, _) => Text.rich(
          TextSpan(
            children: reveal.pace.settledThrough(lastWord, now)
                ? _plain()
                : _revealed(reveal.pace, now),
          ),
          style: base,
        ),
      );
    }
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
