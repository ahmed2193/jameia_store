import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/pro_brands_cubit.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import '../widgets/pro_membership_body.dart';
import '../widgets/pro_outcome_listener.dart';
import '../widgets/pro_status_reporter.dart';
import '../widgets/pro_top_bar.dart';

/// Hero Pro: the paywall for a guest, a prospect and a lapsed member, the
/// member hub for a member — the programme's plans and perks
/// (`GET /v1/subscription-plans`), the customer's subscription
/// (`/v1/account/subscription`) and the brands free delivery covers
/// (`GET /v1/brands`). It replaced the offline "VIP ⇄ Mart" store mode:
/// member prices come from this subscription (`customer.isPro`). What the
/// customer just did (subscribed / cancelled / a failed action) is answered
/// by [ProOutcomeListener]; what the page learned reaches the app-global Pro
/// status through [ProStatusReporter].
class ProMembershipPage extends StatelessWidget {
  const ProMembershipPage({super.key});

  /// Subscribing and cancelling the renewal hold the screen until the
  /// server answers.
  static bool _busy(ProMembershipState state) => state.isBusy;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProMembershipCubit>(
          create: (_) => sl<ProMembershipCubit>()..load(),
        ),
        BlocProvider<ProBrandsCubit>(
          create: (_) => sl<ProBrandsCubit>()..load(),
        ),
      ],
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              // Plan and brand names arrive resolved for the request language.
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) {
                context.read<ProMembershipCubit>().load();
                context.read<ProBrandsCubit>().load();
              },
              child:
                  const CubitBusyOverlay<
                    ProMembershipCubit,
                    ProMembershipState
                  >(
                    busyOf: _busy,
                    child: Scaffold(
                      backgroundColor: AppColors.white,
                      body: ProStatusReporter(
                        child: ProOutcomeListener(
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              children: [
                                ProTopBar(),
                                Expanded(child: ProMembershipBody()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
      ),
    );
  }
}
