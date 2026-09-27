import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_avatar.dart';
import 'assistant_tool_labels.dart';

/// The reply before its first word: pulsing dots + what the assistant is
/// doing ("Thinking", then the tool it runs, kept until the text starts —
/// live tools last milliseconds, N1). After [slowAfter] with no word yet it
/// says so.
class AssistantThinkingBubble extends StatefulWidget {
  const AssistantThinkingBubble({super.key, this.toolName});

  final String? toolName;

  static const Duration slowAfter = Duration(seconds: 10);

  @override
  State<AssistantThinkingBubble> createState() =>
      _AssistantThinkingBubbleState();
}

class _AssistantThinkingBubbleState extends State<AssistantThinkingBubble> {
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(AssistantThinkingBubble.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.toolName;
    final label =
        (_slow
                ? 'assistant.taking_longer'
                : tool == null
                ? 'assistant.thinking'
                : AssistantToolLabels.keyOf(tool))
            .tr();
    return Row(
      children: [
        const AssistantAvatar(mood: AssistantMascotMood.talking),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          child: Semantics(
            label: label,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(SuiRadius.bubble),
                ),
                boxShadow: AppShadows.low,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s10,
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RepaintBoundary(
                        child: BrandedDotLoader(
                          size: AppSize.s28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: MotionGuard.duration(
                            context,
                            AppMotion.fast,
                          ),
                          switchInCurve: AppMotion.signature,
                          child: Text(
                            label,
                            key: ValueKey(label),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.labelGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
