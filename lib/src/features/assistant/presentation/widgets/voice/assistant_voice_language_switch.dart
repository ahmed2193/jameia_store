import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_voice_language.dart';
import '../../cubit/assistant_voice_cubit.dart';

/// The language the customer is heard in, beside the live words, and a tap
/// to switch to the other one — as in the voice search of Gboard or Noon:
/// many customers read the app in English and speak Arabic. The switch is
/// kept for the next messages.
class AssistantVoiceLanguageSwitch extends StatelessWidget {
  const AssistantVoiceLanguageSwitch({super.key, required this.language});

  final AssistantVoiceLanguage language;

  /// The language's own name: "العربية", "English".
  static String nameOf(AssistantVoiceLanguage language) => switch (language) {
    AssistantVoiceLanguage.arabic => 'assistant.voice.lang_ar'.tr(),
    AssistantVoiceLanguage.english => 'assistant.voice.lang_en'.tr(),
  };

  void _switch(BuildContext context) {
    Haptics.selection();
    context.read<AssistantVoiceCubit>().switchLanguage();
  }

  @override
  Widget build(BuildContext context) {
    final name = nameOf(language);
    return Semantics(
      button: true,
      label: 'assistant.voice.a11y_language'.tr(namedArgs: {'language': name}),
      hint: 'assistant.voice.a11y_language_hint'.tr(
        namedArgs: {'language': nameOf(language.other)},
      ),
      onTap: () => _switch(context),
      excludeSemantics: true,
      // A finger-sized target around a small pill.
      child: SizedBox(
        height: AppSize.s48,
        child: Center(
          child: Material(
            color: AppColors.white,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _switch(context),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: AppSpacing.s6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      size: AppSize.s16,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      name,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
