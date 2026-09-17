import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Scan-QR affordance in the Mine header (bundle `c04204`: 28×28dp, 4dp side
/// margins) → the delivery-code page.
class MineScanQrButton extends StatelessWidget {
  const MineScanQrButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s4,
        ),
        child: Image.asset(
          JameiaAssets.mineScanQrCode,
          width: AppSize.s28,
          height: AppSize.s28,
        ),
      ),
    );
  }
}
