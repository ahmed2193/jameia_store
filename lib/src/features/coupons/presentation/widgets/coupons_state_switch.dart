import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../domain/entities/coupon_buckets.dart';
import '../cubit/coupons_cubit.dart';
import '../cubit/coupons_state.dart';

/// Switches a coupon screen on the cubit status: the ticket skeleton while
/// loading, the error view with retry, or [loaded] with the buckets.
class CouponsStateSwitch extends StatelessWidget {
  const CouponsStateSwitch({super.key, required this.loaded});

  final Widget Function(BuildContext context, CouponBuckets buckets) loaded;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CouponsCubit, CouponsState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.buckets != current.buckets,
      builder: (context, state) => switch (state.status) {
        CouponsStatus.initial || CouponsStatus.loading => const Skeletonized(
          loading: true,
          child: CouponsSkeleton(),
        ),
        CouponsStatus.error => ErrorView(
          message: state.failure?.localizedMessage,
          onRetry: () => context.read<CouponsCubit>().load(),
        ),
        CouponsStatus.loaded => loaded(context, state.buckets),
      },
    );
  }
}
