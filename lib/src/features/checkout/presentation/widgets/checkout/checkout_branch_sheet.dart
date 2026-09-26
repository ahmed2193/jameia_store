import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/jameia_sheet_header.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../cubit/checkout_cubit.dart';

/// Pickup branches; a tap selects on the server and closes the sheet. Never
/// taller than [_maxHeightFactor] of the screen.
class CheckoutBranchSheet extends StatelessWidget {
  const CheckoutBranchSheet({super.key});

  static const double _maxHeightFactor = 0.85;

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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JameiaSheetHeader(title: 'checkout.branch_sheet_title'.tr()),
            Flexible(
              // shrinkWrap: a store has a handful of pickup branches (well
              // under 20 rows), and the sheet should hug them, not fill the
              // screen.
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppSpacing.s16,
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}
