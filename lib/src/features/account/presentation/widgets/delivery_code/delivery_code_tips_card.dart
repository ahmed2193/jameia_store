import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../settings/settings_card.dart';
import '../settings/settings_tone.dart';
import 'delivery_code_tip_row.dart';

/// How the delivery code works: give it at the door, never share it in
/// chat, change it only with no order running.
class DeliveryCodeTipsCard extends StatelessWidget {
  const DeliveryCodeTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          DeliveryCodeTipRow(
            icon: JameiaIcons.delivery,
            tone: SettingsTone.amber,
            text: 'account.explain_give_code'.tr(),
          ),
          const SizedBox(height: AppSpacing.s14),
          DeliveryCodeTipRow(
            icon: JameiaIcons.alert,
            tone: SettingsTone.danger,
            text: 'account.explain_never_share'.tr(),
          ),
          const SizedBox(height: AppSpacing.s14),
          DeliveryCodeTipRow(
            icon: JameiaIcons.info,
            tone: SettingsTone.sky,
            text: 'account.explain_change_when_idle'.tr(),
          ),
        ],
      ),
    );
  }
}
