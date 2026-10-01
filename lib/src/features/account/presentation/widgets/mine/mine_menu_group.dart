import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import 'mine_menu_entry.dart';
import 'mine_menu_section.dart';
import 'mine_pro_status_chip.dart';
import 'mine_tone.dart';

/// The Mine menu in three titled cards — shopping, wallet & rewards, help &
/// settings — each cascading in once after the cards above it
/// ([firstEntranceIndex]). Every destination of the tab is here: orders,
/// addresses, coupons, wallet, loyalty points, Hero Pro, invite friends,
/// notifications, the Hero Assistant (while the store runs it), customer
/// service, settings and about.
class MineMenuGroup extends StatelessWidget {
  const MineMenuGroup({
    super.key,
    this.customerUnreadCount = 0,
    this.notificationsUnread = 0,
    this.showAssistant = false,
    this.proMembership,
    this.proOffered = false,
    this.firstEntranceIndex = 0,
  });

  /// Unread customer-service messages → the badge on that cell.
  final int customerUnreadCount;

  /// Unread inbox notifications (app-global `UnreadNotificationsCubit`).
  final int notificationsUnread;

  /// The store runs the Hero Assistant → its cell shows.
  final bool showAssistant;

  /// Where the customer stands with Pro → the Pro row's chip (renews, ends,
  /// join, rejoin); `null` while not known yet (no chip).
  final ProMembershipEntity? proMembership;

  /// The store sells Pro to this customer: the join chips may show.
  final bool proOffered;

  /// Stagger slot of the first card (the cards above take the earlier ones).
  final int firstEntranceIndex;

  @override
  Widget build(BuildContext context) {
    final shopping = <MineMenuEntry>[
      MineMenuEntry(
        icon: HeroIcons.orders,
        label: 'account.menu_orders'.tr(),
        route: Routes.orders,
        tone: MineTone.brand,
      ),
      MineMenuEntry(
        icon: HeroIcons.pin,
        label: 'account.menu_addresses'.tr(),
        route: Routes.addressList,
        tone: MineTone.sky,
      ),
      MineMenuEntry(
        plate: HeroAssets.offerVoucher,
        label: 'account.coupons'.tr(),
        route: Routes.myCoupons,
        tone: MineTone.orange,
      ),
    ];
    final pro = proMembership;
    final rewards = <MineMenuEntry>[
      MineMenuEntry(
        plate: HeroAssets.checkoutWallet,
        label: 'account.wallet'.tr(),
        route: Routes.wallet,
        tone: MineTone.brand,
      ),
      MineMenuEntry(
        plate: HeroAssets.checkoutPoints,
        label: 'account.loyalty_points'.tr(),
        route: Routes.loyalty,
        tone: MineTone.amber,
      ),
      MineMenuEntry(
        plate: HeroAssets.proCrown,
        label: 'pro.title'.tr(),
        route: Routes.proMembership,
        tone: MineTone.pro,
        trailing: pro == null
            ? null
            : MineProStatusChip(membership: pro, offered: proOffered),
      ),
      MineMenuEntry(
        plate: HeroAssets.offerGift,
        label: 'account.invite_friends'.tr(),
        route: Routes.inviteFriends,
        tone: MineTone.rose,
      ),
    ];
    final help = <MineMenuEntry>[
      MineMenuEntry(
        icon: HeroIcons.bell,
        label: 'notifications.title'.tr(),
        route: Routes.notifications,
        badgeCount: notificationsUnread,
      ),
      if (showAssistant)
        MineMenuEntry(
          icon: HeroIcons.assistant,
          label: 'assistant.title'.tr(),
          route: Routes.assistant,
          tone: MineTone.pro,
        ),
      MineMenuEntry(
        icon: HeroIcons.support,
        label: 'account.customer_service'.tr(),
        route: Routes.customerService,
        badgeCount: customerUnreadCount,
      ),
      MineMenuEntry(
        icon: HeroIcons.settings,
        label: 'account.settings'.tr(),
        route: Routes.mineSettings,
      ),
      MineMenuEntry(
        icon: HeroIcons.warning,
        label: 'account.about'.tr(),
        route: Routes.mineAbout,
        // The slate plate: the yellow family's red would read as an alert.
        tone: MineTone.amber,
      ),
    ];
    return Column(
      children: [
        EntranceCascadeItem(
          index: firstEntranceIndex,
          child: MineMenuSection(
            title: 'account.section_shopping'.tr(),
            entries: shopping,
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        EntranceCascadeItem(
          index: firstEntranceIndex + 1,
          child: MineMenuSection(
            title: 'account.section_rewards'.tr(),
            entries: rewards,
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        EntranceCascadeItem(
          index: firstEntranceIndex + 2,
          child: MineMenuSection(
            title: 'account.section_help'.tr(),
            entries: help,
          ),
        ),
      ],
    );
  }
}
