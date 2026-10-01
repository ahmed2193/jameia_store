import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import '../../../../core/widgets/hero_svg_glyph.dart';
import '../../domain/entities/notification_entity.dart';

/// Leading glyph of a notification row: the kind's icon in a tinted circle.
/// Money, rewards, coupons, offers and Pro wear the drawn Hero plates
/// ([plateFor]); the rest are Hero font glyphs ([iconFor]).
class NotificationKindIcon extends StatelessWidget {
  const NotificationKindIcon({super.key, required this.kind});

  final NotificationKind kind;

  static const double _plate = AppSize.s24;

  /// A colour plate (colours baked in), drawn in the disc.
  static String? plateFor(NotificationKind kind) => switch (kind) {
    NotificationKind.points => HeroAssets.checkoutPoints,
    NotificationKind.wallet => HeroAssets.checkoutWallet,
    NotificationKind.coupon => HeroAssets.checkoutTicket,
    NotificationKind.offer => HeroAssets.offerPercent,
    NotificationKind.subscription => HeroAssets.proCrown,
    NotificationKind.campaign => HeroAssets.offerGift,
    _ => null,
  };

  /// The font glyph of the kinds without a plate, tinted [inkFor].
  static IconData iconFor(NotificationKind kind) => switch (kind) {
    NotificationKind.account => HeroIcons.account,
    NotificationKind.order => HeroIcons.orders,
    NotificationKind.review => HeroIcons.starFill,
    NotificationKind.support => HeroIcons.support,
    _ => HeroIcons.megaphone,
  };

  static Color inkFor(NotificationKind kind) => switch (kind) {
    NotificationKind.order => AppColors.primaryDark,
    NotificationKind.points => AppColors.accent3Dark,
    NotificationKind.wallet => AppColors.accent2Dark,
    NotificationKind.coupon => AppColors.accent1Dark,
    NotificationKind.offer => AppColors.accent4Foreground,
    NotificationKind.review => AppColors.accent3Dark,
    NotificationKind.subscription => AppColors.link,
    NotificationKind.account => AppColors.primaryText,
    NotificationKind.campaign => AppColors.accent1Dark,
    NotificationKind.support => AppColors.link,
    NotificationKind.other => AppColors.secondaryText,
  };

  static Color tintFor(NotificationKind kind) => switch (kind) {
    NotificationKind.order => AppColors.brandLightBg,
    NotificationKind.points => AppColors.accent3Light,
    NotificationKind.wallet => AppColors.accent2Light,
    NotificationKind.coupon => AppColors.accent1Light,
    NotificationKind.offer => AppColors.accent4Light,
    NotificationKind.review => AppColors.accent3Light,
    NotificationKind.subscription => AppColors.smallBackground,
    NotificationKind.account => AppColors.smallBackground,
    NotificationKind.campaign => AppColors.accent1Light,
    NotificationKind.support => AppColors.smallBackground,
    NotificationKind.other => AppColors.smallBackground,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.s40,
      height: AppSize.s40,
      decoration: BoxDecoration(color: tintFor(kind), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: switch (plateFor(kind)) {
        final String plate => HeroSvgGlyph.art(plate, size: _plate),
        null => HeroIcon(iconFor(kind), size: AppSize.s20, color: inkFor(kind)),
      },
    );
  }
}
