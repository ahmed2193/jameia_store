import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../domain/entities/coupon_buckets.dart';
import '../../cubit/coupons_cubit.dart';
import '../coupons_app_bar.dart';
import '../coupons_state_switch.dart';
import 'order_coupons_confirm_bar.dart';
import 'order_coupons_list.dart';

/// The checkout coupon picker screen. Holds the pick (starting from
/// [selectedId], the coupon already on the order); "Confirm" pops the picked
/// available coupon, or `null` for none.
class OrderCouponsView extends StatefulWidget {
  const OrderCouponsView({super.key, this.selectedId});

  final String? selectedId;

  @override
  State<OrderCouponsView> createState() => _OrderCouponsViewState();
}

class _OrderCouponsViewState extends State<OrderCouponsView> {
  late String? _selectedId = widget.selectedId;

  void _select(String? id) => setState(() => _selectedId = id);

  void _confirm() => context.pop(
    context.read<CouponsCubit>().state.buckets.availableById(_selectedId),
  );

  @override
  Widget build(BuildContext context) {
    final buckets = context.select<CouponsCubit, CouponBuckets>(
      (cubit) => cubit.state.buckets,
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CouponsAppBar(title: 'coupons.select_coupon'.tr()),
      body: CouponsStateSwitch(
        loaded: (_, loaded) => OrderCouponsList(
          coupons: loaded.available,
          selectedId: _selectedId,
          onSelect: _select,
        ),
      ),
      bottomNavigationBar: OrderCouponsConfirmBar(
        selected: buckets.availableById(_selectedId),
        onConfirm: _confirm,
      ),
    );
  }
}
