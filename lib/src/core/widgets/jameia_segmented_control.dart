import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../motion/haptics.dart';
import '../motion/motion.dart';
import '../motion/spring_curve.dart';
import '../responsive/app_size.dart';
import 'jameia_segment.dart';

/// Pill SEGMENTED CONTROL with one dark thumb that glides (a calm spring,
/// [AppSprings.calm]) under the selected segment — the language switch in
/// settings, any two-to-four way choice. Equal-width segments share the
/// width; a selection haptic fires only when the value actually changes; the
/// thumb follows RTL. Reduced motion → the thumb jumps.
class JameiaSegmentedControl<T> extends StatelessWidget {
  const JameiaSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.height = AppSize.s44,
  });

  static const double _inset = AppSpacing.s4;

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;

  /// `null` = the whole control is disabled (e.g. while a change runs).
  final ValueChanged<T>? onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected);
    final change = onChanged;
    return Container(
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / values.length;
          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositionedDirectional(
                  duration: MotionGuard.duration(
                    context,
                    AppSprings.calm.duration,
                  ),
                  curve: AppSprings.calm,
                  start: width * index,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryText,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final value in values)
                    Expanded(
                      child: JameiaSegment(
                        label: labelOf(value),
                        selected: value == selected,
                        onTap: change == null
                            ? null
                            : () {
                                if (value == selected) return;
                                Haptics.selection();
                                change(value);
                              },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
