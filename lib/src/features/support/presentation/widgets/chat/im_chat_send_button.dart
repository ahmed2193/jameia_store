import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';

/// Send button — lit in the brand colour once there is text, grey otherwise.
/// Rebuilds off the field's value only (never the thread).
class ImChatSendButton extends StatelessWidget {
  const ImChatSendButton({
    super.key,
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final active = value.text.trim().isNotEmpty;
        return InkResponse(
          onTap: active ? () => onSend(controller.text) : null,
          radius: AppSize.s24,
          child: Container(
            width: AppSize.s40,
            height: AppSize.s40,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.divider,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              HeroIcons.arrowUp,
              size: AppSize.s20,
              color: active
                  ? AppColors.brandForeground
                  : AppColors.tertiaryText,
            ),
          ),
        );
      },
    );
  }
}
