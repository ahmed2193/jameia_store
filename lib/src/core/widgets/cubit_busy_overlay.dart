import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'busy_overlay.dart';

/// [BusyOverlay] fed straight from a page cubit: it selects only the busy,
/// done and failed flags, so a flag change rebuilds the overlay — never the
/// page under it — and a data change never rebuilds the overlay.
///
/// [failOf] says the submit the overlay holds came back failed (the state's
/// transient failure of that action): the disc draws a × for a beat before
/// the overlay leaves and the page's failure snack bar takes over.
///
/// ```dart
/// CubitBusyOverlay<ProfileCubit, ProfileState>(
///   busyOf: (state) => state.status == ProfileStatus.saving,
///   doneOf: (state) => state.status == ProfileStatus.saved,
///   failOf: (state) => state.status == ProfileStatus.error,
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
    this.failOf,
    this.label,
    this.doneLabel,
    this.failLabel,
  });

  final bool Function(S state) busyOf;
  final bool Function(S state)? doneOf;
  final bool Function(S state)? failOf;

  /// See [BusyOverlay.label] / [BusyOverlay.doneLabel] /
  /// [BusyOverlay.failLabel].
  final String? label;
  final String? doneLabel;
  final String? failLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<C, S, (bool, bool, bool)>(
      selector: (state) => (
        busyOf(state),
        doneOf?.call(state) ?? false,
        failOf?.call(state) ?? false,
      ),
      builder: (_, flags) => BusyOverlay(
        busy: flags.$1,
        done: flags.$2,
        failed: flags.$3,
        label: label,
        doneLabel: doneLabel,
        failLabel: failLabel,
        child: child,
      ),
    );
  }
}
