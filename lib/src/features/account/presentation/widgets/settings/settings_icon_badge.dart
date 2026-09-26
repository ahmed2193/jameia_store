import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import 'settings_tone.dart';

/// Rounded tinted square holding a settings row's icon.
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.tone,
    this.dimension = defaultDimension,
    this.iconSize = AppSize.s20,
  });

  static const double defaultDimension = AppSize.s36;

  /// Corner radius as a share of [dimension], so a big badge keeps the shape.
  static const double _cornerShare = 0.3;

  final IconData icon;
  final SettingsTone tone;
  final double dimension;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(dimension * _cornerShare),
        ),
        child: Icon(icon, size: iconSize, color: tone.ink),
      ),
    );
  }
}
