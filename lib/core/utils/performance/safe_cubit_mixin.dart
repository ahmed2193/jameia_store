import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin for Cubits, ported from the tapasco/khayool reference.
///
/// Provides:
/// - [safeEmit] — emits only if the cubit is still open (guards the
///   emit-after-close race that offline `Future`-returning use cases can hit
///   when a screen is popped mid-load).
/// - [cancelToken] — a Dio [CancelToken] that auto-cancels on [close]. Harmless
///   while the app is offline; ready for the eventual live-API swap (core
///   already ships `DioConsumer` + `EndPoints`).
/// - [freshCancelToken] — creates a new token, cancelling the old one.
mixin SafeCubitMixin<S> on Cubit<S> {
  CancelToken? _cancelToken;

  /// Returns the current [CancelToken], creating one if needed.
  CancelToken get cancelToken => _cancelToken ??= CancelToken();

  /// Creates a fresh [CancelToken], cancelling the previous one.
  CancelToken freshCancelToken() {
    _cancelToken?.cancel('Refreshed cancel token');
    _cancelToken = CancelToken();
    return _cancelToken!;
  }

  /// Emits [state] only if the cubit has not been closed.
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('Cubit closed');
    _cancelToken = null;
    return super.close();
  }
}
