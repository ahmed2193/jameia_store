import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/loyalty_program.dart';
import '../../cubit/loyalty_program_cubit.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// "Earn N points when you fill this in" — only while the store runs the
/// profile bonus and the saved profile is not complete yet.
class ProfileBonusHint extends StatelessWidget {
  const ProfileBonusHint({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyProgramCubit, LoyaltyProgram>(
      builder: (context, program) =>
          BlocSelector<ProfileCubit, ProfileState, AuthCustomerEntity?>(
            selector: (state) => state.customer,
            builder: (context, customer) {
              final points = customer == null
                  ? 0
                  : program.profileBonusFor(customer);
              if (points <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s10,
                    vertical: AppSpacing.s6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandLightBg,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        size: AppSize.s16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Flexible(
                        child: Text(
                          'profile.profile_bonus_hint'.tr(
                            namedArgs: {'pts': '$points'},
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
