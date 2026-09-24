import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';

/// White centred "My addresses" bar with a back glyph (RE §5).
class AddressListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AddressListAppBar({super.key});

  static const double _scrolledUnderElevation = AppSize.s0_5;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.primaryText,
      elevation: 0,
      scrolledUnderElevation: _scrolledUnderElevation,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(JameiaIcons.back, size: AppSize.s20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'addr.my_addresses'.tr(),
        style: AppTextStyles.headingLarge.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
