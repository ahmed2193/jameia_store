import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';

/// `handoff`: the support ticket a person will answer in this chat.
class AssistantHandoffCard extends StatelessWidget {
  const AssistantHandoffCard({super.key, required this.block});

  final AssistantHandoffBlock block;

  @override
  Widget build(BuildContext context) {
    return AssistantCardFrame(
      title: 'assistant.handoff_title'.tr(
        namedArgs: {'number': Formatters.isolate(block.ticketNumber)},
      ),
      icon: HeroIcons.support,
      borderColor: AppColors.brandTileBorder,
      child: Text(
        'assistant.handoff_body'.tr(),
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
      ),
    );
  }
}
