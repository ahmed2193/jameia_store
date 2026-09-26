import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/profile_field.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_about_header.dart';
import 'profile_completion_card.dart';
import 'profile_date_of_birth_field.dart';
import 'profile_email_field.dart';
import 'profile_gender_selector.dart';
import 'profile_household_field.dart';
import 'profile_name_field.dart';
import 'profile_save_bar.dart';
import 'profile_section_card.dart';
import 'profile_section_title.dart';

/// The form: the completion header, name + email, the optional "About you"
/// details (date of birth, gender, household size) — three sections that
/// rise in once — over the pinned Save bar. Owns the text controllers and
/// focus nodes: it re-seeds the controllers whenever the cubit REPLACES the
/// draft (the server refresh of an untouched form, or a successful save) —
/// never while the user is typing — and moves the focus to the first
/// invalid field when a save is refused.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

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
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _seed(ProfileState state) {
    if (_name.text != state.name) _name.text = state.name;
    if (_email.text != state.email) _email.text = state.email;
  }

  void _focusFirstInvalid(ProfileState state) {
    switch (state.firstInvalidField) {
      case ProfileField.name:
        _nameFocus.requestFocus();
      case ProfileField.email:
        _emailFocus.requestFocus();
      case ProfileField.dateOfBirth ||
          ProfileField.gender ||
          ProfileField.householdSize ||
          null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.customer != current.customer && !current.isDirty,
          listener: (_, state) => _seed(state),
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.rejectedSubmits != current.rejectedSubmits,
          listener: (_, state) => _focusFirstInvalid(state),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsetsDirectional.all(AppSpacing.s16),
              children: [
                const StaggerEntrance(index: 0, child: ProfileCompletionCard()),
                const SizedBox(height: AppSpacing.s16),
                StaggerEntrance(
                  index: 1,
                  child: ProfileSectionCard(
                    children: [
                      ProfileSectionTitle('profile.details_title'.tr()),
                      const SizedBox(height: AppSpacing.s16),
                      ProfileNameField(
                        controller: _name,
                        focusNode: _nameFocus,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      ProfileEmailField(
                        controller: _email,
                        focusNode: _emailFocus,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                const StaggerEntrance(
                  index: 2,
                  child: ProfileSectionCard(
                    children: [
                      ProfileAboutHeader(),
                      SizedBox(height: AppSpacing.s16),
                      ProfileDateOfBirthField(),
                      SizedBox(height: AppSpacing.s16),
                      ProfileGenderSelector(),
                      SizedBox(height: AppSpacing.s16),
                      ProfileHouseholdField(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const ProfileSaveBar(),
        ],
      ),
    );
  }
}
