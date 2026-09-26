import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../auth/presentation/cubit/auth_session_state.dart';
import 'mine_header_delegate.dart';
import 'mine_header_metrics.dart';

/// The pinned, collapsing profile header as a sliver, fed by the app-global
/// session: the signed-in customer, or `null` for a guest. Rebuilds only
/// when that snapshot changes (or the inset / text scale do).
class MineHeaderSliver extends StatelessWidget {
  const MineHeaderSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final textScaler = MediaQuery.textScalerOf(context);
    return BlocSelector<
      AuthSessionCubit,
      AuthSessionState,
      AuthCustomerEntity?
    >(
      selector: (session) => session.isSignedIn ? session.customer : null,
      builder: (context, customer) => SliverPersistentHeader(
        pinned: true,
        delegate: MineHeaderDelegate(
          customer: customer,
          metrics: MineHeaderMetrics(
            topInset: topInset,
            textScaler: textScaler,
            isGuest: customer == null,
          ),
        ),
      ),
    );
  }
}
