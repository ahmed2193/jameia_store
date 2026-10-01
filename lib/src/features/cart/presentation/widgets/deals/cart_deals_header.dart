import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/hero_sheet_header.dart';

/// The deals sheet's head: the shared sheet header — "Buy more, save more"
/// with the "grab all offers" line under it and the ✕ at the end.
class CartDealsHeader extends StatelessWidget {
  const CartDealsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroSheetHeader(
      title: 'cart.deals_title'.tr(),
      subtitle: 'cart.deals_subtitle'.tr(),
    );
  }
}
