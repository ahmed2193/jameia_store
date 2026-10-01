import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/navigation/navigation.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';

/// "Cancel renewal": asks first, then stops the renewal (the paid period keeps
/// running). The page's busy overlay holds the screen while the call is in
/// flight; disabled during any other money action.
class ProCancelRenewalButton extends StatelessWidget {
  const ProCancelRenewalButton({super.key});

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<ProMembershipCubit>();
    final confirmed = await showHeroConfirmDialog(
      context,
      title: 'pro.confirm_cancel_title'.tr(),
      message: 'pro.confirm_cancel_body'.tr(),
      icon: HeroIcons.crown,
      confirmLabel: 'pro.cancel_renewal'.tr(),
      destructive: true,
    );
    if (confirmed) await cubit.cancelSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.isCancelling != current.isCancelling ||
          previous.isBusy != current.isBusy,
      builder: (context, state) {
        // Its own call keeps the red under the overlay; another one greys it.
        final blocked = state.isBusy && !state.isCancelling;
        return TextButton(
          onPressed: state.isBusy ? null : () => _cancel(context),
          child: Text(
            'pro.cancel_renewal'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: blocked ? AppColors.disabledText : AppColors.error,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        );
      },
    );
  }
}
