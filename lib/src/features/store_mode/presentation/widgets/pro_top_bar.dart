import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/shell_arrival.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import 'pro_brand_lockup.dart';

/// The paywall's top bar: close on the start side, the "Hero | Pro" lockup
/// centred (a box as wide as the close button balances it on the end side).
/// Closing returns to where the customer came from, or home when the page
/// was opened directly.
class ProTopBar extends StatelessWidget {
  const ProTopBar({super.key});

  static const double _height = AppSize.s56;
  static const double _side = AppSize.s48;

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.shell, extra: ShellArrival());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s4,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _side,
              child: IconButton(
                onPressed: () => _close(context),
                tooltip: 'pro.close'.tr(),
                icon: const HeroIcon(
                  HeroIcons.close,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const Expanded(child: Center(child: ProBrandLockup())),
            const SizedBox(width: _side),
          ],
        ),
      ),
    );
  }
}
