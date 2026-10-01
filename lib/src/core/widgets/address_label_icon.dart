import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_icons.dart';
import '../domain/entities/address_label.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';

/// The Hero glyph of an address tag (home, office, gathering, other —
/// [iconFor]): the address book rows, the label
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

  static IconData iconFor(AddressLabel label) => switch (label) {
    AddressLabel.home => HeroIcons.home,
    AddressLabel.work => HeroIcons.office,
    AddressLabel.gathering => HeroIcons.people,
    AddressLabel.other => HeroIcons.pin,
  };

  @override
  Widget build(BuildContext context) =>
      HeroIcon(iconFor(label), size: size, color: color);
}
