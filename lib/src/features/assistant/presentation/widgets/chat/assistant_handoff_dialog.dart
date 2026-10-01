import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../mascot/assistant_mascot_mood.dart';
import '../mascot/assistant_prop_scene.dart';

/// "Talk to a person?" through the shared confirmation dialog: what happens,
/// where the answer comes, what to do meanwhile.
abstract final class AssistantHandoffDialog {
  /// Asks, then hands the chat off (the cubit guards a double submit).
  static Future<void> confirm(BuildContext context) async {
    final cubit = context.read<AssistantChatCubit>();
    final confirmed = await showHeroConfirmDialog(
      context,
      title: 'assistant.handoff_dialog_title'.tr(),
      message: 'assistant.handoff_dialog_body'.tr(),
      note: 'assistant.handoff_dialog_note'.tr(),
      art: const AssistantPropScene(
        prop: HeroAssets.assistantPropHandoff,
        mood: AssistantMascotMood.handingOver,
        directional: true,
      ),
      confirmLabel: 'assistant.talk_to_person'.tr(),
    );
    if (confirmed) await cubit.handOff();
  }
}
