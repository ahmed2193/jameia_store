import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// Notifications entry in the home hero: a white disc (reads on the orange
/// banner AND on the collapsed white bar) with a dark bell, plus a red dot
/// while there is anything unread. The count itself lives in the inbox.
class HomeNotificationsBell extends StatelessWidget {
  const HomeNotificationsBell({
    super.key,
    required this.hasUnread,
    required this.onTap,
  });

  final bool hasUnread;
  final VoidCallback onTap;

  /// Disc diameter — the header reserves this much room for the bell.
  static const double discSize = AppSize.s32;
  static const double _dot = AppSize.s8;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'notifications.title'.tr(),
      child: PressScale(
        onTap: onTap,
        child: SizedBox(
          width: discSize,
          height: discSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: AppSize.s20,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (hasUnread)
                PositionedDirectional(
                  top: AppSpacing.s2,
                  end: AppSpacing.s2,
                  child: PopScale.onMount(
                    child: Container(
                      width: _dot,
                      height: _dot,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.white, width: AppSize.s1),
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
