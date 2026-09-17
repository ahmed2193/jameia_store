import 'package:flutter/material.dart';

import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../config/theme/app_colors.dart';

/// Shared frame for Jameia centered home popups (`mkt_resources_*` modals).
/// A 327dp-wide content area with the close button floated above its top-end
/// (real atom: `icon_fall_sky_close_monzly` 32dp). The scrim (`#000000bf`) and
/// slide-in/fade transition are applied by [showJameiaPopup].
class JameiaPopupScaffold extends StatelessWidget {
  const JameiaPopupScaffold({
    super.key,
    required this.child,
    required this.onClose,
    this.width = 327,
  });

  final Widget child;
  final VoidCallback onClose;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            PositionedDirectional(
              top: -44,
              end: 0,
              child: GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Image.asset(
                  JameiaAssets.popupClose,
                  width: 32,
                  height: 32,
                  errorBuilder: (_, _, _) => Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.popupCloseScrim,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      JameiaIcons.close,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Present a Jameia popup with the standard scrim + bottom-slide-in/fade entry
/// (`popup_list_main` `f8c3c0`: bottom −1000→0, opacity 0→1, ~350ms).
Future<T?> showJameiaPopup<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'popup',
    barrierColor: AppColors.popupScrim, // #000000bf
    // One motion reference: Jameia popup enter = [AppMotion.popup] (~350ms) fade +
    // short [AppMotion.popupSlideBegin] lift on the [AppMotion.signature] ease-out.
    transitionDuration: MotionGuard.duration(context, AppMotion.popup),
    // Wrap in a transparent Material so descendant Text inherits a proper text
    // style (no yellow debug underline) and ink effects work.
    pageBuilder: (ctx, _, _) =>
        Material(type: MaterialType.transparency, child: builder(ctx)),
    transitionBuilder: (ctx, anim, _, child) {
      if (MotionGuard.reduced(ctx)) return child;
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.signature);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: AppMotion.popupSlideBegin,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
