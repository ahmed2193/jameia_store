import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'im_chat_quick_reply_chip.dart';

/// The row of canned replies above the composer; a tap sends the reply.
class ImChatQuickReplyRow extends StatelessWidget {
  const ImChatQuickReplyRow({
    super.key,
    required this.replies,
    required this.onTap,
  });

  final List<String> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.s40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, i) =>
            ImChatQuickReplyChip(label: replies[i], onTap: onTap),
      ),
    );
  }
}
