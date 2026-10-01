import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../cubit/delivery_code_cubit.dart';

/// Save bar pinned under the delivery-code screen (the shared
/// [HeroBottomBar]): enabled only for four new digits; a save closes the
/// keyboard and confirms with a snack bar (the big code above flips to the
/// new digits).
class DeliveryCodeSaveBar extends StatelessWidget {
  const DeliveryCodeSaveBar({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroBottomBar(
      child: BlocConsumer<DeliveryCodeCubit, DeliveryCodeState>(
        listenWhen: (previous, current) => !previous.saved && current.saved,
        listener: (context, _) {
          FocusScope.of(context).unfocus();
          showHeroSnackBar(
            context,
            'account.code_updated'.tr(),
            tone: HeroSnackTone.success,
          );
        },
        buildWhen: (previous, current) => previous.canSave != current.canSave,
        builder: (context, state) => AppButton(
          label: 'account.save'.tr(),
          height: AppSize.s52,
          enabled: state.canSave,
          onPressed: context.read<DeliveryCodeCubit>().save,
        ),
      ),
    );
  }
}
