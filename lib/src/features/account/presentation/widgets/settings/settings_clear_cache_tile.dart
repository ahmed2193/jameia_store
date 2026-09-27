import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import '../../cubit/setting_cubit.dart';
import '../../cubit/setting_state.dart';
import 'settings_tile.dart';
import 'settings_tone.dart';

/// "Clear cache" row: runs the clean-up; a small loader fades through in
/// place of the empty trailing slot while it works (the page confirms with a
/// snack bar).
class SettingsClearCacheTile extends StatelessWidget {
  const SettingsClearCacheTile({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingCubit, SettingState, bool>(
      selector: (state) => state.isClearingCache,
      builder: (context, clearing) => SettingsTile(
        icon: Icons.cleaning_services_outlined,
        tone: SettingsTone.teal,
        title: title,
        chevron: false,
        onTap: clearing ? null : context.read<SettingCubit>().clearCache,
        trailing: FadeThroughSwitcher(
          stateKey: clearing,
          child: clearing
              ? const BrandedDotLoader(size: AppSize.s24)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
