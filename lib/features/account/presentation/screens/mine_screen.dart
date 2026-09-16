import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../cubit/account_cubit.dart';

/// KeeTa "Mine" (account) tab — `mach_pro_sailor_c_mine`.
///
/// Layout-faithful 1:1 clone derived from the real bundle.css.json atoms:
///
/// - Page bg: #F5F6FA (`mediumBackground`)
/// - Page-level card margin: 12dp both sides (bundle class `fd9b28`, `j65e56`)
/// - Card radius: 12dp (`AppRadius.card`)
/// - Quick-stats card: height 67dp, radius 16dp, bg #F5F6FA, 0.5dp divider #0000001e
/// - Menu cells: height 48dp, label KeeTa-Regular 14dp, padding 0dp 12dp
/// - Invite banner: #FFFEE0→#FFF gradient 208°, 1dp border, radius 12dp
/// - Delivery-code badge: pill (r500), bg #222222, white text 12dp Medium
/// - Section gaps: 12dp between quick-stats/invite/menu, 24dp at bottom
class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountCubit>(),
      child: const _MineView(),
    );
  }
}

class _MineView extends StatelessWidget {
  const _MineView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          final user = state.user;
          // Brief in-memory load — the overview resolves within a frame.
          if (user == null) return const SizedBox.shrink();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StaggerEntrance(
                  index: 0,
                  child: _ProfileHeader(user: user),
                ),
              ),
              SliverToBoxAdapter(
                child: ContentClamp(
                  child: Column(
                    children: [
                      // 12dp gap between header and quick-stats (b94ec7 height:12dp)
                      const SizedBox(height: AppSpacing.s12),
                      StaggerEntrance(
                        index: 1,
                        child: _QuickStatsRow(
                          coupons: state.couponCount,
                          favourites: state.favouriteCount,
                        ),
                      ),
                      // 12dp gap (b94ec7)
                      const SizedBox(height: AppSpacing.s12),
                      const StaggerEntrance(index: 2, child: _InviteBanner()),
                      // 12dp gap
                      const SizedBox(height: AppSpacing.s12),
                      // customerServiceUnread drives the i13302 badge on the
                      // "Customer service" cell. No live message-count source
                      // exists offline (API /csapi/chat/message/count), so the
                      // datasource supplies a fixed stub; 0 would hide the badge.
                      // The menu group's cells stagger individually inside
                      // [_MenuGroup], so the group itself is not re-wrapped here.
                      _MenuGroup(
                        customerUnreadCount: state.customerServiceUnread,
                      ),
                      // 12dp gap
                      const SizedBox(height: AppSpacing.s12),
                      StaggerEntrance(
                        index: 4,
                        child: _DeliveryCodeCell(code: user.deliveryCode),
                      ),
                      // 24dp bottom padding (aeff4d height:24dp)
                      const SizedBox(height: AppSpacing.s24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────
// Real: header_bg_global_5lx8l5.png full-width behind it (class g5fc1e absolute).
// Row: margin 0dp 20dp 20dp (h03722), avatar 50x50 (gfb120 margin-top 21.5dp),
// name gc2e59: KeeTa-Bold 16dp #222222, subtitle ab9636: KeeTa-Regular 14dp,
// scan icon c04204: 28x28dp, edit icon + arrow right (d8d65f / bd6209: 24dp each).

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserProfileEntity user;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        // Real background image: header_bg_global_5lx8l5.png
        Positioned.fill(
          child: Image.asset(
            KeetaAssets.mineHeaderBg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: topInset + 12,
            // h03722: margin 0dp 20dp 20dp — but content area uses 20dp sides
            start: AppSpacing.s20,
            end: AppSpacing.s20,
            bottom: AppSpacing.s20,
          ),
          child: ContentClamp(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar: 50x50 (gfb120: width 50dp height 50dp)
                  _Avatar(url: user.avatar),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // gc2e59: KeeTa-Bold 16dp #222222
                        Text(
                          user.name.isEmpty
                              ? 'account.default_user_name'.tr()
                              : user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingMedium.copyWith(
                            fontWeight: AppTextStyles.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        // ab9636: KeeTa-Regular 14dp (secondaryText)
                        Text(
                          user.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scan QR icon — c04204: 28x28dp margin 0dp 4dp
                  _ScanQrButton(
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.mineDeliveryCode),
                  ),
                  // d8d65f: edit icon 24x24dp
                  const SizedBox(width: AppSpacing.s6),
                  const Icon(
                    KeetaIcons.edit,
                    size: 24,
                    color: AppColors.primaryText,
                  ),
                  // bd6209: arrow 24x24dp margin-right 30dp (we skip the margin — no trailing item)
                  const SizedBox(width: AppSpacing.s4),
                  const Icon(
                    KeetaIcons.arrowRight,
                    size: 24,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;

  // gfb120: 50x50dp
  static const double _size = 50;

  @override
  Widget build(BuildContext context) {
    // One-shot pop on mount — the avatar grows-in when the tab opens.
    return PopScale.onMount(
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: url.isEmpty
            ? const CircleAvatar(
                backgroundColor: AppColors.white,
                child: Icon(
                  KeetaIcons.merchant,
                  size: 24,
                  color: AppColors.tertiaryText,
                ),
              )
            : KeetaImage.circle(url: url, size: _size),
      ),
    );
  }
}

// ── Scan-QR icon button ───────────────────────────────────────────────────────
// c04204: width 28dp height 28dp flex-shrink 0 margin 0dp 4dp

class _ScanQrButton extends StatelessWidget {
  const _ScanQrButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // PressScale owns the tap here (replacing the raw GestureDetector) so the
    // scan button gives the subtle press feel through the shared reference.
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s4,
        ),
        child: Image.asset(KeetaAssets.mineScanQrCode, width: 28, height: 28),
      ),
    );
  }
}

// ── Quick stats ────────────────────────────────────────────────────────────────
// j6507b: height 67dp, bg #F5F6FA, border-radius 16dp (r3), margin 0dp 9dp
// c5b706: absolute divider 0.5dp, height 35dp, #0000001e
// Stat label: j2b77d KeeTa-Bold 14dp #222222 margin-top 10dp; subtitle: f1b678 KeeTa-Regular 12dp #4D4D4D

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.coupons, required this.favourites});
  final int coupons;
  final int favourites;

  @override
  Widget build(BuildContext context) {
    return Container(
      // j65e56: padding-left 9dp padding-right 9dp
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      // White outer card, radius 12dp
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s16,
          horizontal: AppSpacing.s4,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatCell(
                  value: '$coupons',
                  label: 'account.coupons'.tr(),
                  onTap: () => Navigator.pushNamed(context, Routes.myCoupons),
                ),
              ),
              // c5b706: 0.5dp wide, 35dp tall, #0000001e
              const _StatDivider(),
              Expanded(
                child: _StatCell(
                  value: 'KD 0.000',
                  label: 'account.wallet'.tr(),
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _StatCell(
                  value: '$favourites',
                  label: 'account.favourites'.tr(),
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.shopFavorites),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.onTap});
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) so the InkWell keeps its ripple.
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          // j6507b inner padding — cells are centered, 67dp height container
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // j2b77d: KeeTa-Bold 14dp #222222
              Text(
                value,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              // f1b678: KeeTa-Regular 12dp #4D4D4D
              Text(
                label,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.labelGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      // c5b706: width 0.5dp, height 35dp (absolute in bundle, we use SizedBox height)
      width: 0.5,
      height: 35,
      color: AppColors.overlayDivider, // #0000001e
    );
  }
}

// ── Invite / growth banner ─────────────────────────────────────────────────────
// fd9b28: margin 12dp, row, border 1dp, gradient 208deg #FFFEE0→#FFF, radius 12dp
// dcada9: invite_animation_1l9g7yq.png (animated invite badge)
// j2b77d: title KeeTa-Bold 14dp #222222, margin-top 10dp, margin-left/right 12dp
// f1b678: subtitle KeeTa-Regular 12dp #4D4D4D, margin-top 2dp
// Arrow: mine_arrow_cell_global_1wcybsn.png 20x20 (b3fdaa)

class _InviteBanner extends StatelessWidget {
  const _InviteBanner();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => Navigator.pushNamed(context, Routes.inviteFriends),
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          // fd9b28: gradient 208deg #FFFEE0 0% → #FFFFFF 42%
          gradient: const LinearGradient(
            begin: Alignment(-0.53, -0.85), // ~208 deg
            end: Alignment(0.53, 0.85),
            stops: [0.0, 0.42],
            colors: [AppColors.inviteBannerBg, AppColors.white],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.overlayDivider, // 1dp border
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // dcada9 / invite animation image — 50x50 in bundle
              Image.asset(KeetaAssets.mineBannerBg, width: 50, height: 50),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // j2b77d: KeeTa-Bold 14dp #222222
                    Text(
                      'account.invite_title'.tr(),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    // f1b678: KeeTa-Regular 12dp #4D4D4D
                    Text(
                      'account.invite_subtitle'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              // b3fdaa: mine_arrow_cell_global 20x20
              Image.asset(KeetaAssets.mineArrowCell, width: 20, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu group ─────────────────────────────────────────────────────────────────
// White card, radius 12dp, margin 12dp.
// c4e0db: cell height 48dp.
// c64d9c: row padding 0dp 12dp.
// e65ce4: label KeeTa-Regular 14dp primaryText.
// d90a8d: divider height 1dp margin-left 12dp #00000014 (overlayDivider).
// Arrow: b9d7c3 mine_arrow_cell 18x18 margin-right 8dp.

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({this.customerUnreadCount = 0});

  /// Unread customer-service message count → drives the i13302 badge.
  final int customerUnreadCount;

  @override
  Widget build(BuildContext context) {
    final cells = <_MenuSpec>[
      _MenuSpec(KeetaIcons.orders, 'account.menu_orders'.tr(), Routes.orders),
      // location_on_outlined -> real KeeTa location glyph (wm_c_iconfont_location).
      _MenuSpec(
        KeetaIcons.locationOutline,
        'account.menu_addresses'.tr(),
        Routes.addressList,
      ),
      // confirmation_num (ticket/coupon): no KeeTa glyph in wm_c_iconfont — keep Material.
      _MenuSpec(
        Icons.confirmation_num_outlined,
        'account.coupons'.tr(),
        Routes.myCoupons,
      ),
      _MenuSpec(
        KeetaIcons.reward,
        'account.invite_friends'.tr(),
        Routes.inviteFriends,
      ),
      _MenuSpec(
        KeetaIcons.customerService,
        'account.customer_service'.tr(),
        Routes.customerService,
        badgeCount: customerUnreadCount,
      ),
      _MenuSpec(
        KeetaIcons.filter,
        'account.settings'.tr(),
        Routes.mineSettings,
      ),
      _MenuSpec(KeetaIcons.info, 'account.about'.tr(), Routes.mineAbout),
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
            // d90a8d: margin-left 12dp divider #00000014 — only between items
            if (i != 0)
              Container(
                height: 1,
                margin: const EdgeInsetsDirectional.only(start: AppSpacing.s12),
                color: AppColors.overlayDivider,
              ),
            // Each cell cascades in on its own (index = cell position).
            RepaintBoundary(
              child: StaggerEntrance(
                index: i,
                child: _MenuCell(
                  icon: cells[i].icon,
                  label: cells[i].label,
                  badgeCount: cells[i].badgeCount,
                  onTap: () => Navigator.pushNamed(context, cells[i].route),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuSpec {
  const _MenuSpec(this.icon, this.label, this.route, {this.badgeCount = 0});
  final IconData icon;
  final String label;
  final String route;
  final int badgeCount;
}

// ── Unread badge (customer service) ─────────────────────────────────────────────
// i13302: position absolute, height 20dp, min-width 20dp, border-radius 10dp,
// border 2dp solid #FFFFFF, font KeeTa-Bold 12dp, color #713901, bg #FFDE38,
// padding-left/right 7dp. Counts > 99 render as "99+".

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    // Grow-from-zero pop — the unread badge pops in and re-pops whenever the
    // count changes, sharing KeeTa's `scale_in` grammar through [PopScale].
    return PopScale(
      popKey: count,
      child: Container(
        height: 20,
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.unreadBadgeBg,
          borderRadius: BorderRadius.circular(AppSize.r10),
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: Text(
          text,
          style: AppTextStyles.captionLarge.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.skuOptionFg,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Unread-count badge rendered next to the label (i13302 style).
  /// 0 hides the badge.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
    // whole cell gives the subtle press feel.
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // c4e0db: height 48dp
        child: SizedBox(
          height: 48,
          // c64d9c: padding 0dp 12dp
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryText),
                const SizedBox(width: AppSpacing.s10),
                // e65ce4: KeeTa-Regular 14dp primaryText
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                // i13302: unread badge — yellow pill #FFDE38, brown text #713901,
                // 20dp tall, min-width 20dp, radius 10dp, 2dp white border.
                if (badgeCount > 0) ...[
                  _UnreadBadge(count: badgeCount),
                  const SizedBox(width: AppSpacing.s8),
                ],
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: AppSpacing.s8),
                ],
                // b9d7c3: mine_arrow_cell 18x18 margin-right 8dp
                Image.asset(KeetaAssets.mineArrowCell, width: 18, height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delivery code cell ─────────────────────────────────────────────────────────
// Separate white card, radius 12dp, margin 12dp.
// Trailing badge: d16a98 height 26dp, border-radius pill (500), bg #222222;
//   fe6d54: Keeta-Medium 12dp white padding 0dp 12dp.

class _DeliveryCodeCell extends StatelessWidget {
  const _DeliveryCodeCell({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: _MenuCell(
        icon: KeetaIcons.confirmReceipt,
        label: 'account.delivery_code'.tr(),
        onTap: () => Navigator.pushNamed(context, Routes.mineDeliveryCode),
        trailing: Container(
          // d16a98: height 26dp, border-radius pill, bg #222222 (primaryText)
          height: 26,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryText, // #222222
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            code.isEmpty ? '— — — —' : code,
            // fe6d54: Keeta-Medium 12dp white
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
