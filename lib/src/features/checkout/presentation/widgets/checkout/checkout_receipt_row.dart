import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';

/// One line of the receipt: the [label] at the start (+ an optional
/// [labelTrailing], the ⓘ), the [value] at the end, and under them an
/// optional grey [note] at the start and a [struck] was-value at the end.
/// The sub-line opens and closes with the data (never on mount).
///
/// 14 sp ink rows; [emphasized] is the 16 sp bold total. [value] is one
/// widget (a `JameiaMoneyText`, a `Text`, a switcher) and takes the row's
/// style from the surrounding [DefaultTextStyle].
class CheckoutReceiptRow extends StatelessWidget {
  const CheckoutReceiptRow({
    super.key,
    required this.label,
    required this.value,
    this.labelTrailing,
    this.note,
    this.struck,
    this.emphasized = false,
  });

  /// The label gets the larger share of the line; a value longer than its
  /// share (the total's "KD x off applied" at a large text size) wraps.
  static const int _labelFlex = 3;
  static const int _valueFlex = 2;

  final String label;
  final Widget value;
  final Widget? labelTrailing;
  final String? note;
  final Widget? struck;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.primaryText,
          )
        : AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText);
    final noteText = note;
    final struckValue = struck;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: _labelFlex,
                child: Row(
                  children: [
                    Flexible(child: Text(label, style: style)),
                    ?labelTrailing,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Flexible(
                flex: _valueFlex,
                child: DefaultTextStyle.merge(
                  style: style,
                  textAlign: TextAlign.end,
                  child: value,
                ),
              ),
            ],
          ),
          CollapseReveal(
            visible: noteText != null || struckValue != null,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: noteText == null
                        ? const SizedBox.shrink()
                        : Text(
                            noteText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                  ),
                  if (struckValue != null) ...[
                    const SizedBox(width: AppSpacing.s12),
                    DefaultTextStyle.merge(
                      style: AppTextStyles.bodySmall,
                      child: struckValue,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
