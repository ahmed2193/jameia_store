import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_assistant_availability_usecase.dart';
import 'assistant_availability_state.dart';

/// App-global: whether the store runs the assistant (`/v1/init`), read once
/// per app run when the first entry point builds. It does not depend on the
/// session, so sign-in / sign-out keep it.
///
/// A failed read (offline at launch, a timeout) is tried again on its own
/// after [retryDelays] — otherwise the entry points would stay hidden until
/// the app restarts.
class AssistantAvailabilityCubit extends Cubit<AssistantAvailabilityState>
    with SafeCubitMixin<AssistantAvailabilityState> {
  AssistantAvailabilityCubit({
    required this._getAvailability,
    this.retryDelays = defaultRetryDelays,
  }) : super(const AssistantAvailabilityState());

  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 20),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  final GetAssistantAvailabilityUseCase _getAvailability;

  /// Waits before each automatic retry; after the last one, only a new
  /// [ensureLoaded] call reads again.
  final List<Duration> retryDelays;

  bool _loading = false;
  int _failures = 0;
  Timer? _retry;

  /// Reads the flags unless they are known or already on their way. A failed
  /// read leaves [AssistantAvailabilityStatus.unknown] (entries hidden) and
  /// schedules the next attempt.
  Future<void> ensureLoaded() async {
    if (_loading || state.status != AssistantAvailabilityStatus.unknown) {
      return;
    }
    _retry?.cancel();
    _loading = true;
    final result = await _getAvailability(const NoParams());
    _loading = false;
    if (isClosed) return;
    result.fold(
      (_) => _scheduleRetry(),
      (availability) => safeEmit(
        AssistantAvailabilityState(
          status: availability.isAvailable
              ? AssistantAvailabilityStatus.available
              : AssistantAvailabilityStatus.unavailable,
          allowGuests: availability.allowGuests,
        ),
      ),
    );
  }

  void _scheduleRetry() {
    if (_failures >= retryDelays.length) return;
    _retry = Timer(retryDelays[_failures++], () => unawaited(ensureLoaded()));
  }

  @override
  Future<void> close() {
    _retry?.cancel();
    return super.close();
  }
}
