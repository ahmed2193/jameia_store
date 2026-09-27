import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// The two little circles under a thought bubble, stepping down towards the
/// mascot's head — what makes it read as a thought rather than speech. Each
/// grows with its own animation ([big], [small]), so the thought can rise
/// out of the mascot one circle at a time. The mascot is on the bubble's
/// right when [towardsRight].
class AssistantBuddyThoughtTrail extends StatelessWidget {
  const AssistantBuddyThoughtTrail({
    super.key,
    required this.towardsRight,
    required this.big,
    required this.small,
  });

  final bool towardsRight;
  final Animation<double> big;
  final Animation<double> small;

  static const double _big = AppSize.s9;
  static const double _small = AppSize.s5;

  /// From the bubble's mascot-side edge: the big circle sits a little
  /// inwards, the small one right over the head.
  static const double _bigInset = AppSize.s36;
  static const double _smallInset = AppSize.s30;
  static const BoxDecoration _dot = BoxDecoration(
    color: AppColors.white,
    shape: BoxShape.circle,
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandLightBg)),
    boxShadow: AppShadows.low,
  );

  EdgeInsets _inset(double inset) => towardsRight
      ? EdgeInsets.only(right: inset)
      : EdgeInsets.only(left: inset);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: towardsRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s2),
        Padding(
          padding: _inset(_bigInset),
          child: ScaleTransition(
            scale: big,
            child: const SizedBox.square(
              dimension: _big,
              child: DecoratedBox(decoration: _dot),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Padding(
          padding: _inset(_smallInset),
          child: ScaleTransition(
            scale: small,
            child: const SizedBox.square(
              dimension: _small,
              child: DecoratedBox(decoration: _dot),
            ),
          ),
        ),
      ],
    );
  }
}
