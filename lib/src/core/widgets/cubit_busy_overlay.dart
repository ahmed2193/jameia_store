import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'busy_overlay.dart';

/// [BusyOverlay] fed straight from a page cubit: it selects only the busy
/// (and done) flags, so a flag change rebuilds the overlay — never the page
/// under it — and a data change never rebuilds the overlay.
///
/// ```dart
/// CubitBusyOverlay<ProfileCubit, ProfileState>(
///   busyOf: (state) => state.status == ProfileStatus.saving,
///   doneOf: (state) => state.status == ProfileStatus.saved,
///   doneLabel: 'profile.saved'.tr(),
///   child: Scaffold(...),
/// )
/// ```
class CubitBusyOverlay<C extends StateStreamable<S>, S>
    extends StatelessWidget {
  const CubitBusyOverlay({
    super.key,
    required this.busyOf,
    required this.child,
    this.doneOf,
    this.label,
    this.doneLabel,
  });

  final bool Function(S state) busyOf;
  final bool Function(S state)? doneOf;

  /// See [BusyOverlay.label] / [BusyOverlay.doneLabel].
  final String? label;
  final String? doneLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<C, S, (bool, bool)>(
      selector: (state) => (busyOf(state), doneOf?.call(state) ?? false),
      builder: (_, flags) => BusyOverlay(
        busy: flags.$1,
        done: flags.$2,
        label: label,
        doneLabel: doneLabel,
        child: child,
      ),
    );
  }
}
