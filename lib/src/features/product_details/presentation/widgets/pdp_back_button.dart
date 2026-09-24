import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import 'pdp_circle_button.dart';

/// Leaves the product page. A disc over the photo instead of a bare arrow on
/// a white strip, so the chrome matches the rest of the storefront.
class PdpBackButton extends StatelessWidget {
  const PdpBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PdpCircleButton(
      onTap: () => context.pop(),
      semanticsLabel: 'common.back'.tr(),
      // Material flips the arrow for a right-to-left reading direction.
      child: const Icon(
        Icons.arrow_back,
        size: PdpCircleButton.glyphSize,
        color: AppColors.primaryText,
      ),
    );
  }
}
