import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/domain/entities/order_progress_entities.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/hero_icon.dart';

/// Under a line the picker replaced: "Replaced with Oat milk · 1 L", in the
/// deep brand green with the swap glyph, so the customer sees what came
/// instead without opening anything. One paragraph (the glyph is inline), so
/// a narrow column wraps it instead of overflowing.
class OrderLineSubstitutionNote extends StatelessWidget {
  const OrderLineSubstitutionNote({super.key, required this.substitution});

  final OrderSubstitutionEntity substitution;

  @override
  Widget build(BuildContext context) {
    final name = substitution.displayNameFor(context.locale.languageCode);
    return Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.s4),
              child: HeroIcon(
                HeroIcons.swapHorizontal,
                size: AppSize.s16,
                color: AppColors.brandDeep,
              ),
            ),
          ),
          TextSpan(
            // The name keeps its own direction inside the sentence.
            text: 'orders.line_replaced_with'.tr(
              namedArgs: {'name': Formatters.isolate(name)},
            ),
          ),
        ],
      ),
      style: AppTextStyles.label.copyWith(color: AppColors.brandDeep),
    );
  }
}
