import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// Primary CTA — enabled once the draft differs from the saved profile,
/// spinning while the PATCH is in flight.
class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (previous, current) =>
          previous.canSave != current.canSave ||
          previous.isSaving != current.isSaving,
      builder: (context, state) => AppButton(
        label: 'profile.save'.tr(),
        enabled: state.canSave,
        loading: state.isSaving,
        radius: AppRadius.r3,
        onPressed: context.read<ProfileCubit>().save,
      ),
    );
  }
}
