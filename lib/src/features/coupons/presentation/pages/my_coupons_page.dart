import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../domain/entities/coupon.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../cubit/coupons_cubit.dart';
import '../widgets/coupon_ticket_card.dart';

/// Jameia **My coupons** page (`mach_pro_sailor_c_market_my_coupon_list`).
///
/// AppBar "My coupons" + a 3-tab bar (Available / Used / Expired) over a
/// [DefaultTabController]. Each tab is a lazy list of [CouponTicketCard]s built
/// from `JameiaRepository.coupons` (bucketed by [CouponsCubit]); empty tabs show
/// a per-tab empty state. The cubit is page-scoped (constructed inline).
class MyCouponsPage extends StatelessWidget {
  const MyCouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsCubit>(),
      child: const _MyCouponsView(),
    );
  }
}

class _MyCouponsView extends StatelessWidget {
  const _MyCouponsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: BlocBuilder<CouponsCubit, CouponsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.mediumBackground,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryText,
              surfaceTintColor: AppColors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(JameiaIcons.back),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text(
                'coupons.my_coupons'.tr(),
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.push(Routes.historyCoupons),
                  child: Text(
                    'coupons.history'.tr(),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
              bottom: _CouponTabBar(
                availableCount: state.available.length,
                usedCount: state.used.length,
                expiredCount: state.expired.length,
              ),
            ),
            body: switch (state.status) {
              CouponsStatus.loaded => _Tabs(state: state),
              _ => const Skeletonized(loading: true, child: CouponsSkeleton()),
            },
          );
        },
      ),
    );
  }
}

class _CouponTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _CouponTabBar({
    required this.availableCount,
    required this.usedCount,
    required this.expiredCount,
  });

  final int availableCount;
  final int usedCount;
  final int expiredCount;

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      alignment: AlignmentDirectional.centerStart,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primaryText,
        unselectedLabelColor: AppColors.tertiaryText,
        labelStyle: AppTextStyles.headingSmall.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
        unselectedLabelStyle: AppTextStyles.headingSmall,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        labelPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        tabs: [
          _CountTab(label: 'coupons.available'.tr(), count: availableCount),
          _CountTab(label: 'coupons.used'.tr(), count: usedCount),
          _CountTab(label: 'coupons.expired'.tr(), count: expiredCount),
        ],
      ),
    );
  }
}

/// Tab label with the Jameia coupon-count corner badge (`count_corner_mark`):
/// the per-bucket coupon count rendered as a small red pill next to the label.
class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: AppSpacing.s4),
            Container(
              constraints: const BoxConstraints(minWidth: 16),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent1,
                borderRadius: BorderRadius.circular(AppRadius.r6),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.state});
  final CouponsState state;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _CouponList(
          coupons: state.available,
          status: CouponStatus.available,
          emptyMessage: 'coupons.none_available'.tr(),
        ),
        _CouponList(
          coupons: state.used,
          status: CouponStatus.used,
          emptyMessage: 'coupons.none_used'.tr(),
        ),
        _CouponList(
          coupons: state.expired,
          status: CouponStatus.expired,
          emptyMessage: 'coupons.none_expired'.tr(),
        ),
      ],
    );
  }
}

class _CouponList extends StatelessWidget {
  const _CouponList({
    required this.coupons,
    required this.status,
    required this.emptyMessage,
  });

  final List<CouponEntity> coupons;
  final CouponStatus status;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return EmptyStateView(
        message: emptyMessage,
        icon: Icons.confirmation_number_outlined,
      );
    }
    return ContentClamp(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s12),
        itemCount: coupons.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, i) => StaggerEntrance(
          index: i,
          child: CouponTicketCard(
            coupon: coupons[i],
            status: status,
            // "Use" returns to the root shell (the first route of the stack) so
            // the user can go shop with the coupon.
            onUse: status == CouponStatus.available
                ? () => context.go(Routes.shell)
                : null,
          ),
        ),
      ),
    );
  }
}
