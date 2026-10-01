import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/assistant_text_direction.dart';
import '../assistant_word_reveal.dart';

/// The live words, shaped like the customer's own bubble (end side, brand
/// tint) with a live mark: "Listening…" until the first word, then the
/// latest lines, scrolled to the newest (docs/motion §9.6 §2.9). New
/// trailing words fade in by the word reveal's local pace, append-only — a
/// word the recogniser rewrites swaps without a fade, so corrections never
/// flicker — and the card's height eases over `medium`. While the message
/// goes, the words dim by a colour tween (no opacity layer).
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
    final base = AppTextStyles.bodyLarge.copyWith(height: AppSize.lh1_5);
    final Widget words = waiting
        ? Text(
            'assistant.voice.listening'.tr(),
            style: base.copyWith(color: AppColors.secondaryText),
          )
        : AnimatedDefaultTextStyle(
            duration: MotionGuard.duration(context, AppMotion.fast),
            style: base.copyWith(
              color: finishing ? AppColors.labelGrey : AppColors.primaryText,
            ),
            child: AssistantWordReveal(
              text: transcript,
              // Colour from the dimming style above.
              style: const TextStyle(),
              appendOnly: true,
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          );
    final card = ConstrainedBox(
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
              const HeroIcon(
                HeroIcons.waveform,
                size: AppSize.s18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.s8),
              Flexible(
                child: SingleChildScrollView(reverse: true, child: words),
              ),
            ],
          ),
        ),
      ),
    );
    // An AnimatedSize with no duration re-dirties itself in its own layout:
    // under reduced motion the card simply takes its new size.
    final grow = MotionGuard.duration(context, AppMotion.medium);
    if (grow == Duration.zero) return card;
    return AnimatedSize(
      duration: grow,
      curve: AppMotion.signature,
      alignment: AlignmentDirectional.bottomEnd,
      child: card,
    );
  }
}
