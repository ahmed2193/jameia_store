import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_loader.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_confirm_dialog.dart';

/// "Cancel renewal": asks first, then stops the renewal (the paid period keeps
/// running). A loader while the call is in flight; disabled during any other
/// money action.
class ProCancelRenewalButton extends StatelessWidget {
  const ProCancelRenewalButton({super.key});

  static const double _loaderBox = AppSize.s40;

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<ProMembershipCubit>();
    final confirmed = await showJameiaDialog<bool>(
      context,
      barrierLabel: 'pro.cancel_renewal'.tr(),
      pageBuilder: (_) => ProConfirmDialog(
        title: 'pro.confirm_cancel_title'.tr(),
        message: 'pro.confirm_cancel_body'.tr(),
        confirmLabel: 'pro.cancel_renewal'.tr(),
        isDestructive: true,
      ),
    );
    if (confirmed ?? false) await cubit.cancelSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.isCancelling != current.isCancelling ||
          previous.isBusy != current.isBusy,
      builder: (context, state) {
        if (state.isCancelling) {
          return const SizedBox(
            height: _loaderBox,
            child: AppLoader(size: AppSize.s16),
          );
        }
        return TextButton(
          onPressed: state.isBusy ? null : () => _cancel(context),
          child: Text(
            'pro.cancel_renewal'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: state.isBusy ? AppColors.disabledText : AppColors.error,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        );
      },
    );
  }
}
