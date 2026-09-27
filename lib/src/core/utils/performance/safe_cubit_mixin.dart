import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin for Cubits, ported from the tapasco/khayool reference.
///
/// [safeEmit] emits only if the cubit is still open (guards the emit-after-
/// close race a `Future`-returning use case hits when a screen is popped
/// mid-load).
mixin SafeCubitMixin<S> on Cubit<S> {
  /// Emits [state] only if the cubit has not been closed.
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
