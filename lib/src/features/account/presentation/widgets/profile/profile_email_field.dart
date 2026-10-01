import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../domain/entities/profile_field.dart';
import '../../../domain/entities/profile_update.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_text_field.dart';

/// Optional email; clearing it removes the address from the account.
/// Rebuilds only when its error shows, hides or is refused again.
class ProfileEmailField extends StatelessWidget {
  const ProfileEmailField({
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
          (state.showEmailError, state.refusalsOf(ProfileField.email)),
      builder: (context, error) => ProfileTextField(
        label: '${'profile.email'.tr()} · ${'common.optional'.tr()}',
        controller: controller,
        focusNode: focusNode,
        icon: HeroIcons.mail,
        hintText: 'profile.email_hint'.tr(),
        maxLength: ProfileUpdate.maxEmailLength,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        errorText: error.$1 ? 'profile.email_invalid'.tr() : null,
        shakeKey: error.$2,
        onChanged: context.read<ProfileCubit>().emailChanged,
      ),
    );
  }
}
