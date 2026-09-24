import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';

/// Save CTA — always tappable so an invalid form shows its inline errors;
/// spinning (and inert) while the POST / PATCH is in flight.
class AddressSaveButton extends StatelessWidget {
  const AddressSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
        AppSpacing.s12,
      ),
      child: BlocSelector<AddressEditCubit, AddressEditState, bool>(
        selector: (state) => state.isSaving,
        builder: (context, saving) => AppButton(
          label: 'addr.save_address'.tr(),
          loading: saving,
          radius: AppRadius.r1,
          onPressed: context.read<AddressEditCubit>().save,
        ),
      ),
    );
  }
}
