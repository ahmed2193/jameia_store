import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'pulse_node.dart';

class StepNode extends StatelessWidget {
  const StepNode({
    super.key,
    required this.label,
    required this.node,
    required this.done,
    required this.active,
    required this.leftDone,
    required this.rightDone,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final String node;
  final bool done;
  final bool active;
  final bool leftDone;
  final bool rightDone;
  final bool isFirst;
  final bool isLast;

  // Real connector color from bundle: AppColors.trackingLineTodo #DEDFE4
  // (inactive), primary (active/done).

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Node row: 30dp height, connectors on left/right, node centered.
        SizedBox(
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Connector lines — full-width row, half left / half right.
              PositionedDirectional(
                start: 0,
                end: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSize.r2),
                          bottomLeft: Radius.circular(AppSize.r2),
                        ),
                        child: SizedBox(
                          height: 4,
                          child: ColoredBox(
                            color: isFirst
                                ? AppColors.white
                                : (leftDone
                                      ? AppColors.primary
                                      : AppColors.trackingLineTodo),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(AppSize.r2),
                          bottomRight: Radius.circular(AppSize.r2),
                        ),
                        child: SizedBox(
                          height: 4,
                          child: ColoredBox(
                            color: isLast
                                ? AppColors.white
                                : (rightDone
                                      ? AppColors.primary
                                      : AppColors.trackingLineTodo),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Animated node — 30×30dp, radius=10dp per c33ae0. The CURRENT
              // step gently pulses (scale/glow) to read as "live"; completed
              // steps sit static-filled, upcoming ones stay empty.
              PulseNode(
                active: active,
                child: AnimatedContainer(
                  duration: MotionGuard.duration(context, AppMotion.medium),
                  curve: AppMotion.standard,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : AppColors.smallBackground,
                    borderRadius: BorderRadius.circular(AppRadius.r5), // 10dp
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? Image.asset(
                          node,
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            KeetaIcons.confirm,
                            size: 16,
                            color: AppColors.black,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        // Label — margin-bottom 6dp per f11ae6
        const SizedBox(height: AppSpacing.s6),
        Text(
          label.tr(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionSmall.copyWith(
            color: done ? AppColors.primaryText : AppColors.tertiaryText,
            fontWeight: active ? AppTextStyles.bold : AppTextStyles.regular,
          ),
        ),
      ],
    );
  }
}
