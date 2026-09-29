import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/domain/entities/loyalty_program.dart';
import '../../cubit/loyalty_program_cubit.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// "Earn N points when you fill this in" — a warm points pill (the Rewards
/// colours), only while the store runs the profile bonus and the saved
/// profile is not complete yet. The programme is read after the page opens:
/// the pill opens its room ([CollapseReveal]) instead of snapping in and
/// pushing the section down.
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
              return CollapseReveal(
                visible: points > 0,
                child: points <= 0
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: AppSpacing.s10,
                        ),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppColors.accent3Light,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.r3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.s8,
                              AppSpacing.s6,
                              AppSpacing.s12,
                              AppSpacing.s6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  size: AppSize.s18,
                                  color: AppColors.accent3Dark,
                                ),
                                const SizedBox(width: AppSpacing.s6),
                                Flexible(
                                  child: Text(
                                    'profile.profile_bonus_hint'.tr(
                                      namedArgs: {'pts': '$points'},
                                    ),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.voucherBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
    );
  }
}
