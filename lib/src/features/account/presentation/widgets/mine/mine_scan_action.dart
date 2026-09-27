import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_header_metrics.dart';

/// White round scan button at the end of the Mine header (open or
/// collapsed) → the delivery-code page. Same shape as the round back button
/// of the redesigned screens; it dips on touch and keeps a 48dp tap target.
class MineScanAction extends StatelessWidget {
  const MineScanAction({super.key});

  static const double _pressedScale = 0.9;
  static const double _glyph = AppSize.s22;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: _pressedScale,
      child: IconButton(
        tooltip: 'account.delivery_code'.tr(),
        onPressed: () => context.push(Routes.mineDeliveryCode),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(MineHeaderMetrics.action),
          minimumSize: const Size.square(MineHeaderMetrics.action),
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.divider),
        ),
        icon: Image.asset(
          HeroAssets.mineScanQrCode,
          width: _glyph,
          height: _glyph,
        ),
      ),
    );
  }
}
