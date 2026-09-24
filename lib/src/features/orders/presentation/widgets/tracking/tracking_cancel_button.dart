import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/app_outline_button.dart';
import '../../../domain/entities/cancel_order_request.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../orders_list/cancel_order_sheet.dart';

/// "Cancel order" while the API still allows it; opens the reason sheet.
class TrackingCancelButton extends StatelessWidget {
  const TrackingCancelButton({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<OrderTrackingCubit>();
    final request = await showJameiaBottomSheet<CancelOrderRequest>(
      context,
      isScrollControlled: true,
      builder: (_) => CancelOrderSheet(orderId: orderId),
    );
    if (request == null) return;
    await cubit.cancel(reason: request.reason, note: request.note);
  }

  @override
  Widget build(BuildContext context) {
    final cancelling = context.select<OrderTrackingCubit, bool>(
      (cubit) => cubit.state.isCancelling,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      child: AppOutlineButton(
        label: 'orders.cancel_order'.tr(),
        onPressed: cancelling ? null : () => _cancel(context),
      ),
    );
  }
}
