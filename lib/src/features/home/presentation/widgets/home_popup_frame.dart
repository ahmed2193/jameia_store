import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// Frame of a centred home popup: the content column with the round close
/// button floated above its top-end corner — a white Hero × on a black 60%
/// disc, so it reads (≥ 3:1) over the dark scrim and any card image alike.
class HomePopupFrame extends StatelessWidget {
  const HomePopupFrame({super.key, required this.child, required this.onClose});

  static const double _width = AppSize.s320;
  static const double _closeLift = -AppSize.s44;
  static const double _close = AppSize.s32;
  static const double _glyph = AppSize.s18;

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: _width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              PositionedDirectional(
                top: _closeLift,
                end: 0,
                child: Semantics(
                  button: true,
                  label: 'home.welcome_popup_close'.tr(),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.square(
                      dimension: _close,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.overlayPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: HeroIcon(
                          HeroIcons.close,
                          size: _glyph,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
