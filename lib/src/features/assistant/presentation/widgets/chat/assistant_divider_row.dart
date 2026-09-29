import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// "New chat started": the server closed the thread and the conversation
/// continues in a new one from here. Inserted live ([animate], read once at
/// mount) it fades in over `fast` (docs/motion §9.6 §2.4); from history it
/// sits still.
class AssistantDividerRow extends StatefulWidget {
  const AssistantDividerRow({super.key, this.animate = false});

  final bool animate;

  @override
  State<AssistantDividerRow> createState() => _AssistantDividerRowState();
}

class _AssistantDividerRowState extends State<AssistantDividerRow> {
  late final bool _fades;

  @override
  void initState() {
    super.initState();
    _fades = widget.animate;
  }

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.divider, height: AppSize.s1),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
            ),
            child: Text(
              'assistant.new_chat_started'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.labelGrey,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.divider, height: AppSize.s1),
          ),
        ],
      ),
    );
    if (!_fades) return row;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      builder: (context, shown, child) => Opacity(opacity: shown, child: child),
      child: row,
    );
  }
}
