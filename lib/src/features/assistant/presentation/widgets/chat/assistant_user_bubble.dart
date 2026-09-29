import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_message_entity.dart';
import '../../../domain/entities/assistant_text_direction.dart';
import 'assistant_copy_sheet.dart';
import 'assistant_unsent_row.dart';

/// What the customer said: end-aligned, brand-tinted, in the direction of
/// its own words. A new bubble rises from the composer; an unsent one offers
/// a retry under it.
class AssistantUserBubble extends StatelessWidget {
  const AssistantUserBubble({
    super.key,
    required this.message,
    this.animate = false,
    this.canRetry = false,
  });

  final AssistantMessageEntity message;
  final bool animate;

  /// The unsent bubble is the last row and a message may go now.
  final bool canRetry;

  static const double _maxWidthFactor = 0.8;
  static const BorderRadiusDirectional _shape = BorderRadiusDirectional.only(
    topStart: Radius.circular(SuiRadius.bubble),
    topEnd: Radius.circular(SuiRadius.bubble),
    bottomStart: Radius.circular(SuiRadius.bubble),
    bottomEnd: Radius.circular(AppSize.r4),
  );

  @override
  Widget build(BuildContext context) {
    final rtl =
        AssistantTextDirection.isRtl(message.content) ??
        Directionality.of(context) == TextDirection.rtl;
    final failed = message.delivery == AssistantDelivery.failed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
          ),
          child: EntranceCascadeItem.single(
            play: animate,
            child: Semantics(
              container: true,
              label: 'assistant.you_said'.tr(),
              child: GestureDetector(
                onLongPress: () =>
                    AssistantCopySheet.show(context, message.content),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.brandLightBg,
                    borderRadius: _shape,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s10,
                    ),
                    child: Text(
                      message.content,
                      textDirection: rtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: AppTextStyles.bodyLarge.copyWith(
                        height: AppSize.lh1_5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Folds in over `fast` when the send is refused (docs/motion §9.6
        // §2.8), and away when a retry goes.
        CollapseReveal(
          visible: failed,
          duration: AppMotion.fast,
          alignment: AlignmentDirectional.topEnd,
          child: failed
              ? AssistantUnsentRow(draftKey: message.key, canRetry: canRetry)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
