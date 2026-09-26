import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import 'ledger_retry_pill.dart';

/// Pagination sentinel at the end of the history: the list only builds it
/// when the server has more, and building it (scrolling it into view) asks
/// the cubit for the next page. The branded dots while that page is in
/// flight, a retry pill after a failed attempt — swapped in a fixed-height
/// slot, so the list never jumps.
class LedgerLoadMoreRow<T extends LedgerEntry> extends StatefulWidget {
  const LedgerLoadMoreRow({super.key});

  @override
  State<LedgerLoadMoreRow<T>> createState() => _LedgerLoadMoreRowState<T>();
}

class _LedgerLoadMoreRowState<T extends LedgerEntry>
    extends State<LedgerLoadMoreRow<T>> {
  static const double _slot = AppSize.s48;

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
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: SizedBox(
        height: _slot,
        child: BlocSelector<LedgerCubit<T>, LedgerState<T>, bool>(
          // Loader by default (also for the frame before the request starts,
          // so "retry" never flashes); the retry shows only after a failure.
          selector: (state) => state.loadMoreFailed,
          builder: (context, failed) => FadeThroughSwitcher(
            stateKey: failed,
            child: failed
                ? LedgerRetryPill(
                    onTap: () => context.read<LedgerCubit<T>>().loadMore(),
                  )
                : const AppLoader(size: AppSize.s20),
          ),
        ),
      ),
    );
  }
}
