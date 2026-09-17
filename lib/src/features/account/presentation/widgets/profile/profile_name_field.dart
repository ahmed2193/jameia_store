import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/jameia_outlined_field.dart';
import '../../../domain/entities/profile_update.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_field_error.dart';
import 'profile_field_label.dart';

/// Required display name (1–120 chars).
class ProfileNameField extends StatelessWidget {
  const ProfileNameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) => state.showNameError,
      builder: (context, showError) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileFieldLabel('profile.name'.tr()),
          JameiaOutlinedField(
            controller: controller,
            hintText: 'profile.name_hint'.tr(),
            maxLength: ProfileUpdate.maxNameLength,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            error: showError,
            onChanged: context.read<ProfileCubit>().nameChanged,
          ),
          ProfileFieldError(
            message: showError ? 'profile.name_required'.tr() : null,
          ),
        ],
      ),
    );
  }
}
