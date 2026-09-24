import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_menu_cell.dart';

/// The delivery-code card: its own white card with a dark pill showing the
/// code (bundle `d16a98`: 26dp tall, pill radius, #222222; `fe6d54` 12dp
/// white text).
class MineDeliveryCodeCell extends StatelessWidget {
  const MineDeliveryCodeCell({super.key, required this.code});

  /// Placeholder while no code is set.
  static const String _noCode = '— — — —';

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: MineMenuCell(
        icon: JameiaIcons.confirmReceipt,
        label: 'account.delivery_code'.tr(),
        onTap: () => context.push(Routes.mineDeliveryCode),
        trailing: Container(
          height: AppSize.s26,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryText,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            code.isEmpty ? _noCode : code,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white,
              letterSpacing: AppSize.s1_5,
            ),
          ),
        ),
      ),
    );
  }
}
