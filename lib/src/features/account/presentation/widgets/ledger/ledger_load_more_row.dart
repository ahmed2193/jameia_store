import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';

/// Pagination sentinel at the end of the history: the list only builds it
/// when the server has more, and building it (scrolling it into view) asks
/// the cubit for the next page. A loader while that page is in flight, a
/// retry after a failed attempt.
class LedgerLoadMoreRow<T extends LedgerEntry> extends StatefulWidget {
  const LedgerLoadMoreRow({super.key});

  @override
  State<LedgerLoadMoreRow<T>> createState() => _LedgerLoadMoreRowState<T>();
}

class _LedgerLoadMoreRowState<T extends LedgerEntry>
    extends State<LedgerLoadMoreRow<T>> {
  @override
  void initState() {
    super.initState();
    // After the frame: emitting during build would rebuild the list mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LedgerCubit<T>>().loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: BlocSelector<LedgerCubit<T>, LedgerState<T>, bool>(
        // Loader by default (also for the frame before the request starts, so
        // "retry" never flashes); the retry shows only after a failed attempt.
        selector: (state) => state.loadMoreFailed,
        builder: (context, failed) => !failed
            ? const AppLoader(size: AppSize.s20)
            : Center(
                child: TextButton(
                  onPressed: () => context.read<LedgerCubit<T>>().loadMore(),
                  child: Text('retry'.tr()),
                ),
              ),
      ),
    );
  }
}
