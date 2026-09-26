import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_cart_links.dart';

/// A confirmed proposal: the confirm reply's own words ([message], shown as
/// sent) and the cart one tap away. [message] exists only for a confirm made
/// in this session: then the check pops in and a screen reader hears it;
/// a proposal confirmed earlier (history) sits still.
class AssistantCartActionDone extends StatelessWidget {
  const AssistantCartActionDone({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final justConfirmed = text != null;
    const check = Icon(
      Icons.check_circle_rounded,
      size: AppSize.s20,
      color: AppColors.success,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (justConfirmed) const PopScale.onMount(child: check) else check,
            const SizedBox(width: AppSpacing.s6),
            Expanded(
              child: Semantics(
                liveRegion: justConfirmed,
                child: Text(
                  text == null || text.isEmpty
                      ? 'assistant.action_confirmed'.tr()
                      : text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        // The next step is one tap away.
        const AssistantCartLinks(),
      ],
    );
  }
}
