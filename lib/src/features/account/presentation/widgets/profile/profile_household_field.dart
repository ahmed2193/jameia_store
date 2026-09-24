import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_outlined_box.dart';
import '../../../../../core/widgets/qty_stepper_round_button.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_field_label.dart';

/// Optional household size (1–20): − / + stepper. Below one the value is
/// removed ("Number of people" again).
class ProfileHouseholdField extends StatelessWidget {
  const ProfileHouseholdField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, int?>(
      selector: (state) => state.householdSize,
      builder: (context, size) {
        final cubit = context.read<ProfileCubit>();
        final canAdd = cubit.state.canAddPerson;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileFieldLabel('profile.household_size'.tr()),
            JameiaOutlinedBox(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: AppSize.s18,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: Text(
                      size == null
                          ? 'profile.household_placeholder'.tr()
                          : '$size',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: size == null
                            ? AppColors.tertiaryText
                            : AppColors.primaryText,
                      ),
                    ),
                  ),
                  QtyStepperRoundButton(
                    icon: Icons.remove_rounded,
                    bg: AppColors.smallBackground,
                    fg: size == null
                        ? AppColors.disabledText
                        : AppColors.primaryText,
                    size: AppSize.s28,
                    label: 'profile.household_less'.tr(),
                    onTap: cubit.removePerson,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  QtyStepperRoundButton(
                    icon: Icons.add_rounded,
                    bg: canAdd ? AppColors.primary : AppColors.smallBackground,
                    fg: canAdd
                        ? AppColors.brandForeground
                        : AppColors.disabledText,
                    size: AppSize.s28,
                    label: 'profile.household_more'.tr(),
                    onTap: cubit.addPerson,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
