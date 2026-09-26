import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import 'assistant_cart_button.dart';
import 'assistant_chat_menu.dart';
import 'assistant_chat_title.dart';
import 'assistant_history_button.dart';

/// Chat app bar: avatar + title + live status, then history, the cart (the
/// fly-to-cart destination while the chat is open) and the overflow menu.
class AssistantChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AssistantChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: const AssistantChatTitle(),
      actions: const [
        AssistantHistoryButton(),
        AssistantCartButton(),
        AssistantChatMenu(),
        SizedBox(width: AppSpacing.s4),
      ],
    );
  }
}
