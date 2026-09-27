import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../cubit/account_cubit.dart';
import 'mine_code_pill.dart';
import 'mine_menu_cell.dart';
import 'mine_tone.dart';

/// The delivery-code card: its own white card with the code in a dark pill
/// → the delivery-code page. Rebuilds only when the code changes.
class MineDeliveryCodeCell extends StatelessWidget {
  const MineDeliveryCodeCell({super.key});

  static final BorderRadius _radius = BorderRadius.circular(AppRadius.r3);

  @override
  Widget build(BuildContext context) {
    final code = context.select<AccountCubit, String>(
      (account) => account.state.user?.deliveryCode ?? '',
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: AppShadows.low,
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: _radius,
          clipBehavior: Clip.antiAlias,
          child: MineMenuCell(
            icon: HeroIcons.confirmReceipt,
            tone: MineTone.brand,
            label: 'account.delivery_code'.tr(),
            onTap: () => context.push(Routes.mineDeliveryCode),
            trailing: MineCodePill(code: code),
          ),
        ),
      ),
    );
  }
}
