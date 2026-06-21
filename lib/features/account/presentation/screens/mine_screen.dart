import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';

/// KeeTa "Mine" (account) tab — `mach_pro_sailor_c_mine`.
///
/// Faithful 1:1 clone of KeeTa's account surface: brand-yellow profile header
/// (avatar / name / phone + edit chevron), a quick-stats row
/// (coupons / wallet / favourites), and the stacked menu cells (My orders,
/// Addresses, Coupons, Invite friends, Customer service, Settings, About) plus
/// the inline delivery-code cell. Data is read synchronously from the in-memory
/// [KeetaRepository] (same static-data pattern as `shop_screen.dart`).
class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = sl<KeetaRepository>();
    final user = repo.user;
    final couponCount = repo.coupons.where((c) => !c.used).length;
    final favouriteCount = repo.shops.length;

    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader(user: user)),
          SliverToBoxAdapter(
            child: ContentClamp(
              child: Column(
                children: [
                  _QuickStatsRow(
                    coupons: couponCount,
                    favourites: favouriteCount,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  const _MenuGroup(),
                  const SizedBox(height: AppSpacing.s8),
                  _DeliveryCodeCell(code: user.deliveryCode),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsetsDirectional.only(
        top: topInset + AppSpacing.s24,
        start: AppSpacing.s16,
        end: AppSpacing.s16,
        bottom: AppSpacing.s24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.mediumBackground],
        ),
      ),
      child: ContentClamp(
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppRadius.r3),
          child: Row(
            children: [
              _Avatar(url: user.avatar),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name.isEmpty ? 'KeeTa user' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displaySmall
                          .copyWith(fontWeight: AppTextStyles.bold),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      user.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const Icon(KeetaIcons.edit,
                  size: 18, color: AppColors.primaryText),
              const SizedBox(width: AppSpacing.s4),
              const Icon(KeetaIcons.arrowRight,
                  size: 16, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: url.isEmpty
          ? const CircleAvatar(
              backgroundColor: AppColors.white,
              child: Icon(KeetaIcons.merchant,
                  size: 26, color: AppColors.tertiaryText),
            )
          : KeetaImage.circle(url: url, size: _size),
    );
  }
}

// ── Quick stats ───────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.coupons, required this.favourites});
  final int coupons;
  final int favourites;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '$coupons',
              label: 'Coupons',
              onTap: () => Navigator.pushNamed(context, Routes.myCoupons),
            ),
          ),
          const _StatDivider(),
          const Expanded(
            child: _StatCell(value: '\$0.00', label: 'Wallet'),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatCell(
              value: '$favourites',
              label: 'Favourites',
              onTap: () =>
                  Navigator.pushNamed(context, Routes.shopFavorites),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppTextStyles.displaySmall
                  .copyWith(fontWeight: AppTextStyles.bold)),
          const SizedBox(height: AppSpacing.s2),
          Text(label,
              style: AppTextStyles.captionLarge
                  .copyWith(color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: AppColors.divider,
      );
}

// ── Menu cells ──────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  const _MenuGroup();

  @override
  Widget build(BuildContext context) {
    final cells = <_MenuSpec>[
      _MenuSpec(KeetaIcons.orders, 'My orders', Routes.orders),
      _MenuSpec(KeetaIcons.address, 'Addresses', Routes.addressList),
      _MenuSpec(KeetaIcons.pay, 'Coupons', Routes.myCoupons),
      _MenuSpec(KeetaIcons.reward, 'Invite friends', Routes.inviteFriends),
      _MenuSpec(KeetaIcons.customerService, 'Customer service',
          Routes.customerService),
      _MenuSpec(KeetaIcons.filter, 'Settings', Routes.mineSettings),
      _MenuSpec(KeetaIcons.info, 'About', Routes.mineAbout),
    ];

    return Container(
      margin:
          const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i != 0) const ThinDivider(indent: AppSpacing.s48),
            _MenuCell(
              icon: cells[i].icon,
              label: cells[i].label,
              onTap: () => Navigator.pushNamed(context, cells[i].route),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuSpec {
  const _MenuSpec(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryText),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.headingMedium),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppSpacing.s8),
            ],
            const Icon(KeetaIcons.arrowRight,
                size: 16, color: AppColors.disabledText),
          ],
        ),
      ),
    );
  }
}

// ── Delivery code (inline editor entry) ─────────────────────────────────────

class _DeliveryCodeCell extends StatelessWidget {
  const _DeliveryCodeCell({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: _MenuCell(
        icon: KeetaIcons.confirmReceipt,
        label: 'Delivery code',
        onTap: () =>
            Navigator.pushNamed(context, Routes.mineDeliveryCode),
        trailing: Container(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.brandLightBg,
            borderRadius: BorderRadius.circular(AppRadius.r6),
          ),
          child: Text(
            code.isEmpty ? '— — — —' : code,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
