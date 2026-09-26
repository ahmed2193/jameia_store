import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../cubit/coupons_cubit.dart';
import '../widgets/order_coupons/order_coupons_view.dart';

/// Checkout coupon picker: the available coupons as selectable tickets plus
/// "Don't use a coupon"; "Confirm" pops the chosen `CouponEntity` (or `null`)
/// back to the caller.
class OrderCouponsPage extends StatelessWidget {
  const OrderCouponsPage({super.key, this.selectedId});

  /// Id of the coupon already applied to the order (pre-selects it).
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsCubit>()..load(),
      child: OrderCouponsView(selectedId: selectedId),
    );
  }
}
