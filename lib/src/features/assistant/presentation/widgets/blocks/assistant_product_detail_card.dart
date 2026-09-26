import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/catalog_unavailable_overlay.dart';
import '../../../../../core/widgets/jameia_image.dart';
import '../../../../../core/widgets/price_text.dart';
import '../../../../../core/widgets/rating_badge.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'assistant_card_frame.dart';
import 'assistant_cart_taps.dart';
import 'assistant_product_detail_action.dart';

/// `product_detail`: one product as a wide card — picture, name, rating,
/// price (or "Out of stock") and its cart control. The card opens the
/// product page.
class AssistantProductDetailCard extends StatelessWidget {
  const AssistantProductDetailCard({super.key, required this.product});

  final CatalogProductEntity product;

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    final caption = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => AssistantCartTaps.open(context, product),
        child: AssistantCardFrame(
          transparent: true,
          child: Row(
            children: [
              SizedBox.square(
                dimension: AppSize.s80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    JameiaImage(
                      url: product.image,
                      width: AppSize.s80,
                      height: AppSize.s80,
                      radius: AppRadius.card,
                    ),
                    if (!product.inStock) const CatalogUnavailableOverlay(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall,
                    ),
                    if (product.hasRating) ...[
                      const SizedBox(height: AppSpacing.s4),
                      RatingBadge(
                        rating: product.ratingAverage,
                        count: product.ratingCount,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s6),
                    if (!product.inStock)
                      Text('catalog.out_of_stock'.tr(), style: caption)
                    else if (product.hasListPrice)
                      // Price + struck "was" price shrink together rather
                      // than overflow a narrow card at a large text size.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: PriceText(
                          price: product.priceKdFor(pro: isPro),
                          originalPrice: product.compareAtKd,
                        ),
                      )
                    else
                      Text('catalog.choose_options'.tr(), style: caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              AssistantProductDetailAction(product: product),
            ],
          ),
        ),
      ),
    );
  }
}
