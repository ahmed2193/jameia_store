import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import '../cubit/pro_status_cubit.dart';

/// Hands what the Pro page just learned (its load, a subscribe, a cancel) to
/// the app-global [ProStatusCubit], so the home header, the Mine row and the
/// cart follow at once instead of on the next launch. Only the server's
/// answer is handed over — the device copy the page paints first may be
/// older than what the status already knows. A guest page reports nothing:
/// the session, not this page, decides who is signed out.
class ProStatusReporter extends StatelessWidget {
  const ProStatusReporter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProMembershipCubit, ProMembershipState>(
      listenWhen: (previous, current) =>
          current.isLoaded &&
          !current.isSignedOut &&
          current.isMembershipConfirmed &&
          (!previous.isLoaded ||
              !previous.isMembershipConfirmed ||
              previous.membership != current.membership),
      listener: (context, state) =>
          context.read<ProStatusCubit>().apply(state.membership),
      child: child,
    );
  }
}
