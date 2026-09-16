import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../responsive/app_size.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Parse a `#RRGGBB` / `#AARRGGBB` hex string into a [Color]. Returns [fallback]
/// on malformed input. Shared by promo chips, kingkong tiles, tiles area, etc.
Color hexColor(String hex, [Color fallback = AppColors.primary]) {
  var s = hex.trim().replaceFirst('#', '');
  if (s.isEmpty) return fallback;
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(v);
}

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
        height: 1.0,
        fontWeight: AppTextStyles.bold,
        color: fg,
      ),
    );

    switch (tag.style) {
      case 'coupon':
        return Container(
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.r6),
            border: Border.all(color: bg, width: 0.5),
          ),
          child: _recolor(tag, bg),
        );
      case 'pill':
        return Container(
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
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
          padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 6, 0),
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

  // coupon style renders text in the bg color
  Widget _recolor(PromoTag t, Color c) => Text(
        t.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: AppSize.font11, height: 1.0, fontWeight: AppTextStyles.medium, color: c),
      );
}

/// Feature label (e.g. "Buy 1 Get 1", "Low delivery fee") — outlined neutral
/// chip used in the golden card feature row.
class FeatureLabel extends StatelessWidget {
  const FeatureLabel({super.key, required this.text, this.height = 18});

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandLightBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: AppSize.font11,
          height: 1.0,
          color: AppColors.promotionTagFg,
        ),
      ),
    );
  }
}

/// 2dp bullet/dot separator (`#C2C2C2`, atom `c82c4a`).
class DotSep extends StatelessWidget {
  const DotSep({super.key, this.margin = 6});
  final double margin;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: margin),
        child: Container(
          width: 2,
          height: 2,
          decoration: const BoxDecoration(
            color: AppColors.dotSep,
            shape: BoxShape.circle,
          ),
        ),
      );
}

/// 1×15dp vertical bar separator (`#A5A5A5`, atom `je25a6`).
class VBarSep extends StatelessWidget {
  const VBarSep({super.key, this.height = 12, this.margin = 8});
  final double height;
  final double margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsetsDirectional.symmetric(horizontal: margin),
        width: 1,
        height: height,
        color: AppColors.vBarSep,
      );
}
