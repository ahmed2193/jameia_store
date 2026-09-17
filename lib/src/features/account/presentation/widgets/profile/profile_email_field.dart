import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/jameia_outlined_field.dart';
import '../../../domain/entities/profile_update.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_field_error.dart';
import 'profile_field_label.dart';

/// Optional email; clearing it removes the address from the account.
class ProfileEmailField extends StatelessWidget {
  const ProfileEmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) => state.showEmailError,
      builder: (context, showError) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileFieldLabel(
            '${'profile.email'.tr()} · ${'common.optional'.tr()}',
          ),
          JameiaOutlinedField(
            controller: controller,
            hintText: 'profile.email_hint'.tr(),
            maxLength: ProfileUpdate.maxEmailLength,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            error: showError,
            onChanged: context.read<ProfileCubit>().emailChanged,
          ),
          ProfileFieldError(
            message: showError ? 'profile.email_invalid'.tr() : null,
          ),
        ],
      ),
    );
  }
}
