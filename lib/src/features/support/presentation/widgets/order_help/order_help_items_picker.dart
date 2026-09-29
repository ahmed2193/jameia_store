import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_line_entity.dart';
import 'order_help_item_row.dart';

/// "Which items?" under an issue that needs them (missing, wrong, damaged
/// …): the order's items on a soft panel, each with a box to tick. Built
/// only while its issue is chosen (the reveal drops it once folded).
class OrderHelpItemsPicker extends StatelessWidget {
  const OrderHelpItemsPicker({super.key, required this.lines});

  final List<OrderLineEntity> lines;

  static const BoxDecoration _panel = BoxDecoration(
    color: AppColors.smallBackground,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: DecoratedBox(
        decoration: _panel,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s4,
                ),
                child: Text(
                  'support.help_items_hint'.tr(),
                  style: AppTextStyles.meta,
                ),
              ),
              for (final line in lines)
                OrderHelpItemRow(key: ValueKey<String>(line.key), line: line),
            ],
          ),
        ),
      ),
    );
  }
}
