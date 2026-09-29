import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../mascot/assistant_mascot_mood.dart';
import '../mascot/assistant_prop_scene.dart';

/// The microphone is blocked (WhatsApp's "allow access" prompt): why it is
/// needed and a way to the system settings, where only the customer can
/// allow it again. Pops `true` for the settings.
class AssistantVoiceBlockedDialog extends StatelessWidget {
  const AssistantVoiceBlockedDialog({super.key});

  /// Asks, then opens the settings when the customer agrees.
  static Future<void> show(BuildContext context) async {
    final voice = context.read<AssistantVoiceCubit>();
    final settings = await showHeroDialog<bool>(
      context,
      barrierLabel: 'assistant.voice.blocked_title'.tr(),
      barrierColor: AppColors.overlayPrimary,
      pageBuilder: (_) => const AssistantVoiceBlockedDialog(),
    );
    if (settings ?? false) await voice.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s24,
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSize.r8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AssistantPropScene(
                  prop: HeroAssets.assistantPropMic,
                  mood: AssistantMascotMood.curious,
                ),
                const SizedBox(height: AppSpacing.s12),
                Semantics(
                  header: true,
                  child: Text(
                    'assistant.voice.blocked_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'assistant.voice.blocked_body'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.s20),
                AppButton(
                  label: 'assistant.voice.open_settings'.tr(),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.s8),
                AppOutlineButton(
                  label: 'assistant.voice.not_now'.tr(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
