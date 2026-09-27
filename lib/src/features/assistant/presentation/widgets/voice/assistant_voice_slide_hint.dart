import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_voice_drag.dart';

/// "‹ Slide to cancel": it moves with the finger toward the start of the
/// line and fades out as the finger nears the cancel line.
class AssistantVoiceSlideHint extends StatelessWidget {
  const AssistantVoiceSlideHint({super.key, required this.drag});

  final ValueListenable<AssistantVoiceDrag> drag;

  /// Share of the finger's travel the hint follows.
  static const double _follow = 0.5;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final hint = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.chevron_left_rounded,
          size: AppSize.s20,
          color: AppColors.secondaryText,
        ),
        Flexible(
          child: Text(
            'assistant.voice.slide_to_cancel'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
    return ValueListenableBuilder<AssistantVoiceDrag>(
      valueListenable: drag,
      builder: (context, value, child) {
        final along = value.towardStart * _follow;
        return Opacity(
          opacity: 1 - value.cancelProgress,
          child: Transform.translate(
            offset: Offset(rtl ? along : -along, 0),
            child: child,
          ),
        );
      },
      child: hint,
    );
  }
}
