import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_branch_sheet.dart';
import 'checkout_destination_row.dart';
import 'checkout_sheet_frame.dart';

/// Pickup destination as one flat row: the chosen branch with its address
/// and phone, or the prompt to pick one from the branch sheet.
class CheckoutBranchSection extends StatelessWidget {
  const CheckoutBranchSection({super.key});

  void _choose(BuildContext context) {
    CheckoutSheetFrame.show<void>(
      context,
      // The sheet is a new route: it reaches the page's cubit only this way.
      checkout: context.read<CheckoutCubit>(),
      large: true,
      builder: (_) => const CheckoutBranchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.select<CheckoutCubit, BranchEntity?>(
      (cubit) => cubit.state.branchById(cubit.state.draft.branchId),
    );
    final selecting = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.isSelecting,
    );
    final details = branch == null
        ? const <String>[]
        : <String>[
            if (branch.address.isNotEmpty) branch.address,
            // The number reads left to right inside an Arabic line too.
            if (branch.phone.isNotEmpty) Formatters.isolate(branch.phone),
          ];
    return CheckoutDestinationRow(
      icon: Icons.storefront_outlined,
      title: branch?.name ?? 'checkout.branch_choose'.tr(),
      subtitle: details.isEmpty ? null : details.join(Formatters.middot),
      selecting: selecting,
      onTap: () => _choose(context),
    );
  }
}
