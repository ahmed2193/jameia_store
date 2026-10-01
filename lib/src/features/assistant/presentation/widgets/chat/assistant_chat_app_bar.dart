import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/hero_title_bar.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_cart_button.dart';
import 'assistant_chat_header_avatar.dart';
import 'assistant_chat_menu.dart';
import 'assistant_history_button.dart';

/// The status line under the title.
enum _Status { ready, typing, support }

/// Chat title bar (the shared [HeroTitleBar]): the avatar (its moods follow
/// the chat), "Hero Assistant" and a status line that flips between
/// "Products, offers…", "Typing…" while a reply streams and "With support"
/// once a person has the chat; then history, the cart (the fly-to-cart
/// destination while the chat is open) and the overflow menu. (Screen
/// readers hear the reply through the page's announcements, not this bar.)
class AssistantChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AssistantChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(HeroTitleBar.height);

  @override
  Widget build(BuildContext context) {
    final status = context.select<AssistantChatCubit, _Status>((cubit) {
      final state = cubit.state;
      if (state.isStreaming) return _Status.typing;
      if (state.thread.isHandedOff) return _Status.support;
      return _Status.ready;
    });
    return HeroTitleBar(
      title: 'assistant.title'.tr(),
      subtitle: switch (status) {
        _Status.typing => 'assistant.subtitle_typing',
        _Status.support => 'assistant.status_handed_off',
        _Status.ready => 'assistant.subtitle_ready',
      }.tr(),
      titleLeading: const AssistantChatHeaderAvatar(),
      actions: const [
        AssistantHistoryButton(),
        AssistantCartButton(),
        AssistantChatMenu(),
      ],
    );
  }
}
