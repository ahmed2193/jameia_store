import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/support_chat_message.dart';

/// One chat bubble with its time under it: the customer's at the end in the
/// brand colour, the rider's at the start in white.
class ImChatBubble extends StatelessWidget {
  const ImChatBubble({super.key, required this.message});

  final SupportChatMessage message;

  /// A bubble never takes more than this share of the screen width.
  static const double _maxWidthShare = 0.72;
  static const double _lineHeight = 1.35;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final maxWidth = MediaQuery.sizeOf(context).width * _maxWidthShare;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: mine
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s10,
              ),
              decoration: BoxDecoration(
                color: mine ? AppColors.chatBubbleMine : AppColors.white,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(AppSize.r8),
                  topEnd: const Radius.circular(AppSize.r8),
                  bottomStart: Radius.circular(mine ? AppSize.r8 : AppSize.r2),
                  bottomEnd: Radius.circular(mine ? AppSize.r2 : AppSize.r8),
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                  height: _lineHeight,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s4,
            ),
            child: Text(
              message.time,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
