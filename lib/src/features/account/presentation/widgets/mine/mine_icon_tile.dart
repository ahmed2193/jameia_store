import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_tone.dart';

/// A glyph on a soft tinted tile ([tone]): a rounded square in the menu
/// rows, a disc on the quick-stat tiles ([circle]).
class MineIconTile extends StatelessWidget {
  const MineIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.circle = false,
  });

  static const double size = AppSize.s32;
  static const double _glyph = AppSize.s18;

  final IconData icon;
  final MineTone tone;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppRadius.r5),
      ),
      child: Icon(icon, size: _glyph, color: tone.foreground),
    );
  }
}
