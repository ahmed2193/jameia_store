import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/count_badge.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// A round contact action on the rider card — message or call: the glyph on
/// the brand wash, a press that gives, its name read out (and shown on a
/// long press), and the rider's unread messages counted on its corner.
class LiveMapContactButton extends StatelessWidget {
  const LiveMapContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.unread = 0,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final int unread;

  /// What a screen reader says when it should say more than [label] (the
  /// unread count); [label] otherwise.
  final String? semanticLabel;

  static const double _size = AppSize.s44;

  /// The press target around the [_size] disc: a full 48 dp touch.
  static const double _target = AppSize.s48;
  static const double _glyph = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      // The press below is excluded with the rest: the node taps itself.
      onTap: onPressed,
      child: Tooltip(
        message: label,
        child: PressScale(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: _target,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox.square(
                    dimension: _size,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.brandLightBg,
                        shape: BoxShape.circle,
                      ),
                      child: HeroIcon(
                        icon,
                        size: _glyph,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: -AppSpacing.s2,
                    end: -AppSpacing.s2,
                    child: CountBadge(
                      count: unread,
                      color: AppColors.error,
                      borderColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
