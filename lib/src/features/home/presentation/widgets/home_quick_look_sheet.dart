import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_secondary_button.dart';
import '../../../../core/widgets/catalog_discount_badge.dart';
import '../../../../core/widgets/hero_image.dart';
import '../../../../core/widgets/hero_sheet_handle.dart';
import '../../../../core/widgets/shelf_card_price.dart';
import '../../../../core/widgets/rating_badge.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'home_layout.dart';
import 'home_quick_look_cart_button.dart';

/// A quick look at a home product, opened by a long press on its card: the
/// picture popping up, the name, the price, the rating, the basket control
/// and a way on to the full product page — without leaving the feed.
class HomeQuickLookSheet extends StatelessWidget {
  const HomeQuickLookSheet({
    super.key,
    required this.product,
    required this.onOpen,
  });

  final CatalogProductEntity product;

  /// Opens the full product page (the sheet has closed by then).
  final VoidCallback onOpen;

  static const double _picture = AppSize.s96;

  static Future<void> show(
    BuildContext context, {
    required CatalogProductEntity product,
    required VoidCallback onOpen,
  }) => showHeroBottomSheet<void>(
    context,
    builder: (_) => HomeQuickLookSheet(product: product, onOpen: onOpen),
  );

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          HomeLayout.gutter,
          AppSpacing.s10,
          HomeLayout.gutter,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeroSheetHandle(),
            const SizedBox(height: AppSpacing.s16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PopScale.onMount(
                  child: Stack(
                    children: [
                      HeroImage(
                        url: product.image,
                        width: _picture,
                        height: _picture,
                        radius: AppRadius.card,
                      ),
                      if (product.hasDiscount)
                        PositionedDirectional(
                          top: AppSpacing.s4,
                          start: AppSpacing.s4,
                          child: CatalogDiscountBadge(
                            percent: product.discountPercent,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      if (product.hasListPrice) ...[
                        const SizedBox(height: AppSpacing.s8),
                        ShelfCardPrice(
                          priceKd: product.priceKdFor(pro: isPro),
                          wasKd: product.compareAtKd,
                        ),
                      ],
                      if (product.hasRating) ...[
                        const SizedBox(height: AppSpacing.s6),
                        RatingBadge(
                          rating: product.ratingAverage,
                          count: product.ratingCount,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                if (product.canQuickAdd) ...[
                  Expanded(child: HomeQuickLookCartButton(product: product)),
                  const SizedBox(width: AppSpacing.s10),
                ],
                Expanded(
                  child: HeroSecondaryButton(
                    label: 'home.view_details'.tr(),
                    expanded: true,
                    onPressed: () {
                      context.pop();
                      onOpen();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
