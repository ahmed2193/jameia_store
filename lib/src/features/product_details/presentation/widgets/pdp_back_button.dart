import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/hero_icons.dart';
import '../../../../core/widgets/round_outlined_button.dart';

/// Leaves the product page: the storefront's round white button, reading on
/// the gallery and on the white bar the gallery scrolls under. The arrow
/// flips with the reading direction.
class PdpBackButton extends StatelessWidget {
  const PdpBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return RoundOutlinedButton(
      icon: HeroIcons.back,
      label: 'common.back'.tr(),
      onTap: () => context.pop(),
    );
  }
}
