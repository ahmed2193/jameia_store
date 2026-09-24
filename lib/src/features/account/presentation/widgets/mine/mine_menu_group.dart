import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_menu_cell.dart';

/// The Mine menu card: white, radius 12dp, 12dp side margin; 1dp dividers
/// (bundle `d90a8d`, 12dp start inset) between the cells. Every cell cascades
/// in on its own.
class MineMenuGroup extends StatelessWidget {
  const MineMenuGroup({
    super.key,
    this.customerUnreadCount = 0,
    this.notificationsUnread = 0,
  });

  /// Unread customer-service messages → the badge on that cell.
  final int customerUnreadCount;

  /// Unread inbox notifications (app-global `UnreadNotificationsCubit`).
  final int notificationsUnread;

  @override
  Widget build(BuildContext context) {
    final cells = <_MineMenuItem>[
      _MineMenuItem(
        JameiaIcons.orders,
        'account.menu_orders'.tr(),
        Routes.orders,
      ),
      _MineMenuItem(
        JameiaIcons.locationOutline,
        'account.menu_addresses'.tr(),
        Routes.addressList,
      ),
      _MineMenuItem(
        Icons.account_balance_wallet_outlined,
        'account.wallet'.tr(),
        Routes.wallet,
      ),
      _MineMenuItem(
        Icons.stars_outlined,
        'account.loyalty_points'.tr(),
        Routes.loyalty,
      ),
      _MineMenuItem(
        Icons.workspace_premium_outlined,
        'pro.title'.tr(),
        Routes.proMembership,
      ),
      // No Jameia coupon glyph in wm_c_iconfont — keep Material.
      _MineMenuItem(
        Icons.confirmation_num_outlined,
        'account.coupons'.tr(),
        Routes.myCoupons,
      ),
      // Referral gift — wm_c_iconfont has no reward glyph, only the word 賞.
      _MineMenuItem(
        Icons.card_giftcard,
        'account.invite_friends'.tr(),
        Routes.inviteFriends,
      ),
      _MineMenuItem(
        Icons.notifications_none_rounded,
        'notifications.title'.tr(),
        Routes.notifications,
        badgeCount: notificationsUnread,
      ),
      _MineMenuItem(
        JameiaIcons.customerService,
        'account.customer_service'.tr(),
        Routes.customerService,
        badgeCount: customerUnreadCount,
      ),
      // Material: wm_c_iconfont's nearest glyph is a funnel, which reads as
      // "filter" — it is the one the Discover channel filter uses.
      _MineMenuItem(
        Icons.settings_outlined,
        'account.settings'.tr(),
        Routes.mineSettings,
      ),
      _MineMenuItem(JameiaIcons.info, 'account.about'.tr(), Routes.mineAbout),
    ];

    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i != 0)
              Container(
                height: AppSize.s1,
                margin: const EdgeInsetsDirectional.only(start: AppSpacing.s12),
                color: AppColors.overlayDivider,
              ),
            RepaintBoundary(
              child: StaggerEntrance(
                index: i,
                child: MineMenuCell(
                  icon: cells[i].icon,
                  label: cells[i].label,
                  badgeCount: cells[i].badgeCount,
                  onTap: () => context.push(cells[i].route),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What one menu cell shows and where it goes.
class _MineMenuItem {
  const _MineMenuItem(this.icon, this.label, this.route, {this.badgeCount = 0});

  final IconData icon;
  final String label;
  final String route;
  final int badgeCount;
}
