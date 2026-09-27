import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/data_freshness.dart';
import 'stale_data_notice.dart';

/// [StaleDataNotice] fed straight from a page cubit: it selects only the
/// freshness, so a freshness change rebuilds the note — never the list
/// beside it — and a data change never rebuilds the note.
class CubitStaleNotice<C extends StateStreamable<S>, S>
    extends StatelessWidget {
  const CubitStaleNotice({
    super.key,
    required this.freshnessOf,
    this.padding = StaleDataNotice.defaultPadding,
  });

  final DataFreshness Function(S state) freshnessOf;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => BlocSelector<C, S, DataFreshness>(
    selector: freshnessOf,
    builder: (context, freshness) =>
        StaleDataNotice(freshness: freshness, padding: padding),
  );
}
