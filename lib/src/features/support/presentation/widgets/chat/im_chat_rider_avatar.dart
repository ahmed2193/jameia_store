import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The rider's round avatar in the chat's title bar: the delivery glyph on a
/// muted disc.
class ImChatRiderAvatar extends StatelessWidget {
  const ImChatRiderAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSize.s36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.smallBackground,
            shape: BoxShape.circle,
          ),
          child: HeroIcon(
            HeroIcons.delivery,
            size: AppSize.s20,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
