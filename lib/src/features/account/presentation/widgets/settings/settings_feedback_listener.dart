import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../cubit/setting_cubit.dart';
import '../../cubit/setting_state.dart';

/// Snack-bar feedback of the Settings screen: a finished cache clean-up and
/// any failed setting (the switch has already been put back).
class SettingsFeedbackListener extends StatelessWidget {
  const SettingsFeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingCubit, SettingState>(
      listenWhen: (previous, current) =>
          (current.failure != null && current.failure != previous.failure) ||
          (previous.isClearingCache && !current.isClearingCache),
      listener: (context, state) {
        final failure = state.failure;
        showHeroSnackBar(
          context,
          failure != null
              ? failure.localizedMessage
              : 'settings.cache_cleared'.tr(),
          tone: failure != null ? HeroSnackTone.error : HeroSnackTone.success,
        );
      },
      child: child,
    );
  }
}
