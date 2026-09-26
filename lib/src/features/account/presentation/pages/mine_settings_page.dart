import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../cubit/setting_cubit.dart';
import '../widgets/settings/settings_app_bar.dart';
import '../widgets/settings/settings_body.dart';
import '../widgets/settings/settings_feedback_listener.dart';

/// Mine → Settings: language, push notifications, account / privacy links,
/// cache clean-up, About and log out, on the app-global [SettingCubit].
///
/// The page depends on the active locale, so a language switch made here
/// re-labels it in place (see [SettingsBody]).
class MineSettingsPage extends StatefulWidget {
  const MineSettingsPage({super.key});

  @override
  State<MineSettingsPage> createState() => _MineSettingsPageState();
}

class _MineSettingsPageState extends State<MineSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingCubit>().loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: SettingsAppBar(title: 'settings.title'.tr()),
      body: SettingsFeedbackListener(
        child: SettingsBody(languageCode: languageCode),
      ),
    );
  }
}
