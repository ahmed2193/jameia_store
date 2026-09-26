import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import 'ledger_list.dart';
import 'ledger_skeleton.dart';

/// Switches a wallet / points screen on the cubit status — skeleton, sign-in
/// prompt (the route answered 401), error + retry, or the list — fading
/// through from one to the next. Transient failures (refresh, next page)
/// are the failure listener's business.
class LedgerBody<T extends LedgerEntry> extends StatelessWidget {
  const LedgerBody({
    super.key,
    required this.header,
    required this.entryBuilder,
    required this.entryDate,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.signInMessage,
    required this.todayLabel,
    required this.yesterdayLabel,
  });

  /// Above the entries: the balance card and the section title.
  final Widget header;

  /// One history row.
  final Widget Function(T entry) entryBuilder;

  /// When a line was booked — the history groups on its day.
  final DateTime Function(T entry) entryDate;
  final IconData emptyIcon;
  final String emptyMessage;
  final String signInMessage;
  final String todayLabel;
  final String yesterdayLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LedgerCubit<T>, LedgerState<T>>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.ledger != current.ledger,
      builder: (context, state) => FadeThroughSwitcher(
        // `initial` and `loading` are one skeleton; the sign-in prompt and
        // the error view are two different screens.
        stateKey: (
          state.status == LedgerStatus.initial
              ? LedgerStatus.loading
              : state.status,
          state.isSignedOut,
        ),
        child: switch (state.status) {
          LedgerStatus.initial ||
          LedgerStatus.loading => const LedgerSkeleton(),
          LedgerStatus.error when state.isSignedOut => EmptyStateView(
            message: signInMessage,
            icon: Icons.lock_outline_rounded,
            actionLabel: 'auth.log_in_or_sign_up'.tr(),
            onAction: () => context.go(Routes.login),
          ),
          LedgerStatus.error => ErrorView(
            message: state.failure?.localizedMessage,
            onRetry: () => context.read<LedgerCubit<T>>().load(),
          ),
          LedgerStatus.loaded => LedgerList<T>(
            ledger: state.ledger,
            header: header,
            entryBuilder: entryBuilder,
            entryDate: entryDate,
            empty: EmptyStateView(message: emptyMessage, icon: emptyIcon),
            todayLabel: todayLabel,
            yesterdayLabel: yesterdayLabel,
          ),
        },
      ),
    );
  }
}
