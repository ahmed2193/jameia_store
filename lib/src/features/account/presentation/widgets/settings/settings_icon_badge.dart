import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon_plate.dart';
import 'settings_tone.dart';

/// A settings row's icon: white on a rounded [HeroIconPlate] in the row's
/// [SettingsTone.plate] colour.
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.tone,
    this.dimension = defaultDimension,
  });

  static const double defaultDimension = AppSize.s36;

  final IconData icon;
  final SettingsTone tone;
  final double dimension;

  @override
  Widget build(BuildContext context) =>
      HeroIconPlate(icon, size: dimension, color: tone.plate);
}
