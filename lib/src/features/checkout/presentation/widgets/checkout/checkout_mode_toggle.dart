import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_entity.dart';
import '../../cubit/checkout_cubit.dart';

/// Delivery / pickup switch.
class CheckoutModeToggle extends StatelessWidget {
  const CheckoutModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<CheckoutCubit, FulfillmentMode>(
      (cubit) => cubit.state.draft.mode,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<FulfillmentMode>(
          segments: [
            ButtonSegment<FulfillmentMode>(
              value: FulfillmentMode.delivery,
              label: Text('checkout.mode_delivery'.tr()),
              icon: const Icon(Icons.delivery_dining_outlined),
            ),
            ButtonSegment<FulfillmentMode>(
              value: FulfillmentMode.pickup,
              label: Text('checkout.mode_pickup'.tr()),
              icon: const Icon(Icons.storefront_outlined),
            ),
          ],
          selected: <FulfillmentMode>{mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              context.read<CheckoutCubit>().setMode(selection.first),
        ),
      ),
    );
  }
}
