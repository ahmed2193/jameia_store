import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/phone_number.dart';
import '../../../../../core/widgets/jameia_outlined_box.dart';

/// Country-code selector box (flag + dial code + caret). Kuwait only.
class LoginCountryCodeBox extends StatelessWidget {
  const LoginCountryCodeBox({super.key});

  @override
  Widget build(BuildContext context) {
    return JameiaOutlinedBox(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(PhoneNumber.kuwaitFlag, style: AppTextStyles.headingSmall),
          const SizedBox(width: AppSpacing.s6),
          Text(
            PhoneNumber.kuwaitDialCode,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Image.asset(
            JameiaAssets.loginArrowDown,
            width: AppSize.s12,
            height: AppSize.s12,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
