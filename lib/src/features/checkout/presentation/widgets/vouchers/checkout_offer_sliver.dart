import 'package:flutter/widgets.dart';

import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../domain/entities/checkout_offer_card.dart';
import 'checkout_offer_ticket.dart';

/// A lazy list of offer tickets. Each is keyed by its offer, so a list that
/// changes keeps every ticket's state (its countdown, its progress bar)
/// with its offer. [firstIndex] is the first ticket's place in the page's
/// entrance cascade: only the first screenful rises in, once.
class CheckoutOfferSliver extends StatelessWidget {
  const CheckoutOfferSliver({
    super.key,
    required this.cards,
    required this.firstIndex,
  });

  final List<CheckoutOfferCard> cards;
  final int firstIndex;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: cards.length,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        final index = cards.indexWhere((card) => card.offerId == key.value);
        return index < 0 ? null : index;
      },
      itemBuilder: (_, index) {
        final card = cards[index];
        return EntranceCascadeItem(
          key: ValueKey<String>(card.offerId),
          index: firstIndex + index,
          child: CheckoutOfferTicket(card: card),
        );
      },
    );
  }
}
