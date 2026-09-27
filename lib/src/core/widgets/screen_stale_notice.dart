import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/data_freshness.dart';
import '../utils/performance/screen_loader_mixin.dart';
import 'cubit_stale_notice.dart';
import 'stale_data_notice.dart';

/// The "Updated … ago" note of a screen whose state holds a `ScreenLoad`:
/// [CubitStaleNotice] selecting that load's freshness, so no page declares
/// its own selector.
class ScreenStaleNotice<
  C extends StateStreamable<S>,
  S extends ScreenLoadState<S>
>
    extends StatelessWidget {
  const ScreenStaleNotice({
    super.key,
    this.padding = StaleDataNotice.defaultPadding,
  });

  final EdgeInsetsGeometry padding;

  DataFreshness _freshnessOf(S state) => state.load.freshness;

  @override
  Widget build(BuildContext context) =>
      CubitStaleNotice<C, S>(freshnessOf: _freshnessOf, padding: padding);
}
