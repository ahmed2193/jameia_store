import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/faq_item.dart';
import 'support_faq_answer.dart';
import 'support_faq_chevron.dart';

/// One expandable topic: the question header toggles the answer below it.
class SupportFaqTile extends StatelessWidget {
  const SupportFaqTile({
    super.key,
    required this.index,
    required this.faq,
    required this.expanded,
  });

  /// This topic's index in the full list.
  final int index;
  final FaqItem faq;

  /// The open topic's index (-1 == none).
  final ValueNotifier<int> expanded;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: expanded,
      builder: (context, current, _) {
        final isOpen = current == index;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              PressScale(
                // The InkWell keeps the gesture, ripple and expand toggle.
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () => expanded.value = isOpen ? -1 : index,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s14),
                    child: Row(
                      children: [
                        const HeroIcon(
                          HeroIcons.help,
                          size: AppSize.s18,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: AppSpacing.s10),
                        Expanded(
                          child: Text(
                            faq.questionKey.tr(),
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        SupportFaqChevron(open: isOpen),
                      ],
                    ),
                  ),
                ),
              ),
              // Opens medium, closes fast; the answer stays drawn while it
              // closes (§9.4 #20).
              CollapseReveal(
                visible: isOpen,
                child: SupportFaqAnswer(answerKey: faq.answerKey),
              ),
            ],
          ),
        );
      },
    );
  }
}
