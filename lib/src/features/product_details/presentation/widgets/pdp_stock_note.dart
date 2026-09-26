import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';

/// How the stock of the selection stands, only when it matters: out of
/// stock (red) or running out ("Only 3 left", in the warning colour).
/// Nothing while there is plenty.
class PdpStockNote extends StatelessWidget {
  const PdpStockNote({super.key, required this.inStock, this.lowStockLeft});

  final bool inStock;

  /// Units left when they are running out, else `null`.
  final int? lowStockLeft;

  /// Whether the note has anything to say.
  static bool shows({required bool inStock, int? lowStockLeft}) =>
      !inStock || lowStockLeft != null;

  @override
  Widget build(BuildContext context) {
    final left = lowStockLeft;
    if (!shows(inStock: inStock, lowStockLeft: left)) {
      return const SizedBox.shrink();
    }
    final (icon, label, color) = !inStock
        ? (
            Icons.remove_circle_outline_rounded,
            'catalog.out_of_stock'.tr(),
            AppColors.error,
          )
        : (
            Icons.hourglass_bottom_rounded,
            'product.only_left'.tr(namedArgs: {'count': '$left'}),
            AppColors.warn,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSize.s16, color: color),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ),
      ],
    );
  }
}
