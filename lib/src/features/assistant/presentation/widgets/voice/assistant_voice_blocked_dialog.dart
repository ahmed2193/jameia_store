import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../mascot/assistant_mascot_mood.dart';
import '../mascot/assistant_prop_scene.dart';

/// The microphone is blocked (WhatsApp's "allow access" prompt), through the
/// shared confirmation dialog: why it is needed and a way to the system
/// settings, where only the customer can allow it again.
abstract final class AssistantVoiceBlockedDialog {
  /// Asks, then opens the settings when the customer agrees.
  static Future<void> show(BuildContext context) async {
    final voice = context.read<AssistantVoiceCubit>();
    final settings = await showHeroConfirmDialog(
      context,
      title: 'assistant.voice.blocked_title'.tr(),
      message: 'assistant.voice.blocked_body'.tr(),
      art: const AssistantPropScene(
        prop: HeroAssets.assistantPropMic,
        mood: AssistantMascotMood.curious,
      ),
      confirmLabel: 'assistant.voice.open_settings'.tr(),
      cancelLabel: 'assistant.voice.not_now'.tr(),
    );
    if (settings) await voice.openSettings();
  }
}
