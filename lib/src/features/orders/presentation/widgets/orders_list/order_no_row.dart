import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

// ── Order-number row (tap-to-copy) ────────────────────────────────────────────

class OrderNoRow extends StatelessWidget {
  const OrderNoRow({super.key, required this.orderId});

  final String orderId;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: orderId));
    // Bundle deep-dive § 2.2: copy-order-no toast — confirm with a snackbar.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('orders.order_id_copied'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copy(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Bundle: Jameia-Regular 12dp tertiary meta line for the order number.
          Flexible(
            child: Text(
              'orders.order_no'.tr(namedArgs: {'id': orderId}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.tertiaryText,
                fontWeight: AppTextStyles.regular,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s6),
          // Tap-to-copy affordance (link blue), per copy-order-no interaction.
          Text(
            'orders.copy'.tr(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.link,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ],
      ),
    );
  }
}
