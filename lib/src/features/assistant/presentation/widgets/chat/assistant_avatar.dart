import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';

/// The assistant's sparkle disc beside its bubbles (decorative: the bubble
/// itself says who is speaking).
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = AppSize.s28});

  final double size;

  static const double _glyphRatio = 0.55;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.brandLightBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome,
            size: size * _glyphRatio,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
