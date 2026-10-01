import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_line_thumb.dart';
import '../../../../../core/widgets/sticker_text.dart';
import '../../../domain/entities/checkout_thumb.dart';

/// A picture of the order-summary strip: the line's 56 dp thumb (the cart
/// row's size, one decode for both), its count ("2x", bottom-start, left to
/// right in Arabic too; it bumps when it changes), and a corner disc at the
/// top end — amber "!" for a line the server flagged, a gift for a free
/// product an offer added. Both discs are static.
class CheckoutThumbTile extends StatelessWidget {
  const CheckoutThumbTile({super.key, required this.thumb});

  final CheckoutThumb thumb;

  static const double _inset = AppSpacing.s4;
  static const double _disc = AppSize.s16;
  static const double _glyph = AppSize.s12;

  @override
  Widget build(BuildContext context) {
    final flagged = thumb.hasIssue;
    return Stack(
      children: [
        HeroLineThumb(url: thumb.imageUrl),
        PositionedDirectional(
          start: _inset,
          bottom: AppSpacing.s2,
          child: ChangeBump(
            value: thumb.quantity,
            alignment: AlignmentDirectional.bottomStart,
            child: Directionality(
              textDirection: TextDirection.ltr,
              // A white rim keeps the count readable on any picture.
              child: StickerText(
                'checkout.qty_times'.tr(
                  namedArgs: {'count': '${thumb.quantity}'},
                ),
                outline: AppColors.white,
                rim: AppSize.s2,
                style: AppTextStyles.tag.copyWith(color: AppColors.primaryText),
              ),
            ),
          ),
        ),
        if (flagged || thumb.isGift)
          PositionedDirectional(
            top: _inset,
            end: _inset,
            child: SizedBox.square(
              dimension: _disc,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: flagged ? AppColors.warn : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: HeroIcon(
                  flagged ? HeroIcons.exclamation : HeroIcons.gift,
                  size: _glyph,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
