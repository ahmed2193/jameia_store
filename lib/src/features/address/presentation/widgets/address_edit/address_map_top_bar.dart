import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/hero_map_button.dart';
import 'address_search_pill.dart';

/// Floats over the top of the map picker: back, and the search pill — which
/// steps aside while the building-type panel is up ([searchHidden]), as in
/// Glovo, leaving back alone over the map.
class AddressMapTopBar extends StatelessWidget {
  const AddressMapTopBar({
    super.key,
    required this.onBack,
    required this.onSearch,
    required this.searchHidden,
  });

  final VoidCallback onBack;
  final VoidCallback onSearch;
  final ValueListenable<bool> searchHidden;

  /// Its height (the map keeps this much room under the status bar): the
  /// map button's, which the pill matches.
  static const double height = HeroMapButton.diameter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroMapButton(
          icon: HeroIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: searchHidden,
            builder: (context, hidden, pill) => IgnorePointer(
              ignoring: hidden,
              child: AnimatedOpacity(
                opacity: hidden ? 0 : 1,
                duration: MotionGuard.duration(context, AppMotion.fast),
                curve: AppMotion.signature,
                child: pill,
              ),
            ),
            child: AddressSearchPill(onTap: onSearch),
          ),
        ),
      ],
    );
  }
}
