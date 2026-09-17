import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_field_label.dart';
import 'profile_gender_chip.dart';

/// Male / female / prefer-not-to-say (the backend accepts `male`, `female` or
/// `null`).
class ProfileGenderSelector extends StatelessWidget {
  const ProfileGenderSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, CustomerGender?>(
      selector: (state) => state.gender,
      builder: (context, gender) {
        final select = context.read<ProfileCubit>().genderChanged;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileFieldLabel('profile.gender'.tr()),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                ProfileGenderChip(
                  label: 'profile.gender_male'.tr(),
                  selected: gender == CustomerGender.male,
                  onTap: () => select(CustomerGender.male),
                ),
                ProfileGenderChip(
                  label: 'profile.gender_female'.tr(),
                  selected: gender == CustomerGender.female,
                  onTap: () => select(CustomerGender.female),
                ),
                ProfileGenderChip(
                  label: 'profile.gender_unset'.tr(),
                  selected: gender == null,
                  onTap: () => select(null),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
