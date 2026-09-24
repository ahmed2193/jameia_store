import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// Shown while the saved account still carries the sign-up placeholder name
/// (the phone number): asks for a real name first.
class ProfileCompleteBanner extends StatelessWidget {
  const ProfileCompleteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) => state.needsName,
      builder: (context, needsName) {
        if (!needsName) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.brandLightBg,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.waving_hand_outlined,
                  size: AppSize.s22,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.complete_profile'.tr(),
                        style: AppTextStyles.headingMedium.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'profile.complete_profile_hint'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
