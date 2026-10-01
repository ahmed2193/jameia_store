import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import 'live_map_camera_action.dart';

/// The live map's camera button, a white pill over the map's foot that
/// offers what the camera is not doing: "See the route" while it rides
/// along with the rider, "Follow the rider" once the customer took the map
/// or looks at the route; nothing while the camera frames the ride by
/// itself. It pops in and out and changes its words with a fade, keeping
/// the last ones while it goes. Hidden, it takes no taps and reads to
/// nobody.
class LiveMapCameraButton extends StatefulWidget {
  const LiveMapCameraButton({
    super.key,
    required this.action,
    required this.onPressed,
  });

  /// What a tap does; `null` hides the button.
  final LiveMapCameraAction? action;
  final ValueChanged<LiveMapCameraAction> onPressed;

  @override
  State<LiveMapCameraButton> createState() => _LiveMapCameraButtonState();
}

class _LiveMapCameraButtonState extends State<LiveMapCameraButton> {
  static const double _height = AppSize.s44;
  static const double _glyph = AppSize.s20;
  static const double _hiddenScale = 0.6;

  /// What the button shows: the action, or the last one while it goes.
  late LiveMapCameraAction _shown = widget.action ?? LiveMapCameraAction.follow;

  @override
  void didUpdateWidget(LiveMapCameraButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final action = widget.action;
    if (action != null) _shown = action;
  }

  void _tap() {
    final action = widget.action;
    if (action != null) widget.onPressed(action);
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.action != null;
    final duration = MotionGuard.duration(context, AppMotion.medium);
    final label = _shown.labelKey.tr();
    final face = FadeThroughSwitcher(
      stateKey: _shown,
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(_shown.icon, size: _glyph, color: AppColors.primaryText),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: AppMotion.signature,
          child: AnimatedScale(
            scale: visible ? 1 : _hiddenScale,
            duration: duration,
            curve: visible ? AppSprings.snappy : AppMotion.exit,
            child: Semantics(
              button: true,
              label: label,
              // Replaces the child's semantics, its tap action included.
              excludeSemantics: true,
              onTap: _tap,
              child: PressScale(
                onTap: _tap,
                pressedScale: AppMotion.pressedScaleSmall,
                child: Container(
                  height: _height,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.medium,
                  ),
                  child: duration == Duration.zero
                      ? face
                      : AnimatedSize(
                          duration: duration,
                          curve: AppMotion.signature,
                          alignment: AlignmentDirectional.centerEnd,
                          child: face,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
