import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/cart_loyalty_entity.dart';
import '../../../../../core/widgets/jameia_list_card.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_coupon_row.dart';
import 'cart_express_toggle.dart';
import 'cart_loyalty_row.dart';
import 'cart_section.dart';

/// "Offers & options": the coupon, loyalty points and express delivery rows
/// on one hairline card. This is the only place that decides which rows
/// show — the rows draw themselves unconditionally — so the card only draws
/// hairlines between rows that are really there; the card eases to its new
/// height when a row grows (a coupon's discount line) or comes and goes.
class CartOptionsSection extends StatelessWidget {
  const CartOptionsSection({super.key});

  /// Points show for a customer who has some, or while some are applied.
  static bool _offersLoyalty(int available, CartLoyaltyEntity loyalty) =>
      available > 0 || loyalty.isApplied;

  @override
  Widget build(BuildContext context) {
    final available = context.select<AuthSessionCubit, int>(
      (session) => session.state.customer?.loyaltyPoints ?? 0,
    );
    final (loyalty, expressOffered) = context
        .select<CartCubit, (CartLoyaltyEntity, bool)>(
          (cubit) =>
              (cubit.state.cart.loyalty, cubit.state.cart.expressOffered),
        );
    return CartSection(
      title: 'cart.section_options'.tr(),
      card: JameiaListCard(
        children: [
          const CartCouponRow(),
          if (_offersLoyalty(available, loyalty)) const CartLoyaltyRow(),
          if (expressOffered) const CartExpressToggle(),
        ],
      ),
    );
  }
}
