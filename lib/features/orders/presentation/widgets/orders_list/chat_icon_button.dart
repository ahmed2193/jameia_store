import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

// ── Rider chat icon button ────────────────────────────────────────────────────

class ChatIconButton extends StatelessWidget {
  const ChatIconButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Bundle: jad5b5 — 40×40dp, border-radius r4 (13dp), bg smallBackground #F0F1F5
    return Material(
      color: AppColors.smallBackground,
      borderRadius: BorderRadius.circular(AppRadius.r4), // 13dp rounded square
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r4),
        onTap: onPressed,
        child: const SizedBox(
          width: AppSpacing.s40,
          height: AppSpacing.s40,
          child: Icon(
            KeetaIcons.chatRider,
            size: 20,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
