import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/load_more_footer.dart';
import '../../../../../core/widgets/next_page_sentinel.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';

/// Pagination sentinel at the end of the history: the list only builds it
/// when the server has more and it scrolls into view, and in view it asks
/// for the next page ([NextPageSentinel]). The shared [LoadMoreFooter]: the
/// branded dots while that page is in flight, the retry pill after a failed
/// attempt, swapped in place. Offline, a failed page says "More will load
/// when you're back" instead: the history asks again by itself.
class LedgerLoadMoreRow<T extends LedgerEntry> extends StatelessWidget {
  const LedgerLoadMoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LedgerCubit<T>>();
    return NextPageSentinel<LedgerCubit<T>, LedgerState<T>>(
      onNextPage: cubit.loadMore,
      builder: (context, failed) => LoadMoreFooter(
        failed: failed,
        onRetry: () => cubit.loadMore(retry: true),
      ),
    );
  }
}
