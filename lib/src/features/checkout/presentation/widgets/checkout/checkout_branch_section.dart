import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/jameia_sheet_header.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_branch_sheet.dart';
import 'checkout_destination_row.dart';
import 'checkout_section.dart';

/// Pickup destination: the chosen branch, or the prompt to pick one from
/// the branch sheet.
class CheckoutBranchSection extends StatelessWidget {
  const CheckoutBranchSection({super.key});

  void _choose(BuildContext context) {
    final cubit = context.read<CheckoutCubit>();
    showJameiaBottomSheet<void>(
      context,
      large: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: JameiaSheetHeader.shape,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const CheckoutBranchSheet()),
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
    return CheckoutSection(
      title: 'checkout.branch_title'.tr(),
      child: CheckoutDestinationRow(
        icon: Icons.storefront_outlined,
        title: branch?.name ?? 'checkout.branch_choose'.tr(),
        subtitle: branch == null || branch.address.isEmpty
            ? null
            : branch.address,
        chosen: branch != null,
        selecting: selecting,
        onTap: () => _choose(context),
      ),
    );
  }
}
