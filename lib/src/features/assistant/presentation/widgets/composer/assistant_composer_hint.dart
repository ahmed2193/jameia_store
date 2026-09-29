import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/rotating_line.dart';

/// The empty composer's placeholder: it cycles through example questions
/// ("Try: eggs and milk for breakfast") so the customer sees what to ask,
/// on the app's one ticker ([RotatingLine]: every `AppMotion.carousel` the
/// next example rises into place as the last leaves above). Rotating is
/// ambient motion: it rests under a covered route (the chat behind a sheet
/// or a pushed page), off screen, in the background, under reduced motion
/// (one example, still) and after the ambient budget. Screen readers get the
/// plain hint.
class AssistantComposerHint extends StatelessWidget {
  const AssistantComposerHint({super.key});

  static const List<String> examples = [
    'assistant.composer_try_breakfast',
    'assistant.composer_try_offers',
    'assistant.composer_try_dinner',
    'assistant.composer_try_delivery',
  ];

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.tertiaryText,
    );
    return Semantics(
      label: 'assistant.composer_hint'.tr(),
      excludeSemantics: true,
      child: RotatingLine(
        items: [
          for (final key in examples)
            RotatingLineItem(
              id: key,
              child: Text(
                key.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}
