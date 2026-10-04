import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/order_line_entity.dart';
import '../../../../core/domain/entities/order_progress_entities.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/hero_money_text.dart';
import '../../../../core/widgets/hero_tag.dart';
import '../../domain/entities/order_line_changes.dart';
import 'order_line_layout.dart';
import 'order_line_substitution_note.dart';

/// One ordered line: the photo (when [showThumb]), the quantity (`2×`), the
/// name and variant, the unit price when [showUnitPrice] and more than one
/// was bought ("KD 0.899 each", the invoice), what picking did to it (an
/// "Unavailable" tag with the name and price struck through, or "Replaced
/// with …"), and the line total as the server priced it.
class OrderLineRow extends StatelessWidget {
  const OrderLineRow({
    super.key,
    required this.line,
    this.showThumb = false,
    this.showUnitPrice = false,
    this.outcome = OrderLineOutcome.kept,
    this.substitution,
  });

  final OrderLineEntity line;
  final bool showThumb;
  final bool showUnitPrice;
  final OrderLineOutcome outcome;
  final OrderSubstitutionEntity? substitution;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final substitution = this.substitution;
    final unavailable = outcome == OrderLineOutcome.unavailable;
    return OrderLineLayout(
      quantity: line.quantity,
      name: line.nameFor(lc),
      subtitle: line.variantNameFor(lc),
      caption: showUnitPrice && line.quantity > 1
          ? 'orders.invoice_each'.tr(
              namedArgs: {'price': Formatters.priceInline(line.unitPriceKd)},
            )
          : '',
      thumbUrl: showThumb ? line.image : null,
      struck: outcome != OrderLineOutcome.kept,
      note: switch (outcome) {
        OrderLineOutcome.kept => null,
        OrderLineOutcome.unavailable => Align(
          alignment: AlignmentDirectional.centerStart,
          child: HeroTag(
            label: 'orders.line_unavailable'.tr(),
            tone: HeroTagTone.error,
          ),
        ),
        OrderLineOutcome.substituted =>
          substitution == null
              ? null
              : OrderLineSubstitutionNote(substitution: substitution),
      },
      // What the picker could not find is not part of the order any more:
      // its price is struck like its name.
      trailing: HeroMoneyText(
        kd: line.lineTotalKd,
        style: AppTextStyles.itemTitle,
        color: unavailable ? AppColors.secondaryText : null,
        strike: unavailable,
      ),
    );
  }
}
