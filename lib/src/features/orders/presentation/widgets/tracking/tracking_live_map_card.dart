import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../live_map/live_map_live_dot.dart';

/// "Follow your order live" on the order page while a delivery is on its
/// way: the Hero map tile with the rider on the road, a live dot, and
/// "Track on map", which opens the live rider map over the order page
/// (`Routes.orderLiveMap`, sliding up).
class TrackingLiveMapCard extends StatelessWidget {
  const TrackingLiveMapCard({super.key, required this.order});

  final OrderEntity order;

  /// The art is 120 × 88; shown this wide, its own height.
  static const double _artWidth = AppSize.s96;
  static const double _artHeight = _artWidth * 88 / 120;

  void _open(BuildContext context) =>
      context.push(Routes.orderLiveMap, extra: order);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // The glyph box is square: cover the art's own box with it
                // and clip the empty bands above and below.
                const ClipRect(
                  child: SizedBox(
                    width: _artWidth,
                    height: _artHeight,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: HeroSvgGlyph.art(
                        HeroAssets.trackingLiveMap,
                        size: _artWidth,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const LiveMapLiveDot(),
                          Text(
                            'orders.live_badge'.tr(),
                            style: AppTextStyles.tag.copyWith(
                              color: AppColors.brandDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        'orders.live_card_title'.tr(),
                        style: AppTextStyles.headingMedium,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        'orders.live_card_subtitle'.tr(),
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              label: 'orders.live_card_button'.tr(),
              onPressed: () => _open(context),
            ),
          ],
        ),
      ),
    );
  }
}
