import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';

/// Copies [text] (the order number) for the customer to paste into a chat
/// with support, then says so.
class TrackingCopyButton extends StatelessWidget {
  const TrackingCopyButton({super.key, required this.text});

  final String text;

  Future<void> _copy(BuildContext context) async {
    Haptics.commit();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showHeroSnackBar(
        context,
        'orders.number_copied'.tr(),
        tone: HeroSnackTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _copy(context),
      tooltip: 'orders.copy_number'.tr(),
      visualDensity: VisualDensity.compact,
      iconSize: AppSize.s18,
      color: AppColors.brandDeep,
      icon: const Icon(Icons.copy_rounded),
    );
  }
}
