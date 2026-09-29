import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../domain/entities/assistant_block.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import '../blocks/assistant_card_list.dart';
import 'assistant_reply_text.dart';

/// The canonical reply order (L4): text on top, cards under it in arrival
/// order, then the footer (actions + chips, or the error row). The same
/// children in the same slots whether streaming or stored, so the row keeps
/// its elements through `message_end`, a failure and a retry. The footer
/// opens when it arrives (`message_end`, a failure: height `medium`, fade)
/// and closes over `fast` when it goes (a retry) — never on a row opened
/// from history ([CollapseReveal] only moves on a change).
class AssistantReplyLayout extends StatelessWidget {
  const AssistantReplyLayout({
    super.key,
    required this.richText,
    required this.cards,
    this.typing = false,
    this.toolName,
    this.streaming = false,
    this.live = false,
    this.animate = false,
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

  /// The reply starts in this session's flow: its text row enters once.
  final bool animate;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssistantReplyText(
          key: const ValueKey<String>('text'),
          richText: richText,
          typing: typing,
          toolName: toolName,
          streaming: streaming,
          animate: animate,
        ),
        // Keyed: the cards come and go without the slots around them
        // losing their elements.
        if (cards.isNotEmpty)
          Padding(
            key: const ValueKey<String>('cards'),
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
            child: AssistantCardList(cards: cards, live: live),
          ),
        CollapseReveal(
          key: const ValueKey<String>('footer'),
          visible: footer != null,
          child: footer ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}
