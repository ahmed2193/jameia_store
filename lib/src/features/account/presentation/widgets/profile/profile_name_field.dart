import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/profile_field.dart';
import '../../../domain/entities/profile_update.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_text_field.dart';

/// Required display name (1–120 chars). Rebuilds only when its error shows,
/// hides or is refused again — never while the user types.
class ProfileNameField extends StatelessWidget {
  const ProfileNameField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, (bool, int)>(
      selector: (state) =>
          (state.showNameError, state.refusalsOf(ProfileField.name)),
      builder: (context, error) => ProfileTextField(
        label: 'profile.name'.tr(),
        controller: controller,
        focusNode: focusNode,
        icon: Icons.person_outline_rounded,
        hintText: 'profile.name_hint'.tr(),
        maxLength: ProfileUpdate.maxNameLength,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        errorText: error.$1 ? 'profile.name_required'.tr() : null,
        shakeKey: error.$2,
        onChanged: context.read<ProfileCubit>().nameChanged,
      ),
    );
  }
}
