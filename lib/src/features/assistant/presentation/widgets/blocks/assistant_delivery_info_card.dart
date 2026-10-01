import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/hero_money_text.dart';
import '../../../../../core/widgets/hero_summary_line.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';

/// `delivery_info`: area, zone, fee (0 is "Free" — N22) and the usual wait.
/// Only the fields the server sent are drawn.
class AssistantDeliveryInfoCard extends StatelessWidget {
  const AssistantDeliveryInfoCard({super.key, required this.block});

  final AssistantDeliveryInfoBlock block;

  @override
  Widget build(BuildContext context) {
    final fee = block.feeKd;
    final eta = block.etaMinutes;
    final area = block.areaName;
    final zone = block.zoneName;
    return AssistantCardFrame(
      title: 'assistant.delivery_title'.tr(),
      icon: HeroIcons.delivery,
      child: Column(
        children: [
          if (area != null && block.hasArea)
            HeroSummaryLine(
              label: 'assistant.delivery_area'.tr(),
              value: Text(area),
            ),
          if (zone != null && block.hasZone)
            HeroSummaryLine(
              label: 'assistant.delivery_zone'.tr(),
              value: Text(zone),
            ),
          if (fee != null)
            HeroSummaryLine(
              label: 'assistant.delivery_fee'.tr(),
              value: fee == 0
                  ? Text(
                      'assistant.delivery_free'.tr(),
                      style: const TextStyle(color: AppColors.brandDeep),
                    )
                  : HeroMoneyText(kd: fee),
            ),
          if (eta != null)
            HeroSummaryLine(
              label: 'assistant.delivery_eta_label'.tr(),
              value: Text(
                'assistant.delivery_eta'.tr(namedArgs: {'minutes': '$eta'}),
              ),
            ),
        ],
      ),
    );
  }
}
