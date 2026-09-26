import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/haptics.dart';
import '../../cubit/setting_cubit.dart';
import '../../cubit/setting_state.dart';
import 'settings_switch.dart';
import 'settings_tile.dart';
import 'settings_tone.dart';

/// Push-notification row: the whole row and its switch both flip the
/// choice, and a screen reader hears one "switch, on/off" control.
class SettingsNotificationsTile extends StatelessWidget {
  const SettingsNotificationsTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingCubit, SettingState, bool>(
      selector: (state) => state.notificationsEnabled,
      builder: (context, enabled) {
        void toggle(bool value) {
          Haptics.selection();
          context.read<SettingCubit>().setNotificationsEnabled(value);
        }

        return MergeSemantics(
          child: SettingsTile(
            icon: Icons.notifications_none_rounded,
            tone: SettingsTone.amber,
            title: title,
            subtitle: subtitle,
            onTap: () => toggle(!enabled),
            trailing: SettingsSwitch(value: enabled, onChanged: toggle),
          ),
        );
      },
    );
  }
}
