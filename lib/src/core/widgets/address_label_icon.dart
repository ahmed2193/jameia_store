import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_assets.dart';
import '../domain/entities/address_label.dart';
import '../responsive/app_size.dart';
import 'hero_svg_glyph.dart';

/// The drawn Hero glyph of an address tag (home, office, gathering, other —
/// `HeroAssets.addressLabel*`, mono): the address book rows, the label
/// chips of the address form, an order's destination. Decorative: the tag's
/// name is always written beside it.
class AddressLabelIcon extends StatelessWidget {
  const AddressLabelIcon({
    super.key,
    required this.label,
    this.size = AppSize.s18,
    this.color = AppColors.primaryText,
  });

  final AddressLabel label;
  final double size;
  final Color color;

  static String assetFor(AddressLabel label) => switch (label) {
    AddressLabel.home => HeroAssets.addressLabelHome,
    AddressLabel.work => HeroAssets.addressLabelOffice,
    AddressLabel.gathering => HeroAssets.addressLabelGathering,
    AddressLabel.other => HeroAssets.addressLabelOther,
  };

  @override
  Widget build(BuildContext context) =>
      HeroSvgGlyph.mono(assetFor(label), size: size, color: color);
}
