import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/next_page_sentinel.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import 'ledger_retry_pill.dart';

/// Pagination sentinel at the end of the history: the list only builds it
/// when the server has more and it scrolls into view, and in view it asks
/// for the next page ([NextPageSentinel]). The branded dots while that page
/// is in flight, a retry pill after a failed attempt — swapped in a
/// fixed-height slot, so the list never jumps. Offline, a failed page says
/// "More will load when you're back" instead: the history asks again by
/// itself.
class LedgerLoadMoreRow<T extends LedgerEntry> extends StatelessWidget {
  const LedgerLoadMoreRow({super.key});

  static const double _slot = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LedgerCubit<T>>();
    return NextPageSentinel<LedgerCubit<T>, LedgerState<T>>(
      onNextPage: cubit.loadMore,
      builder: (context, failed) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s8,
        ),
        child: SizedBox(
          height: _slot,
          child: FadeThroughSwitcher(
            stateKey: failed,
            child: failed
                ? LedgerRetryPill(onTap: () => cubit.loadMore(retry: true))
                : const AppLoader.inline(),
          ),
        ),
      ),
    );
  }
}
