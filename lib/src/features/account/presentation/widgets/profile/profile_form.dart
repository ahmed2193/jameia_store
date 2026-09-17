import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_email_field.dart';
import 'profile_gender_selector.dart';
import 'profile_name_field.dart';
import 'profile_save_button.dart';

/// The form: name, email, gender, save. Owns the text controllers and re-seeds
/// them whenever the cubit REPLACES the draft (the server refresh of an
/// untouched form, or a successful save) — never while the user is typing.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    _name = TextEditingController(text: state.name);
    _email = TextEditingController(text: state.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _seed(ProfileState state) {
    if (_name.text != state.name) _name.text = state.name;
    if (_email.text != state.email) _email.text = state.email;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.customer != current.customer && !current.isDirty,
      listener: (_, state) => _seed(state),
      child: ListView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        children: [
          StaggerEntrance(
            index: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileNameField(controller: _name),
                  const SizedBox(height: AppSpacing.s16),
                  ProfileEmailField(controller: _email),
                  const SizedBox(height: AppSpacing.s16),
                  const ProfileGenderSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const StaggerEntrance(index: 1, child: ProfileSaveButton()),
        ],
      ),
    );
  }
}
