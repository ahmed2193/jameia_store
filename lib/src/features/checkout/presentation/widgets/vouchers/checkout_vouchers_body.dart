import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/offer_entity.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/motion/second_clock_scope.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_offers_view.dart';
import '../../cubit/checkout_offers_cubit.dart';
import '../../cubit/checkout_offers_state.dart';
import 'checkout_applied_coupon_card.dart';
import 'checkout_code_row.dart';
import 'checkout_offer_sliver.dart';
import 'checkout_vouchers_footer.dart';
import 'checkout_vouchers_header.dart';

/// The "Coupons & offers" page body: the code row, the coupon on the cart,
/// the offers the cart already applied, the ones the basket is working
/// towards (most progressed first), and the footer — one lazy scroll view
/// on the 9 dp page margin. The offers come from the cart, enriched by the
/// store's offer list ([CheckoutOffersView]); offers limited to branches
/// other than [branchId] are left out.
///
/// It waits for the offer list (a cached read) so the cards arrive with
/// their terms; then the first screenful rises in once.
class CheckoutVouchersBody extends StatelessWidget {
  const CheckoutVouchersBody({super.key, this.branchId});

  /// The serving branch (the route's extra).
  final String? branchId;

  /// Cascade slots: the code row, the coupon card, then the tickets.
  static const int _couponIndex = 1;
  static const int _firstTicketIndex = 2;
  static const int _cascadeItems = 4;

  @override
  Widget build(BuildContext context) {
    final ready = context.select<CheckoutOffersCubit, bool>(
      (cubit) => cubit.state.status == CheckoutOffersStatus.ready,
    );
    final offers = context.select<CheckoutOffersCubit, List<OfferEntity>>(
      (cubit) => cubit.state.offers,
    );
    final now = SecondClockScope.maybeOf(context)?.now ?? DateTime.now();
    final view = context.select<CartCubit, CheckoutOffersView>(
      (cubit) => CheckoutOffersView.of(
        offers: offers,
        cart: cubit.state.cart,
        now: now,
        branchId: branchId,
      ),
    );
    if (!ready) return const AppLoader();
    final applied = view.applied;
    final locked = view.locked;
    return EntranceCascade(
      maxItems: _cascadeItems,
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.pageMargin,
                AppSpacing.s12,
                AppSpacing.pageMargin,
                0,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(
                    child: EntranceCascadeItem(
                      index: 0,
                      child: CheckoutCodeRow(),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: EntranceCascadeItem(
                      index: _couponIndex,
                      child: CheckoutAppliedCouponCard(),
                    ),
                  ),
                  if (applied.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: CheckoutVouchersHeader(
                        title: 'checkout.offers_applied_title'.tr(),
                      ),
                    ),
                    CheckoutOfferSliver(
                      cards: applied,
                      firstIndex: _firstTicketIndex,
                    ),
                  ],
                  if (locked.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: CheckoutVouchersHeader(
                        title: 'checkout.offers_locked_title'.tr(),
                      ),
                    ),
                    CheckoutOfferSliver(
                      cards: locked,
                      firstIndex: _firstTicketIndex + applied.length,
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: CheckoutVouchersFooter(hasOffers: !view.isEmpty),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
