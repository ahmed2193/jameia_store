import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/haptics.dart';
import '../../cubit/setting_cubit.dart';
import '../../cubit/setting_state.dart';
import 'settings_switch.dart';
import 'settings_tile.dart';
import 'settings_tone.dart';

/// Vibration row: turns every haptic in the app on or off. The whole row and
/// its switch both flip the choice, and a screen reader hears one "switch,
/// on/off" control. Turning it off gives one last click.
class SettingsHapticsTile extends StatelessWidget {
  const SettingsHapticsTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingCubit, SettingState, bool>(
      selector: (state) => state.hapticsEnabled,
      builder: (context, enabled) {
        void toggle(bool value) {
          Haptics.pick();
          context.read<SettingCubit>().setHapticsEnabled(value);
        }

        return MergeSemantics(
          child: SettingsTile(
            icon: Icons.vibration_rounded,
            tone: SettingsTone.teal,
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
