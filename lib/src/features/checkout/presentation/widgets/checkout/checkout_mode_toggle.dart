import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/cart_entity.dart';
import '../../../../../core/widgets/jameia_segmented_control.dart';
import '../../cubit/checkout_cubit.dart';

/// Delivery / pickup switch: a pill segmented control whose dark thumb glides
/// to the chosen mode (a selection haptic only when the mode changes).
class CheckoutModeToggle extends StatelessWidget {
  const CheckoutModeToggle({super.key});

  /// The two modes a customer can pick; never `FulfillmentMode.values`, which
  /// also holds the wire fallback `other`.
  static const List<FulfillmentMode> _modes = <FulfillmentMode>[
    FulfillmentMode.delivery,
    FulfillmentMode.pickup,
  ];

  @override
  Widget build(BuildContext context) {
    final mode = context.select<CheckoutCubit, FulfillmentMode>(
      (cubit) => cubit.state.draft.mode,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: JameiaSegmentedControl<FulfillmentMode>(
        values: _modes,
        selected: mode,
        labelOf: (value) =>
            (value == FulfillmentMode.pickup
                    ? 'checkout.mode_pickup'
                    : 'checkout.mode_delivery')
                .tr(),
        onChanged: (value) => context.read<CheckoutCubit>().setMode(value),
      ),
    );
  }
}
