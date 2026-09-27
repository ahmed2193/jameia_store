import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/hero_section_header.dart';

/// A titled block under the cart's lines ("Offers & options", "Payment
/// summary"): the group title, then [card] inside the gutter, easing to its
/// new height when a row grows or comes and goes.
class CartSection extends StatelessWidget {
  const CartSection({super.key, required this.title, required this.card});

  final String title;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroSectionHeader(title: title, titleStyle: AppTextStyles.groupTitle),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: AnimatedSize(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: AppMotion.signature,
            alignment: AlignmentDirectional.topCenter,
            child: card,
          ),
        ),
      ],
    );
  }
}
