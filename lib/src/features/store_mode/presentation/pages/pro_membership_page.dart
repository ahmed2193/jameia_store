import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import '../widgets/pro_membership_body.dart';

/// Jm3eia Pro: the programme's perks and plans
/// (`GET /v1/subscription-plans`) and the customer's subscription
/// (`/v1/account/subscription`). It replaced the offline "VIP ⇄ Mart" store
/// mode: member prices come from this subscription (`customer.isPro`).
class ProMembershipPage extends StatelessWidget {
  const ProMembershipPage({super.key});

  void _onState(BuildContext context, ProMembershipState state) {
    final outcome = state.outcome;
    if (outcome != null) {
      showJameiaSnackBar(context, switch (outcome) {
        ProMembershipOutcome.subscribed => 'pro.subscribed_toast'.tr(),
        ProMembershipOutcome.cancelled => 'pro.cancelled_toast'.tr(),
      });
      // The reply carries no customer object: re-read the session so
      // `isPro` (member prices everywhere) follows.
      context.read<AuthSessionCubit>().restore();
      return;
    }
    final failure = state.failure;
    // A failed first load is rendered inline by the body, not toasted.
    if (failure == null || state.status == ProMembershipStatus.error) return;
    showJameiaSnackBar(context, failure.localizedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProMembershipCubit>(
      create: (_) => sl<ProMembershipCubit>()..load(),
      child: Builder(
        builder: (context) => MultiBlocListener(
          listeners: [
            BlocListener<ProMembershipCubit, ProMembershipState>(
              listenWhen: (previous, current) =>
                  current.outcome != null ||
                  (current.failure != null &&
                      previous.failure != current.failure),
              listener: _onState,
            ),
            // Plan names arrive resolved for the request language.
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) =>
                  context.read<ProMembershipCubit>().load(),
            ),
          ],
          child: Scaffold(
            backgroundColor: AppColors.mediumBackground,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              surfaceTintColor: AppColors.white,
              elevation: 0,
              centerTitle: false,
              title: Text(
                'pro.title'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
            body: const ProMembershipBody(),
          ),
        ),
      ),
    );
  }
}
