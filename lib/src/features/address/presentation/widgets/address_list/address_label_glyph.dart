import 'package:flutter/material.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/address_label.dart';
import '../../../../../core/responsive/app_size.dart';

/// The 18dp tag glyph (RE §5 / §2.1).
class AddressLabelGlyph extends StatelessWidget {
  const AddressLabelGlyph({super.key, required this.label});

  final AddressLabel label;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      switch (label) {
        AddressLabel.home => HeroAssets.labelHome,
        AddressLabel.work => HeroAssets.labelOffice,
        AddressLabel.gathering => HeroAssets.labelGathering,
        AddressLabel.other => HeroAssets.labelOther,
      },
      width: AppSize.s18,
      height: AppSize.s18,
      fit: BoxFit.contain,
    );
  }
}
