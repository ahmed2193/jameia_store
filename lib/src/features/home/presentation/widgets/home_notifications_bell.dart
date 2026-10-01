import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import 'home_bell_ring.dart';

/// Notifications entry of the home header: a hairline-framed white disc with
/// a dark bell (it reads on the open header and on the pinned bar alike),
/// plus a red dot while there is anything unread — the bell swings when
/// something new comes in. The count lives in the inbox.
class HomeNotificationsBell extends StatelessWidget {
  const HomeNotificationsBell({
    super.key,
    required this.hasUnread,
    required this.onTap,
  });

  final bool hasUnread;
  final VoidCallback onTap;

  /// Disc diameter — the header reserves this much room for the bell.
  static const double discSize = AppSize.s40;
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
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Center(
                  child: HomeBellRing(
                    ringing: hasUnread,
                    child: const HeroIcon(
                      HeroIcons.bell,
                      size: AppSize.s22,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
              if (hasUnread)
                PositionedDirectional(
                  top: AppSpacing.s6,
                  end: AppSpacing.s6,
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
