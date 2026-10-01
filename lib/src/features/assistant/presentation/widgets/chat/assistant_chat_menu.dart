import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../onboarding/assistant_onboarding_sheet.dart';
import 'assistant_handoff_dialog.dart';

enum _MenuItem { tour, newChat, handOff }

/// The overflow menu: what the assistant can do (its tour again — a
/// question picked there is sent right away), start a new chat (the current
/// one stays in history), or hand the chat to a person when the
/// conversation allows it.
class AssistantChatMenu extends StatelessWidget {
  const AssistantChatMenu({super.key});

  void _onSelected(BuildContext context, _MenuItem item) {
    switch (item) {
      case _MenuItem.tour:
        _replayTour(context);
      case _MenuItem.newChat:
        context.read<AssistantChatCubit>().startNewChat();
        showHeroSnackBar(context, 'assistant.new_chat_started'.tr());
      case _MenuItem.handOff:
        AssistantHandoffDialog.confirm(context);
    }
  }

  Future<void> _replayTour(BuildContext context) async {
    final chat = context.read<AssistantChatCubit>();
    final result = await AssistantOnboardingSheet.show(context);
    final starter = result?.starter;
    if (starter != null && chat.state.canSend) {
      chat.send(starter.promptKey.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final (canStartNew, canHandOff) = context
        .select<AssistantChatCubit, (bool, bool)>(
          (cubit) => (
            !cubit.state.isWelcome && !cubit.state.isStreaming,
            cubit.state.canHandOff,
          ),
        );
    return PopupMenuButton<_MenuItem>(
      tooltip: 'assistant.more'.tr(),
      icon: const HeroIcon(
        HeroIcons.moreVertical,
        size: AppSize.s24,
        color: AppColors.primaryText,
      ),
      color: AppColors.white,
      onSelected: (item) => _onSelected(context, item),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MenuItem.tour,
          child: Text('assistant.menu_tour'.tr()),
        ),
        PopupMenuItem(
          value: _MenuItem.newChat,
          enabled: canStartNew,
          child: Text('assistant.new_chat'.tr()),
        ),
        PopupMenuItem(
          value: _MenuItem.handOff,
          enabled: canHandOff,
          child: Text('assistant.talk_to_person'.tr()),
        ),
      ],
    );
  }
}
