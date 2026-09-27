import 'package:flutter/widgets.dart';

import '../../../../../core/motion/pop_switcher.dart';
import '../../../domain/entities/checkout_offer_card.dart';
import 'checkout_applied_mark.dart';
import 'checkout_offer_progress.dart';

/// Where an offer stands: "✓ Applied" once the cart applied it, otherwise
/// its progress. Offers apply by themselves, so there is never an "Apply"
/// button and no "Best offer" (the API does not rank offers). A change of
/// state pops in; the first build is static.
class CheckoutOfferStatus extends StatelessWidget {
  const CheckoutOfferStatus({super.key, required this.card});

  final CheckoutOfferCard card;

  @override
  Widget build(BuildContext context) {
    return PopSwitcher(
      stateKey: card.isApplied,
      alignment: AlignmentDirectional.centerEnd,
      child: card.isApplied
          ? const CheckoutAppliedMark()
          : CheckoutOfferProgress(card: card),
    );
  }
}
