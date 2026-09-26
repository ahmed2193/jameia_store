import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../cubit/cart_cubit.dart';
import '../deals/cart_deals_strip.dart';
import 'cart_checkout_bar.dart';
import 'cart_items_header.dart';
import 'cart_lines_sliver.dart';
import 'cart_options_section.dart';
import 'cart_summary_section.dart';
import 'cart_sync_banner.dart';

/// The loaded cart on the white page: the "n items · Clear cart" header, the
/// sync notice, the lines (hairlines between them), the offers & options
/// card, the payment summary card, and — pinned — the deals strip (the next
/// offer to unlock, "Add item") over the checkout bar.
///
/// The body selects nothing: every block selects its own slice, so no
/// snapshot rebuilds the page. The lines are a lazy sliver, so a 60-line
/// cart only builds what is on screen.
class CartBody extends StatelessWidget {
  const CartBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: Column(
        children: [
          Expanded(
            child: BrandedRefresh(
              onRefresh: () => context.read<CartCubit>().refresh(),
              child: const CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: CartItemsHeader()),
                  SliverToBoxAdapter(child: CartSyncBanner()),
                  SliverPadding(
                    padding: EdgeInsetsDirectional.only(top: AppSpacing.s8),
                    sliver: CartLinesSliver(),
                  ),
                  SliverToBoxAdapter(child: CartOptionsSection()),
                  SliverToBoxAdapter(child: CartSummarySection()),
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.section),
                  ),
                ],
              ),
            ),
          ),
          const CartDealsStrip(),
          const CartCheckoutBar(),
        ],
      ),
    );
  }
}
