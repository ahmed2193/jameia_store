import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/summary_row.dart';
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
      icon: Icons.delivery_dining_outlined,
      child: Column(
        children: [
          if (area != null && block.hasArea)
            SummaryRow(label: 'assistant.delivery_area'.tr(), value: area),
          if (zone != null && block.hasZone)
            SummaryRow(label: 'assistant.delivery_zone'.tr(), value: zone),
          if (fee != null)
            SummaryRow(
              label: 'assistant.delivery_fee'.tr(),
              value: fee == 0
                  ? 'assistant.delivery_free'.tr()
                  : Formatters.isolate(Formatters.price(fee)),
              valueColor: fee == 0 ? AppColors.freeDelivery : null,
            ),
          if (eta != null)
            SummaryRow(
              label: 'assistant.delivery_eta_label'.tr(),
              value: 'assistant.delivery_eta'.tr(
                namedArgs: {'minutes': '$eta'},
              ),
            ),
        ],
      ),
    );
  }
}
