import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';

/// Toasts the failures that keep the list on screen (a pull-to-refresh or a
/// next page). A failed first load is rendered inline by the body instead.
class LedgerFailureListener<T extends LedgerEntry> extends StatelessWidget {
  const LedgerFailureListener({
    super.key,
    required this.loadMoreFailedMessage,
    required this.child,
  });

  final String loadMoreFailedMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LedgerCubit<T>, LedgerState<T>>(
      listenWhen: (previous, current) =>
          current.failure != null && current.status != LedgerStatus.error,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showJameiaSnackBar(
          context,
          state.failedAction == LedgerAction.loadMore
              ? loadMoreFailedMessage
              : failure.localizedMessage,
        );
      },
      child: child,
    );
  }
}
