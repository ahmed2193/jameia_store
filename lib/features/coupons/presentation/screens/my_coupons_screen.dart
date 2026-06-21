import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/coupons_cubit.dart';
import '../widgets/coupon_ticket_card.dart';

/// KeeTa **My coupons** page (`mach_pro_sailor_c_market_my_coupon_list`).
///
/// AppBar "My coupons" + a 3-tab bar (Available / Used / Expired) over a
/// [DefaultTabController]. Each tab is a lazy list of [CouponTicketCard]s built
/// from `KeetaRepository.coupons` (bucketed by [CouponsCubit]); empty tabs show
/// a per-tab empty state. The cubit is page-scoped (constructed inline).
class MyCouponsScreen extends StatelessWidget {
  const MyCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CouponsCubit(sl<KeetaRepository>())..load(),
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
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryText,
          surfaceTintColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text('My coupons',
              style: AppTextStyles.headingLarge
                  .copyWith(fontWeight: AppTextStyles.bold)),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.historyCoupons),
              child: Text('History',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: AppColors.secondaryText)),
            ),
          ],
          bottom: const _CouponTabBar(),
        ),
        body: BlocBuilder<CouponsCubit, CouponsState>(
          builder: (context, state) {
            return switch (state) {
              CouponsLoading() => const AppLoader(),
              CouponsLoaded() => _Tabs(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _CouponTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _CouponTabBar();

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
        labelStyle:
            AppTextStyles.headingSmall.copyWith(fontWeight: AppTextStyles.bold),
        unselectedLabelStyle: AppTextStyles.headingSmall,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        labelPadding:
            const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s16),
        tabs: const [
          Tab(text: 'Available'),
          Tab(text: 'Used'),
          Tab(text: 'Expired'),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.state});
  final CouponsLoaded state;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _CouponList(
          coupons: state.available,
          status: CouponStatus.available,
          emptyMessage: 'No coupons available yet',
        ),
        _CouponList(
          coupons: state.used,
          status: CouponStatus.used,
          emptyMessage: 'No used coupons',
        ),
        _CouponList(
          coupons: state.expired,
          status: CouponStatus.expired,
          emptyMessage: 'No expired coupons',
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

  final List<Coupon> coupons;
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
        itemBuilder: (_, i) => CouponTicketCard(
          coupon: coupons[i],
          status: status,
          onUse: status == CouponStatus.available
              ? () => Navigator.popUntil(context, (r) => r.isFirst)
              : null,
        ),
      ),
    );
  }
}
