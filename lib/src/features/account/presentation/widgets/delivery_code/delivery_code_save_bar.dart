import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/delivery_code_cubit.dart';

/// Save bar pinned under the delivery-code screen: enabled only for four new
/// digits; a save closes the keyboard and confirms with a snack bar (the
/// big code above flips to the new digits).
class DeliveryCodeSaveBar extends StatelessWidget {
  const DeliveryCodeSaveBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s12,
          ),
          child: BlocConsumer<DeliveryCodeCubit, DeliveryCodeState>(
            listenWhen: (previous, current) => !previous.saved && current.saved,
            listener: (context, _) {
              FocusScope.of(context).unfocus();
              showHeroSnackBar(
                context,
                'account.code_updated'.tr(),
                behavior: SnackBarBehavior.floating,
              );
            },
            buildWhen: (previous, current) =>
                previous.canSave != current.canSave,
            builder: (context, state) => AppButton(
              label: 'account.save'.tr(),
              enabled: state.canSave,
              onPressed: context.read<DeliveryCodeCubit>().save,
            ),
          ),
        ),
      ),
    );
  }
}
