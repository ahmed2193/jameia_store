import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// A round grey icon button of the composer.
class ImChatIconCircle extends StatelessWidget {
  const ImChatIconCircle({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: AppSize.s24,
      child: Container(
        width: AppSize.s40,
        height: AppSize.s40,
        decoration: const BoxDecoration(
          color: AppColors.mediumBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: HeroIcon(
          icon,
          size: AppSize.s20,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
