import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_block.dart';
import '../chat/assistant_entrance.dart';
import 'assistant_block_view.dart';

/// The cards of a reply in server order. A card that arrives while the reply
/// streams enters (fade + rise + scale); stored cards — and the same cards
/// after the `message_end` swap — sit still.
///
/// While a reply streams its row rebuilds on every text flush (up to 20 a
/// second) but its cards list keeps its identity, so the card widgets are
/// built once per list and handed back unchanged: the framework then skips
/// the whole card subtree (product rails included).
class AssistantCardList extends StatefulWidget {
  const AssistantCardList({super.key, required this.cards, this.live = false});

  final List<AssistantBlock> cards;
  final bool live;

  @override
  State<AssistantCardList> createState() => _AssistantCardListState();
}

class _AssistantCardListState extends State<AssistantCardList> {
  static const double _enterScale = 0.98;

  List<AssistantBlock>? _builtFor;
  bool? _builtLive;
  List<Widget> _children = const <Widget>[];

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (!identical(cards, _builtFor) || widget.live != _builtLive) {
      _builtFor = cards;
      _builtLive = widget.live;
      final live = widget.live;
      _children = [
        for (final (index, card) in cards.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: index == 0 ? 0 : AppSpacing.s8,
            ),
            child: RepaintBoundary(
              child: AssistantEntrance(
                animate: live,
                beginScale: _enterScale,
                child: AssistantBlockView(block: card, live: live),
              ),
            ),
          ),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _children,
    );
  }
}
