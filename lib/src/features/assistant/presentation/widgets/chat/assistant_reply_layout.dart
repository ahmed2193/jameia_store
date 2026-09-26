import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_block.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import '../blocks/assistant_card_list.dart';
import 'assistant_text_bubble.dart';
import 'assistant_thinking_bubble.dart';

/// The canonical reply order (L4): text on top, cards under it in arrival
/// order, then the footer (actions + chips, or the error row). The same
/// children in the same slots whether streaming or stored.
class AssistantReplyLayout extends StatelessWidget {
  const AssistantReplyLayout({
    super.key,
    required this.richText,
    required this.cards,
    this.typing = false,
    this.toolName,
    this.streaming = false,
    this.live = false,
    this.footer,
  });

  final AssistantRichText richText;
  final List<AssistantBlock> cards;

  /// No word yet: the thinking bubble stands in for the text.
  final bool typing;
  final String? toolName;
  final bool streaming;

  /// Still streaming: new cards enter, proposals cannot be confirmed yet.
  final bool live;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (typing)
          AssistantThinkingBubble(toolName: toolName)
        else if (!richText.isEmpty)
          AssistantTextBubble(richText: richText, streaming: streaming),
        // Keyed: the text slot comes and goes (thinking → words, a reply
        // with no prose) without the cards below losing their elements.
        if (cards.isNotEmpty)
          Padding(
            key: const ValueKey<String>('cards'),
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
            child: AssistantCardList(cards: cards, live: live),
          ),
        if (footer case final footer?)
          KeyedSubtree(key: const ValueKey<String>('footer'), child: footer),
      ],
    );
  }
}
