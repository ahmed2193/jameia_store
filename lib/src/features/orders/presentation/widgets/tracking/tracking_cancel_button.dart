import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../orders_list/cancel_order_sheet.dart';

/// "Cancel order" while the API still allows it — a full-width red-outlined
/// pill at the foot of the page; opens the reason sheet (built once, like
/// the list's, so typing a note does not rebuild it).
class TrackingCancelButton extends StatelessWidget {
  const TrackingCancelButton({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<OrderTrackingCubit>();
    final request = await CancelOrderSheet.show(context, orderId: orderId);
    if (request == null) return;
    await cubit.cancel(reason: request.reason, note: request.note);
  }

  @override
  Widget build(BuildContext context) {
    final cancelling = context.select<OrderTrackingCubit, bool>(
      (cubit) => cubit.state.isCancelling,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSecondaryButton(
        label: 'orders.cancel_order'.tr(),
        expanded: true,
        destructive: true,
        onPressed: cancelling ? null : () => _cancel(context),
      ),
    );
  }
}
