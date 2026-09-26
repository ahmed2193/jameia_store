import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_paywall_view.dart';
import 'pro_unavailable_view.dart';

/// Body of the Pro page: loader → the paywall; "programme unavailable" when
/// the store switched Pro off; error + retry (offline = the error view). A
/// guest sees the whole paywall; joining leads to sign-in.
class ProMembershipBody extends StatelessWidget {
  const ProMembershipBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProMembershipCubit, ProMembershipState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.program.isUnavailable != current.program.isUnavailable,
      builder: (context, state) {
        final cubit = context.read<ProMembershipCubit>();
        return switch (state.status) {
          ProMembershipStatus.initial ||
          ProMembershipStatus.loading => const AppLoader(),
          ProMembershipStatus.error => ErrorView(
            message: state.failure?.localizedMessage,
            onRetry: cubit.load,
          ),
          ProMembershipStatus.loaded when state.program.isUnavailable =>
            ProUnavailableView(onRefresh: cubit.refresh),
          ProMembershipStatus.loaded => const ProPaywallView(),
        };
      },
    );
  }
}
