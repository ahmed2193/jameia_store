import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_block.dart';

/// One question: tap to unfold its answer (chevron turns, the answer grows
/// in). Announced as expanded / collapsed.
class AssistantFaqRow extends StatefulWidget {
  const AssistantFaqRow({super.key, required this.item});

  final AssistantFaqItem item;

  @override
  State<AssistantFaqRow> createState() => _AssistantFaqRowState();
}

class _AssistantFaqRowState extends State<AssistantFaqRow> {
  bool _open = false;

  static const double _halfTurn = 0.5;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.s48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? _halfTurn : 0,
                    duration: MotionGuard.duration(context, AppMotion.medium),
                    curve: AppMotion.signature,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: AppSize.s22,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        CollapseReveal(
          visible: _open,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
            child: Text(
              item.answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
                height: AppSize.lh1_5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
