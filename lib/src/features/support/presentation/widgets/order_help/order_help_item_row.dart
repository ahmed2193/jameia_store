import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_line_entity.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_line_thumb.dart';
import '../../cubit/order_help_cubit.dart';
import 'order_help_check_box.dart';

/// One item of the order in "Which items?": its photo, name (and variant),
/// the quantity bought, and a box the customer ticks. It selects its own
/// tick, so a tap rebuilds this row only. Announced as a checkbox.
class OrderHelpItemRow extends StatelessWidget {
  const OrderHelpItemRow({super.key, required this.line});

  final OrderLineEntity line;

  static const int _nameLines = 2;

  void _toggle(BuildContext context) {
    Haptics.pick();
    context.read<OrderHelpCubit>().toggleProduct(line.productId);
  }

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final checked = context.select<OrderHelpCubit, bool>(
      (cubit) => cubit.state.request.productIds.contains(line.productId),
    );
    final variant = line.variantNameFor(lc);
    return MergeSemantics(
      child: Semantics(
        checked: checked,
        child: InkWell(
          onTap: () => _toggle(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.s56),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                children: [
                  HeroLineThumb(url: line.image, size: AppSize.s40),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          line.nameFor(lc),
                          style: AppTextStyles.itemTitle,
                          maxLines: _nameLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (variant.isNotEmpty)
                          Text(
                            variant,
                            style: AppTextStyles.meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'support.help_item_quantity'.tr(
                      namedArgs: {'count': '${line.quantity}'},
                    ),
                    style: AppTextStyles.meta,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  OrderHelpCheckBox(checked: checked),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
