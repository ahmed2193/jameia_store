import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_sheet_frame.dart';

/// Pickup branches in the checkout sheet shell; a tap selects on the server
/// and closes the sheet. Open it with `CheckoutSheetFrame.show(checkout:)`:
/// it reads the page's cubit.
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
    return CheckoutSheetFrame(
      title: 'checkout.branch_sheet_title'.tr(),
      // shrinkWrap: a store has a handful of pickup branches (well under 20
      // rows) and the sheet should hug them; the frame caps its height and
      // hands the list the space left (Flexible).
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
        itemCount: branches.length,
        separatorBuilder: (_, _) =>
            const ThinDivider(indent: AppSpacing.gutter),
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
    );
  }
}
