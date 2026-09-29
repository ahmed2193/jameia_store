import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';

/// "Thanks!" beside the thumbs after a rating (docs/motion §9.6 §2.10,
/// approval #12) — the proof next to the control, instead of a snack bar
/// away from it. A new [showKey] (a rating) fades it in over `fast`; it
/// stays [AppMotion.snackDwell], then fades out. A polite live region: a
/// screen reader hears it once. Nothing at rest.
class AssistantThanksNote extends StatefulWidget {
  const AssistantThanksNote({super.key, required this.showKey});

  /// Bumped on every rating; `0` = none yet.
  final int showKey;

  @override
  State<AssistantThanksNote> createState() => _AssistantThanksNoteState();
}

class _AssistantThanksNoteState extends State<AssistantThanksNote> {
  bool _shown = false;
  Timer? _dwell;

  @override
  void didUpdateWidget(AssistantThanksNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showKey == oldWidget.showKey || widget.showKey == 0) return;
    _shown = true;
    _dwell?.cancel();
    _dwell = Timer(AppMotion.snackDwell, () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionGuard.duration(context, AppMotion.fast),
      switchInCurve: AppMotion.signature,
      switchOutCurve: AppMotion.exit,
      child: _shown
          ? Semantics(
              key: const ValueKey<bool>(true),
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.s4),
                child: Text(
                  'assistant.feedback_thanks_short'.tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey<bool>(false)),
    );
  }
}
