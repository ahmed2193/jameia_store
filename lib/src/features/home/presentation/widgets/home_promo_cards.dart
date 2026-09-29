import 'package:flutter/material.dart';

import '../../../../core/motion/entrance_cascade_item.dart';
import '../../domain/entities/home_link.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_layout.dart';
import 'home_promo_card_tile.dart';
import 'home_section_block.dart';

/// "Shop by occasion": a lazily built row of storefront tiles, each a link.
class HomePromoCards extends StatelessWidget {
  const HomePromoCards({
    super.key,
    required this.section,
    required this.onOpenLink,
  });

  final HomePromoCardsSection section;

  /// Receives the link and the card title (the title of the page it opens).
  final void Function(HomeLink link, String title) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final cards = section.cards;
    return HomeSectionBlock(
      section: section,
      child: SizedBox(
        // The square tile plus the title lines under it, which grow with the
        // reader's text scale.
        height: HomePromoCardTile.cellHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: HomeLayout.gutter,
          ),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: HomeLayout.itemGap),
          itemBuilder: (context, index) => EntranceCascadeItem(
            key: ValueKey(cards[index].id),
            index: index,
            child: HomePromoCardTile(
              card: cards[index],
              index: index,
              onTap: () => onOpenLink(cards[index].link, cards[index].title),
            ),
          ),
        ),
      ),
    );
  }
}
