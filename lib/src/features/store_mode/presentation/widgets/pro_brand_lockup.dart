import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion_widgets.dart';
import 'pro_lockup_block.dart';

/// "Hero | Pro" wordmark: the brand name on Hero green beside the Pro
/// badge on the Pro gradient (mirrored in RTL, so it still reads
/// brand-first). Pops in once when the page opens.
class ProBrandLockup extends StatelessWidget {
  const ProBrandLockup({super.key});

  static const LinearGradient _proGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: AppColors.proGradient,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'pro.title'.tr(),
      excludeSemantics: true,
      child: PopScale.onMount(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s4,
          children: [
            ProLockupBlock(
              label: 'pro.brand_name'.tr(),
              color: AppColors.primary,
            ),
            ProLockupBlock(
              label: 'pro.badge'.tr(),
              color: AppColors.accentViolet,
              gradient: _proGradient,
            ),
          ],
        ),
      ),
    );
  }
}
