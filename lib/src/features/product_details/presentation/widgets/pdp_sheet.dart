import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';

/// The product page's white sheet under the gallery. Its rounded top reaches
/// [overlap] up into the gallery's grey, which carries on behind its
/// corners, and it holds the flat blocks: the first one is measured from
/// the sheet's very edge, not from under a blank strip.
class PdpSheet extends StatelessWidget {
  const PdpSheet({super.key, required this.child});

  final Widget child;

  /// How far the sheet reaches up into the gallery's grey.
  static const double overlap = AppSpacing.s24;
  static const double radius = AppRadius.sheet;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // The gallery's grey, carried on behind the rounded corners only.
        const PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          height: overlap,
          child: ColoredBox(color: AppColors.smallBackground),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          ),
          child: child,
        ),
      ],
    );
  }
}
