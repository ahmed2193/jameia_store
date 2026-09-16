import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'tracking_helpers.dart';

/// Summary row whose value can be copied to the clipboard (feature #8).
class CopyableLine extends StatelessWidget {
  const CopyableLine({
    super.key,
    required this.label,
    required this.value,
    required this.copyValue,
  });
  final String label;
  final String value;
  final String copyValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(value, style: AppTextStyles.bodyLarge),
        const SizedBox(width: AppSpacing.s8),
        GestureDetector(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: copyValue));
            if (context.mounted) {
              trackingToast(context, 'orders.order_id_copied'.tr());
            }
          },
          child: const Icon(
            KeetaIcons.confirmReceipt,
            size: 16,
            color: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}
