import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import 'im_chat_icon_circle.dart';
import 'im_chat_send_button.dart';

/// The input bar: attach (a snack bar offline), a growing text field and the
/// send button.
class ImChatComposer extends StatelessWidget {
  const ImChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  static const int _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.s12,
        end: AppSpacing.s12,
        top: AppSpacing.s8,
        bottom: AppSpacing.s8 + bottomPad,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ImChatIconCircle(
            icon: HeroIcons.camera,
            onTap: () => showHeroSnackBar(context, 'support.attach_photo'.tr()),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.mediumBackground,
                borderRadius: BorderRadius.circular(AppRadius.r2),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: _maxLines,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'support.message_hint'.tr(),
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          ImChatSendButton(controller: controller, onSend: onSend),
        ],
      ),
    );
  }
}
