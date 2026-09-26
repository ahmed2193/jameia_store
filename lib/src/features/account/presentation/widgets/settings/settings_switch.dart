import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

/// The platform switch (Cupertino on iOS) in the brand green, with a check /
/// cross in the Material thumb so the state reads without colour.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static final WidgetStateProperty<Icon?> _thumbIcon =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check_rounded, color: AppColors.primaryDark)
            : const Icon(Icons.close_rounded, color: AppColors.tertiaryText),
      );

  static const WidgetStateProperty<Color?> _outline = WidgetStatePropertyAll(
    AppColors.scrimTransparent,
  );

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.white,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: AppColors.white,
      inactiveTrackColor: AppColors.disabledText,
      trackOutlineColor: _outline,
      thumbIcon: _thumbIcon,
    );
  }
}
