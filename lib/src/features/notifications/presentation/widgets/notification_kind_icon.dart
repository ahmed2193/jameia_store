import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/notification_entity.dart';

/// Leading glyph of a notification row: the kind's icon in a tinted circle.
/// Jameia glyphs where the icon font has one; Material otherwise.
class NotificationKindIcon extends StatelessWidget {
  const NotificationKindIcon({super.key, required this.kind});

  final NotificationKind kind;

  static IconData iconFor(NotificationKind kind) => switch (kind) {
    NotificationKind.order => JameiaIcons.orders,
    // Material for both: the font's reward glyph is the word 賞 and its pay
    // glyph is a ¥ sign, and this app bills in Kuwaiti dinars.
    NotificationKind.points => Icons.loyalty_outlined,
    NotificationKind.wallet => Icons.account_balance_wallet_outlined,
    NotificationKind.coupon => Icons.confirmation_number_outlined,
    NotificationKind.offer => JameiaIcons.flame,
    NotificationKind.review => JameiaIcons.star,
    NotificationKind.subscription => Icons.autorenew_rounded,
    NotificationKind.account => Icons.person_outline_rounded,
    NotificationKind.campaign => Icons.campaign_outlined,
    NotificationKind.support => JameiaIcons.customerService,
    NotificationKind.other => JameiaIcons.notice,
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
      child: Icon(iconFor(kind), size: AppSize.s20, color: inkFor(kind)),
    );
  }
}
