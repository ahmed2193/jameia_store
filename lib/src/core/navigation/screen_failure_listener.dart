import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/failures.dart';
import '../utils/performance/screen_loader_mixin.dart';
import 'jameia_snack_bar.dart';

/// Tells a screen's transient failures, the one way for every cached screen:
/// a failed read over the data on screen, or something the customer did,
/// goes through [showFailureSnackBar] (offline: a banner nudge, and "needs
/// internet" for an action). A failed next page is its footer's to tell and
/// the full-screen failure is the body's, so neither is toasted.
///
/// [onUnauthorized] (a customer route answered 401 over the data on screen)
/// replaces the snack bar — the page sends the customer to sign in.
class ScreenFailureListener<
  C extends StateStreamable<S>,
  S extends ScreenLoadState<S>
>
    extends StatelessWidget {
  const ScreenFailureListener({
    super.key,
    required this.child,
    this.onUnauthorized,
  });

  final Widget child;
  final void Function(BuildContext context)? onUnauthorized;

  static bool _shouldTell<S extends ScreenLoadState<S>>(S previous, S current) {
    final told = current.load.toldFailure;
    return told != null && told != previous.load.toldFailure;
  }

  void _tell(BuildContext context, S state) {
    final failure = state.load.toldFailure;
    if (failure == null) return;
    final signIn = onUnauthorized;
    if (failure is UnauthorizedFailure && signIn != null) {
      signIn(context);
      return;
    }
    showFailureSnackBar(context, failure, action: state.load.failedOnAction);
  }

  @override
  Widget build(BuildContext context) => BlocListener<C, S>(
    listenWhen: _shouldTell,
    listener: _tell,
    child: child,
  );
}
