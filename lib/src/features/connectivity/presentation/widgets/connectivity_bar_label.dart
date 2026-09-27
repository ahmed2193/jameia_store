import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../cubit/connectivity_banner_mode.dart';

/// The banner's text block: "You're offline" over "Showing what you last
/// saw" ("Reconnecting…" while a check runs), or the single "Back online"
/// line. Wraps at large text sizes, then ellipsizes.
class ConnectivityBarLabel extends StatelessWidget {
  const ConnectivityBarLabel({super.key, required this.mode});

  final ConnectivityBannerMode mode;

  static const int _maxLines = 2;
  static const double _subtitleAlpha = 0.78;

  @override
  Widget build(BuildContext context) {
    final title = AppTextStyles.label.copyWith(color: AppColors.white);
    if (mode == ConnectivityBannerMode.backOnline) {
      return Text(
        'connectivity.back_online'.tr(),
        maxLines: _maxLines,
        overflow: TextOverflow.ellipsis,
        style: title,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mode == ConnectivityBannerMode.reconnecting
              ? 'connectivity.reconnecting'.tr()
              : 'connectivity.offline_title'.tr(),
          maxLines: _maxLines,
          overflow: TextOverflow.ellipsis,
          style: title,
        ),
        Text(
          'connectivity.offline_subtitle'.tr(),
          maxLines: _maxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.white.withValues(alpha: _subtitleAlpha),
          ),
        ),
      ],
    );
  }
}
