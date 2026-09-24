import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../domain/entities/home_link.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_promo_card_tile.dart';
import 'home_section_block.dart';

/// "Shop by occasion": a lazily built horizontal strip of coloured link cards.
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
        // The square artwork plus the caption lines under it, which grow
        // with the reader's text scale.
        height: HomePromoCardTile.cellHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin,
          ),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (context, index) => HomePromoCardTile(
            key: ValueKey(cards[index].id),
            card: cards[index],
            onTap: () => onOpenLink(cards[index].link, cards[index].title),
          ),
        ),
      ),
    );
  }
}
