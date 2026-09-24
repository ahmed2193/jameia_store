import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../../core/domain/entities/cart_offer_line_entity.dart';
import '../../../../../core/domain/entities/cart_offer_progress_entity.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_checkout_bar.dart';
import 'cart_coupon_row.dart';
import 'cart_express_toggle.dart';
import 'cart_items_header.dart';
import 'cart_line_tile.dart';
import 'cart_loyalty_row.dart';
import 'cart_offer_line_tile.dart';
import 'cart_offer_progress_banner.dart';
import 'cart_section_card.dart';
import 'cart_sync_banner.dart';
import 'cart_totals_summary.dart';

/// The loaded cart on grey, in rounded white cards: sync notice, offer
/// progress, the lines, the coupon / loyalty / express card, the totals card,
/// and the sticky checkout bar.
///
/// The lines are a lazy sliver, so a 60-line cart only builds what is on
/// screen, and each tile selects its own line by [CartLineRef]: a tap on one
/// stepper rebuilds that tile, not the list.
class CartBody extends StatelessWidget {
  const CartBody({super.key, this.showHeader = false});

  /// Adds the "n items · Clear cart" row (the Cart tab has no app bar).
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final (lines, offerLines, progress) = context
        .select<
          CartCubit,
          (
            List<CartLineEntity>,
            List<CartOfferLineEntity>,
            List<CartOfferProgressEntity>,
          )
        >(
          (cubit) => (
            cubit.state.cart.lines,
            cubit.state.cart.offerLines,
            cubit.state.cart.offerProgress,
          ),
        );
    final total = lines.length + offerLines.length;
    return ContentClamp(
      child: Column(
        children: [
          Expanded(
            child: BrandedRefresh(
              onRefresh: () => context.read<CartCubit>().refresh(),
              child: CustomScrollView(
                slivers: [
                  if (showHeader)
                    const SliverPadding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.s16,
                        AppSpacing.s8,
                        AppSpacing.s4,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: CartItemsHeader()),
                    ),
                  const SliverToBoxAdapter(child: CartSyncBanner()),
                  SliverList.builder(
                    itemCount: progress.length,
                    itemBuilder: (_, index) => CartOfferProgressBanner(
                      key: ValueKey<String>(progress[index].offerId),
                      progress: progress[index],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.s12,
                      AppSpacing.s12,
                      AppSpacing.s12,
                      0,
                    ),
                    sliver: DecoratedSliver(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppSize.r16),
                      ),
                      sliver: SliverList.separated(
                        itemCount: total,
                        separatorBuilder: (_, _) =>
                            const ThinDivider(indent: AppSpacing.s16),
                        itemBuilder: (_, index) => index < lines.length
                            ? CartLineTile(
                                key: ValueKey<CartLineRef>(lines[index].ref),
                                lineRef: lines[index].ref,
                              )
                            : CartOfferLineTile(
                                key: ValueKey<String>(
                                  offerLines[index - lines.length].key,
                                ),
                                line: offerLines[index - lines.length],
                              ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: CartSectionCard(
                      child: Column(
                        children: [
                          CartCouponRow(),
                          ThinDivider(indent: AppSpacing.s16),
                          CartLoyaltyRow(),
                          CartExpressToggle(),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: CartSectionCard(child: CartTotalsSummary()),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.s16),
                  ),
                ],
              ),
            ),
          ),
          const CartCheckoutBar(),
        ],
      ),
    );
  }
}
