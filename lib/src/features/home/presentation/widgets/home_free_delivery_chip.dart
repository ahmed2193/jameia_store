import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/light_sweep.dart';

/// "Free delivery" picked out of the first-order bar's line: lime letters on
/// the sticker ink, a light sweeping across it now and then (the one sweep
/// of its screen, within the ambient budget). Set in the line's [style]
/// (handed over: a widget inside a rich text does not inherit its style).
class HomeFreeDeliveryChip extends StatelessWidget {
  const HomeFreeDeliveryChip({
    super.key,
    required this.label,
    required this.style,
  });

  final String label;
  final TextStyle style;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppSize.r3),
  );

  @override
  Widget build(BuildContext context) {
    return LightSweep(
      borderRadius: _radius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.stickerOutline,
          borderRadius: _radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s1,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: style.copyWith(color: AppColors.proLime),
          ),
        ),
      ),
    );
  }
}
