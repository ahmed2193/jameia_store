import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/screen_load.dart';
import '../utils/performance/screen_loader_mixin.dart';
import 'connectivity_scope.dart';
import 'load_more_offline_note.dart';
import 'offline_inline_note.dart';

/// The end of a paged list while the server has more, written once for the
/// lists that page by building it (a lazy sliver or list row): whenever it
/// is in view with no page on its way it asks for the next one — when it
/// first appears, after each page lands, after page 1 was read again — so a
/// short list fills up and a list never dead-ends on a spinner.
///
/// A failed page waits: offline it says "More will load when you're back"
/// (the list asks again by itself on reconnect); otherwise [builder] shows
/// the list's own retry. While a page is on its way, [builder] shows its
/// loader.
class NextPageSentinel<
  C extends StateStreamable<S>,
  S extends ScreenLoadState<S>
>
    extends StatelessWidget {
  const NextPageSentinel({
    super.key,
    required this.onNextPage,
    required this.builder,
    this.offlinePadding = OfflineInlineNote.defaultPadding,
  });

  /// Asks the cubit for the next page (it ignores a call it cannot serve).
  final VoidCallback onNextPage;

  /// The footer while a page is on its way (`failed` = false) or after one
  /// failed while online (`failed` = true: the retry).
  final Widget Function(BuildContext context, bool failed) builder;

  /// A list that already keeps its side gutters passes a vertical one.
  final EdgeInsetsGeometry offlinePadding;

  @override
  Widget build(BuildContext context) => BlocSelector<C, S, NextPageLoad>(
    selector: (state) => state.load.nextPage,
    builder: (context, nextPage) {
      if (nextPage == NextPageLoad.idle) {
        // After the frame: emitting during build would rebuild the list
        // mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onNextPage();
        });
      }
      final failed = nextPage == NextPageLoad.failed;
      if (failed && ConnectivityScope.isOfflineOf(context)) {
        return LoadMoreOfflineNote(padding: offlinePadding);
      }
      return builder(context, failed);
    },
  );
}
