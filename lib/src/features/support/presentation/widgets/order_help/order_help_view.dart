import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/failure_view.dart';
import '../../cubit/order_help_cubit.dart';
import '../../cubit/order_help_state.dart';
import 'order_help_body.dart';
import 'order_help_sent_view.dart';
import 'order_help_skeleton.dart';

enum _Screen { loading, failed, form, sent }

/// The help page's state swap: the skeleton while the options are on the
/// way, the connection check / error with a retry when they could not be
/// read, the form, and the thanks once the ticket is open. Rebuilds only
/// when one of those changes — never on a pick or a keystroke.
class OrderHelpView extends StatelessWidget {
  const OrderHelpView({
    super.key,
    required this.order,
    required this.onSend,
    required this.onDone,
  });

  final OrderEntity order;
  final VoidCallback onSend;
  final VoidCallback onDone;

  static bool _screenChanged(OrderHelpState previous, OrderHelpState current) =>
      current.load.screenChangedFrom(previous.load) ||
      previous.groups != current.groups ||
      previous.receipt != current.receipt;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderHelpCubit, OrderHelpState>(
      buildWhen: _screenChanged,
      builder: (context, state) {
        final failure = state.loadFailure;
        final (_Screen screen, Widget child) = state.sent
            ? (_Screen.sent, OrderHelpSentView(onDone: onDone))
            : state.load.isLoaded
            ? (
                _Screen.form,
                OrderHelpBody(
                  order: order,
                  groups: state.groups,
                  onSend: onSend,
                ),
              )
            : failure != null
            ? (
                _Screen.failed,
                FailureView(
                  failure: failure,
                  onRetry: () => context.read<OrderHelpCubit>().load(),
                ),
              )
            : (_Screen.loading, const OrderHelpSkeleton());
        return FadeThroughSwitcher(stateKey: screen, child: child);
      },
    );
  }
}
