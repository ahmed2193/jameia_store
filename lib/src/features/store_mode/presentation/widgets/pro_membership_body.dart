import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/pro_brands_cubit.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_paywall_view.dart';
import 'pro_unavailable_view.dart';

/// Body of the Pro page: loader → the paywall (the saved one at once, with
/// the "Updated … ago" note while offline or after a failed reload);
/// "programme unavailable" when the store switched Pro off; error + retry,
/// or "No connection" when nothing is saved. A guest sees the whole
/// paywall; joining leads to sign-in. A returning connection refreshes a
/// saved or failed page, and the brand rows when none could be shown.
class ProMembershipBody extends StatelessWidget {
  const ProMembershipBody({super.key});

  void _onReconnected(BuildContext context) {
    unawaited(context.read<ProMembershipCubit>().onReconnected());
    unawaited(context.read<ProBrandsCubit>().onReconnected());
  }

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => _onReconnected(context),
      child: BlocBuilder<ProMembershipCubit, ProMembershipState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.program.isUnavailable != current.program.isUnavailable,
        builder: (context, state) {
          final cubit = context.read<ProMembershipCubit>();
          return switch (state.status) {
            ProMembershipStatus.initial ||
            ProMembershipStatus.loading => const AppLoader(),
            ProMembershipStatus.error => FailureView(
              failure: state.failure,
              onRetry: cubit.load,
            ),
            ProMembershipStatus.loaded when state.program.isUnavailable =>
              ProUnavailableView(onRefresh: cubit.refresh),
            ProMembershipStatus.loaded => const ProPaywallView(),
          };
        },
      ),
    );
  }
}
