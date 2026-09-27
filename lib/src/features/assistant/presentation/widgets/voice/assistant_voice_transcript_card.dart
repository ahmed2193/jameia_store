import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_text_direction.dart';

/// The live words, shaped like the customer's own bubble (end side, brand
/// tint) with a live mark: "Listening…" until the first word, then the
/// latest lines, scrolled to the newest; dimmed while the message goes.
class AssistantVoiceTranscriptCard extends StatelessWidget {
  const AssistantVoiceTranscriptCard({
    super.key,
    required this.transcript,
    required this.finishing,
  });

  final String transcript;

  /// The last words are coming in: the message is on its way.
  final bool finishing;

  static const double _maxWidthFactor = 0.8;

  /// About four lines; older words scroll away above.
  static const double _maxHeight = AppSize.s110;

  static const double _borderAlpha = 0.35;
  static const double _finishingOpacity = 0.6;

  static const BorderRadiusDirectional _shape = BorderRadiusDirectional.only(
    topStart: Radius.circular(SuiRadius.bubble),
    topEnd: Radius.circular(SuiRadius.bubble),
    bottomStart: Radius.circular(SuiRadius.bubble),
    bottomEnd: Radius.circular(AppSize.r4),
  );

  @override
  Widget build(BuildContext context) {
    final waiting = transcript.isEmpty;
    final rtl =
        AssistantTextDirection.isRtl(transcript) ??
        Directionality.of(context) == TextDirection.rtl;
    return AnimatedOpacity(
      duration: MotionGuard.duration(context, AppMotion.fast),
      opacity: finishing ? _finishingOpacity : 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
          maxHeight: _maxHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandLightBg,
            borderRadius: _shape,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: _borderAlpha),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: AppSize.s18,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      waiting ? 'assistant.voice.listening'.tr() : transcript,
                      textDirection: waiting
                          ? null
                          : (rtl ? TextDirection.rtl : TextDirection.ltr),
                      style: AppTextStyles.bodyLarge.copyWith(
                        height: AppSize.lh1_5,
                        color: waiting
                            ? AppColors.secondaryText
                            : AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
