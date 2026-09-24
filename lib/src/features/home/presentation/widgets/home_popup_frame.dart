import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/responsive/app_size.dart';

/// Frame of a centred home popup: the content column with the round close
/// button floated above its top-end corner.
class HomePopupFrame extends StatelessWidget {
  const HomePopupFrame({super.key, required this.child, required this.onClose});

  static const double _width = AppSize.s320;
  static const double _closeLift = -AppSize.s44;

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
                child: GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Image.asset(
                    JameiaAssets.popupClose,
                    width: AppSize.s32,
                    height: AppSize.s32,
                    errorBuilder: (_, _, _) => Container(
                      width: AppSize.s32,
                      height: AppSize.s32,
                      decoration: const BoxDecoration(
                        color: AppColors.popupCloseScrim,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        JameiaIcons.close,
                        size: AppSize.s18,
                        color: AppColors.white,
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
