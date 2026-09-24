import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../cubit/checkout_cubit.dart';

/// Pickup branches; a tap selects on the server and closes the sheet.
class CheckoutBranchSheet extends StatelessWidget {
  const CheckoutBranchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = context.select<CheckoutCubit, List<BranchEntity>>(
      (cubit) => cubit.state.branches,
    );
    final selectedId = context.select<CheckoutCubit, String?>(
      (cubit) => cubit.state.draft.branchId,
    );
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Text(
              'checkout.branch_sheet_title'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                return OptionRow(
                  key: ValueKey<String>(branch.id),
                  title: branch.name,
                  subtitle: branch.address.isEmpty ? null : branch.address,
                  selected: branch.id == selectedId,
                  onTap: () {
                    context.read<CheckoutCubit>().selectBranch(branch.id);
                    context.pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
