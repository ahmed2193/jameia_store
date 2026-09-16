import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/orders_list/in_progress_body.dart';
import '../widgets/orders_list/orders_list.dart';
import '../widgets/orders_list/orders_tab_bar.dart';

/// KeeTa Orders list (`mach_pro_sailor_c_order_list`) — two tabs
/// (In progress / History) over [KeetaRepository.orders], per-order shop header,
/// status chip, item summary, date/total, and per-state actions (Track for
/// active orders; Reorder + Review for completed ones). Empty state per tab.
///
/// Real bundle metrics (bundle.css.json):
/// - page bg #F5F6FA | card 12dp radius | card padding 16dp/10dp (V/H)
/// - tab bar 50dp high | tab indicator 3dp #0D0D0D | page horizontal inset 12dp
/// - shop logo 40×40dp r13 | shop name KeeTa-Bold 16dp #222222
/// - items KeeTa-Regular 12dp #808080 | status chip r4.8dp padding 2×6dp
/// - primary action button: #FFEA00 bg, 24dp radius, 48dp height, 13/32dp padding
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (_) => sl<OrdersCubit>(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          // Bundle: background-color #F5F6FA
          backgroundColor: AppColors.mediumBackground,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
            centerTitle: false,
            // Bundle: font-size 18dp KeeTa-Medium (da93c4)
            title: Text(
              'orders.title'.tr(),
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: AppTextStyles.medium,
              ),
            ),
            bottom: const OrdersTabBar(),
          ),
          body: BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) {
              return switch (state.status) {
                OrdersStatus.initial ||
                OrdersStatus.loading => const AppLoader(),
                OrdersStatus.error => ErrorView(
                  message: 'orders.could_not_load'.tr(),
                  onRetry: () => context.read<OrdersCubit>().load(),
                ),
                OrdersStatus.loaded => TabBarView(
                  children: [
                    InProgressBody(orders: state.active),
                    OrdersList(
                      orders: state.history,
                      emptyMessage: 'orders.empty_history'.tr(),
                    ),
                  ],
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}
