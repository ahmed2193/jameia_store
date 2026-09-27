import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/address_edit_cubit.dart';

/// Save CTA — always tappable so an invalid form shows its inline errors.
/// While the POST / PATCH is in flight the page's busy overlay holds the
/// screen; the pill keeps its label under it.
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
      child: AppButton(
        label: 'addr.save_address'.tr(),
        radius: AppRadius.r1,
        onPressed: context.read<AddressEditCubit>().save,
      ),
    );
  }
}
