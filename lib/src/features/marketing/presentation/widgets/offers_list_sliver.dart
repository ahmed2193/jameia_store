import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/motion/entrance_cascade.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import 'offer_tile.dart';

/// The offers as a lazily built sliver in 16dp gutters. The cards on screen
/// when the list first arrives cascade in once ([EntranceCascade]). A card
/// built later, whether scrolled into view, scrolled back to after the list
/// dropped it, or added by a refresh, is simply there: nothing replays and
/// nothing waits blank. A refresh moves the cards that stay instead of
/// rebuilding them.
class OffersListSliver extends StatelessWidget {
  const OffersListSliver({super.key, required this.offers});

  final List<OfferEntity> offers;

  static const EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.s16,
    AppSpacing.s8,
    AppSpacing.s16,
    AppSpacing.s24,
  );
  static const double gap = AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    return EntranceCascade(
      child: SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: offers.length,
          findItemIndexCallback: (key) {
            final index = offers.indexWhere(
              (offer) => ValueKey<String>(offer.id) == key,
            );
            return index < 0 ? null : index;
          },
          itemBuilder: (context, index) {
            final offer = offers[index];
            return EntranceCascadeItem(
              key: ValueKey<String>(offer.id),
              index: index,
              child: OfferTile(offer: offer),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: gap),
        ),
      ),
    );
  }
}
