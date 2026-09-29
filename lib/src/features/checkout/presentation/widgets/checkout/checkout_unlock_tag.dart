import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/offer_entity.dart';
import '../../../../../core/motion/deferred_value.dart';
import '../../../../../core/motion/motion_beat.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_offer_hints.dart';
import '../../../domain/entities/checkout_unlock.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_offers_cubit.dart';
import 'checkout_red_tag.dart';

/// The red tag on the savings card: the nearest reward the basket can still
/// unlock by spending more ("Add KD 1.500 for free delivery", "… for 10% off
/// (up to KD 3.000)", "… for KD 1.000 off"), worded from the REWARD, never
/// from the offer's name. Only an honest one shows
/// ([CheckoutOfferHints.nearestUnlock]: a subtotal target of a known,
/// combinable offer running at the serving branch; no free delivery while
/// it is free already or picked up). A reward with no wording (other
/// types) shows no tag.
///
/// A new offer pops in from the end; the same offer with a new amount just
/// updates; nothing pops on the first build. A change lands a beat after
/// the control that caused it ([MotionBeat.second], backlog B2-03).
class CheckoutUnlockTag extends StatelessWidget {
  const CheckoutUnlockTag({super.key});

  static String? _label(CheckoutUnlock unlock) {
    final amount = Formatters.price(unlock.remainingKd);
    final cap = unlock.maxDiscountKd;
    return switch (unlock.rewardType) {
      OfferRewardType.freeDelivery =>
        'checkout.savings_unlock_free_delivery'.tr(
          namedArgs: {'amount': amount},
        ),
      OfferRewardType.percentageDiscount when cap != null =>
        'checkout.savings_unlock_percent_cap'.tr(
          namedArgs: {
            'amount': amount,
            'percent': '${unlock.percent}',
            'cap': Formatters.price(cap),
          },
        ),
      OfferRewardType.percentageDiscount =>
        'checkout.savings_unlock_percent'.tr(
          namedArgs: {'amount': amount, 'percent': '${unlock.percent}'},
        ),
      OfferRewardType.fixedDiscount => 'checkout.savings_unlock_amount'.tr(
        namedArgs: {'amount': amount, 'off': Formatters.price(unlock.amountKd)},
      ),
      OfferRewardType.freeProduct => 'checkout.savings_unlock_gift'.tr(
        namedArgs: {'amount': amount},
      ),
      OfferRewardType.other => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final offers = context.select<CheckoutOffersCubit, List<OfferEntity>>(
      (cubit) => cubit.state.offers,
    );
    final (branchId, pickup) = context.select<CheckoutCubit, (String?, bool)>(
      (cubit) => (cubit.state.selection?.branchId, cubit.state.draft.isPickup),
    );
    final unlock = context.select<CartCubit, CheckoutUnlock?>(
      (cubit) => CheckoutOfferHints.nearestUnlockOf(
        cart: cubit.state.cart,
        offers: offers,
        branchId: branchId,
        pickup: pickup,
      ),
    );
    final liveLabel = unlock == null ? null : _label(unlock);
    return DeferredValue<(String, String?)>(
      value: (liveLabel == null ? '' : unlock?.offerId ?? '', liveLabel),
      delay: MotionBeat.second,
      builder: (context, shown) {
        final (offerId, label) = shown;
        return PopSwitcher(
          stateKey: offerId,
          alignment: AlignmentDirectional.bottomEnd,
          child: label == null
              ? const SizedBox.shrink()
              : CheckoutRedTag(label: label),
        );
      },
    );
  }
}
