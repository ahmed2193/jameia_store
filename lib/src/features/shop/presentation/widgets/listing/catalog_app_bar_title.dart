import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';

/// The catalogue app bar's title, which fades across when it changes (a
/// category page names its tree once the tree loads).
class CatalogAppBarTitle extends StatelessWidget {
  const CatalogAppBarTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionGuard.duration(context, AppMotion.medium),
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: Text(
        title,
        key: ValueKey<String>(title),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headingLarge.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
