import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/qty_stepper_round_button.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_field_label.dart';
import 'profile_field_shell.dart';

/// Optional household size (1–20): − / + stepper, the count flipping to its
/// new value. Below one the value is removed ("Number of people" again); a
/// button that would do nothing is dimmed.
class ProfileHouseholdField extends StatelessWidget {
  const ProfileHouseholdField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, (int?, bool)>(
      selector: (state) => (state.householdSize, state.canAddPerson),
      builder: (context, household) {
        final (size, canAdd) = household;
        final cubit = context.read<ProfileCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileFieldLabel('profile.household_size'.tr()),
            ProfileFieldShell(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.s14,
                end: AppSpacing.s6,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: AppSize.s20,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    // The placeholder ↔ a number flips (a label swap); the
                    // number itself rolls up / down with the stepper.
                    child: FlipValue(
                      flipKey: size == null,
                      child: size == null
                          ? Text(
                              'profile.household_placeholder'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: AppColors.tertiaryText,
                              ),
                            )
                          : RollingNumber(
                              value: size,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: AppColors.primaryText,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  QtyStepperRoundButton(
                    icon: Icons.remove_rounded,
                    bg: AppColors.white,
                    fg: AppColors.primaryText,
                    size: AppSize.s36,
                    label: 'profile.household_less'.tr(),
                    enabled: size != null,
                    onTap: cubit.removePerson,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  QtyStepperRoundButton(
                    icon: Icons.add_rounded,
                    bg: AppColors.primary,
                    fg: AppColors.brandForeground,
                    size: AppSize.s36,
                    label: 'profile.household_more'.tr(),
                    enabled: canAdd,
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
