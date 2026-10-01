import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import '../../../../core/widgets/sticker_text.dart';

/// "Added ✓" — what the buy bar's block says for a moment after an add, in
/// sticker letters; the tick pops in.
class PdpAddedLabel extends StatelessWidget {
  const PdpAddedLabel({super.key, required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StickerText('product.added'.tr(), style: style),
        const SizedBox(width: AppSpacing.s6),
        PopScale.onMount(
          child: HeroIcon(
            HeroIcons.check,
            size: AppSize.s20,
            color: style.color,
          ),
        ),
      ],
    );
  }
}
