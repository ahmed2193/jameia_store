import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The ↖ at the end of an answer of the address search, Google Maps style:
/// the answer's name goes into the search box, to search on from there (it
/// points at the box; it turns ↗ right to left). While the answer's point
/// is looked up ([busy]) the dots take its place. A 48 dp target.
class SuggestionFillButton extends StatelessWidget {
  const SuggestionFillButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  /// What a screen reader hears ("Use “Salmiya” in the search").
  final String label;
  final bool busy;
  final VoidCallback onTap;

  static const double target = AppSize.s48;
  static const double _glyph = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: target,
      child: FadeThroughSwitcher(
        stateKey: busy,
        crossFade: true,
        child: busy
            ? const AppLoader.inline(size: _glyph)
            : Semantics(
                button: true,
                label: label,
                excludeSemantics: true,
                onTap: onTap,
                child: PressScale(
                  onTap: onTap,
                  pressedScale: AppMotion.pressedScaleSmall,
                  child: const Center(
                    child: HeroIcon(
                      HeroIcons.arrowUpStart,
                      size: _glyph,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
