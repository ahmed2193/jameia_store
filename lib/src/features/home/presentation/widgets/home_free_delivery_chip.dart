import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/light_sweep.dart';

/// "Free delivery" picked out of the first-order bar's line: lime letters on
/// the sticker ink, a light sweeping across it now and then (the one sweep
/// of its screen, within the ambient budget). Inherits the line's type.
class HomeFreeDeliveryChip extends StatelessWidget {
  const HomeFreeDeliveryChip({super.key, required this.label});

  final String label;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppSize.r4),
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
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s2,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: DefaultTextStyle.of(context).style
                .copyWith(color: AppColors.proLime),
          ),
        ),
      ),
    );
  }
}
