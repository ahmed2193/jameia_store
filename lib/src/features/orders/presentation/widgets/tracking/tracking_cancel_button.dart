import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../domain/entities/cancel_order_request.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../orders_list/cancel_order_sheet.dart';

/// "Cancel order" while the API still allows it — a full-width secondary
/// pill; opens the reason sheet.
class TrackingCancelButton extends StatelessWidget {
  const TrackingCancelButton({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<OrderTrackingCubit>();
    final request = await showHeroBottomSheet<CancelOrderRequest>(
      context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: HeroSheetHeader.shape,
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
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.section,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSecondaryButton(
        label: 'orders.cancel_order'.tr(),
        expanded: true,
        onPressed: cancelling ? null : () => _cancel(context),
      ),
    );
  }
}
