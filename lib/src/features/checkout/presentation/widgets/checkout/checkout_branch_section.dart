import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_branch_sheet.dart';
import 'checkout_section_title.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle('checkout.branch_title'.tr()),
        ListTile(
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          leading: const Icon(
            JameiaIcons.store,
            size: AppSize.s22,
            color: AppColors.primary,
          ),
          title: Text(
            branch?.name ?? 'checkout.branch_choose'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          subtitle: branch == null || branch.address.isEmpty
              ? null
              : Text(
                  branch.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
          trailing: selecting
              ? const SizedBox(
                  width: AppSize.s20,
                  height: AppSize.s20,
                  child: CircularProgressIndicator(strokeWidth: AppSize.s2),
                )
              : const Icon(Icons.chevron_right, color: AppColors.tertiaryText),
          onTap: selecting ? null : () => _choose(context),
        ),
      ],
    );
  }
}
