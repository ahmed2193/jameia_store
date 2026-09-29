import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../settings/settings_card.dart';
import '../settings/settings_tone.dart';
import 'delivery_code_tip_row.dart';

/// How the delivery code works: the handover picture (the rider at the door
/// asks, the phone shows the code — [HeroAssets.deliveryCodeHandover],
/// mirrored in RTL so it reads from the start), then give it at the door,
/// never share it in chat, change it only with no order running. The
/// picture is decorative: the first tip says the same in words.
class DeliveryCodeTipsCard extends StatelessWidget {
  const DeliveryCodeTipsCard({super.key});

  static const double _artWidth = AppSize.s120;
  static const double _artHeight = AppSize.s90;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          SvgPicture.asset(
            HeroAssets.deliveryCodeHandover,
            width: _artWidth,
            height: _artHeight,
            matchTextDirection: true,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: AppSpacing.s12),
          DeliveryCodeTipRow(
            icon: HeroIcons.delivery,
            tone: SettingsTone.amber,
            text: 'account.explain_give_code'.tr(),
          ),
          const SizedBox(height: AppSpacing.s14),
          DeliveryCodeTipRow(
            icon: HeroIcons.alert,
            tone: SettingsTone.danger,
            text: 'account.explain_never_share'.tr(),
          ),
          const SizedBox(height: AppSpacing.s14),
          DeliveryCodeTipRow(
            icon: HeroIcons.info,
            tone: SettingsTone.sky,
            text: 'account.explain_change_when_idle'.tr(),
          ),
        ],
      ),
    );
  }
}
