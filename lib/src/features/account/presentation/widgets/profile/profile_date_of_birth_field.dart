import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_date_of_birth_sheet.dart';
import 'profile_field_label.dart';
import 'profile_value_box.dart';

/// Optional date of birth: tap opens the calendar sheet, "Clear" removes it.
class ProfileDateOfBirthField extends StatelessWidget {
  const ProfileDateOfBirthField({super.key});

  Future<void> _pick(BuildContext context, DateTime? current) async {
    final cubit = context.read<ProfileCubit>();
    final picked = await showJameiaBottomSheet<DateTime>(
      context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (_) => ProfileDateOfBirthSheet(initial: current),
    );
    if (picked != null) cubit.dateOfBirthChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, DateTime?>(
      selector: (state) => state.dateOfBirth,
      builder: (context, date) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileFieldLabel('profile.date_of_birth'.tr()),
          ProfileValueBox(
            icon: Icons.cake_outlined,
            value: date == null
                ? null
                : DateFormat.yMMMMd(context.locale.languageCode).format(date),
            placeholder: 'profile.date_placeholder'.tr(),
            onTap: () => _pick(context, date),
            onClear: date == null
                ? null
                : () => context.read<ProfileCubit>().dateOfBirthChanged(null),
          ),
        ],
      ),
    );
  }
}
