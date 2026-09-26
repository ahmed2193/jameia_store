import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/delivery_code_cubit.dart';
import '../widgets/delivery_code/delivery_code_body.dart';
import '../widgets/delivery_code/delivery_code_save_bar.dart';
import '../widgets/settings/settings_app_bar.dart';

/// Mine → Delivery code: the code the rider asks for at the door, a copy
/// button, an editor for a new code and a pinned Save bar, over a
/// page-scoped [DeliveryCodeCubit].
class MineDeliveryCodePage extends StatelessWidget {
  const MineDeliveryCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeliveryCodeCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: SettingsAppBar(title: 'account.delivery_code'.tr()),
        body: const DeliveryCodeBody(),
        bottomNavigationBar: const DeliveryCodeSaveBar(),
      ),
    );
  }
}
