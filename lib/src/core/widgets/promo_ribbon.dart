import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'hex_color.dart';

/// Coupon-style promo ribbon used on the home golden feed card + shop meta.
///
/// `style`:
///  • `ribbon` — solid `#D90012` with a cut top-left corner (real atom `c1cd40`:
///    `border-top-left-radius: 24dp; background:#D90012; height:36dp`, scaled here)
///  • `coupon` — outlined voucher pill (border + tinted bg)
///  • `pill`   — plain filled rounded chip
class PromoRibbon extends StatelessWidget {
  const PromoRibbon({super.key, required this.tag, this.height = 18});

  final PromoTag tag;
  final double height;

  static const double _tightLineHeight = 1.0;

  @override
  Widget build(BuildContext context) {
    final bg = hexColor(tag.bg, AppColors.couponRibbon);
    final fg = hexColor(tag.fg, AppColors.white);
    final text = Text(
      tag.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppSize.font12,
        height: _tightLineHeight,
        fontWeight: AppTextStyles.bold,
        color: fg,
      ),
    );

    switch (tag.style) {
      case 'coupon':
        return Container(
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s5,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.r6),
            border: Border.all(color: bg, width: AppSize.s0_5),
          ),
          // coupon style renders text in the bg color
          child: Text(
            tag.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSize.font11,
              height: _tightLineHeight,
              fontWeight: AppTextStyles.medium,
              color: bg,
            ),
          ),
        );
      case 'pill':
        return Container(
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s6,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.r6),
          ),
          child: text,
        );
      case 'ribbon':
      default:
        // Cut top-left corner ribbon (24dp corner scaled to chip height).
        return Container(
          height: height,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s8,
            0,
            AppSpacing.s6,
            0,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(AppSize.r10),
              topEnd: Radius.circular(AppSize.r3),
              bottomEnd: Radius.circular(AppSize.r3),
              bottomStart: Radius.circular(AppSize.r3),
            ).resolve(Directionality.of(context)),
          ),
          child: text,
        );
    }
  }
}
