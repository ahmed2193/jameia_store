import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The caret after the letters the mascot is typing: a short rounded bar in
/// the brand colour that takes no room in the line (so nothing shifts as it
/// moves) and fades away once the line is typed ([visible] false).
class AssistantBuddyTypingCaret extends StatelessWidget {
  const AssistantBuddyTypingCaret({
    super.key,
    required this.visible,
    required this.height,
  });

  final bool visible;
  final double height;

  static const double _width = AppSize.s2;
  static const double _gap = AppSize.s1;
  static const BoxDecoration _bar = BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.all(Radius.circular(AppSize.r1)),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: height,
      child: OverflowBox(
        minWidth: 0,
        maxWidth: _gap + _width,
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: MotionGuard.duration(context, AppMotion.medium),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: _gap),
            child: SizedBox(
              width: _width,
              height: height,
              child: const DecoratedBox(decoration: _bar),
            ),
          ),
        ),
      ),
    );
  }
}
