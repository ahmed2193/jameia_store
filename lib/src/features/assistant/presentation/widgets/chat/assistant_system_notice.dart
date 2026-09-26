import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/assistant_message_entity.dart';

/// A `system` message (e.g. a support note): a centred muted line, shown as
/// sent.
class AssistantSystemNotice extends StatelessWidget {
  const AssistantSystemNotice({super.key, required this.message});

  final AssistantMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final text = message.hasText
        ? message.richText.plainText
        : message.content.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s4,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.captionLarge.copyWith(color: AppColors.labelGrey),
      ),
    );
  }
}
